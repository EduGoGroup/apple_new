import Testing
import Foundation
@testable import EduNetwork

@Suite("CircuitBreaker Tests")
struct CircuitBreakerTests {
    struct TestError: Error {}

    @Test("Starts in closed state")
    func testInitialState() async {
        let cb = CircuitBreaker(config: .default)
        let state = await cb.currentState
        #expect(state == .closed)
    }

    @Test("Transitions from closed to open after failure threshold")
    func testClosedToOpen() async throws {
        let config = CircuitBreakerConfig(failureThreshold: 3, resetTimeout: 30)
        let cb = CircuitBreaker(config: config)

        for _ in 0..<3 {
            do {
                let _: Int = try await cb.execute {
                    throw TestError()
                }
            } catch is TestError {}
        }

        let state = await cb.currentState
        #expect(state == .open)
    }

    @Test("Rejects requests when open")
    func testRejectsWhenOpen() async throws {
        let config = CircuitBreakerConfig(failureThreshold: 1, resetTimeout: 60)
        let cb = CircuitBreaker(config: config)

        // Trip the breaker
        do {
            let _: Int = try await cb.execute { throw TestError() }
        } catch is TestError {}

        // Next call should be rejected
        do {
            let _: Int = try await cb.execute { return 42 }
            Issue.record("Expected CircuitBreakerOpenError")
        } catch is CircuitBreakerOpenError {
            // Expected
        }
    }

    @Test("Transitions from open to halfOpen after timeout")
    func testOpenToHalfOpen() async throws {
        let config = CircuitBreakerConfig(failureThreshold: 1, resetTimeout: 0.1)
        let cb = CircuitBreaker(config: config)

        // Trip the breaker
        do {
            let _: Int = try await cb.execute { throw TestError() }
        } catch is TestError {}

        #expect(await cb.currentState == .open)

        // Wait for reset timeout
        try await Task.sleep(for: .milliseconds(150))

        // Should allow a probe request (transitions to halfOpen)
        let result: Int = try await cb.execute { return 42 }
        #expect(result == 42)
        #expect(await cb.currentState == .closed)
    }

    @Test("Transitions from halfOpen to open on failure")
    func testHalfOpenToOpen() async throws {
        let config = CircuitBreakerConfig(failureThreshold: 1, resetTimeout: 0.1)
        let cb = CircuitBreaker(config: config)

        // Trip the breaker
        do {
            let _: Int = try await cb.execute { throw TestError() }
        } catch is TestError {}

        // Wait for reset timeout
        try await Task.sleep(for: .milliseconds(150))

        // Fail in half-open state
        do {
            let _: Int = try await cb.execute { throw TestError() }
        } catch is TestError {}

        #expect(await cb.currentState == .open)
    }

    @Test("Transitions from halfOpen to closed on success")
    func testHalfOpenToClosed() async throws {
        let config = CircuitBreakerConfig(failureThreshold: 1, resetTimeout: 0.1)
        let cb = CircuitBreaker(config: config)

        // Trip the breaker
        do {
            let _: Int = try await cb.execute { throw TestError() }
        } catch is TestError {}

        // Wait for reset timeout
        try await Task.sleep(for: .milliseconds(150))

        // Succeed in half-open state
        let result: Int = try await cb.execute { return 99 }
        #expect(result == 99)
        #expect(await cb.currentState == .closed)
    }

    @Test("Reset restores closed state")
    func testReset() async throws {
        let config = CircuitBreakerConfig(failureThreshold: 1, resetTimeout: 60)
        let cb = CircuitBreaker(config: config)

        // Trip the breaker
        do {
            let _: Int = try await cb.execute { throw TestError() }
        } catch is TestError {}

        #expect(await cb.currentState == .open)

        await cb.reset()

        #expect(await cb.currentState == .closed)

        // Should work again
        let result: Int = try await cb.execute { return 42 }
        #expect(result == 42)
    }
}

@Suite("RateLimiter Tests")
struct RateLimiterTests {
    @Test("Allows requests within limit")
    func testAllowsWithinLimit() async throws {
        let config = RateLimiterConfig(maxRequests: 5, windowDuration: 60)
        let limiter = RateLimiter(config: config)

        for _ in 0..<5 {
            try await limiter.acquire()
        }

        // All 5 should have been allowed without error
        let available = await limiter.availableRequests
        #expect(available == 0)
    }

    @Test("tryAcquire returns true within limit")
    func testTryAcquireWithinLimit() async {
        let config = RateLimiterConfig(maxRequests: 3, windowDuration: 60)
        let limiter = RateLimiter(config: config)

        let first = await limiter.tryAcquire()
        let second = await limiter.tryAcquire()
        let third = await limiter.tryAcquire()

        #expect(first == true)
        #expect(second == true)
        #expect(third == true)
    }

    @Test("tryAcquire returns false when at capacity")
    func testTryAcquireAtCapacity() async {
        let config = RateLimiterConfig(maxRequests: 2, windowDuration: 60)
        let limiter = RateLimiter(config: config)

        _ = await limiter.tryAcquire()
        _ = await limiter.tryAcquire()
        let result = await limiter.tryAcquire()

        #expect(result == false)
    }

    @Test("availableRequests reflects current capacity")
    func testAvailableRequests() async {
        let config = RateLimiterConfig(maxRequests: 5, windowDuration: 60)
        let limiter = RateLimiter(config: config)

        #expect(await limiter.availableRequests == 5)

        _ = await limiter.tryAcquire()
        _ = await limiter.tryAcquire()

        #expect(await limiter.availableRequests == 3)
    }

    @Test("Expired timestamps are cleaned up")
    func testTimestampCleanup() async throws {
        let config = RateLimiterConfig(maxRequests: 2, windowDuration: 0.1)
        let limiter = RateLimiter(config: config)

        _ = await limiter.tryAcquire()
        _ = await limiter.tryAcquire()
        #expect(await limiter.tryAcquire() == false)

        // Wait for window to expire
        try await Task.sleep(for: .milliseconds(150))

        // Should be able to acquire again
        let result = await limiter.tryAcquire()
        #expect(result == true)
    }
}
