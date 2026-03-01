import Foundation

/// A thread-safe actor that publishes state updates to multiple subscribers via AsyncSequence.
///
/// StatePublisher provides a reactive pattern for emitting states from use cases
/// to UI layers. It supports multiple concurrent subscribers — each access to
/// `stream` creates an independent AsyncStream that receives all future emissions.
///
/// # Multi-Consumer Support
/// Unlike a raw AsyncStream (which is single-consumer), StatePublisher maintains
/// a set of continuations and fans out each emitted state to all active subscribers.
/// Terminated continuations are cleaned up lazily on the next `send()`.
///
/// # Thread Safety
/// All state mutations and emissions are actor-isolated, ensuring thread-safe
/// access from any concurrent context.
///
/// # Backpressure Strategy
/// Uses unbounded buffering per subscriber, suitable for UI-driven consumption
/// where new states replace outdated ones. For high-frequency emissions with
/// backpressure control, use `BufferedStatePublisher` instead.
///
/// # Example
/// ```swift
/// let publisher = StatePublisher<UploadState>()
///
/// // Multiple subscribers can observe independently
/// Task {
///     for await state in await publisher.stream {
///         updateProgressBar(with: state)
///     }
/// }
///
/// Task {
///     for await state in await publisher.stream {
///         logState(state)
///     }
/// }
///
/// // Emit states from use case — all subscribers receive each emission
/// await publisher.send(UploadState(progress: 0.5, status: .uploading))
/// ```
public actor StatePublisher<State: AsyncState> {
    /// The current state value, if any has been emitted.
    public private(set) var currentState: State?

    /// Active continuations keyed by unique ID for multi-consumer support.
    private var continuations: [UUID: AsyncStream<State>.Continuation] = [:]

    /// Indicates whether the publisher has been terminated.
    private var isTerminated: Bool = false

    /// Creates a new StatePublisher ready to emit states.
    public init() {}

    /// Creates a new independent AsyncStream for subscribing to state updates.
    ///
    /// Each access creates a new stream that independently receives all future
    /// state emissions. Multiple consumers can subscribe simultaneously, and each
    /// will receive every emitted state.
    ///
    /// If the publisher has already been terminated, the returned stream
    /// completes immediately.
    ///
    /// - Returns: A StateStream that emits State values.
    public var stream: StateStream<State> {
        let id = UUID()
        let (stream, continuation) = AsyncStream<State>.makeStream(
            bufferingPolicy: .unbounded
        )

        if isTerminated {
            continuation.finish()
        } else {
            continuations[id] = continuation
        }

        return StateStream(sequence: stream)
    }

    /// The number of currently active subscribers.
    public var subscriberCount: Int {
        continuations.count
    }

    /// Emits a new state to all subscribers.
    ///
    /// The state is stored as currentState and emitted to every active stream.
    /// Terminated continuations are cleaned up automatically.
    /// If the publisher has been terminated, this method has no effect.
    ///
    /// - Parameter state: The state to emit.
    public func send(_ state: State) {
        guard !isTerminated else { return }

        currentState = state
        yieldToAll(state)
    }

    /// Emits a new state only if it differs from the current state.
    ///
    /// Useful for reducing redundant UI updates when states may be
    /// emitted multiple times with the same value.
    ///
    /// - Parameter state: The state to emit if different from current.
    /// - Returns: true if the state was emitted, false if deduplicated.
    @discardableResult
    public func sendIfChanged(_ state: State) -> Bool {
        guard !isTerminated else { return false }

        if let current = currentState, current == state {
            return false
        }

        currentState = state
        yieldToAll(state)
        return true
    }

    /// Terminates the publisher, completing all streams for all subscribers.
    ///
    /// After calling finish(), no more states can be emitted. All subscribers
    /// iterating their streams will complete their iteration.
    ///
    /// This method is idempotent - calling it multiple times has no effect.
    public func finish() {
        guard !isTerminated else { return }

        isTerminated = true
        for continuation in continuations.values {
            continuation.finish()
        }
        continuations.removeAll()
    }

    /// Terminates the publisher with an error.
    ///
    /// The error is not directly propagated to subscribers (AsyncStream
    /// doesn't support errors). Use this to signal abnormal termination
    /// and log the error appropriately.
    ///
    /// - Parameter error: The error that caused termination.
    public func finish(throwing error: any Error) {
        guard !isTerminated else { return }

        isTerminated = true
        for continuation in continuations.values {
            continuation.finish()
        }
        continuations.removeAll()
    }

    // MARK: - Private Helpers

    /// Yields a state to all active continuations and cleans up terminated ones.
    private func yieldToAll(_ state: State) {
        var terminatedIds: [UUID] = []
        for (id, continuation) in continuations {
            let result = continuation.yield(state)
            if case .terminated = result {
                terminatedIds.append(id)
            }
        }
        for id in terminatedIds {
            continuations.removeValue(forKey: id)
        }
    }
}
