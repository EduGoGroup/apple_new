import Testing
import Foundation
@testable import EduNetwork

@Suite("NetworkClient Tests")
struct NetworkClientTests {
    // MARK: - HTTPRequest Builder Tests

    @Test("HTTPRequest builds valid URL request")
    func testHTTPRequestBuildsValidURLRequest() throws {
        let request = HTTPRequest(url: "https://api.test.com/users")
            .method(.post)
            .header("X-Custom", "value")
            .queryParam("page", "1")

        let urlRequest = try request.build()

        #expect(urlRequest.url?.absoluteString.contains("api.test.com/users") == true)
        #expect(urlRequest.url?.absoluteString.contains("page=1") == true)
        #expect(urlRequest.httpMethod == "POST")
        #expect(urlRequest.value(forHTTPHeaderField: "X-Custom") == "value")
    }

    @Test("HTTPRequest with JSON body sets content type")
    func testHTTPRequestWithJSONBody() throws {
        let data = try JSONSerialization.data(withJSONObject: [
            "name": "test",
            "value": 42
        ])

        let request = HTTPRequest.post("https://api.test.com/data")
            .jsonBody(data)

        let urlRequest = try request.build()

        #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(urlRequest.httpBody != nil)
    }

    @Test("HTTPRequest convenience methods create correct HTTP methods")
    func testHTTPRequestConvenienceMethods() throws {
        let getRequest = HTTPRequest.get("https://api.test.com")
        let postRequest = HTTPRequest.post("https://api.test.com")
        let putRequest = HTTPRequest.put("https://api.test.com")
        let deleteRequest = HTTPRequest.delete("https://api.test.com")
        let patchRequest = HTTPRequest.patch("https://api.test.com")

        #expect(getRequest.method == .get)
        #expect(postRequest.method == .post)
        #expect(putRequest.method == .put)
        #expect(deleteRequest.method == .delete)
        #expect(patchRequest.method == .patch)
    }

    @Test("HTTPRequest with bearer token sets Authorization header")
    func testHTTPRequestBearerToken() throws {
        let request = HTTPRequest.get("https://api.test.com")
            .bearerToken("my-token-123")

        let urlRequest = try request.build()

        #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer my-token-123")
    }

    @Test("HTTPRequest with basic auth sets Authorization header")
    func testHTTPRequestBasicAuth() throws {
        let request = HTTPRequest.get("https://api.test.com")
            .basicAuth(username: "user", password: "pass")

        let urlRequest = try request.build()

        let expectedCredentials = "user:pass".data(using: .utf8)!.base64EncodedString()
        #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == "Basic \(expectedCredentials)")
    }

    @Test("HTTPRequest with timeout sets correct value")
    func testHTTPRequestTimeout() throws {
        let request = HTTPRequest.get("https://api.test.com")
            .timeout(45)

        let urlRequest = try request.build()

        #expect(urlRequest.timeoutInterval == 45)
    }

    @Test("HTTPRequest acceptJSON adds Accept header")
    func testHTTPRequestAcceptJSON() throws {
        let request = HTTPRequest.get("https://api.test.com")
            .acceptJSON()

        let urlRequest = try request.build()

        #expect(urlRequest.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test("HTTPRequest with multiple query params")
    func testHTTPRequestMultipleQueryParams() throws {
        let request = HTTPRequest.get("https://api.test.com/search")
            .queryParams(["q": "test", "page": "1", "limit": "20"])

        let urlRequest = try request.build()
        let urlString = urlRequest.url?.absoluteString ?? ""

        #expect(urlString.contains("q=test"))
        #expect(urlString.contains("page=1"))
        #expect(urlString.contains("limit=20"))
    }

    @Test("HTTPRequest with multiple headers")
    func testHTTPRequestMultipleHeaders() throws {
        let request = HTTPRequest.get("https://api.test.com")
            .headers([
                "X-API-Key": "key-123",
                "X-Request-ID": "req-456",
                "Accept-Language": "es"
            ])

        let urlRequest = try request.build()

        #expect(urlRequest.value(forHTTPHeaderField: "X-API-Key") == "key-123")
        #expect(urlRequest.value(forHTTPHeaderField: "X-Request-ID") == "req-456")
        #expect(urlRequest.value(forHTTPHeaderField: "Accept-Language") == "es")
    }

    // MARK: - NetworkClient Instance Tests

    @Test("NetworkClient shared instance exists")
    func testNetworkClientSharedInstance() {
        let client = NetworkClient.shared
        #expect(client != nil)
    }

    @Test("NetworkClient can be initialized with custom configuration")
    func testNetworkClientCustomInit() {
        let policy = ExponentialBackoffRetryPolicy(maxRetryCount: 5)
        let client = NetworkClient(interceptors: [], retryPolicy: policy)
        #expect(client != nil)
    }

    // MARK: - MockNetworkClient Tests

    @Test("MockNetworkClient returns configured response")
    func testMockNetworkClientResponse() async throws {
        let mock = MockNetworkClient()

        struct TestResponse: Decodable, Sendable, Equatable {
            let id: Int
            let name: String
        }

        await mock.setResponse(TestResponse(id: 1, name: "Test"))

        let request = HTTPRequest.get("https://api.test.com")
        let response: TestResponse = try await mock.request(request)

        #expect(response.id == 1)
        #expect(response.name == "Test")
    }

    @Test("MockNetworkClient throws configured error")
    func testMockNetworkClientError() async throws {
        let mock = MockNetworkClient()
        await mock.setError(.unauthorized)

        let request = HTTPRequest.get("https://api.test.com")

        await #expect(throws: NetworkError.unauthorized) {
            let _: EmptyResponse = try await mock.request(request)
        }
    }

    @Test("MockNetworkClient records request history")
    func testMockNetworkClientHistory() async throws {
        let mock = MockNetworkClient()
        await mock.setResponse(EmptyResponse())

        let request1 = HTTPRequest.get("https://api.test.com/users")
        let request2 = HTTPRequest.post("https://api.test.com/data")

        let _: EmptyResponse = try await mock.request(request1)
        let _: EmptyResponse = try await mock.request(request2)

        let count = await mock.requestCount
        let wasRequestedUsers = await mock.wasRequestedWith(url: "/users")
        let wasRequestedPost = await mock.wasRequestedWith(method: .post)

        #expect(count == 2)
        #expect(wasRequestedUsers)
        #expect(wasRequestedPost)
    }

    @Test("MockNetworkClient reset clears all state")
    func testMockNetworkClientReset() async throws {
        let mock = MockNetworkClient()
        await mock.setResponse(EmptyResponse())
        await mock.setError(.timeout)

        let request = HTTPRequest.get("https://api.test.com")
        do {
            let _: EmptyResponse = try await mock.request(request)
        } catch {
            // Expected
        }

        await mock.reset()

        let count = await mock.requestCount
        let wasRequested = await mock.wasRequested

        #expect(count == 0)
        #expect(!wasRequested)
    }
}

@Suite("Response Types Tests")
struct ResponseTypesTests {
    @Test("EmptyResponse can be decoded from empty JSON")
    func testEmptyResponseDecoding() throws {
        let json = "{}".data(using: .utf8)!
        let decoder = JSONDecoder()

        let response = try decoder.decode(EmptyResponse.self, from: json)
        #expect(response == EmptyResponse())
    }

    @Test("EmptyResponse can be decoded from null JSON")
    func testEmptyResponseFromNull() throws {
        let json = "null".data(using: .utf8)!
        let decoder = JSONDecoder()

        let response = try decoder.decode(EmptyResponse.self, from: json)
        #expect(response == EmptyResponse())
    }

    @Test("APIResponse decodes correctly")
    func testAPIResponseDecoding() throws {
        let json = """
        {
            "data": {"id": 1, "name": "Test"},
            "message": "Success",
            "success": true
        }
        """.data(using: .utf8)!

        struct TestData: Decodable, Sendable {
            let id: Int
            let name: String
        }

        let decoder = JSONDecoder()
        let response = try decoder.decode(APIResponse<TestData>.self, from: json)

        #expect(response.success == true)
        #expect(response.message == "Success")
        #expect(response.data.id == 1)
        #expect(response.data.name == "Test")
    }

    @Test("PaginatedResponse decodes and computes pagination correctly")
    func testPaginatedResponseDecoding() throws {
        let json = """
        {
            "items": [{"id": 1}, {"id": 2}, {"id": 3}],
            "total_count": 100,
            "page": 2,
            "page_size": 3
        }
        """.data(using: .utf8)!

        struct TestItem: Decodable, Sendable {
            let id: Int
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(PaginatedResponse<TestItem>.self, from: json)

        #expect(response.items.count == 3)
        #expect(response.totalCount == 100)
        #expect(response.page == 2)
        #expect(response.pageSize == 3)
        #expect(response.hasNextPage == true)
        #expect(response.totalPages == 34)
    }

    @Test("PaginatedResponse hasNextPage false on last page")
    func testPaginatedResponseLastPage() {
        struct TestItem: Decodable, Sendable {
            let id: Int
        }

        let response = PaginatedResponse<TestItem>(
            items: [],
            totalCount: 10,
            page: 2,
            pageSize: 5
        )

        #expect(response.hasNextPage == false)
        #expect(response.totalPages == 2)
    }
}
