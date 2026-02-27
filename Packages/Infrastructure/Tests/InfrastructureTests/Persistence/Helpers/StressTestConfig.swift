import Foundation

// MARK: - Stress Test Configuration

/// Configuration for stress tests with different intensity levels.
///
/// Provides predefined configurations for various stress testing scenarios,
/// from quick smoke tests to full enterprise-grade stress tests.
///
/// ## Example Usage
/// ```swift
/// let config = StressTestConfig.enterprise
/// for _ in 0..<config.operationCount {
///     // Execute stress test operations
/// }
/// #expect(elapsed < config.maxDuration)
/// ```
public struct StressTestConfig: Sendable {

    // MARK: - Properties

    /// Number of concurrent operations to execute
    public let operationCount: Int

    /// Maximum allowed duration for the test
    public let maxDuration: Duration

    /// Maximum concurrent operations allowed (for rate limiting tests)
    public let maxConcurrency: Int

    /// Timeout for individual operations
    public let operationTimeout: Duration

    /// Whether to use strict validation (fail on any error vs partial success)
    public let strictMode: Bool

    /// Failure rate threshold (percentage of allowed failures)
    public let allowedFailureRate: Double

    /// Description for logging/reporting
    public let description: String

    // MARK: - Initialization

    public init(
        operationCount: Int,
        maxDuration: Duration,
        maxConcurrency: Int = .max,
        operationTimeout: Duration = .seconds(30),
        strictMode: Bool = false,
        allowedFailureRate: Double = 0.0,
        description: String = "Custom stress test"
    ) {
        self.operationCount = operationCount
        self.maxDuration = maxDuration
        self.maxConcurrency = maxConcurrency
        self.operationTimeout = operationTimeout
        self.strictMode = strictMode
        self.allowedFailureRate = allowedFailureRate
        self.description = description
    }

    // MARK: - Predefined Configurations

    /// Quick smoke test - 100 operations, 5 second limit
    ///
    /// Use for rapid validation during development
    public static let smoke = StressTestConfig(
        operationCount: 100,
        maxDuration: .seconds(5),
        maxConcurrency: 50,
        operationTimeout: .seconds(2),
        strictMode: true,
        allowedFailureRate: 0.0,
        description: "Smoke test - 100 ops, 5s max"
    )

    /// Light stress test - 500 operations, 15 second limit
    ///
    /// Use for regular CI/CD pipelines
    public static let light = StressTestConfig(
        operationCount: 500,
        maxDuration: .seconds(15),
        maxConcurrency: 100,
        operationTimeout: .seconds(5),
        strictMode: true,
        allowedFailureRate: 0.0,
        description: "Light stress - 500 ops, 15s max"
    )

    /// Medium stress test - 1000 operations, 30 second limit
    ///
    /// Use for nightly builds or pre-release testing
    public static let medium = StressTestConfig(
        operationCount: 1000,
        maxDuration: .seconds(30),
        maxConcurrency: 200,
        operationTimeout: .seconds(10),
        strictMode: true,
        allowedFailureRate: 0.0,
        description: "Medium stress - 1000 ops, 30s max"
    )

    /// Heavy stress test - 5000 operations, 60 second limit
    ///
    /// Use for release candidate testing
    public static let heavy = StressTestConfig(
        operationCount: 5000,
        maxDuration: .seconds(60),
        maxConcurrency: 500,
        operationTimeout: .seconds(15),
        strictMode: false,
        allowedFailureRate: 0.01,
        description: "Heavy stress - 5000 ops, 60s max"
    )

    /// Enterprise stress test - 10000 operations, 120 second limit
    ///
    /// Full enterprise-grade stress test for production readiness
    public static let enterprise = StressTestConfig(
        operationCount: 10000,
        maxDuration: .seconds(120),
        maxConcurrency: 1000,
        operationTimeout: .seconds(30),
        strictMode: false,
        allowedFailureRate: 0.001,
        description: "Enterprise stress - 10000 ops, 120s max"
    )

    // MARK: - Specialized Configurations

    /// Configuration for timeout testing
    public static let timeoutTest = StressTestConfig(
        operationCount: 100,
        maxDuration: .seconds(30),
        maxConcurrency: 20,
        operationTimeout: .seconds(1),
        strictMode: false,
        allowedFailureRate: 0.5,
        description: "Timeout test - 100 ops, 1s timeout"
    )

    /// Configuration for cancellation testing
    public static let cancellationTest = StressTestConfig(
        operationCount: 200,
        maxDuration: .seconds(10),
        maxConcurrency: 50,
        operationTimeout: .seconds(5),
        strictMode: false,
        allowedFailureRate: 1.0,
        description: "Cancellation test - 200 ops"
    )

    /// Configuration for rate limiting verification
    public static let rateLimitTest = StressTestConfig(
        operationCount: 500,
        maxDuration: .seconds(30),
        maxConcurrency: 10,
        operationTimeout: .seconds(5),
        strictMode: true,
        allowedFailureRate: 0.0,
        description: "Rate limit test - 500 ops, max 10 concurrent"
    )

    /// Configuration for partial failure scenarios
    public static let partialFailureTest = StressTestConfig(
        operationCount: 100,
        maxDuration: .seconds(10),
        maxConcurrency: 50,
        operationTimeout: .seconds(2),
        strictMode: false,
        allowedFailureRate: 0.3,
        description: "Partial failure test - 30% failure rate allowed"
    )

    /// Configuration for race condition detection
    public static let raceConditionTest = StressTestConfig(
        operationCount: 1000,
        maxDuration: .seconds(10),
        maxConcurrency: .max,
        operationTimeout: .seconds(1),
        strictMode: true,
        allowedFailureRate: 0.0,
        description: "Race condition test - 1000 concurrent ops"
    )

    // MARK: - Batch Size Configurations

    /// Configuration for testing different batch sizes
    public static func batchSizeTest(size: BatchSize) -> StressTestConfig {
        switch size {
        case .small:
            return StressTestConfig(
                operationCount: 50,
                maxDuration: .seconds(5),
                description: "Batch size test - small (50)"
            )
        case .medium:
            return StressTestConfig(
                operationCount: 200,
                maxDuration: .seconds(15),
                description: "Batch size test - medium (200)"
            )
        case .large:
            return StressTestConfig(
                operationCount: 500,
                maxDuration: .seconds(30),
                description: "Batch size test - large (500)"
            )
        case .xlarge:
            return StressTestConfig(
                operationCount: 1000,
                maxDuration: .seconds(60),
                description: "Batch size test - xlarge (1000)"
            )
        }
    }

    /// Batch size categories
    public enum BatchSize: Sendable {
        case small
        case medium
        case large
        case xlarge
    }

    // MARK: - Factory Methods

    /// Creates a configuration scaled from base by a factor
    public func scaled(by factor: Double) -> StressTestConfig {
        StressTestConfig(
            operationCount: Int(Double(operationCount) * factor),
            maxDuration: .seconds(Int64(Double(maxDuration.components.seconds) * factor)),
            maxConcurrency: Int(Double(maxConcurrency) * factor),
            operationTimeout: operationTimeout,
            strictMode: strictMode,
            allowedFailureRate: allowedFailureRate,
            description: "\(description) (scaled \(factor)x)"
        )
    }

    /// Creates a configuration with modified concurrency limit
    public func withMaxConcurrency(_ limit: Int) -> StressTestConfig {
        StressTestConfig(
            operationCount: operationCount,
            maxDuration: maxDuration,
            maxConcurrency: limit,
            operationTimeout: operationTimeout,
            strictMode: strictMode,
            allowedFailureRate: allowedFailureRate,
            description: "\(description) (max concurrency: \(limit))"
        )
    }

    /// Creates a configuration with modified timeout
    public func withTimeout(_ timeout: Duration) -> StressTestConfig {
        StressTestConfig(
            operationCount: operationCount,
            maxDuration: maxDuration,
            maxConcurrency: maxConcurrency,
            operationTimeout: timeout,
            strictMode: strictMode,
            allowedFailureRate: allowedFailureRate,
            description: "\(description) (timeout: \(timeout))"
        )
    }

    /// Creates a strict mode version of this configuration
    public func strict() -> StressTestConfig {
        StressTestConfig(
            operationCount: operationCount,
            maxDuration: maxDuration,
            maxConcurrency: maxConcurrency,
            operationTimeout: operationTimeout,
            strictMode: true,
            allowedFailureRate: 0.0,
            description: "\(description) (strict)"
        )
    }
}

// MARK: - Stress Test Result

/// Result of a stress test execution
public struct StressTestResult: Sendable {

    /// Total operations executed
    public let totalOperations: Int

    /// Successful operations
    public let successCount: Int

    /// Failed operations
    public let failureCount: Int

    /// Total duration of the test
    public let duration: Duration

    /// Maximum concurrent operations observed
    public let maxConcurrentObserved: Int

    /// Individual operation durations (sample)
    public let operationDurations: [Duration]

    /// Errors encountered (sample)
    public let errors: [String]

    /// Configuration used for the test
    public let config: StressTestConfig

    // MARK: - Computed Properties

    /// Success rate (0.0 - 1.0)
    public var successRate: Double {
        guard totalOperations > 0 else { return 0 }
        return Double(successCount) / Double(totalOperations)
    }

    /// Failure rate (0.0 - 1.0)
    public var failureRate: Double {
        1.0 - successRate
    }

    /// Operations per second throughput
    public var throughput: Double {
        let seconds = Double(duration.components.seconds) +
            Double(duration.components.attoseconds) / 1_000_000_000_000_000_000
        guard seconds > 0 else { return 0 }
        return Double(totalOperations) / seconds
    }

    /// Average operation duration
    public var averageOperationDuration: Duration? {
        guard !operationDurations.isEmpty else { return nil }
        let totalNanoseconds = operationDurations.reduce(0) { sum, duration in
            sum + duration.components.seconds * 1_000_000_000 +
            duration.components.attoseconds / 1_000_000_000
        }
        return .nanoseconds(totalNanoseconds / Int64(operationDurations.count))
    }

    /// Whether the test passed based on configuration
    public var passed: Bool {
        // Check duration
        guard duration <= config.maxDuration else { return false }

        // Check failure rate
        guard failureRate <= config.allowedFailureRate else { return false }

        // Check strict mode
        if config.strictMode && failureCount > 0 {
            return false
        }

        // Check concurrency limit
        if maxConcurrentObserved > config.maxConcurrency {
            return false
        }

        return true
    }

    /// Summary description
    public var summary: String {
        """
        Stress Test Result: \(passed ? "PASSED" : "FAILED")
        - Config: \(config.description)
        - Duration: \(duration) (limit: \(config.maxDuration))
        - Success Rate: \(String(format: "%.2f%%", successRate * 100)) (\(successCount)/\(totalOperations))
        - Throughput: \(String(format: "%.1f", throughput)) ops/sec
        - Max Concurrent: \(maxConcurrentObserved) (limit: \(config.maxConcurrency))
        """
    }

    // MARK: - Factory

    public init(
        totalOperations: Int,
        successCount: Int,
        failureCount: Int,
        duration: Duration,
        maxConcurrentObserved: Int,
        operationDurations: [Duration] = [],
        errors: [String] = [],
        config: StressTestConfig
    ) {
        self.totalOperations = totalOperations
        self.successCount = successCount
        self.failureCount = failureCount
        self.duration = duration
        self.maxConcurrentObserved = maxConcurrentObserved
        self.operationDurations = operationDurations
        self.errors = errors
        self.config = config
    }
}

// MARK: - Stress Test Runner

/// Runs stress tests with a given configuration
public actor StressTestRunner {

    private var currentConcurrent: Int = 0
    private var maxConcurrentObserved: Int = 0
    private var operationDurations: [Duration] = []
    private var errors: [String] = []

    public init() {}

    /// Records an operation starting
    public func recordStart() {
        currentConcurrent += 1
        maxConcurrentObserved = max(maxConcurrentObserved, currentConcurrent)
    }

    /// Records an operation completing
    public func recordEnd(duration: Duration, error: (any Error)? = nil) {
        currentConcurrent -= 1
        operationDurations.append(duration)
        if let error = error {
            errors.append(String(describing: error))
        }
    }

    /// Gets the current maximum concurrent observed
    public func getMaxConcurrent() -> Int {
        maxConcurrentObserved
    }

    /// Gets sampled operation durations
    public func getOperationDurations() -> [Duration] {
        // Return sample of durations to avoid memory issues
        if operationDurations.count <= 100 {
            return operationDurations
        }
        let stride = operationDurations.count / 100
        return (0..<100).map { operationDurations[$0 * stride] }
    }

    /// Gets sampled errors
    public func getErrors() -> [String] {
        Array(errors.prefix(50))
    }

    /// Resets the runner state
    public func reset() {
        currentConcurrent = 0
        maxConcurrentObserved = 0
        operationDurations = []
        errors = []
    }
}

// MARK: - Environment-Based Configuration

extension StressTestConfig {

    /// Returns appropriate configuration based on CI/environment
    ///
    /// Checks environment variables to determine the appropriate
    /// stress test intensity level.
    public static var forCurrentEnvironment: StressTestConfig {
        if ProcessInfo.processInfo.environment["CI"] != nil {
            // Running in CI - use medium intensity
            return .medium
        }

        if ProcessInfo.processInfo.environment["STRESS_TEST_LEVEL"] == "full" {
            return .enterprise
        }

        if ProcessInfo.processInfo.environment["STRESS_TEST_LEVEL"] == "heavy" {
            return .heavy
        }

        // Default for local development - use light
        return .light
    }

    /// Configuration for unit tests (fast, reliable)
    public static var forUnitTests: StressTestConfig {
        .smoke
    }

    /// Configuration for integration tests
    public static var forIntegrationTests: StressTestConfig {
        .medium
    }

    /// Configuration for performance benchmarks
    public static var forBenchmarks: StressTestConfig {
        .heavy
    }
}
