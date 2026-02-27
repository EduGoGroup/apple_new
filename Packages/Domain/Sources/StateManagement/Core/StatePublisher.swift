/// A thread-safe actor that publishes state updates to subscribers via AsyncSequence.
///
/// StatePublisher provides a reactive pattern for emitting states from use cases
/// to UI layers. It uses AsyncStream internally with unbounded buffering,
/// optimized for UI consumption patterns where states are processed quickly.
///
/// # Thread Safety
/// All state mutations and emissions are actor-isolated, ensuring thread-safe
/// access from any concurrent context.
///
/// # Backpressure Strategy
/// Uses unbounded buffering by default, suitable for UI-driven consumption
/// where new states replace outdated ones. For high-frequency emissions,
/// consider implementing state coalescing at the consumer level.
///
/// # Example
/// ```swift
/// let publisher = StatePublisher<UploadState>()
///
/// // Emit states from use case
/// await publisher.send(UploadState(progress: 0.5, status: .uploading))
///
/// // Subscribe from UI
/// for await state in await publisher.stream {
///     updateUI(with: state)
/// }
/// ```
public actor StatePublisher<State: AsyncState> {
    /// The current state value, if any has been emitted.
    public private(set) var currentState: State?

    /// The underlying continuation for emitting values to the stream.
    private var continuation: AsyncStream<State>.Continuation?

    /// The stream that subscribers can iterate over.
    private var _stream: AsyncStream<State>?

    /// Indicates whether the publisher has been terminated.
    private var isTerminated: Bool = false

    /// Creates a new StatePublisher ready to emit states.
    public init() {}

    /// The AsyncStream for subscribing to state updates.
    ///
    /// Creates the stream lazily on first access. Multiple accesses return
    /// the same stream instance.
    ///
    /// - Returns: An AsyncStream that emits State values.
    public var stream: StateStream<State> {
        if _stream == nil {
            let (stream, continuation) = AsyncStream<State>.makeStream(
                bufferingPolicy: .unbounded
            )
            self._stream = stream
            self.continuation = continuation
        }
        return StateStream(sequence: _stream!)
    }

    /// Emits a new state to all subscribers.
    ///
    /// The state is stored as currentState and emitted to the stream.
    /// If the publisher has been terminated, this method has no effect.
    ///
    /// - Parameter state: The state to emit.
    public func send(_ state: State) {
        guard !isTerminated else { return }

        currentState = state
        continuation?.yield(state)
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
        continuation?.yield(state)
        return true
    }

    /// Terminates the publisher, completing the stream for all subscribers.
    ///
    /// After calling finish(), no more states can be emitted. Subscribers
    /// iterating the stream will complete their iteration.
    ///
    /// This method is idempotent - calling it multiple times has no effect.
    public func finish() {
        guard !isTerminated else { return }

        isTerminated = true
        continuation?.finish()
        continuation = nil
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
        continuation?.finish()
        continuation = nil
    }
}
