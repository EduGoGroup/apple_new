import Foundation
import OSLog
import EduNetwork
import EduModels

/// Actor responsable de cargar y cachear definiciones de pantalla.
public actor ScreenLoader {
    private let networkClient: NetworkClientProtocol
    private let baseURL: String
    private var memoryCache: [String: CachedScreen] = [:]
    private var etagCache: [String: String] = [:]
    private var bundleVersions: [String: String] = [:]
    private let maxCacheSize: Int
    private let defaultTTL: TimeInterval
    private let logger: os.Logger?

    /// Entrada de cache para una pantalla.
    public struct CachedScreen: Sendable {
        public let screen: ScreenDefinition
        public let cachedAt: Date
        public let etag: String?
        public let expiresAt: Date
        public let bundleVersion: String?
    }

    public init(
        networkClient: NetworkClientProtocol,
        baseURL: String,
        maxCacheSize: Int = 20,
        cacheExpiration: TimeInterval = 3600,
        logger: os.Logger? = nil
    ) {
        self.networkClient = networkClient
        self.baseURL = baseURL
        self.maxCacheSize = maxCacheSize
        self.defaultTTL = cacheExpiration
        self.logger = logger
    }

    // MARK: - Seed from Sync Bundle

    /// Pre-populates the cache with screens from the sync bundle.
    ///
    /// Converts each `ScreenBundleDTO` into a `ScreenDefinition` and stores it
    /// in the memory cache with pattern-based TTL. Screens with zero TTL
    /// (e.g. login) are skipped.
    ///
    /// Screen serialization/deserialization runs in parallel via `withTaskGroup`
    /// for improved performance with large bundles.
    public func seedFromBundle(screens: [String: ScreenBundleDTO]) async {
        // Capture defaultTTL for use in child tasks (value type, safe to capture)
        let capturedDefaultTTL = defaultTTL

        let results = await withTaskGroup(
            of: (String, ScreenDefinition, String, TimeInterval)?.self
        ) { group in
            for (key, bundleDTO) in screens {
                group.addTask {
                    guard let pattern = ScreenPattern(rawValue: bundleDTO.pattern) else {
                        return nil
                    }

                    let patternTTL = Self.effectiveTTLStatic(
                        for: pattern,
                        defaultTTL: capturedDefaultTTL
                    )
                    guard patternTTL > 0 else { return nil }

                    let encoder = JSONEncoder()
                    let decoder = JSONDecoder()

                    guard let templateData = try? encoder.encode(bundleDTO.template),
                          let template = try? decoder.decode(ScreenTemplate.self, from: templateData) else {
                        return nil
                    }

                    let slotData: [String: JSONValue]? = bundleDTO.slotData?.objectValue
                    let versionInt = Int(bundleDTO.version.split(separator: ".").first ?? "0") ?? 0

                    let screen = ScreenDefinition(
                        screenId: bundleDTO.screenKey,
                        screenKey: bundleDTO.screenKey,
                        screenName: bundleDTO.screenName,
                        pattern: pattern,
                        version: versionInt,
                        template: template,
                        slotData: slotData,
                        dataEndpoint: nil,
                        dataConfig: nil,
                        actions: [],
                        handlerKey: bundleDTO.handlerKey,
                        updatedAt: ""
                    )

                    return (key, screen, bundleDTO.version, patternTTL)
                }
            }

            var collected: [(String, ScreenDefinition, String, TimeInterval)] = []
            for await result in group {
                if let entry = result {
                    collected.append(entry)
                }
            }
            return collected
        }

        let now = Date()
        for (key, screen, version, patternTTL) in results {
            memoryCache[key] = CachedScreen(
                screen: screen,
                cachedAt: now,
                etag: nil,
                expiresAt: now.addingTimeInterval(patternTTL),
                bundleVersion: version
            )
            bundleVersions[key] = version
        }
    }

    /// Pure function to compute TTL for a pattern. Used by child tasks in `seedFromBundle`.
    private static func effectiveTTLStatic(for pattern: ScreenPattern, defaultTTL: TimeInterval) -> TimeInterval {
        guard defaultTTL > 0 else { return 0 }
        switch pattern {
        case .dashboard: return 60
        case .list: return 300
        case .form: return 3600
        case .detail: return 600
        case .settings: return 1800
        case .login: return 0
        case .search, .profile, .modal, .notification, .onboarding, .emptyState:
            return 300
        }
    }

    // MARK: - TTL per Pattern

    /// Returns the effective cache TTL for a given screen pattern.
    ///
    /// If `defaultTTL` was set to zero (via `cacheExpiration: 0` in init),
    /// all TTLs resolve to zero, disabling caching entirely.
    private func effectiveTTL(for pattern: ScreenPattern) -> TimeInterval {
        Self.effectiveTTLStatic(for: pattern, defaultTTL: defaultTTL)
    }

    // MARK: - Load Screen

    /// Carga una pantalla con soporte de cache y ETag.
    public func loadScreen(key: String) async throws -> ScreenDefinition {
        // 1. Check memory cache (if not expired)
        if let cached = memoryCache[key],
           Date() < cached.expiresAt {
            logger?.debug("[EduGo.Cache.Screen] L1 HIT: \(key, privacy: .public)")
            return cached.screen
        }

        // 2. Build request with ETag if available
        let url = "\(baseURL)/v1/screens/\(key)"
        var request = HTTPRequest.get(url)
            .queryParam("platform", "ios")

        if let etag = etagCache[key] {
            request = request.header("If-None-Match", etag)
        }

        // 3. Execute request
        logger?.debug("[EduGo.Cache.Screen] REMOTE: \(key, privacy: .public)")
        do {
            let (data, response) = try await networkClient.requestData(request)

            // 304 Not Modified - return cached
            if response.statusCode == 304, let cached = memoryCache[key] {
                logger?.debug("[EduGo.Cache.Screen] L1 HIT (revalidated): \(key, privacy: .public)")
                let patternTTL = effectiveTTL(for: cached.screen.pattern)
                let now = Date()
                memoryCache[key] = CachedScreen(
                    screen: cached.screen,
                    cachedAt: now,
                    etag: cached.etag,
                    expiresAt: now.addingTimeInterval(patternTTL),
                    bundleVersion: cached.bundleVersion
                )
                return cached.screen
            }

            // 200 OK - parse and cache
            let decoder = JSONDecoder()
            let screen = try decoder.decode(ScreenDefinition.self, from: data)
            let etag = response.value(forHTTPHeaderField: "ETag")

            cacheScreen(key: key, screen: screen, etag: etag)

            return screen
        } catch {
            // If error and we have stale cache, return it
            if let cached = memoryCache[key] {
                logger?.debug("[EduGo.Cache.Screen] STALE FALLBACK: \(key, privacy: .public)")
                return cached.screen
            }
            logger?.debug("[EduGo.Cache.Screen] MISS: \(key, privacy: .public)")
            throw error
        }
    }

    // MARK: - Version Check

    /// Checks if a newer version is available for a cached screen.
    ///
    /// Hits `GET /api/v1/screen-config/version/{key}` and compares the remote
    /// version with the locally cached bundle version. If a newer version exists,
    /// the cache entry is invalidated and the method returns `true`.
    ///
    /// Returns `false` if versions match, if no cached version exists, or if the
    /// network request fails (version check is non-critical).
    public func checkVersion(for key: String) async -> Bool {
        guard let currentVersion = bundleVersions[key] else { return false }

        let url = "\(baseURL)/v1/screen-config/version/\(key)"
        let request = HTTPRequest.get(url)

        do {
            let (data, _) = try await networkClient.requestData(request)
            let decoder = JSONDecoder()
            let versionResponse = try decoder.decode(ScreenVersionResponse.self, from: data)

            if versionResponse.version != currentVersion {
                invalidateCache(key: key)
                return true
            }
        } catch {
            // Version check failure is non-critical; keep existing cache
        }

        return false
    }

    // MARK: - Cache Management

    /// Invalida el cache de una pantalla especifica.
    public func invalidateCache(key: String) {
        memoryCache.removeValue(forKey: key)
        etagCache.removeValue(forKey: key)
        bundleVersions.removeValue(forKey: key)
    }

    /// Limpia todo el cache.
    public func clearCache() {
        memoryCache.removeAll()
        etagCache.removeAll()
        bundleVersions.removeAll()
    }

    /// Numero de entradas en cache.
    public var cacheCount: Int {
        memoryCache.count
    }

    private func cacheScreen(key: String, screen: ScreenDefinition, etag: String?) {
        // LRU eviction if at capacity
        if memoryCache.count >= maxCacheSize {
            if let oldestKey = memoryCache.min(by: { $0.value.cachedAt < $1.value.cachedAt })?.key {
                memoryCache.removeValue(forKey: oldestKey)
                etagCache.removeValue(forKey: oldestKey)
            }
        }

        let patternTTL = effectiveTTL(for: screen.pattern)
        let now = Date()
        memoryCache[key] = CachedScreen(
            screen: screen,
            cachedAt: now,
            etag: etag,
            expiresAt: now.addingTimeInterval(patternTTL),
            bundleVersion: nil
        )
        if let etag {
            etagCache[key] = etag
        }
    }
}

// MARK: - Version Response DTO

/// Response from the screen version check endpoint.
private struct ScreenVersionResponse: Codable, Sendable {
    let version: String
}
