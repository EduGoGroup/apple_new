import Testing
import Foundation
import EduNetwork
import EduModels
@testable import EduDynamicUI

@Suite("ScreenLoader Seed & Version Tests")
struct ScreenLoaderSeedTests {

    // MARK: - Fixtures

    /// A valid ScreenTemplate JSON structure as JSONValue.
    static let validTemplateJSON: JSONValue = .object([
        "zones": .array([
            .object([
                "id": .string("zone-1"),
                "type": .string("container"),
                "slots": .array([])
            ])
        ])
    ])

    static func makeBundleDTO(
        screenKey: String = "dashboard_main",
        screenName: String = "Dashboard",
        pattern: String = "dashboard",
        version: String = "1.0.0",
        template: JSONValue = validTemplateJSON,
        slotData: JSONValue? = nil,
        handlerKey: String? = nil
    ) -> ScreenBundleDTO {
        ScreenBundleDTO(
            screenKey: screenKey,
            screenName: screenName,
            pattern: pattern,
            version: version,
            template: template,
            slotData: slotData,
            handlerKey: handlerKey
        )
    }

    /// Sample ScreenDefinition JSON for network mock responses.
    static let sampleScreenJSON = """
    {
        "screenId": "scr-test",
        "screenKey": "test_screen",
        "screenName": "Test Screen",
        "pattern": "list",
        "version": 1,
        "template": {
            "zones": [
                {
                    "id": "zone-1",
                    "type": "container",
                    "slots": []
                }
            ]
        },
        "actions": [],
        "updatedAt": "2025-01-01T00:00:00Z"
    }
    """.data(using: .utf8)!

    // MARK: - seedFromBundle Tests

    @Test("seedFromBundle populates cache with valid screen")
    func seedPopulatesCache() async {
        let mock = MockNetworkClient()
        let loader = ScreenLoader(networkClient: mock, baseURL: "https://api.test.com")

        let dto = Self.makeBundleDTO()
        await loader.seedFromBundle(screens: ["dashboard_main": dto])

        let count = await loader.cacheCount
        #expect(count == 1)
    }

    @Test("seedFromBundle screen is served by loadScreen")
    func seedServedByLoadScreen() async throws {
        let mock = MockNetworkClient()
        let loader = ScreenLoader(networkClient: mock, baseURL: "https://api.test.com")

        let dto = Self.makeBundleDTO(
            screenKey: "my_dashboard",
            screenName: "My Dashboard",
            pattern: "dashboard",
            version: "2.0.0"
        )
        await loader.seedFromBundle(screens: ["my_dashboard": dto])

        let screen = try await loader.loadScreen(key: "my_dashboard")
        #expect(screen.screenKey == "my_dashboard")
        #expect(screen.screenName == "My Dashboard")
        #expect(screen.pattern == .dashboard)
        #expect(screen.version == 2)

        // No network request should have been made
        let requestCount = await mock.requestCount
        #expect(requestCount == 0)
    }

    @Test("seedFromBundle populates multiple screens")
    func seedMultipleScreens() async {
        let mock = MockNetworkClient()
        let loader = ScreenLoader(networkClient: mock, baseURL: "https://api.test.com")

        let screens: [String: ScreenBundleDTO] = [
            "dash": Self.makeBundleDTO(screenKey: "dash", pattern: "dashboard"),
            "settings": Self.makeBundleDTO(screenKey: "settings", pattern: "settings"),
            "grades": Self.makeBundleDTO(screenKey: "grades", pattern: "list"),
        ]

        await loader.seedFromBundle(screens: screens)

        let count = await loader.cacheCount
        #expect(count == 3)
    }

    @Test("seedFromBundle skips invalid pattern")
    func seedSkipsInvalidPattern() async {
        let mock = MockNetworkClient()
        let loader = ScreenLoader(networkClient: mock, baseURL: "https://api.test.com")

        let dto = Self.makeBundleDTO(pattern: "nonexistent_pattern")
        await loader.seedFromBundle(screens: ["key": dto])

        let count = await loader.cacheCount
        #expect(count == 0)
    }

    @Test("seedFromBundle skips login pattern (TTL 0)")
    func seedSkipsLoginPattern() async {
        let mock = MockNetworkClient()
        let loader = ScreenLoader(networkClient: mock, baseURL: "https://api.test.com")

        let dto = Self.makeBundleDTO(pattern: "login")
        await loader.seedFromBundle(screens: ["login_screen": dto])

        let count = await loader.cacheCount
        #expect(count == 0)
    }

    @Test("seedFromBundle skips invalid template JSON")
    func seedSkipsInvalidTemplate() async {
        let mock = MockNetworkClient()
        let loader = ScreenLoader(networkClient: mock, baseURL: "https://api.test.com")

        // String value can't decode to ScreenTemplate (needs object with zones)
        let dto = Self.makeBundleDTO(template: .string("not a template"))
        await loader.seedFromBundle(screens: ["key": dto])

        let count = await loader.cacheCount
        #expect(count == 0)
    }

    @Test("seedFromBundle parses major version from semver string")
    func seedParsesVersion() async throws {
        let mock = MockNetworkClient()
        let loader = ScreenLoader(networkClient: mock, baseURL: "https://api.test.com")

        let dto = Self.makeBundleDTO(version: "3.2.1")
        await loader.seedFromBundle(screens: ["key": dto])

        let screen = try await loader.loadScreen(key: "key")
        #expect(screen.version == 3)
    }

    @Test("seedFromBundle preserves slotData as dictionary")
    func seedPreservesSlotData() async throws {
        let mock = MockNetworkClient()
        let loader = ScreenLoader(networkClient: mock, baseURL: "https://api.test.com")

        let slotData: JSONValue = .object([
            "title": .string("Welcome"),
            "count": .integer(42)
        ])
        let dto = Self.makeBundleDTO(slotData: slotData)
        await loader.seedFromBundle(screens: ["key": dto])

        let screen = try await loader.loadScreen(key: "key")
        #expect(screen.slotData?["title"] == .string("Welcome"))
        #expect(screen.slotData?["count"] == .integer(42))
    }

    @Test("seedFromBundle preserves handlerKey")
    func seedPreservesHandlerKey() async throws {
        let mock = MockNetworkClient()
        let loader = ScreenLoader(networkClient: mock, baseURL: "https://api.test.com")

        let dto = Self.makeBundleDTO(handlerKey: "dashboard_handler")
        await loader.seedFromBundle(screens: ["key": dto])

        let screen = try await loader.loadScreen(key: "key")
        #expect(screen.handlerKey == "dashboard_handler")
    }

    @Test("seedFromBundle with cacheExpiration 0 seeds nothing")
    func seedWithZeroTTLSeedsNothing() async {
        let mock = MockNetworkClient()
        let loader = ScreenLoader(
            networkClient: mock,
            baseURL: "https://api.test.com",
            cacheExpiration: 0
        )

        let dto = Self.makeBundleDTO()
        await loader.seedFromBundle(screens: ["key": dto])

        let count = await loader.cacheCount
        #expect(count == 0)
    }

    // MARK: - checkVersion Tests

    @Test("checkVersion returns false when no cached version")
    func checkVersionNoCachedVersion() async {
        let mock = MockNetworkClient()
        let loader = ScreenLoader(networkClient: mock, baseURL: "https://api.test.com")

        let result = await loader.checkVersion(for: "unknown_key")
        #expect(result == false)
    }

    @Test("checkVersion returns false when versions match")
    func checkVersionSameVersion() async {
        let mock = MockNetworkClient()
        let loader = ScreenLoader(networkClient: mock, baseURL: "https://api.test.com")

        // Seed a screen first
        let dto = Self.makeBundleDTO(version: "1.0.0")
        await loader.seedFromBundle(screens: ["key": dto])

        // Mock version API to return same version
        let versionJSON = """
        {"version": "1.0.0"}
        """.data(using: .utf8)!
        await mock.setDataResponse(data: versionJSON)

        let result = await loader.checkVersion(for: "key")
        #expect(result == false)

        // Cache should still exist
        let count = await loader.cacheCount
        #expect(count == 1)
    }

    @Test("checkVersion returns true and invalidates when newer version")
    func checkVersionNewerVersion() async {
        let mock = MockNetworkClient()
        let loader = ScreenLoader(networkClient: mock, baseURL: "https://api.test.com")

        let dto = Self.makeBundleDTO(version: "1.0.0")
        await loader.seedFromBundle(screens: ["key": dto])

        // Mock version API to return newer version
        let versionJSON = """
        {"version": "2.0.0"}
        """.data(using: .utf8)!
        await mock.setDataResponse(data: versionJSON)

        let result = await loader.checkVersion(for: "key")
        #expect(result == true)

        // Cache should be invalidated
        let count = await loader.cacheCount
        #expect(count == 0)
    }

    @Test("checkVersion returns false on network error")
    func checkVersionNetworkError() async {
        let mock = MockNetworkClient()
        let loader = ScreenLoader(networkClient: mock, baseURL: "https://api.test.com")

        let dto = Self.makeBundleDTO(version: "1.0.0")
        await loader.seedFromBundle(screens: ["key": dto])

        await mock.setError(NetworkError.networkFailure(underlyingError: "offline"))

        let result = await loader.checkVersion(for: "key")
        #expect(result == false)

        // Cache should be preserved despite error
        let count = await loader.cacheCount
        #expect(count == 1)
    }

    @Test("checkVersion sends correct URL")
    func checkVersionCorrectURL() async {
        let mock = MockNetworkClient()
        let loader = ScreenLoader(networkClient: mock, baseURL: "https://api.test.com")

        let dto = Self.makeBundleDTO(version: "1.0.0")
        await loader.seedFromBundle(screens: ["my_screen": dto])

        let versionJSON = """
        {"version": "1.0.0"}
        """.data(using: .utf8)!
        await mock.setDataResponse(data: versionJSON)

        _ = await loader.checkVersion(for: "my_screen")

        let request = await mock.lastRequest
        #expect(request?.url == "https://api.test.com/v1/screen-config/version/my_screen")
    }

    // MARK: - loadScreen falls through to network after seed expiry

    @Test("loadScreen fetches from network when seeded cache expires")
    func loadScreenFallsToNetworkAfterExpiry() async throws {
        let mock = MockNetworkClient()
        // Use cacheExpiration: 0 to make seeded entries expire immediately
        let loader = ScreenLoader(
            networkClient: mock,
            baseURL: "https://api.test.com",
            cacheExpiration: 0
        )

        // seedFromBundle won't cache anything with TTL 0
        let dto = Self.makeBundleDTO()
        await loader.seedFromBundle(screens: ["key": dto])
        let count = await loader.cacheCount
        #expect(count == 0)

        // Network should be used
        await mock.setDataResponse(data: Self.sampleScreenJSON)
        let screen = try await loader.loadScreen(key: "test_screen")
        #expect(screen.screenKey == "test_screen")

        let requestCount = await mock.requestCount
        #expect(requestCount == 1)
    }

    // MARK: - clearCache clears bundle versions too

    @Test("clearCache also clears bundle versions")
    func clearCacheClearsBundleVersions() async {
        let mock = MockNetworkClient()
        let loader = ScreenLoader(networkClient: mock, baseURL: "https://api.test.com")

        let dto = Self.makeBundleDTO(version: "1.0.0")
        await loader.seedFromBundle(screens: ["key": dto])

        await loader.clearCache()

        // checkVersion should return false (no cached version to compare)
        let versionJSON = """
        {"version": "2.0.0"}
        """.data(using: .utf8)!
        await mock.setDataResponse(data: versionJSON)

        let result = await loader.checkVersion(for: "key")
        #expect(result == false)
    }
}
