import Testing
import Foundation
import EduNetwork
@testable import EduDynamicUI

@Suite("ScreenLoader Tests")
struct ScreenLoaderTests {

    // MARK: - Fixtures

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

    // MARK: - Tests

    @Test("loadScreen returns parsed ScreenDefinition")
    func loadScreenReturnsScreen() async throws {
        let mock = MockNetworkClient()
        await mock.setDataResponse(data: Self.sampleScreenJSON)

        let loader = ScreenLoader(
            networkClient: mock,
            baseURL: "https://api.test.com"
        )

        let screen = try await loader.loadScreen(key: "test_screen")
        #expect(screen.screenKey == "test_screen")
        #expect(screen.pattern == .list)
    }

    @Test("loadScreen uses cache on second call")
    func loadScreenUsesCache() async throws {
        let mock = MockNetworkClient()
        await mock.setDataResponse(data: Self.sampleScreenJSON)

        let loader = ScreenLoader(
            networkClient: mock,
            baseURL: "https://api.test.com"
        )

        _ = try await loader.loadScreen(key: "test_screen")
        _ = try await loader.loadScreen(key: "test_screen")

        let count = await mock.requestCount
        #expect(count == 1)
    }

    @Test("loadScreen sends platform=ios query parameter")
    func loadScreenSendsPlatform() async throws {
        let mock = MockNetworkClient()
        await mock.setDataResponse(data: Self.sampleScreenJSON)

        let loader = ScreenLoader(
            networkClient: mock,
            baseURL: "https://api.test.com"
        )

        _ = try await loader.loadScreen(key: "my_screen")

        let request = await mock.lastRequest
        #expect(request?.queryParameters["platform"] == "ios")
        #expect(request?.url == "https://api.test.com/v1/screens/my_screen")
    }

    @Test("loadScreen sends ETag header on subsequent requests")
    func loadScreenSendsETag() async throws {
        let mock = MockNetworkClient()
        await mock.setDataResponse(
            data: Self.sampleScreenJSON,
            headers: ["ETag": "\"v1-abc123\""]
        )

        let loader = ScreenLoader(
            networkClient: mock,
            baseURL: "https://api.test.com",
            cacheExpiration: 0 // Force cache expiration
        )

        // First load - caches with ETag
        _ = try await loader.loadScreen(key: "test_screen")

        // Reset mock for second request
        await mock.setDataResponse(data: Self.sampleScreenJSON)

        // Second load - should send ETag
        _ = try await loader.loadScreen(key: "test_screen")

        let request = await mock.lastRequest
        #expect(request?.headers["If-None-Match"] == "\"v1-abc123\"")
    }

    @Test("loadScreen returns stale cache on network error")
    func loadScreenReturnsStaleCacheOnError() async throws {
        let mock = MockNetworkClient()
        await mock.setDataResponse(data: Self.sampleScreenJSON)

        let loader = ScreenLoader(
            networkClient: mock,
            baseURL: "https://api.test.com",
            cacheExpiration: 0 // Force cache expiration
        )

        // First load - populates cache
        let first = try await loader.loadScreen(key: "test_screen")
        #expect(first.screenKey == "test_screen")

        // Set error for second request
        await mock.setError(NetworkError.networkFailure(underlyingError: "no connection"))

        // Second load - should return stale cache
        let second = try await loader.loadScreen(key: "test_screen")
        #expect(second.screenKey == "test_screen")
    }

    @Test("loadScreen throws when no cache and network error")
    func loadScreenThrowsWhenNoCacheAndError() async {
        let mock = MockNetworkClient()
        await mock.setError(NetworkError.networkFailure(underlyingError: "no connection"))

        let loader = ScreenLoader(
            networkClient: mock,
            baseURL: "https://api.test.com"
        )

        await #expect(throws: Error.self) {
            _ = try await loader.loadScreen(key: "nonexistent")
        }
    }

    @Test("invalidateCache removes cached entry")
    func invalidateCacheRemovesEntry() async throws {
        let mock = MockNetworkClient()
        await mock.setDataResponse(data: Self.sampleScreenJSON)

        let loader = ScreenLoader(
            networkClient: mock,
            baseURL: "https://api.test.com"
        )

        _ = try await loader.loadScreen(key: "test_screen")
        let countBefore = await loader.cacheCount
        #expect(countBefore == 1)

        await loader.invalidateCache(key: "test_screen")
        let countAfter = await loader.cacheCount
        #expect(countAfter == 0)
    }

    @Test("LRU eviction when cache is at capacity")
    func lruEviction() async throws {
        let mock = MockNetworkClient()
        await mock.setDataResponse(data: Self.sampleScreenJSON)

        let loader = ScreenLoader(
            networkClient: mock,
            baseURL: "https://api.test.com",
            maxCacheSize: 2
        )

        // Load 3 screens into a cache of size 2
        _ = try await loader.loadScreen(key: "screen_a")

        // Small delay so timestamps differ
        try await Task.sleep(for: .milliseconds(10))
        _ = try await loader.loadScreen(key: "screen_b")

        try await Task.sleep(for: .milliseconds(10))
        _ = try await loader.loadScreen(key: "screen_c")

        let count = await loader.cacheCount
        #expect(count == 2)
    }

    @Test("LRU eviction evicts least-recently-accessed, not least-recently-inserted")
    func lruEvictionUsesAccessOrder() async throws {
        let mock = MockNetworkClient()
        await mock.setDataResponse(data: Self.sampleScreenJSON)

        let loader = ScreenLoader(
            networkClient: mock,
            baseURL: "https://api.test.com",
            maxCacheSize: 2,
            cacheExpiration: 3600
        )

        // Load screen_a (request #1) — inserted first
        _ = try await loader.loadScreen(key: "screen_a")
        try await Task.sleep(for: .milliseconds(20))

        // Load screen_b (request #2) — inserted second
        _ = try await loader.loadScreen(key: "screen_b")
        try await Task.sleep(for: .milliseconds(20))

        // Re-access screen_a from cache → updates lastAccessedAt to most recent
        _ = try await loader.loadScreen(key: "screen_a")
        let requestsBeforeEviction = await mock.requestCount
        #expect(requestsBeforeEviction == 2) // a and b loaded from network

        try await Task.sleep(for: .milliseconds(20))

        // Load screen_c (request #3) → triggers LRU eviction
        // screen_b has the oldest lastAccessedAt → it must be evicted
        _ = try await loader.loadScreen(key: "screen_c")
        #expect(await loader.cacheCount == 2)

        // screen_a is still cached → no new network request
        _ = try await loader.loadScreen(key: "screen_a")
        #expect(await mock.requestCount == 3) // only a, b, c

        // screen_b was evicted → triggers a new network request
        _ = try await loader.loadScreen(key: "screen_b")
        #expect(await mock.requestCount == 4) // b reloaded
    }

    @Test("clearCache removes all entries")
    func clearCacheRemovesAll() async throws {
        let mock = MockNetworkClient()
        await mock.setDataResponse(data: Self.sampleScreenJSON)

        let loader = ScreenLoader(
            networkClient: mock,
            baseURL: "https://api.test.com"
        )

        _ = try await loader.loadScreen(key: "screen_a")
        _ = try await loader.loadScreen(key: "screen_b")

        await loader.clearCache()
        let count = await loader.cacheCount
        #expect(count == 0)
    }
}
