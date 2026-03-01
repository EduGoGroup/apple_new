import Foundation
import OSLog
import EduModels
import EduNetwork

/// Resultado de una carga de datos con indicador de frescura.
public struct DataLoadResult: Sendable {
    /// Los datos cargados.
    public let data: [String: EduModels.JSONValue]
    /// Indica si los datos provienen del cache (potencialmente desactualizados).
    public let isStale: Bool

    public init(data: [String: EduModels.JSONValue], isStale: Bool) {
        self.data = data
        self.isStale = isStale
    }
}

/// Actor responsable de cargar datos dinamicos con soporte dual-API y cache offline.
public actor DataLoader {
    private let networkClient: NetworkClientProtocol
    private let adminBaseURL: String
    private let mobileBaseURL: String
    private let maxCacheSize: Int

    // MARK: - Offline Support

    /// Cache en memoria: clave → (datos, timestamp).
    private var cache: [String: (data: [String: EduModels.JSONValue], timestamp: Date)] = [:]

    /// Number of entries currently in the cache.
    public var cacheCount: Int { cache.count }

    /// Indica si hay conexión de red disponible.
    public private(set) var isOnline: Bool = true

    /// Logger opcional para observabilidad de cache.
    private let logger: os.Logger?

    /// Handler para encolar mutaciones offline.
    /// Inyectado desde la capa Domain ya que DynamicUI no depende de ella.
    public var offlineMutationHandler: (@Sendable (String, String, EduModels.JSONValue) async -> Void)?

    public init(
        networkClient: NetworkClientProtocol,
        adminBaseURL: String,
        mobileBaseURL: String,
        maxCacheSize: Int = 50,
        logger: os.Logger? = nil
    ) {
        self.networkClient = networkClient
        var sanitizedAdmin = adminBaseURL
        while sanitizedAdmin.hasSuffix("/") { sanitizedAdmin = String(sanitizedAdmin.dropLast()) }
        self.adminBaseURL = sanitizedAdmin
        var sanitizedMobile = mobileBaseURL
        while sanitizedMobile.hasSuffix("/") { sanitizedMobile = String(sanitizedMobile.dropLast()) }
        self.mobileBaseURL = sanitizedMobile
        self.maxCacheSize = max(1, maxCacheSize)
        self.logger = logger
    }

    // MARK: - Online State

    /// Actualiza el estado de conectividad.
    public func setOnline(_ online: Bool) {
        isOnline = online
    }

    // MARK: - Data Loading

    /// Carga datos de un endpoint con routing dual-API.
    /// Soporta respuestas JSON tanto como objeto `{}` como array `[]`.
    public func loadData(
        endpoint: String,
        config: DataConfig?,
        params: [String: String]? = nil
    ) async throws -> [String: EduModels.JSONValue] {
        let result = try await loadDataWithResult(endpoint: endpoint, config: config, params: params)
        return result.data
    }

    /// Carga datos con indicador de frescura (stale/fresh).
    ///
    /// - Online: fetch → cache → retorna fresh
    /// - Offline: retorna desde cache (stale) si existe
    /// - Fetch falla online: intenta cache como fallback (stale)
    public func loadDataWithResult(
        endpoint: String,
        config: DataConfig?,
        params: [String: String]? = nil
    ) async throws -> DataLoadResult {
        let cacheKey = buildCacheKey(endpoint: endpoint, params: params)

        if !isOnline {
            // Offline: retornar desde cache
            if let cached = cache[cacheKey] {
                cache[cacheKey] = (data: cached.data, timestamp: Date())
                logger?.debug("[EduGo.Cache.Data] STALE (offline): \(cacheKey, privacy: .public)")
                return DataLoadResult(data: cached.data, isStale: true)
            }
            logger?.debug("[EduGo.Cache.Data] MISS (offline): \(cacheKey, privacy: .public)")
            throw NetworkError.networkFailure(underlyingError: "Sin conexión y sin datos en cache")
        }

        // Online: intentar fetch
        logger?.debug("[EduGo.Cache.Data] REMOTE: \(cacheKey, privacy: .public)")
        do {
            var request = buildRequest(endpoint: endpoint, config: config, offset: 0)
            if let params {
                request = request.queryParams(params)
            }

            let data = try await fetchAndNormalize(request)
            insertIntoCache(key: cacheKey, data: data)
            return DataLoadResult(data: data, isStale: false)
        } catch {
            // Fallback a cache si el fetch falla
            if let cached = cache[cacheKey] {
                cache[cacheKey] = (data: cached.data, timestamp: Date())
                logger?.debug("[EduGo.Cache.Data] STALE FALLBACK: \(cacheKey, privacy: .public)")
                return DataLoadResult(data: cached.data, isStale: true)
            }
            logger?.debug("[EduGo.Cache.Data] MISS: \(cacheKey, privacy: .public)")
            throw error
        }
    }

    /// Carga la siguiente pagina de datos (offset-based).
    public func loadNextPage(
        endpoint: String,
        config: DataConfig?,
        currentOffset: Int
    ) async throws -> [String: EduModels.JSONValue] {
        let request = buildRequest(endpoint: endpoint, config: config, offset: currentOffset)
        return try await fetchAndNormalize(request)
    }

    // MARK: - Offline Mutations

    /// Encola una mutación offline a través del handler inyectado.
    public func enqueueOfflineMutation(
        endpoint: String,
        method: String,
        body: EduModels.JSONValue
    ) async {
        await offlineMutationHandler?(endpoint, method, body)
    }

    // MARK: - Cache Management

    /// Invalida entradas de cache más antiguas que el intervalo dado.
    public func invalidateCache(olderThan interval: TimeInterval = 300) {
        let cutoff = Date().addingTimeInterval(-interval)
        cache = cache.filter { $0.value.timestamp > cutoff }
    }

    /// Limpia todo el cache.
    public func clearCache() {
        cache.removeAll()
    }

    // MARK: - Private

    /// Inserts data into cache, evicting the oldest entry if at capacity.
    private func insertIntoCache(key: String, data: [String: EduModels.JSONValue]) {
        // If the key already exists, just update it (no eviction needed)
        if cache[key] != nil {
            cache[key] = (data: data, timestamp: Date())
            return
        }
        // Evict oldest entry if at capacity
        if cache.count >= maxCacheSize {
            if let oldest = cache.min(by: { $0.value.timestamp < $1.value.timestamp }) {
                cache.removeValue(forKey: oldest.key)
            }
        }
        cache[key] = (data: data, timestamp: Date())
    }

    private func buildCacheKey(endpoint: String, params: [String: String]?) -> String {
        var key = endpoint
        if let params, !params.isEmpty {
            let sortedParams = params.sorted { $0.key < $1.key }
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: "&")
            key += "?\(sortedParams)"
        }
        return key
    }

    private func buildRequest(endpoint: String, config: DataConfig?, offset: Int) -> HTTPRequest {
        let (baseURL, path) = resolveEndpoint(endpoint)
        var request = HTTPRequest.get(baseURL + path)

        if let defaultParams = config?.defaultParams {
            request = request.queryParams(defaultParams)
        }

        if let pagination = config?.pagination {
            let limitKey = pagination.limitParam ?? "limit"
            let offsetKey = pagination.offsetParam ?? pagination.pageParam ?? "offset"
            let size = pagination.pageSize ?? 20
            request = request
                .queryParam(limitKey, String(size))
                .queryParam(offsetKey, String(offset))
        }

        return request
    }

    /// Ejecuta el request y normaliza la respuesta a diccionario.
    /// Si la API devuelve un array, lo envuelve en {"items": [...]}.
    private func fetchAndNormalize(_ request: HTTPRequest) async throws -> [String: EduModels.JSONValue] {
        let (data, _) = try await networkClient.requestData(request)

        let decoder = JSONDecoder()

        // Intentar como diccionario primero
        if let dict = try? decoder.decode([String: EduModels.JSONValue].self, from: data) {
            return dict
        }

        // Si falla, intentar como array y envolver
        let array = try decoder.decode([EduModels.JSONValue].self, from: data)
        return ["items": .array(array)]
    }

    /// Resuelve el endpoint a una URL base y path.
    /// - "admin:" prefix -> adminBaseURL
    /// - "mobile:" prefix -> mobileBaseURL
    /// - No prefix -> mobileBaseURL (default)
    private func resolveEndpoint(_ endpoint: String) -> (baseURL: String, path: String) {
        if endpoint.hasPrefix("admin:") {
            let path = String(endpoint.dropFirst("admin:".count))
            return (adminBaseURL, path)
        } else if endpoint.hasPrefix("mobile:") {
            let path = String(endpoint.dropFirst("mobile:".count))
            return (mobileBaseURL, path)
        } else {
            return (mobileBaseURL, endpoint)
        }
    }
}
