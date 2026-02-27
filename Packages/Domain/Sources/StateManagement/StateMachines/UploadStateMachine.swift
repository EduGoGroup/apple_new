/// A state machine actor that manages upload state transitions with validation.
///
/// UploadStateMachine enforces valid state transitions and emits states via
/// StatePublisher. It implements progress throttling to prevent UI saturation
/// during rapid progress updates.
///
/// # Thread Safety
/// All operations are actor-isolated, ensuring thread-safe state management
/// from any concurrent context.
///
/// # Transition Rules
/// - `validating` → `creating` | `error`
/// - `creating` → `uploading(0.0)` | `error`
/// - `uploading` → `uploading(higher)` | `processing` | `error`
/// - `processing` → `ready` | `error`
/// - `ready` → (terminal)
/// - `error` → `validating` (retry only)
///
/// # Example
/// ```swift
/// let machine = UploadStateMachine()
///
/// // Subscribe to states
/// Task {
///     for await state in await machine.stateStream {
///         updateUI(with: state)
///     }
/// }
///
/// // Drive state transitions
/// try await machine.startValidation()
/// try await machine.transitionToCreating()
/// try await machine.updateProgress(0.5)
/// try await machine.transitionToProcessing()
/// try await machine.transitionToReady()
/// ```
public actor UploadStateMachine {
    /// The current state of the upload process.
    public private(set) var currentState: UploadState = .validating

    /// Minimum progress increment required to emit a new state (throttling).
    private let progressThrottleThreshold: Double = 0.01

    /// Last emitted progress value for throttling comparison.
    private var lastEmittedProgress: Double = 0.0

    /// Indicates whether the machine has been terminated.
    private var isTerminated: Bool = false

    /// The underlying continuation for emitting values to the stream.
    private var continuation: AsyncStream<UploadState>.Continuation?

    /// The stream that subscribers can iterate over.
    private var _stream: AsyncStream<UploadState>?

    /// Creates a new UploadStateMachine in the validating state.
    public init() {}

    // MARK: - State Stream

    /// The stream of state updates for subscribers.
    public var stateStream: StateStream<UploadState> {
        if _stream == nil {
            let (stream, cont) = AsyncStream<UploadState>.makeStream(
                bufferingPolicy: .unbounded
            )
            self._stream = stream
            self.continuation = cont
        }
        return StateStream(sequence: _stream!)
    }

    // MARK: - State Transitions

    /// Starts the upload process by emitting the initial validating state.
    ///
    /// - Throws: `InvalidTransitionError` if not in a valid starting state.
    public func startValidation() throws {
        switch currentState {
        case .validating:
            // Already in validating, just emit
            emit(.validating)
        case .error:
            // Retry from error
            transitionTo(.validating)
        default:
            throw InvalidTransitionError(from: currentState, to: .validating)
        }
    }

    /// Transitions from validating to creating state.
    ///
    /// - Throws: `InvalidTransitionError` if not in validating state.
    public func transitionToCreating() throws {
        guard case .validating = currentState else {
            throw InvalidTransitionError(from: currentState, to: .creating)
        }
        transitionTo(.creating)
    }

    /// Transitions from creating to uploading state with initial progress.
    ///
    /// - Throws: `InvalidTransitionError` if not in creating state.
    public func startUploading() throws {
        guard case .creating = currentState else {
            throw InvalidTransitionError(from: currentState, to: .uploading(progress: 0.0))
        }
        lastEmittedProgress = 0.0
        transitionTo(.uploading(progress: 0.0))
    }

    /// Updates the upload progress.
    ///
    /// Progress updates are throttled to prevent UI saturation. Only updates
    /// that exceed the threshold from the last emitted progress are emitted.
    /// Progress decrements are ignored (S3 can report non-linear progress).
    ///
    /// - Parameter progress: The new progress value (0.0 to 1.0).
    /// - Throws: `InvalidTransitionError` if not in uploading state.
    public func updateProgress(_ progress: Double) throws {
        guard case .uploading = currentState else {
            throw InvalidTransitionError(from: currentState, to: .uploading(progress: progress))
        }

        // Clamp progress to valid range
        let clampedProgress = max(0.0, min(1.0, progress))

        // Ignore progress decrements (S3 can report non-linear progress)
        guard clampedProgress >= lastEmittedProgress else {
            return
        }

        // Apply throttling: only emit if progress changed significantly
        let progressDelta = clampedProgress - lastEmittedProgress
        guard progressDelta >= progressThrottleThreshold || clampedProgress >= 1.0 else {
            // Update internal state without emitting
            currentState = .uploading(progress: clampedProgress)
            return
        }

        lastEmittedProgress = clampedProgress
        transitionTo(.uploading(progress: clampedProgress))
    }

    /// Transitions from uploading to processing state.
    ///
    /// - Throws: `InvalidTransitionError` if not in uploading state.
    public func transitionToProcessing() throws {
        guard case .uploading = currentState else {
            throw InvalidTransitionError(from: currentState, to: .processing)
        }
        transitionTo(.processing)
    }

    /// Transitions from processing to ready state.
    ///
    /// - Throws: `InvalidTransitionError` if not in processing state.
    public func transitionToReady() throws {
        guard case .processing = currentState else {
            throw InvalidTransitionError(from: currentState, to: .ready)
        }
        transitionTo(.ready)
        finish()
    }

    /// Transitions to error state from any active state.
    ///
    /// Error transitions are always allowed from any non-terminal state.
    ///
    /// - Parameter error: The error that caused the failure.
    /// - Throws: `InvalidTransitionError` if already in a terminal state.
    public func transitionToError(_ error: UploadError) throws {
        switch currentState {
        case .ready:
            throw InvalidTransitionError(from: currentState, to: .error(error))
        case .error:
            // Already in error, update with new error
            transitionTo(.error(error))
        default:
            transitionTo(.error(error))
        }
    }

    /// Handles cancellation by transitioning to error state with cancelled error.
    ///
    /// - Throws: `InvalidTransitionError` if already in a terminal state.
    public func cancel() throws {
        try transitionToError(.cancelled)
    }

    // MARK: - Transition Validation

    /// Checks if a transition from one state to another is valid.
    ///
    /// Useful for debugging and testing state machine logic.
    ///
    /// - Parameters:
    ///   - from: The source state.
    ///   - to: The target state.
    /// - Returns: true if the transition is valid, false otherwise.
    public static func isValidTransition(from: UploadState, to: UploadState) -> Bool {
        switch (from, to) {
        // From validating
        case (.validating, .creating):
            return true
        case (.validating, .error):
            return true

        // From creating
        case (.creating, .uploading):
            return true
        case (.creating, .error):
            return true

        // From uploading
        case (.uploading, .uploading):
            return true
        case (.uploading, .processing):
            return true
        case (.uploading, .error):
            return true

        // From processing
        case (.processing, .ready):
            return true
        case (.processing, .error):
            return true

        // From error (retry)
        case (.error, .validating):
            return true

        // All other transitions are invalid
        default:
            return false
        }
    }

    // MARK: - Private Helpers

    /// Performs the actual state transition and emits the new state.
    private func transitionTo(_ newState: UploadState) {
        currentState = newState
        emit(newState)
    }

    /// Emits a state to the stream.
    private func emit(_ state: UploadState) {
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

// MARK: - Invalid Transition Error

/// Error thrown when an invalid state transition is attempted.
public struct InvalidTransitionError: Error, Equatable, Sendable {
    /// The source state of the attempted transition.
    public let from: UploadState

    /// The target state of the attempted transition.
    public let to: UploadState

    /// Creates an InvalidTransitionError.
    ///
    /// - Parameters:
    ///   - from: The source state.
    ///   - to: The target state.
    public init(from: UploadState, to: UploadState) {
        self.from = from
        self.to = to
    }
}

extension InvalidTransitionError: CustomStringConvertible {
    public var description: String {
        "Invalid transition from \(from) to \(to)"
    }
}
