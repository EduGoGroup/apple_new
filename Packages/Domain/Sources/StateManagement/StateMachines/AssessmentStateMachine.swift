import Foundation

/// A state machine actor that manages assessment state transitions with optional persistence.
///
/// AssessmentStateMachine enforces valid state transitions for the assessment workflow
/// and optionally persists state for crash recovery. It implements automatic timeout
/// detection for assessments that exceed the time limit.
///
/// # Thread Safety
/// All operations are actor-isolated, ensuring thread-safe state management
/// from any concurrent context.
///
/// # Transition Rules
/// - `idle` → `loading` | `error`
/// - `loading` → `ready` | `error`
/// - `ready` → `inProgress(0)` | `error`
/// - `inProgress` → `inProgress(+1)` | `submitting` | `error`
/// - `submitting` → `completed(score)` | `error`
/// - `completed` → (terminal)
/// - `error` → `idle` (reset only)
///
/// # Persistence
/// When a persistence provider is configured, the state machine automatically
/// saves state changes for later recovery. Use `recoverState()` on startup
/// to resume from a previous state.
///
/// # Example
/// ```swift
/// let machine = AssessmentStateMachine(
///     assessmentId: "assessment_123",
///     persistence: UserDefaultsStatePersistence()
/// )
///
/// // Try to recover from previous state
/// if let recovered = try await machine.recoverState() {
///     print("Recovered from: \(recovered)")
/// }
///
/// // Subscribe to states
/// Task {
///     for await state in await machine.stateStream {
///         updateUI(with: state)
///     }
/// }
///
/// // Drive state transitions
/// try await machine.startLoading()
/// try await machine.transitionToReady()
/// try await machine.startAssessment(totalQuestions: 10)
/// try await machine.answerQuestion() // increments count
/// try await machine.submit()
/// try await machine.complete(score: 0.85)
/// ```
public actor AssessmentStateMachine {
    /// The unique identifier for this assessment.
    public let assessmentId: String

    /// The current state of the assessment process.
    public private(set) var currentState: AssessmentState = .idle

    /// The total number of questions in the assessment.
    private var totalQuestions: Int = 0

    /// Timestamp when inProgress state was entered (for timeout detection).
    private var inProgressStartTime: Date?

    /// Timeout duration in seconds (default 30 minutes).
    private let timeoutDuration: TimeInterval

    /// Optional persistence provider for crash recovery.
    private let persistence: (any StatePersistence)?

    /// Indicates whether the machine has been terminated.
    private var isTerminated: Bool = false

    /// The underlying continuation for emitting values to the stream.
    private var continuation: AsyncStream<AssessmentState>.Continuation?

    /// The stream that subscribers can iterate over.
    private var _stream: AsyncStream<AssessmentState>?

    /// Creates a new AssessmentStateMachine.
    ///
    /// - Parameters:
    ///   - assessmentId: Unique identifier for this assessment.
    ///   - persistence: Optional persistence provider for crash recovery.
    ///   - timeoutDuration: Timeout in seconds (default 30 minutes).
    public init(
        assessmentId: String,
        persistence: (any StatePersistence)? = nil,
        timeoutDuration: TimeInterval = 30 * 60
    ) {
        self.assessmentId = assessmentId
        self.persistence = persistence
        self.timeoutDuration = timeoutDuration
    }

    // MARK: - State Stream

    /// The stream of state updates for subscribers.
    public var stateStream: StateStream<AssessmentState> {
        if _stream == nil {
            let (stream, cont) = AsyncStream<AssessmentState>.makeStream(
                bufferingPolicy: .unbounded
            )
            self._stream = stream
            self.continuation = cont
        }
        return StateStream(sequence: _stream!)
    }

    // MARK: - State Recovery

    /// Attempts to recover state from persistence.
    ///
    /// Call this on app startup to resume from a previous state after
    /// a crash or app termination.
    ///
    /// - Returns: The recovered state if one exists, nil otherwise.
    public func recoverState() async throws -> AssessmentState? {
        guard let persistence = persistence else {
            return nil
        }

        guard let recoveredState: AssessmentState = try await persistence.load(forKey: persistenceKey) else {
            return nil
        }

        // Only recover from recoverable states
        switch recoveredState {
        case .inProgress, .ready:
            currentState = recoveredState
            if case .inProgress = recoveredState {
                inProgressStartTime = Date()
            }
            emit(currentState)
            return recoveredState
        default:
            // Don't recover from idle, loading, submitting, completed, or error
            await persistence.remove(forKey: persistenceKey)
            return nil
        }
    }

    // MARK: - State Transitions

    /// Starts loading the assessment.
    ///
    /// - Throws: `AssessmentTransitionError` if not in idle state.
    public func startLoading() async throws {
        guard case .idle = currentState else {
            throw AssessmentTransitionError(from: currentState, to: .loading)
        }
        await transitionTo(.loading)
    }

    /// Transitions from loading to ready state.
    ///
    /// - Throws: `AssessmentTransitionError` if not in loading state.
    public func transitionToReady() async throws {
        guard case .loading = currentState else {
            throw AssessmentTransitionError(from: currentState, to: .ready)
        }
        await transitionTo(.ready)
    }

    /// Starts the assessment with the given number of questions.
    ///
    /// - Parameter totalQuestions: Total number of questions in the assessment.
    /// - Throws: `AssessmentTransitionError` if not in ready state.
    public func startAssessment(totalQuestions: Int) async throws {
        guard case .ready = currentState else {
            throw AssessmentTransitionError(
                from: currentState,
                to: .inProgress(answeredCount: 0, totalQuestions: totalQuestions)
            )
        }

        self.totalQuestions = totalQuestions
        self.inProgressStartTime = Date()
        await transitionTo(.inProgress(answeredCount: 0, totalQuestions: totalQuestions))
    }

    /// Records an answered question, incrementing the count.
    ///
    /// - Throws: `AssessmentTransitionError` if not in inProgress state.
    /// - Throws: `AssessmentError.timeout` if assessment has timed out.
    public func answerQuestion() async throws {
        guard case .inProgress(let answered, let total) = currentState else {
            throw AssessmentTransitionError(
                from: currentState,
                to: .inProgress(answeredCount: 0, totalQuestions: 0)
            )
        }

        // Check for timeout
        if let startTime = inProgressStartTime,
           Date().timeIntervalSince(startTime) > timeoutDuration {
            try await transitionToError(.timeout)
            throw AssessmentError.timeout
        }

        let newCount = min(answered + 1, total)
        await transitionTo(.inProgress(answeredCount: newCount, totalQuestions: total))
    }

    /// Updates the answered count directly.
    ///
    /// - Parameter count: The new answered count.
    /// - Throws: `AssessmentTransitionError` if not in inProgress state.
    public func updateAnsweredCount(_ count: Int) async throws {
        guard case .inProgress(_, let total) = currentState else {
            throw AssessmentTransitionError(
                from: currentState,
                to: .inProgress(answeredCount: count, totalQuestions: 0)
            )
        }

        // Check for timeout
        if let startTime = inProgressStartTime,
           Date().timeIntervalSince(startTime) > timeoutDuration {
            try await transitionToError(.timeout)
            throw AssessmentError.timeout
        }

        let clampedCount = max(0, min(count, total))
        await transitionTo(.inProgress(answeredCount: clampedCount, totalQuestions: total))
    }

    /// Transitions to submitting state.
    ///
    /// - Throws: `AssessmentTransitionError` if not in inProgress state.
    public func submit() async throws {
        guard case .inProgress = currentState else {
            throw AssessmentTransitionError(from: currentState, to: .submitting)
        }
        await transitionTo(.submitting)
    }

    /// Completes the assessment with the given score.
    ///
    /// - Parameter score: The final score (0.0 to 1.0).
    /// - Throws: `AssessmentTransitionError` if not in submitting state.
    public func complete(score: Double) async throws {
        guard case .submitting = currentState else {
            throw AssessmentTransitionError(from: currentState, to: .completed(score: score))
        }

        let clampedScore = max(0.0, min(1.0, score))
        await transitionTo(.completed(score: clampedScore))

        // Clear persisted state on completion
        await clearPersistedState()

        finish()
    }

    /// Transitions to error state from any active state.
    ///
    /// - Parameter error: The error that caused the failure.
    /// - Throws: `AssessmentTransitionError` if in a terminal state.
    public func transitionToError(_ error: AssessmentError) async throws {
        switch currentState {
        case .completed:
            throw AssessmentTransitionError(from: currentState, to: .error(error))
        case .error:
            // Already in error, update with new error
            await transitionTo(.error(error))
        default:
            await transitionTo(.error(error))
        }
    }

    /// Cancels the assessment.
    ///
    /// - Throws: `AssessmentTransitionError` if in a terminal state.
    public func cancel() async throws {
        try await transitionToError(.cancelled)
    }

    /// Resets the state machine to idle for a new assessment.
    ///
    /// Can only be called from error or idle states.
    ///
    /// - Throws: `AssessmentTransitionError` if not in error or idle state.
    public func resetToIdle() async throws {
        switch currentState {
        case .idle:
            // Already idle, just emit
            emit(.idle)
        case .error:
            await clearPersistedState()
            inProgressStartTime = nil
            totalQuestions = 0
            await transitionTo(.idle)
        default:
            throw AssessmentTransitionError(from: currentState, to: .idle)
        }
    }

    /// Checks if the assessment has timed out.
    ///
    /// - Returns: true if the assessment has exceeded the timeout duration.
    public func hasTimedOut() -> Bool {
        guard case .inProgress = currentState,
              let startTime = inProgressStartTime else {
            return false
        }
        return Date().timeIntervalSince(startTime) > timeoutDuration
    }

    /// Returns the remaining time in seconds, or nil if not in progress.
    public func remainingTime() -> TimeInterval? {
        guard case .inProgress = currentState,
              let startTime = inProgressStartTime else {
            return nil
        }
        let elapsed = Date().timeIntervalSince(startTime)
        return max(0, timeoutDuration - elapsed)
    }

    // MARK: - Transition Validation

    /// Checks if a transition from one state to another is valid.
    ///
    /// - Parameters:
    ///   - from: The source state.
    ///   - to: The target state.
    /// - Returns: true if the transition is valid, false otherwise.
    public static func isValidTransition(from: AssessmentState, to: AssessmentState) -> Bool {
        switch (from, to) {
        // From idle
        case (.idle, .loading):
            return true
        case (.idle, .error):
            return true

        // From loading
        case (.loading, .ready):
            return true
        case (.loading, .error):
            return true

        // From ready
        case (.ready, .inProgress):
            return true
        case (.ready, .error):
            return true

        // From inProgress
        case (.inProgress, .inProgress):
            return true
        case (.inProgress, .submitting):
            return true
        case (.inProgress, .error):
            return true

        // From submitting
        case (.submitting, .completed):
            return true
        case (.submitting, .error):
            return true

        // From error (reset)
        case (.error, .idle):
            return true

        // All other transitions are invalid
        default:
            return false
        }
    }

    // MARK: - Private Helpers

    /// The persistence key for this assessment.
    private var persistenceKey: String {
        "assessment_\(assessmentId)"
    }

    /// Performs the actual state transition, persists, and emits.
    private func transitionTo(_ newState: AssessmentState) async {
        currentState = newState
        await persistState()
        emit(newState)
    }

    /// Persists the current state if persistence is enabled.
    private func persistState() async {
        guard let persistence = persistence else { return }

        // Only persist recoverable states
        switch currentState {
        case .inProgress, .ready:
            try? await persistence.save(currentState, forKey: persistenceKey)
        default:
            // Don't persist non-recoverable states
            break
        }
    }

    /// Clears persisted state.
    private func clearPersistedState() async {
        guard let persistence = persistence else { return }
        await persistence.remove(forKey: persistenceKey)
    }

    /// Emits a state to the stream.
    private func emit(_ state: AssessmentState) {
        guard !isTerminated else { return }
        continuation?.yield(state)
    }

    /// Terminates the stream.
    private func finish() {
        guard !isTerminated else { return }
        isTerminated = true
        continuation?.finish()
        continuation = nil
    }
}

// MARK: - Assessment Transition Error

/// Error thrown when an invalid assessment state transition is attempted.
public struct AssessmentTransitionError: Error, Equatable, Sendable {
    /// The source state of the attempted transition.
    public let from: AssessmentState

    /// The target state of the attempted transition.
    public let to: AssessmentState

    /// Creates an AssessmentTransitionError.
    ///
    /// - Parameters:
    ///   - from: The source state.
    ///   - to: The target state.
    public init(from: AssessmentState, to: AssessmentState) {
        self.from = from
        self.to = to
    }
}

extension AssessmentTransitionError: CustomStringConvertible {
    public var description: String {
        "Invalid assessment transition from \(from) to \(to)"
    }
}
