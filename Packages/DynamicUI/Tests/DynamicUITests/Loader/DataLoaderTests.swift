import Testing
import Foundation
import EduModels
import EduNetwork
@testable import EduDynamicUI

@Suite("DataLoader Tests")
struct DataLoaderTests {

    // MARK: - Fixtures

    private func makeLoader(mock: MockNetworkClient) -> DataLoader {
        DataLoader(
            networkClient: mock,
            adminBaseURL: "https://admin.api.test",
            mobileBaseURL: "https://mobile.api.test"
        )
    }

    private func makeMockWithResponse() async -> MockNetworkClient {
        let mock = MockNetworkClient()
        let json = """
        {"items": [], "total": 0}
        """.data(using: .utf8)!
        await mock.setDataResponse(data: json)
        return mock
    }

    // MARK: - Endpoint Routing Tests

    @Test("admin: prefix routes to admin base URL")
    func adminPrefixRouting() async throws {
        let mock = await makeMockWithResponse()
        let loader = makeLoader(mock: mock)

        _ = try await loader.loadData(endpoint: "admin:/api/v1/users", config: nil)

        let request = await mock.lastRequest
        #expect(request?.url == "https://admin.api.test/api/v1/users")
    }

    @Test("mobile: prefix routes to mobile base URL")
    func mobilePrefixRouting() async throws {
        let mock = await makeMockWithResponse()
        let loader = makeLoader(mock: mock)

        _ = try await loader.loadData(endpoint: "mobile:/api/v1/courses", config: nil)

        let request = await mock.lastRequest
        #expect(request?.url == "https://mobile.api.test/api/v1/courses")
    }

    @Test("No prefix routes to mobile base URL by default")
    func defaultRouting() async throws {
        let mock = await makeMockWithResponse()
        let loader = makeLoader(mock: mock)

        _ = try await loader.loadData(endpoint: "/api/v1/dashboard", config: nil)

        let request = await mock.lastRequest
        #expect(request?.url == "https://mobile.api.test/api/v1/dashboard")
    }

    // MARK: - Parameter Injection Tests

    @Test("defaultParams from config are injected")
    func defaultParamsInjection() async throws {
        let mock = await makeMockWithResponse()
        let loader = makeLoader(mock: mock)

        let config = try JSONDecoder().decode(DataConfig.self, from: """
        {
            "defaultParams": {
                "role": "teacher",
                "status": "active"
            }
        }
        """.data(using: .utf8)!)

        _ = try await loader.loadData(endpoint: "/api/v1/data", config: config)

        let request = await mock.lastRequest
        #expect(request?.queryParameters["role"] == "teacher")
        #expect(request?.queryParameters["status"] == "active")
    }

    @Test("Additional params are injected alongside config params")
    func additionalParamsInjection() async throws {
        let mock = await makeMockWithResponse()
        let loader = makeLoader(mock: mock)

        let config = try JSONDecoder().decode(DataConfig.self, from: """
        {
            "defaultParams": {
                "role": "teacher"
            }
        }
        """.data(using: .utf8)!)

        _ = try await loader.loadData(
            endpoint: "/api/v1/data",
            config: config,
            params: ["search": "math"]
        )

        let request = await mock.lastRequest
        #expect(request?.queryParameters["role"] == "teacher")
        #expect(request?.queryParameters["search"] == "math")
    }

    @Test("Pagination params are injected from config")
    func paginationParamsInjection() async throws {
        let mock = await makeMockWithResponse()
        let loader = makeLoader(mock: mock)

        let config = try JSONDecoder().decode(DataConfig.self, from: """
        {
            "pagination": {
                "pageSize": 25,
                "limitParam": "limit",
                "offsetParam": "offset"
            }
        }
        """.data(using: .utf8)!)

        _ = try await loader.loadData(endpoint: "/api/v1/items", config: config)

        let request = await mock.lastRequest
        #expect(request?.queryParameters["limit"] == "25")
        #expect(request?.queryParameters["offset"] == "0")
    }

    @Test("loadNextPage uses correct offset")
    func loadNextPageOffset() async throws {
        let mock = await makeMockWithResponse()
        let loader = makeLoader(mock: mock)

        let config = try JSONDecoder().decode(DataConfig.self, from: """
        {
            "pagination": {
                "pageSize": 10,
                "limitParam": "limit",
                "offsetParam": "offset"
            }
        }
        """.data(using: .utf8)!)

        _ = try await loader.loadNextPage(
            endpoint: "/api/v1/items",
            config: config,
            currentOffset: 30
        )

        let request = await mock.lastRequest
        #expect(request?.queryParameters["limit"] == "10")
        #expect(request?.queryParameters["offset"] == "30")
    }

    @Test("loadData with nil config makes plain request")
    func loadDataWithNilConfig() async throws {
        let mock = await makeMockWithResponse()
        let loader = makeLoader(mock: mock)

        _ = try await loader.loadData(endpoint: "/api/v1/simple", config: nil)

        let request = await mock.lastRequest
        #expect(request?.queryParameters.isEmpty == true)
    }

    @Test("loadData throws on network error")
    func loadDataThrowsOnError() async {
        let mock = MockNetworkClient()
        await mock.setError(NetworkError.timeout)
        let loader = makeLoader(mock: mock)

        await #expect(throws: Error.self) {
            _ = try await loader.loadData(endpoint: "/api/v1/data", config: nil)
        }
    }

    // MARK: - Offline Mode Tests

    @Test("Offline returns cached data as stale")
    func offlineReturnsCachedData() async throws {
        let mock = await makeMockWithResponse()
        let loader = makeLoader(mock: mock)

        // Load data while online to populate cache
        _ = try await loader.loadData(endpoint: "/api/v1/data", config: nil)

        // Go offline
        await loader.setOnline(false)

        // Should return cached data marked as stale
        let result = try await loader.loadDataWithResult(endpoint: "/api/v1/data", config: nil, params: nil)
        #expect(result.isStale == true)

        // No additional network request should be made
        let requestCount = await mock.requestCount
        #expect(requestCount == 1)
    }

    @Test("Offline with no cache throws network error")
    func offlineNoCacheThrows() async {
        let mock = MockNetworkClient()
        let loader = makeLoader(mock: mock)

        await loader.setOnline(false)

        await #expect(throws: Error.self) {
            _ = try await loader.loadDataWithResult(endpoint: "/api/v1/unknown", config: nil, params: nil)
        }
    }

    @Test("Online fetch failure falls back to cache as stale")
    func onlineFailureFallsBackToCache() async throws {
        let mock = await makeMockWithResponse()
        let loader = makeLoader(mock: mock)

        // Populate cache
        _ = try await loader.loadData(endpoint: "/api/v1/data", config: nil)

        // Set error for next request
        await mock.setError(NetworkError.timeout)

        // Should fall back to cached data
        let result = try await loader.loadDataWithResult(endpoint: "/api/v1/data", config: nil, params: nil)
        #expect(result.isStale == true)
    }

    @Test("Online fresh data is not stale")
    func onlineFreshDataNotStale() async throws {
        let mock = await makeMockWithResponse()
        let loader = makeLoader(mock: mock)

        let result = try await loader.loadDataWithResult(endpoint: "/api/v1/data", config: nil, params: nil)
        #expect(result.isStale == false)
    }

    @Test("clearCache removes all cached entries")
    func clearCacheRemovesAll() async throws {
        let mock = await makeMockWithResponse()
        let loader = makeLoader(mock: mock)

        // Populate cache
        _ = try await loader.loadData(endpoint: "/api/v1/data", config: nil)

        // Clear
        await loader.clearCache()

        // Go offline - should throw since cache is empty
        await loader.setOnline(false)
        await #expect(throws: Error.self) {
            _ = try await loader.loadDataWithResult(endpoint: "/api/v1/data", config: nil, params: nil)
        }
    }

    @Test("setOnline updates isOnline property")
    func setOnlineUpdatesProperty() async {
        let mock = MockNetworkClient()
        let loader = makeLoader(mock: mock)

        let initial = await loader.isOnline
        #expect(initial == true)

        await loader.setOnline(false)
        let offline = await loader.isOnline
        #expect(offline == false)

        await loader.setOnline(true)
        let online = await loader.isOnline
        #expect(online == true)
    }
}
