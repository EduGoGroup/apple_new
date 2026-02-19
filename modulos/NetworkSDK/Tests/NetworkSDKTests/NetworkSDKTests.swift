import XCTest
@testable import NetworkSDK

// MARK: - HTTPMethod Tests

final class HTTPMethodTests: XCTestCase {

    func testAllCases() {
        let cases = HTTPMethod.allCases
        XCTAssertTrue(cases.contains(.get))
        XCTAssertTrue(cases.contains(.post))
        XCTAssertTrue(cases.contains(.put))
        XCTAssertTrue(cases.contains(.delete))
        XCTAssertTrue(cases.contains(.patch))
    }

    func testRawValues() {
        XCTAssertEqual(HTTPMethod.get.rawValue, "GET")
        XCTAssertEqual(HTTPMethod.post.rawValue, "POST")
        XCTAssertEqual(HTTPMethod.put.rawValue, "PUT")
        XCTAssertEqual(HTTPMethod.delete.rawValue, "DELETE")
        XCTAssertEqual(HTTPMethod.patch.rawValue, "PATCH")
    }
}

// MARK: - HTTPRequest Tests

final class HTTPRequestTests: XCTestCase {

    func testInit() {
        let request = HTTPRequest(url: "https://api.example.com/users")
        XCTAssertEqual(request.url, "https://api.example.com/users")
    }

    func testMethodBuilder() {
        let request = HTTPRequest(url: "https://api.example.com")
            .method(.post)
        XCTAssertEqual(request.method, .post)
    }

    func testHeaderBuilder() {
        let request = HTTPRequest(url: "https://api.example.com")
            .header("Content-Type", "application/json")
        XCTAssertEqual(request.headers["Content-Type"], "application/json")
    }

    func testMultipleHeaders() {
        let request = HTTPRequest(url: "https://api.example.com")
            .headers(["Accept": "application/json", "X-Custom": "value"])
        XCTAssertEqual(request.headers["Accept"], "application/json")
        XCTAssertEqual(request.headers["X-Custom"], "value")
    }

    func testQueryParam() {
        let request = HTTPRequest(url: "https://api.example.com")
            .queryParam("page", "1")
        XCTAssertEqual(request.queryParameters["page"], "1")
    }

    func testMultipleQueryParams() {
        let request = HTTPRequest(url: "https://api.example.com")
            .queryParams(["page": "1", "limit": "20"])
        XCTAssertEqual(request.queryParameters["page"], "1")
        XCTAssertEqual(request.queryParameters["limit"], "20")
    }

    func testBodyBuilder() {
        let bodyData = "test".data(using: .utf8)!
        let request = HTTPRequest(url: "https://api.example.com")
            .body(bodyData)
        XCTAssertEqual(request.body, bodyData)
    }

    func testChainedBuilders() {
        let request = HTTPRequest(url: "https://api.example.com/users")
            .method(.post)
            .header("Content-Type", "application/json")
            .queryParam("version", "2")
        XCTAssertEqual(request.method, .post)
        XCTAssertEqual(request.headers["Content-Type"], "application/json")
        XCTAssertEqual(request.queryParameters["version"], "2")
    }
}

// MARK: - NetworkError Tests

final class NetworkErrorTests: XCTestCase {

    func testNetworkFailureEquality() {
        XCTAssertEqual(
            NetworkError.networkFailure(underlyingError: "test"),
            NetworkError.networkFailure(underlyingError: "test")
        )
    }

    func testTimeoutEquality() {
        XCTAssertEqual(NetworkError.timeout, NetworkError.timeout)
    }

    func testServerErrorEquality() {
        XCTAssertEqual(
            NetworkError.serverError(statusCode: 500, message: nil),
            NetworkError.serverError(statusCode: 500, message: nil)
        )
        XCTAssertNotEqual(
            NetworkError.serverError(statusCode: 500, message: nil),
            NetworkError.serverError(statusCode: 503, message: nil)
        )
    }

    func testCancelledEquality() {
        XCTAssertEqual(NetworkError.cancelled, NetworkError.cancelled)
    }

    func testUnauthorized() {
        XCTAssertEqual(NetworkError.unauthorized, NetworkError.unauthorized)
    }

    func testErrorDescription() {
        let error = NetworkError.timeout
        XCTAssertNotNil(error.errorDescription)
        XCTAssertFalse(error.errorDescription!.isEmpty)
    }

    func testDebugDescription() {
        let error = NetworkError.timeout
        let debug = error.debugDescription
        XCTAssertFalse(debug.isEmpty)
    }

    func testInvalidURL() {
        let error = NetworkError.invalidURL("bad-url")
        XCTAssertNotNil(error.errorDescription)
    }
}

// MARK: - EmptyResponse Tests

final class EmptyResponseTests: XCTestCase {

    func testInit() {
        let empty = EmptyResponse()
        XCTAssertNotNil(empty)
    }

    func testEquality() {
        XCTAssertEqual(EmptyResponse(), EmptyResponse())
    }

    func testDecodable() throws {
        let data = "{}".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(EmptyResponse.self, from: data)
        XCTAssertEqual(decoded, EmptyResponse())
    }
}

// MARK: - RetryDecision Tests

final class RetryDecisionTests: XCTestCase {

    func testEquality() {
        XCTAssertEqual(RetryDecision.doNotRetry, RetryDecision.doNotRetry)
        XCTAssertEqual(RetryDecision.retryImmediately, RetryDecision.retryImmediately)
        XCTAssertEqual(RetryDecision.retryAfter(1.0), RetryDecision.retryAfter(1.0))
        XCTAssertNotEqual(RetryDecision.retryImmediately, RetryDecision.doNotRetry)
    }
}

// MARK: - RequestContext Tests

final class RequestContextTests: XCTestCase {

    func testInit() {
        let request = HTTPRequest(url: "https://example.com")
        let context = RequestContext(
            originalRequest: request,
            attemptNumber: 1,
            elapsedTime: 0.5,
            metadata: ["key": "value"]
        )
        XCTAssertEqual(context.attemptNumber, 1)
        XCTAssertEqual(context.elapsedTime, 0.5)
        XCTAssertEqual(context.metadata["key"], "value")
    }

    func testNextAttempt() {
        let request = HTTPRequest(url: "https://example.com")
        let context = RequestContext(
            originalRequest: request,
            attemptNumber: 1,
            elapsedTime: 0.5,
            metadata: [:]
        )
        let next = context.nextAttempt(elapsedTime: 1.0)
        XCTAssertEqual(next.attemptNumber, 2)
        XCTAssertEqual(next.elapsedTime, 1.0)
    }
}

// MARK: - LogLevel Tests

final class LogLevelTests: XCTestCase {

    func testOrdering() {
        XCTAssertTrue(LogLevel.verbose > LogLevel.debug)
        XCTAssertTrue(LogLevel.debug > LogLevel.info)
        XCTAssertTrue(LogLevel.info > LogLevel.error)
    }

    func testAllCases() {
        XCTAssertGreaterThanOrEqual(LogLevel.allCases.count, 4)
    }
}

// MARK: - LoggingInterceptor Tests

final class LoggingInterceptorTests: XCTestCase {

    func testDefaultInit() {
        let interceptor = LoggingInterceptor()
        XCTAssertEqual(interceptor.level, .info)
        XCTAssertFalse(interceptor.includeHeaders)
        XCTAssertFalse(interceptor.includeBody)
    }

    func testCustomInit() {
        let interceptor = LoggingInterceptor(
            level: .debug,
            subsystem: "com.test",
            category: "network",
            includeHeaders: true,
            includeBody: true
        )
        XCTAssertEqual(interceptor.level, .debug)
        XCTAssertEqual(interceptor.subsystem, "com.test")
        XCTAssertEqual(interceptor.category, "network")
        XCTAssertTrue(interceptor.includeHeaders)
        XCTAssertTrue(interceptor.includeBody)
    }

    func testAdaptPassesThrough() async throws {
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
        XCTAssertEqual(adapted.url?.absoluteString, "https://example.com")
        XCTAssertEqual(adapted.value(forHTTPHeaderField: "X-Test"), "value")
    }
}

// MARK: - ExponentialBackoffRetryPolicy Tests

final class ExponentialBackoffRetryPolicyTests: XCTestCase {

    func testDefaultInit() {
        let policy = ExponentialBackoffRetryPolicy()
        XCTAssertEqual(policy.maxRetryCount, 3)
        XCTAssertGreaterThan(policy.baseDelay, 0)
    }

    func testShouldRetryNetworkFailure() {
        let policy = ExponentialBackoffRetryPolicy()
        XCTAssertTrue(policy.shouldRetry(error: .networkFailure(underlyingError: "offline")))
    }

    func testShouldRetryTimeout() {
        let policy = ExponentialBackoffRetryPolicy()
        XCTAssertTrue(policy.shouldRetry(error: .timeout))
    }

    func testShouldNotRetryClientError() {
        let policy = ExponentialBackoffRetryPolicy()
        XCTAssertFalse(policy.shouldRetry(error: .serverError(statusCode: 400, message: nil)))
    }

    func testShouldRetryServerError() {
        let policy = ExponentialBackoffRetryPolicy()
        let result = policy.shouldRetry(error: .serverError(statusCode: 503, message: nil))
        XCTAssertTrue(result)
    }
}

// MARK: - SimpleTokenProvider Tests

final class SimpleTokenProviderTests: XCTestCase {

    func testGetAccessToken() async {
        let provider = SimpleTokenProvider(getToken: { "test-token" })
        let token = await provider.getAccessToken()
        XCTAssertEqual(token, "test-token")
    }

    func testRefreshToken() async {
        let provider = SimpleTokenProvider(
            getToken: { "token" },
            refresh: { "refresh-token" }
        )
        let token = await provider.refreshToken()
        XCTAssertEqual(token, "refresh-token")
    }

    func testNilTokenByDefault() async {
        let provider = SimpleTokenProvider(getToken: { nil })
        let access = await provider.getAccessToken()
        XCTAssertNil(access)
        let refresh = await provider.refreshToken()
        XCTAssertNil(refresh)
    }

    func testIsTokenExpired() async {
        let provider = SimpleTokenProvider(
            getToken: { "token" },
            isExpired: { true }
        )
        let expired = await provider.isTokenExpired()
        XCTAssertTrue(expired)
    }

    func testIsTokenNotExpiredByDefault() async {
        let provider = SimpleTokenProvider(getToken: { "token" })
        let expired = await provider.isTokenExpired()
        XCTAssertFalse(expired)
    }
}

// MARK: - StaticTokenProvider Tests

final class StaticTokenProviderTests: XCTestCase {

    func testWithToken() async {
        let provider = StaticTokenProvider(token: "static-token")
        let token = await provider.getAccessToken()
        XCTAssertEqual(token, "static-token")
    }

    func testWithNilToken() async {
        let provider = StaticTokenProvider(token: nil)
        let token = await provider.getAccessToken()
        XCTAssertNil(token)
    }
}

// MARK: - NetworkClient Tests

final class NetworkClientTests: XCTestCase {

    func testSetAndRemoveGlobalHeader() async {
        let client = NetworkClient()
        await client.setGlobalHeader("test-value", forKey: "X-Test")
        await client.removeGlobalHeader(forKey: "X-Test")
        // No crash = pass
    }

    func testSetAndClearAuthToken() async {
        let client = NetworkClient()
        await client.setAuthorizationToken("Bearer token123")
        await client.clearAuthorizationToken()
        // No crash = pass
    }
}

// MARK: - InterceptableNetworkClient Tests

final class InterceptableNetworkClientTests: XCTestCase {

    func testSetAndRemoveGlobalHeader() async {
        let client = InterceptableNetworkClient()
        await client.setGlobalHeader("test-value", forKey: "X-Test")
        await client.removeGlobalHeader(forKey: "X-Test")
    }

    func testSetAndClearAuthToken() async {
        let client = InterceptableNetworkClient()
        await client.setAuthorizationToken("Bearer token123")
        await client.clearAuthorizationToken()
    }
}
