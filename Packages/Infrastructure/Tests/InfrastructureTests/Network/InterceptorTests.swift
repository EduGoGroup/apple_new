import Testing
import Foundation
@testable import EduNetwork

@Suite("Interceptor Tests")
struct InterceptorTests {
    struct HeaderInterceptor: RequestInterceptor {
        let value: String

        func adapt(
            _ request: URLRequest,
            context: RequestContext
        ) async throws -> URLRequest {
            var modified = request
            modified.setValue(value, forHTTPHeaderField: "X-Test")
            return modified
        }
    }

    struct RetryDecisionInterceptor: RequestInterceptor {
        let decision: RetryDecision

        func retry(
            _ request: URLRequest,
            dueTo error: NetworkError,
            context: RequestContext
        ) async -> RetryDecision {
            decision
        }
    }

    @Test("AuthenticationInterceptor adds Authorization header")
    func testAuthenticationInterceptorAddsHeader() async throws {
        let tokenProvider = StaticTokenProvider(token: "token-123")
        let interceptor = AuthenticationInterceptor(
            tokenProvider: tokenProvider,
            autoRefresh: false
        )

        let httpRequest = HTTPRequest.get("https://example.com")
        let urlRequest = try httpRequest.build()

        let adapted = try await interceptor.adapt(
            urlRequest,
            context: RequestContext(originalRequest: httpRequest)
        )

        #expect(adapted.value(forHTTPHeaderField: "Authorization") == "Bearer token-123")
    }

    @Test("InterceptorChain applies adapt in order")
    func testInterceptorChainAdaptOrder() async throws {
        let first = HeaderInterceptor(value: "A")
        let second = HeaderInterceptor(value: "B")
        let chain = InterceptorChain([first, second])

        let httpRequest = HTTPRequest.get("https://example.com")
        let urlRequest = try httpRequest.build()

        let adapted = try await chain.adapt(
            urlRequest,
            context: RequestContext(originalRequest: httpRequest)
        )

        #expect(adapted.value(forHTTPHeaderField: "X-Test") == "B")
    }

    @Test("InterceptorChain evaluates retry in reverse order")
    func testInterceptorChainRetryOrder() async throws {
        let first = RetryDecisionInterceptor(decision: .doNotRetry)
        let second = RetryDecisionInterceptor(decision: .retryImmediately)
        let chain = InterceptorChain([first, second])

        let httpRequest = HTTPRequest.get("https://example.com")
        let urlRequest = try httpRequest.build()
        let decision = await chain.retry(
            urlRequest,
            dueTo: .networkFailure(underlyingError: "offline"),
            context: RequestContext(originalRequest: httpRequest)
        )

        #expect(decision == .retryImmediately)
    }

    @Test("ExponentialBackoffRetryPolicy returns deterministic delay when jitter is zero")
    func testExponentialBackoffDelay() {
        let policy = ExponentialBackoffRetryPolicy(
            baseDelay: 1.0,
            maxDelay: 10.0,
            jitterFactor: 0.0,
            maxRetryCount: 3
        )

        #expect(policy.delay(forAttempt: 2) == 2.0)
    }

    @Test("RetryInterceptor returns retry decision for retriable error")
    func testRetryInterceptorDecision() async throws {
        let policy = ExponentialBackoffRetryPolicy(
            baseDelay: 1.0,
            maxDelay: 10.0,
            jitterFactor: 0.0,
            maxRetryCount: 3
        )
        let interceptor = RetryInterceptor(policy: policy)

        let httpRequest = HTTPRequest.get("https://example.com")
        let urlRequest = try httpRequest.build()
        let decision = await interceptor.retry(
            urlRequest,
            dueTo: .networkFailure(underlyingError: "offline"),
            context: RequestContext(originalRequest: httpRequest)
        )

        #expect(decision == .retryAfter(1.0))
    }
}

// MARK: - AuthenticationInterceptor Token Refresh Tests

/// Mock TokenProvider that tracks refresh calls and simulates expiry.
private final class RefreshableTokenProvider: TokenProvider, @unchecked Sendable {
    private var _token: String?
    private var _expired: Bool
    private var _refreshResult: String?
    var refreshCallCount = 0

    init(token: String?, expired: Bool = false, refreshResult: String? = nil) {
        _token = token
        _expired = expired
        _refreshResult = refreshResult
    }

    func getAccessToken() async -> String? { _token }

    func refreshToken() async -> String? {
        refreshCallCount += 1
        if let result = _refreshResult {
            _token = result
            _expired = false
        }
        return _refreshResult
    }

    func isTokenExpired() async -> Bool { _expired }
}

/// Mock SessionExpiredHandler that tracks calls.
private final class MockSessionExpiredHandler: SessionExpiredHandler, @unchecked Sendable {
    var sessionExpiredCallCount = 0

    func onSessionExpired() async {
        sessionExpiredCallCount += 1
    }
}

@Suite("AuthenticationInterceptor Token Refresh Tests")
struct AuthInterceptorRefreshTests {

    @Test("Auto-refresh is triggered when token is expired")
    func autoRefreshOnExpiredToken() async throws {
        let provider = RefreshableTokenProvider(
            token: "old-token",
            expired: true,
            refreshResult: "new-token"
        )
        let interceptor = AuthenticationInterceptor(
            tokenProvider: provider,
            autoRefresh: true
        )

        let httpRequest = HTTPRequest.get("https://example.com/api/data")
        let urlRequest = try httpRequest.build()

        let adapted = try await interceptor.adapt(
            urlRequest,
            context: RequestContext(originalRequest: httpRequest)
        )

        #expect(provider.refreshCallCount == 1)
        #expect(adapted.value(forHTTPHeaderField: "Authorization") == "Bearer new-token")
    }

    @Test("No refresh when token is not expired")
    func noRefreshWhenTokenValid() async throws {
        let provider = RefreshableTokenProvider(
            token: "valid-token",
            expired: false,
            refreshResult: "should-not-be-used"
        )
        let interceptor = AuthenticationInterceptor(
            tokenProvider: provider,
            autoRefresh: true
        )

        let httpRequest = HTTPRequest.get("https://example.com/api/data")
        let urlRequest = try httpRequest.build()

        let adapted = try await interceptor.adapt(
            urlRequest,
            context: RequestContext(originalRequest: httpRequest)
        )

        #expect(provider.refreshCallCount == 0)
        #expect(adapted.value(forHTTPHeaderField: "Authorization") == "Bearer valid-token")
    }

    @Test("Retry on 401 triggers refresh and returns retryImmediately")
    func retryOn401TriggersRefresh() async throws {
        let provider = RefreshableTokenProvider(
            token: "expired",
            expired: false,
            refreshResult: "refreshed-token"
        )
        let interceptor = AuthenticationInterceptor(
            tokenProvider: provider,
            autoRefresh: false,
            retryOn401: true
        )

        let httpRequest = HTTPRequest.get("https://example.com/api/data")
        let urlRequest = try httpRequest.build()
        let context = RequestContext(originalRequest: httpRequest, attemptNumber: 1)

        let decision = await interceptor.retry(
            urlRequest,
            dueTo: .unauthorized,
            context: context
        )

        #expect(provider.refreshCallCount == 1)
        #expect(decision == .retryImmediately)
    }

    @Test("Retry on 401 with failed refresh calls sessionExpiredHandler")
    func retryOn401FailedRefreshCallsSessionExpired() async throws {
        let provider = RefreshableTokenProvider(
            token: "expired",
            expired: false,
            refreshResult: nil
        )
        let sessionHandler = MockSessionExpiredHandler()
        let interceptor = AuthenticationInterceptor(
            tokenProvider: provider,
            sessionExpiredHandler: sessionHandler,
            autoRefresh: false,
            retryOn401: true
        )

        let httpRequest = HTTPRequest.get("https://example.com/api/data")
        let urlRequest = try httpRequest.build()
        let context = RequestContext(originalRequest: httpRequest, attemptNumber: 1)

        let decision = await interceptor.retry(
            urlRequest,
            dueTo: .unauthorized,
            context: context
        )

        #expect(decision == .doNotRetry)
        #expect(sessionHandler.sessionExpiredCallCount == 1)
    }

    @Test("Retry on 401 respects maxRetryCount")
    func retryRespectsMaxRetryCount() async throws {
        let provider = RefreshableTokenProvider(
            token: "expired",
            expired: false,
            refreshResult: "refreshed"
        )
        let interceptor = AuthenticationInterceptor(
            tokenProvider: provider,
            autoRefresh: false,
            retryOn401: true,
            maxRetryCount: 1
        )

        let httpRequest = HTTPRequest.get("https://example.com/api/data")
        let urlRequest = try httpRequest.build()

        // attemptNumber > maxRetryCount → doNotRetry
        let context = RequestContext(originalRequest: httpRequest, attemptNumber: 2)
        let decision = await interceptor.retry(
            urlRequest,
            dueTo: .unauthorized,
            context: context
        )

        #expect(decision == .doNotRetry)
        #expect(provider.refreshCallCount == 0)
    }

    @Test("Retry ignores non-401 errors")
    func retryIgnoresNon401Errors() async throws {
        let provider = RefreshableTokenProvider(
            token: "valid",
            expired: false,
            refreshResult: "refreshed"
        )
        let interceptor = AuthenticationInterceptor(
            tokenProvider: provider,
            autoRefresh: false,
            retryOn401: true
        )

        let httpRequest = HTTPRequest.get("https://example.com/api/data")
        let urlRequest = try httpRequest.build()
        let context = RequestContext(originalRequest: httpRequest, attemptNumber: 1)

        let decision = await interceptor.retry(
            urlRequest,
            dueTo: .timeout,
            context: context
        )

        #expect(decision == .doNotRetry)
        #expect(provider.refreshCallCount == 0)
    }

    @Test("Excluded paths skip authentication")
    func excludedPathsSkipAuth() async throws {
        let provider = RefreshableTokenProvider(
            token: "token",
            expired: false
        )
        let interceptor = AuthenticationInterceptor(
            tokenProvider: provider,
            autoRefresh: false,
            excludedPaths: ["/auth/login"]
        )

        let httpRequest = HTTPRequest.get("https://example.com/auth/login")
        let urlRequest = try httpRequest.build()

        let adapted = try await interceptor.adapt(
            urlRequest,
            context: RequestContext(originalRequest: httpRequest)
        )

        #expect(adapted.value(forHTTPHeaderField: "Authorization") == nil)
    }
}
