import Testing
import Foundation
@testable import NetworkSDK

// MARK: - HTTPMethod Tests

@Suite struct HTTPMethodTests {

    @Test func testAllCases() {
        let cases = HTTPMethod.allCases
        #expect(cases.contains(.get))
        #expect(cases.contains(.post))
        #expect(cases.contains(.put))
        #expect(cases.contains(.delete))
        #expect(cases.contains(.patch))
    }

    @Test func testRawValues() {
        #expect(HTTPMethod.get.rawValue == "GET")
        #expect(HTTPMethod.post.rawValue == "POST")
        #expect(HTTPMethod.put.rawValue == "PUT")
        #expect(HTTPMethod.delete.rawValue == "DELETE")
        #expect(HTTPMethod.patch.rawValue == "PATCH")
    }
}

// MARK: - HTTPRequest Tests

@Suite struct HTTPRequestTests {

    @Test func testInit() {
        let request = HTTPRequest(url: "https://api.example.com/users")
        #expect(request.url == "https://api.example.com/users")
    }

    @Test func testMethodBuilder() {
        let request = HTTPRequest(url: "https://api.example.com")
            .method(.post)
        #expect(request.method == .post)
    }

    @Test func testHeaderBuilder() {
        let request = HTTPRequest(url: "https://api.example.com")
            .header("Content-Type", "application/json")
        #expect(request.headers["Content-Type"] == "application/json")
    }

    @Test func testMultipleHeaders() {
        let request = HTTPRequest(url: "https://api.example.com")
            .headers(["Accept": "application/json", "X-Custom": "value"])
        #expect(request.headers["Accept"] == "application/json")
        #expect(request.headers["X-Custom"] == "value")
    }

    @Test func testQueryParam() {
        let request = HTTPRequest(url: "https://api.example.com")
            .queryParam("page", "1")
        #expect(request.queryParameters["page"] == "1")
    }

    @Test func testMultipleQueryParams() {
        let request = HTTPRequest(url: "https://api.example.com")
            .queryParams(["page": "1", "limit": "20"])
        #expect(request.queryParameters["page"] == "1")
        #expect(request.queryParameters["limit"] == "20")
    }

    @Test func testBodyBuilder() {
        let bodyData = "test".data(using: .utf8)!
        let request = HTTPRequest(url: "https://api.example.com")
            .body(bodyData)
        #expect(request.body == bodyData)
    }

    @Test func testChainedBuilders() {
        let request = HTTPRequest(url: "https://api.example.com/users")
            .method(.post)
            .header("Content-Type", "application/json")
            .queryParam("version", "2")
        #expect(request.method == .post)
        #expect(request.headers["Content-Type"] == "application/json")
        #expect(request.queryParameters["version"] == "2")
    }
}

// MARK: - NetworkError Tests

@Suite struct NetworkErrorTests {

    @Test func testNetworkFailureEquality() {
        #expect(
            NetworkError.networkFailure(underlyingError: "test") ==
            NetworkError.networkFailure(underlyingError: "test")
        )
    }

    @Test func testTimeoutEquality() {
        #expect(NetworkError.timeout == NetworkError.timeout)
    }

    @Test func testServerErrorEquality() {
        #expect(
            NetworkError.serverError(statusCode: 500, message: nil) ==
            NetworkError.serverError(statusCode: 500, message: nil)
        )
        #expect(
            NetworkError.serverError(statusCode: 500, message: nil) !=
            NetworkError.serverError(statusCode: 503, message: nil)
        )
    }

    @Test func testCancelledEquality() {
        #expect(NetworkError.cancelled == NetworkError.cancelled)
    }

    @Test func testUnauthorized() {
        #expect(NetworkError.unauthorized == NetworkError.unauthorized)
    }

    @Test func testErrorDescription() {
        let error = NetworkError.timeout
        #expect(error.errorDescription != nil)
        #expect(!error.errorDescription!.isEmpty)
    }

    @Test func testDebugDescription() {
        let error = NetworkError.timeout
        let debug = error.debugDescription
        #expect(!debug.isEmpty)
    }

    @Test func testInvalidURL() {
        let error = NetworkError.invalidURL("bad-url")
        #expect(error.errorDescription != nil)
    }
}

// MARK: - EmptyResponse Tests

@Suite struct EmptyResponseTests {

    @Test func testInit() {
        let empty = EmptyResponse()
        #expect(empty != nil)
    }

    @Test func testEquality() {
        #expect(EmptyResponse() == EmptyResponse())
    }

    @Test func testDecodable() throws {
        let data = "{}".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(EmptyResponse.self, from: data)
        #expect(decoded == EmptyResponse())
    }
}

// MARK: - RetryDecision Tests

@Suite struct RetryDecisionTests {

    @Test func testEquality() {
        #expect(RetryDecision.doNotRetry == RetryDecision.doNotRetry)
        #expect(RetryDecision.retryImmediately == RetryDecision.retryImmediately)
        #expect(RetryDecision.retryAfter(1.0) == RetryDecision.retryAfter(1.0))
        #expect(RetryDecision.retryImmediately != RetryDecision.doNotRetry)
    }
}

// MARK: - RequestContext Tests

@Suite struct RequestContextTests {

    @Test func testInit() {
        let request = HTTPRequest(url: "https://example.com")
        let context = RequestContext(
            originalRequest: request,
            attemptNumber: 1,
            elapsedTime: 0.5,
            metadata: ["key": "value"]
        )
        #expect(context.attemptNumber == 1)
        #expect(context.elapsedTime == 0.5)
        #expect(context.metadata["key"] == "value")
    }

    @Test func testNextAttempt() {
        let request = HTTPRequest(url: "https://example.com")
        let context = RequestContext(
            originalRequest: request,
            attemptNumber: 1,
            elapsedTime: 0.5,
            metadata: [:]
        )
        let next = context.nextAttempt(elapsedTime: 1.0)
        #expect(next.attemptNumber == 2)
        #expect(next.elapsedTime == 1.0)
    }
}

// MARK: - LogLevel Tests

@Suite struct LogLevelTests {

    @Test func testOrdering() {
        #expect(LogLevel.verbose > LogLevel.debug)
        #expect(LogLevel.debug > LogLevel.info)
        #expect(LogLevel.info > LogLevel.error)
    }

    @Test func testAllCases() {
        #expect(LogLevel.allCases.count >= 4)
    }
}

// MARK: - LoggingInterceptor Tests

@Suite struct LoggingInterceptorTests {

    @Test func testDefaultInit() {
        let interceptor = LoggingInterceptor()
        #expect(interceptor.level == .info)
        #expect(!interceptor.includeHeaders)
        #expect(!interceptor.includeBody)
    }

    @Test func testCustomInit() {
        let interceptor = LoggingInterceptor(
            level: .debug,
            subsystem: "com.test",
            category: "network",
            includeHeaders: true,
            includeBody: true
        )
        #expect(interceptor.level == .debug)
        #expect(interceptor.subsystem == "com.test")
        #expect(interceptor.category == "network")
        #expect(interceptor.includeHeaders)
        #expect(interceptor.includeBody)
    }

    @Test func testAdaptPassesThrough() async throws {
        let interceptor = LoggingInterceptor()
        var urlRequest = URLRequest(url: URL(string: "https://example.com")!)
        urlRequest.setValue("value", forHTTPHeaderField: "X-Test")
        let context = RequestContext(
            originalRequest: HTTPRequest(url: "https://example.com"),
            attemptNumber: 1,
            elapsedTime: 0,
            metadata: [:]
        )
        let adapted = try await interceptor.adapt(urlRequest, context: context)
        #expect(adapted.url?.absoluteString == "https://example.com")
        #expect(adapted.value(forHTTPHeaderField: "X-Test") == "value")
    }
}

// MARK: - ExponentialBackoffRetryPolicy Tests

@Suite struct ExponentialBackoffRetryPolicyTests {

    @Test func testDefaultInit() {
        let policy = ExponentialBackoffRetryPolicy()
        #expect(policy.maxRetryCount == 3)
        #expect(policy.baseDelay > 0)
    }

    @Test func testShouldRetryNetworkFailure() {
        let policy = ExponentialBackoffRetryPolicy()
        #expect(policy.shouldRetry(error: .networkFailure(underlyingError: "offline")))
    }

    @Test func testShouldRetryTimeout() {
        let policy = ExponentialBackoffRetryPolicy()
        #expect(policy.shouldRetry(error: .timeout))
    }

    @Test func testShouldNotRetryClientError() {
        let policy = ExponentialBackoffRetryPolicy()
        #expect(!policy.shouldRetry(error: .serverError(statusCode: 400, message: nil)))
    }

    @Test func testShouldRetryServerError() {
        let policy = ExponentialBackoffRetryPolicy()
        let result = policy.shouldRetry(error: .serverError(statusCode: 503, message: nil))
        #expect(result)
    }
}

// MARK: - SimpleTokenProvider Tests

@Suite struct SimpleTokenProviderTests {

    @Test func testGetAccessToken() async {
        let provider = SimpleTokenProvider(getToken: { "test-token" })
        let token = await provider.getAccessToken()
        #expect(token == "test-token")
    }

    @Test func testRefreshToken() async {
        let provider = SimpleTokenProvider(
            getToken: { "token" },
            refresh: { "refresh-token" }
        )
        let token = await provider.refreshToken()
        #expect(token == "refresh-token")
    }

    @Test func testNilTokenByDefault() async {
        let provider = SimpleTokenProvider(getToken: { nil })
        let access = await provider.getAccessToken()
        #expect(access == nil)
        let refresh = await provider.refreshToken()
        #expect(refresh == nil)
    }

    @Test func testIsTokenExpired() async {
        let provider = SimpleTokenProvider(
            getToken: { "token" },
            isExpired: { true }
        )
        let expired = await provider.isTokenExpired()
        #expect(expired)
    }

    @Test func testIsTokenNotExpiredByDefault() async {
        let provider = SimpleTokenProvider(getToken: { "token" })
        let expired = await provider.isTokenExpired()
        #expect(!expired)
    }
}

// MARK: - StaticTokenProvider Tests

@Suite struct StaticTokenProviderTests {

    @Test func testWithToken() async {
        let provider = StaticTokenProvider(token: "static-token")
        let token = await provider.getAccessToken()
        #expect(token == "static-token")
    }

    @Test func testWithNilToken() async {
        let provider = StaticTokenProvider(token: nil)
        let token = await provider.getAccessToken()
        #expect(token == nil)
    }
}

// MARK: - NetworkClient Tests

@Suite struct NetworkClientTests {

    @Test func testSetAndRemoveGlobalHeader() async {
        let client = NetworkClient()
        await client.setGlobalHeader("test-value", forKey: "X-Test")
        await client.removeGlobalHeader(forKey: "X-Test")
        // No crash = pass
    }

    @Test func testSetAndClearAuthToken() async {
        let client = NetworkClient()
        await client.setAuthorizationToken("Bearer token123")
        await client.clearAuthorizationToken()
        // No crash = pass
    }
}

// MARK: - InterceptableNetworkClient Tests

@Suite struct InterceptableNetworkClientTests {

    @Test func testSetAndRemoveGlobalHeader() async {
        let client = InterceptableNetworkClient()
        await client.setGlobalHeader("test-value", forKey: "X-Test")
        await client.removeGlobalHeader(forKey: "X-Test")
    }

    @Test func testSetAndClearAuthToken() async {
        let client = InterceptableNetworkClient()
        await client.setAuthorizationToken("Bearer token123")
        await client.clearAuthorizationToken()
    }
}
