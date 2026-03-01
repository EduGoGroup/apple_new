import Testing
import Foundation
import EduNetwork
import EduModels
@testable import EduDynamicUI

@Suite("ScreenLoader Parallel Seed Tests")
struct ScreenLoaderParallelTests {

    // MARK: - Fixtures

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
        screenKey: String = "screen",
        screenName: String = "Screen",
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

    // MARK: - Parallel Seed Correctness

    @Test("seedFromBundle processes many screens in parallel and caches all")
    func seedManyScreensParallel() async {
        let mock = MockNetworkClient()
        let loader = ScreenLoader(networkClient: mock, baseURL: "https://api.test.com")

        var screens: [String: ScreenBundleDTO] = [:]
        for i in 0..<20 {
            screens["screen_\(i)"] = Self.makeBundleDTO(
                screenKey: "screen_\(i)",
                screenName: "Screen \(i)",
                pattern: "list",
                version: "\(i + 1).0.0"
            )
        }

        await loader.seedFromBundle(screens: screens)

        let count = await loader.cacheCount
        #expect(count == 20)
    }

    @Test("parallel seedFromBundle produces same result as expected for each screen")
    func parallelSeedProducesCorrectEntries() async throws {
        let mock = MockNetworkClient()
        let loader = ScreenLoader(networkClient: mock, baseURL: "https://api.test.com")

        let screens: [String: ScreenBundleDTO] = [
            "dash": Self.makeBundleDTO(screenKey: "dash", screenName: "Dashboard", pattern: "dashboard", version: "2.0.0"),
            "settings": Self.makeBundleDTO(screenKey: "settings", screenName: "Settings", pattern: "settings", version: "3.0.0"),
            "grades": Self.makeBundleDTO(screenKey: "grades", screenName: "Grades", pattern: "list", version: "1.5.0"),
        ]

        await loader.seedFromBundle(screens: screens)

        let dashScreen = try await loader.loadScreen(key: "dash")
        #expect(dashScreen.screenKey == "dash")
        #expect(dashScreen.screenName == "Dashboard")
        #expect(dashScreen.pattern == .dashboard)
        #expect(dashScreen.version == 2)

        let settingsScreen = try await loader.loadScreen(key: "settings")
        #expect(settingsScreen.screenKey == "settings")
        #expect(settingsScreen.version == 3)

        let gradesScreen = try await loader.loadScreen(key: "grades")
        #expect(gradesScreen.screenKey == "grades")
        #expect(gradesScreen.version == 1)
    }

    @Test("parallel seedFromBundle caches unknown patterns and skips login")
    func parallelSeedCachesUnknownSkipsLogin() async {
        let mock = MockNetworkClient()
        let loader = ScreenLoader(networkClient: mock, baseURL: "https://api.test.com")

        let screens: [String: ScreenBundleDTO] = [
            "valid": Self.makeBundleDTO(screenKey: "valid", pattern: "dashboard"),
            "unknown": Self.makeBundleDTO(screenKey: "unknown", pattern: "nonexistent"),
            "login": Self.makeBundleDTO(screenKey: "login", pattern: "login"),
        ]

        await loader.seedFromBundle(screens: screens)

        let count = await loader.cacheCount
        #expect(count == 2) // "valid" + "unknown" cached; "login" skipped (TTL 0)
    }

    @Test("parallel seedFromBundle preserves slotData and handlerKey")
    func parallelSeedPreservesData() async throws {
        let mock = MockNetworkClient()
        let loader = ScreenLoader(networkClient: mock, baseURL: "https://api.test.com")

        let slotData: JSONValue = .object(["title": .string("Hello")])
        let screens: [String: ScreenBundleDTO] = [
            "key": Self.makeBundleDTO(
                screenKey: "key",
                pattern: "list",
                slotData: slotData,
                handlerKey: "my_handler"
            )
        ]

        await loader.seedFromBundle(screens: screens)

        let screen = try await loader.loadScreen(key: "key")
        #expect(screen.slotData?["title"] == .string("Hello"))
        #expect(screen.handlerKey == "my_handler")
    }

    @Test("parallel seedFromBundle with zero TTL seeds nothing")
    func parallelSeedZeroTTL() async {
        let mock = MockNetworkClient()
        let loader = ScreenLoader(
            networkClient: mock,
            baseURL: "https://api.test.com",
            cacheExpiration: 0
        )

        let screens: [String: ScreenBundleDTO] = [
            "a": Self.makeBundleDTO(screenKey: "a", pattern: "dashboard"),
            "b": Self.makeBundleDTO(screenKey: "b", pattern: "list"),
        ]

        await loader.seedFromBundle(screens: screens)

        let count = await loader.cacheCount
        #expect(count == 0)
    }
}
