import Foundation
import Testing
@testable import EduPersistence

// MARK: - Mock Operations for Concurrency Testing

/// Provides mock operations with configurable behavior for testing concurrency patterns.
///
/// ## Features
/// - Configurable delays to simulate network/IO latency
/// - Configurable failure rates for testing error handling
/// - Thread-safe counters for tracking concurrent execution
/// - Deterministic failures based on index for reproducible tests
///
/// ## Example Usage
/// ```swift
/// let helper = ConcurrencyTestHelpers()
///
/// // Create operations that fail 20% of the time
/// let operations = helper.makeFailingOperations(
///     count: 100,
///     failureRate: 0.2,
///     delay: .milliseconds(10)
/// )
///
/// let result = await coordinator.executeBatchCollecting(operations)
/// #expect(result.failures.count > 0)
/// ```
public actor ConcurrencyTestHelpers {

    // MARK: - Tracking Counters

    /// Number of operations started (for concurrent execution tracking)
    public private(set) var operationsStarted: Int = 0

    /// Number of operations completed successfully
    public private(set) var operationsCompleted: Int = 0

    /// Number of operations that failed
    public private(set) var operationsFailed: Int = 0

    /// Maximum concurrent operations observed
    public private(set) var maxConcurrentOperations: Int = 0

    /// Current concurrent operations count
    private var currentConcurrentOperations: Int = 0

    /// Timestamps of operation starts (for rate limiting verification)
    public private(set) var operationStartTimes: [Date] = []

    // MARK: - Initialization

    public init() {}

    // MARK: - Counter Management

    /// Resets all tracking counters
    public func resetCounters() {
        operationsStarted = 0
        operationsCompleted = 0
        operationsFailed = 0
        maxConcurrentOperations = 0
        currentConcurrentOperations = 0
        operationStartTimes = []
    }

    /// Records an operation starting
    public func recordStart() {
        operationsStarted += 1
        currentConcurrentOperations += 1
        maxConcurrentOperations = max(maxConcurrentOperations, currentConcurrentOperations)
        operationStartTimes.append(Date())
    }

    /// Records an operation completing
    public func recordCompletion(success: Bool) {
        currentConcurrentOperations -= 1
        if success {
            operationsCompleted += 1
        } else {
            operationsFailed += 1
        }
    }

    // MARK: - Metrics

    /// Calculates the current metrics snapshot
    public var metrics: ConcurrencyMetrics {
        ConcurrencyMetrics(
            started: operationsStarted,
            completed: operationsCompleted,
            failed: operationsFailed,
            maxConcurrent: maxConcurrentOperations
        )
    }

    // MARK: - Mock Operation Factories

    /// Creates operations that always succeed after a configurable delay.
    ///
    /// - Parameters:
    ///   - count: Number of operations to create
    ///   - delay: Delay before completing each operation
    ///   - value: Value to return from each operation
    /// - Returns: Array of async operations
    public func makeSuccessfulOperations<T: Sendable>(
        count: Int,
        delay: Duration = .zero,
        value: T
    ) -> [@Sendable () async throws -> T] {
        (0..<count).map { _ in
            { [weak self] in
                await self?.recordStart()
                if delay > .zero {
                    try await Task.sleep(for: delay)
                }
                await self?.recordCompletion(success: true)
                return value
            }
        }
    }

    /// Creates operations that always fail after a configurable delay.
    ///
    /// - Parameters:
    ///   - count: Number of operations to create
    ///   - delay: Delay before failing each operation
    ///   - error: Error to throw from each operation
    /// - Returns: Array of async operations that always throw
    public func makeFailingOperations<T: Sendable>(
        count: Int,
        delay: Duration = .zero,
        error: any Error = MockOperationError.intentionalFailure
    ) -> [@Sendable () async throws -> T] {
        (0..<count).map { _ in
            { [weak self] in
                await self?.recordStart()
                if delay > .zero {
                    try await Task.sleep(for: delay)
                }
                await self?.recordCompletion(success: false)
                throw error
            }
        }
    }

    /// Creates operations with a configurable failure rate.
    ///
    /// - Parameters:
    ///   - count: Number of operations to create
    ///   - failureRate: Probability of failure (0.0 - 1.0)
    ///   - delay: Delay before completing/failing each operation
    ///   - value: Value to return on success
    /// - Returns: Array of async operations with random failures
    public func makeOperationsWithFailureRate<T: Sendable>(
        count: Int,
        failureRate: Double,
        delay: Duration = .zero,
        value: T
    ) -> [@Sendable () async throws -> T] {
        (0..<count).map { index in
            { [weak self] in
                await self?.recordStart()
                if delay > .zero {
                    try await Task.sleep(for: delay)
                }
                // Use index-based deterministic "randomness" for reproducibility
                let shouldFail = Double(index % 100) / 100.0 < failureRate
                if shouldFail {
                    await self?.recordCompletion(success: false)
                    throw MockOperationError.randomFailure(index: index)
                }
                await self?.recordCompletion(success: true)
                return value
            }
        }
    }

    /// Creates operations that fail at specific indices.
    ///
    /// - Parameters:
    ///   - count: Number of operations to create
    ///   - failingIndices: Set of indices that should fail
    ///   - delay: Delay before completing/failing each operation
    ///   - value: Value to return on success
    /// - Returns: Array of async operations with deterministic failures
    public func makeOperationsWithDeterministicFailures<T: Sendable>(
        count: Int,
        failingIndices: Set<Int>,
        delay: Duration = .zero,
        value: T
    ) -> [@Sendable () async throws -> T] {
        (0..<count).map { index in
            { [weak self] in
                await self?.recordStart()
                if delay > .zero {
                    try await Task.sleep(for: delay)
                }
                if failingIndices.contains(index) {
                    await self?.recordCompletion(success: false)
                    throw MockOperationError.deterministicFailure(index: index)
                }
                await self?.recordCompletion(success: true)
                return value
            }
        }
    }

    /// Creates operations with variable delays to test timeout behavior.
    ///
    /// - Parameters:
    ///   - count: Number of operations to create
    ///   - baseDelay: Minimum delay for operations
    ///   - variableDelay: Additional random delay range
    ///   - value: Value to return on success
    /// - Returns: Array of async operations with variable timing
    public func makeOperationsWithVariableDelay<T: Sendable>(
        count: Int,
        baseDelay: Duration,
        variableDelay: Duration,
        value: T
    ) -> [@Sendable () async throws -> T] {
        (0..<count).map { index in
            { [weak self] in
                await self?.recordStart()
                // Deterministic "variable" delay based on index
                let variableMultiplier = Double(index % 10) / 10.0
                let additionalNanoseconds = Int64(
                    Double(variableDelay.components.attoseconds / 1_000_000_000) * variableMultiplier
                )
                let totalDelay = baseDelay + .nanoseconds(additionalNanoseconds)
                try await Task.sleep(for: totalDelay)
                await self?.recordCompletion(success: true)
                return value
            }
        }
    }

    /// Creates operations that simulate slow operations exceeding timeout.
    ///
    /// - Parameters:
    ///   - count: Number of operations to create
    ///   - timeout: The timeout threshold
    ///   - exceedingCount: Number of operations that should exceed timeout
    ///   - value: Value to return on success
    /// - Returns: Array of async operations with some exceeding timeout
    public func makeOperationsExceedingTimeout<T: Sendable>(
        count: Int,
        timeout: Duration,
        exceedingCount: Int,
        value: T
    ) -> [@Sendable () async throws -> T] {
        (0..<count).map { index in
            { [weak self] in
                await self?.recordStart()
                let shouldExceedTimeout = index < exceedingCount
                let delay = shouldExceedTimeout ? timeout + .seconds(1) : .milliseconds(10)
                try await Task.sleep(for: delay)
                await self?.recordCompletion(success: true)
                return value
            }
        }
    }

    /// Creates operations that check for cancellation periodically.
    ///
    /// - Parameters:
    ///   - count: Number of operations to create
    ///   - checkInterval: How often to check for cancellation
    ///   - totalDuration: Total duration of the operation
    ///   - value: Value to return on success
    /// - Returns: Array of cancellation-aware operations
    public func makeCancellationAwareOperations<T: Sendable>(
        count: Int,
        checkInterval: Duration = .milliseconds(10),
        totalDuration: Duration = .milliseconds(100),
        value: T
    ) -> [@Sendable () async throws -> T] {
        (0..<count).map { _ in
            { [weak self] in
                await self?.recordStart()
                let iterations = Int(totalDuration.components.seconds * 1000 /
                                    max(checkInterval.components.seconds * 1000, 1))
                for _ in 0..<max(iterations, 1) {
                    try Task.checkCancellation()
                    try await Task.sleep(for: checkInterval)
                }
                await self?.recordCompletion(success: true)
                return value
            }
        }
    }
}

// MARK: - Concurrency Metrics

/// Metrics collected during concurrent operation execution.
public struct ConcurrencyMetrics: Sendable, Equatable {
    public let started: Int
    public let completed: Int
    public let failed: Int
    public let maxConcurrent: Int

    public var total: Int { started }
    public var successRate: Double {
        guard started > 0 else { return 0 }
        return Double(completed) / Double(started)
    }
}

// MARK: - Mock Errors

/// Errors used in mock operations for testing.
public enum MockOperationError: Error, Sendable, Equatable {
    /// Intentional failure for testing error handling
    case intentionalFailure

    /// Random failure based on probability
    case randomFailure(index: Int)

    /// Deterministic failure at specific index
    case deterministicFailure(index: Int)

    /// Simulated network error
    case networkError(String)

    /// Simulated timeout
    case operationTimeout(duration: TimeInterval)

    /// Resource temporarily unavailable
    case resourceBusy

    /// Operation was cancelled
    case cancelled
}

extension MockOperationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .intentionalFailure:
            return "Intentional failure for testing"
        case .randomFailure(let index):
            return "Random failure at index \(index)"
        case .deterministicFailure(let index):
            return "Deterministic failure at index \(index)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .operationTimeout(let duration):
            return "Operation timed out after \(duration)s"
        case .resourceBusy:
            return "Resource is temporarily busy"
        case .cancelled:
            return "Operation was cancelled"
        }
    }
}

// MARK: - Race Condition Detection

/// Helper for detecting race conditions in concurrent code.
///
/// Uses atomic counters and timing analysis to detect potential race conditions.
public actor RaceConditionDetector {

    /// Shared state that operations will read/write to detect races
    private var sharedCounter: Int = 0

    /// History of counter values for analysis
    private var counterHistory: [(timestamp: Date, value: Int, operation: String)] = []

    /// Detected anomalies
    private var anomalies: [RaceConditionAnomaly] = []

    public init() {}

    /// Resets the detector state
    public func reset() {
        sharedCounter = 0
        counterHistory = []
        anomalies = []
    }

    /// Increments the shared counter and records the operation
    public func increment(operationID: String) -> Int {
        let oldValue = sharedCounter
        sharedCounter += 1
        let newValue = sharedCounter
        counterHistory.append((Date(), newValue, "increment:\(operationID)"))

        // Detect if increment didn't produce expected value (would indicate race)
        if newValue != oldValue + 1 {
            anomalies.append(RaceConditionAnomaly(
                type: .unexpectedValue,
                expected: oldValue + 1,
                actual: newValue,
                operation: operationID
            ))
        }
        return newValue
    }

    /// Decrements the shared counter and records the operation
    public func decrement(operationID: String) -> Int {
        let oldValue = sharedCounter
        sharedCounter -= 1
        let newValue = sharedCounter
        counterHistory.append((Date(), newValue, "decrement:\(operationID)"))

        if newValue != oldValue - 1 {
            anomalies.append(RaceConditionAnomaly(
                type: .unexpectedValue,
                expected: oldValue - 1,
                actual: newValue,
                operation: operationID
            ))
        }
        return newValue
    }

    /// Gets the current counter value
    public func getValue() -> Int {
        sharedCounter
    }

    /// Gets all detected anomalies
    public func getAnomalies() -> [RaceConditionAnomaly] {
        anomalies
    }

    /// Checks if any race conditions were detected
    public var hasRaceConditions: Bool {
        !anomalies.isEmpty
    }

    /// Creates operations that perform increment/decrement cycles for race detection
    public func makeRaceTestOperations(
        count: Int,
        delay: Duration = .zero
    ) -> [@Sendable () async throws -> Int] {
        (0..<count).map { index in
            { [weak self] in
                guard let self = self else { throw MockOperationError.cancelled }

                // Increment
                let incrementResult = await self.increment(operationID: "op-\(index)")

                if delay > .zero {
                    try await Task.sleep(for: delay)
                }

                // Decrement
                let decrementResult = await self.decrement(operationID: "op-\(index)")

                return decrementResult - incrementResult
            }
        }
    }
}

/// Represents a detected race condition anomaly
public struct RaceConditionAnomaly: Sendable, Equatable {
    public enum AnomalyType: Sendable, Equatable {
        case unexpectedValue
        case missingOperation
        case duplicateOperation
    }

    public let type: AnomalyType
    public let expected: Int
    public let actual: Int
    public let operation: String
}

// MARK: - Concurrent Write Simulator

/// Simulates concurrent writes to detect data corruption issues.
public actor ConcurrentWriteSimulator {

    /// Data store being written to concurrently
    private var dataStore: [String: String] = [:]

    /// Write history for verification
    private var writeHistory: [(key: String, value: String, timestamp: Date)] = []

    /// Detected conflicts
    private var conflicts: [WriteConflict] = []

    public init() {}

    /// Resets the simulator
    public func reset() {
        dataStore = [:]
        writeHistory = []
        conflicts = []
    }

    /// Performs a write operation
    public func write(key: String, value: String) -> WriteResult {
        let previousValue = dataStore[key]
        dataStore[key] = value
        writeHistory.append((key, value, Date()))

        if let previous = previousValue, previous != value {
            let conflict = WriteConflict(
                key: key,
                previousValue: previous,
                newValue: value,
                timestamp: Date()
            )
            conflicts.append(conflict)
            return .conflictResolved(previous: previous, current: value)
        }
        return .success
    }

    /// Reads a value from the store
    public func read(key: String) -> String? {
        dataStore[key]
    }

    /// Gets all detected conflicts
    public func getConflicts() -> [WriteConflict] {
        conflicts
    }

    /// Verifies data integrity after concurrent operations
    public func verifyIntegrity() -> IntegrityResult {
        // Each key should have a consistent final value
        var keyValues: [String: Set<String>] = [:]

        for (key, value, _) in writeHistory {
            keyValues[key, default: []].insert(value)
        }

        let multiValueKeys = keyValues.filter { $0.value.count > 1 }

        if multiValueKeys.isEmpty {
            return .consistent
        } else {
            return .inconsistent(conflicts: multiValueKeys.map { key, values in
                WriteConflict(
                    key: key,
                    previousValue: values.first ?? "",
                    newValue: values.dropFirst().first ?? "",
                    timestamp: Date()
                )
            })
        }
    }

    /// Creates operations that write to the same keys concurrently
    public func makeConcurrentWriteOperations(
        keys: [String],
        operationsPerKey: Int,
        delay: Duration = .zero
    ) -> [@Sendable () async throws -> WriteResult] {
        var operations: [@Sendable () async throws -> WriteResult] = []

        for key in keys {
            for i in 0..<operationsPerKey {
                operations.append { [weak self] in
                    guard let self = self else { throw MockOperationError.cancelled }
                    if delay > .zero {
                        try await Task.sleep(for: delay)
                    }
                    return await self.write(key: key, value: "value-\(i)-\(UUID().uuidString.prefix(4))")
                }
            }
        }

        return operations
    }
}

/// Result of a write operation
public enum WriteResult: Sendable, Equatable {
    case success
    case conflictResolved(previous: String, current: String)
}

/// Represents a write conflict
public struct WriteConflict: Sendable, Equatable {
    public let key: String
    public let previousValue: String
    public let newValue: String
    public let timestamp: Date

    public static func == (lhs: WriteConflict, rhs: WriteConflict) -> Bool {
        lhs.key == rhs.key &&
        lhs.previousValue == rhs.previousValue &&
        lhs.newValue == rhs.newValue
    }
}

/// Result of integrity verification
public enum IntegrityResult: Sendable {
    case consistent
    case inconsistent(conflicts: [WriteConflict])

    public var isConsistent: Bool {
        if case .consistent = self { return true }
        return false
    }
}

// MARK: - Assertion Helpers

/// Assertion helpers for concurrency tests
public enum ConcurrencyAssertions {

    /// Asserts that the maximum concurrent operations did not exceed the limit
    public static func assertMaxConcurrency(
        _ metrics: ConcurrencyMetrics,
        limit: Int
    ) {
        #expect(
            metrics.maxConcurrent <= limit,
            "Max concurrent operations (\(metrics.maxConcurrent)) exceeded limit (\(limit))"
        )
    }

    /// Asserts that all operations completed
    public static func assertAllCompleted(
        _ metrics: ConcurrencyMetrics
    ) {
        let total = metrics.completed + metrics.failed
        #expect(
            total == metrics.started,
            "Not all operations completed: \(total)/\(metrics.started)"
        )
    }

    /// Asserts that the success rate meets the minimum threshold
    public static func assertSuccessRate(
        _ metrics: ConcurrencyMetrics,
        minimum: Double
    ) {
        #expect(
            metrics.successRate >= minimum,
            "Success rate (\(metrics.successRate)) below minimum (\(minimum))"
        )
    }
}
