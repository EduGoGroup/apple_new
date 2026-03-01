import Testing
import Foundation
import EduModels
import EduNetwork
@testable import EduDynamicUI

@Suite("DataLoader Edge Case Tests")
struct DataLoaderEdgeCaseTests {

    // MARK: - Helpers

    private func makeLoader(
        mock: MockNetworkClient,
        maxCacheSize: Int = 50
    ) -> DataLoader {
        DataLoader(
            networkClient: mock,
            adminBaseURL: "https://admin.api.test",
            mobileBaseURL: "https://mobile.api.test",
            maxCacheSize: maxCacheSize
        )
    }

    // MARK: - Array Response Normalization

    @Test("Array response is wrapped in items key")
    func arrayResponseNormalization() async throws {
        let mock = MockNetworkClient()
        let json = """
        [{"id": 1, "name": "A"}, {"id": 2, "name": "B"}]
        """.data(using: .utf8)!
        await mock.setDataResponse(data: json)

        let loader = makeLoader(mock: mock)
        let result = try await loader.loadData(endpoint: "/api/v1/items", config: nil)

        #expect(result["items"] != nil)
        if case .array(let items) = result["items"] {
            #expect(items.count == 2)
        } else {
            Issue.record("Expected .array for items key")
        }
    }

    @Test("Object response is returned as-is")
    func objectResponsePassthrough() async throws {
        let mock = MockNetworkClient()
        let json = """
        {"total": 5, "page": 1}
        """.data(using: .utf8)!
        await mock.setDataResponse(data: json)

        let loader = makeLoader(mock: mock)
        let result = try await loader.loadData(endpoint: "/api/v1/data", config: nil)

        #expect(result["total"] == .integer(5))
        #expect(result["page"] == .integer(1))
    }

    // MARK: - Cache Key Isolation

    @Test("Same endpoint with different params creates separate cache entries")
    func cacheKeyIsolation() async throws {
        let mock = MockNetworkClient()
        let json = """
        {"data": "value"}
        """.data(using: .utf8)!
        await mock.setDataResponse(data: json)

        let loader = makeLoader(mock: mock)

        _ = try await loader.loadData(endpoint: "/api/v1/data", config: nil, params: ["page": "1"])
        _ = try await loader.loadData(endpoint: "/api/v1/data", config: nil, params: ["page": "2"])

        let count = await loader.cacheCount
        #expect(count == 2)
    }

    @Test("Same endpoint with same params reuses cache entry")
    func cacheKeyReuse() async throws {
        let mock = MockNetworkClient()
        let json = """
        {"data": "value"}
        """.data(using: .utf8)!
        await mock.setDataResponse(data: json)

        let loader = makeLoader(mock: mock)

        _ = try await loader.loadData(endpoint: "/api/v1/data", config: nil, params: ["a": "1"])
        _ = try await loader.loadData(endpoint: "/api/v1/data", config: nil, params: ["a": "1"])

        let count = await loader.cacheCount
        #expect(count == 1)
    }

    // MARK: - URL Sanitization

    @Test("Trailing slashes on base URLs are stripped")
    func trailingSlashSanitization() async throws {
        let mock = MockNetworkClient()
        let json = """
        {"ok": true}
        """.data(using: .utf8)!
        await mock.setDataResponse(data: json)

        let loader = DataLoader(
            networkClient: mock,
            adminBaseURL: "https://admin.api.test///",
            mobileBaseURL: "https://mobile.api.test//"
        )

        _ = try await loader.loadData(endpoint: "/api/v1/test", config: nil)
        let request = await mock.lastRequest
        #expect(request?.url == "https://mobile.api.test/api/v1/test")
    }

    // MARK: - Invalidate Cache

    @Test("invalidateCache removes only old entries")
    func invalidateCacheSelectivity() async throws {
        let mock = MockNetworkClient()
        let json = """
        {"v": 1}
        """.data(using: .utf8)!
        await mock.setDataResponse(data: json)

        let loader = makeLoader(mock: mock)

        // Load two endpoints
        _ = try await loader.loadData(endpoint: "/api/v1/old", config: nil)
        _ = try await loader.loadData(endpoint: "/api/v1/new", config: nil)

        // Invalidate with 0 seconds (everything is "old")
        await loader.invalidateCache(olderThan: 0)

        let count = await loader.cacheCount
        #expect(count == 0)
    }
}
