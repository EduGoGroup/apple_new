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
