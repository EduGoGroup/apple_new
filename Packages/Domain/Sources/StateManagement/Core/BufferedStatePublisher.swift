/// A thread-safe actor that publishes state updates with configurable buffering.
///
/// BufferedStatePublisher extends the StatePublisher pattern with pluggable
/// buffering strategies, allowing fine-grained control over backpressure behavior.
///
/// # Single-Consumer Design
/// This publisher supports a **single consumer** only. The `stream` property
/// returns the same underlying AsyncStream on every access. If multiple callers
/// iterate the stream, each emitted element is delivered to only one of them
/// (non-deterministic). For multi-consumer scenarios, use `StatePublisher` instead,
/// which creates independent streams per subscriber.
///
/// # Buffering Strategies
/// - `UnboundedBuffer`: No limit (default, matches StatePublisher behavior)
/// - `BoundedBuffer`: Fixed capacity, suspends producer when full
/// - `DroppingBuffer`: Fixed capacity, drops oldest elements when full
///
/// # Thread Safety
/// All state mutations and emissions are actor-isolated, ensuring thread-safe
/// access from any concurrent context.
///
/// # Example
/// ```swift
/// // Create with bounded buffer for backpressure
/// let publisher = BufferedStatePublisher<UploadState>(
///     buffer: BoundedBuffer(capacity: 10)
/// )
///
/// // Producer (may suspend if buffer full)
/// await publisher.send(UploadState(progress: 0.5))
///
/// // Single consumer
/// for await state in await publisher.stream {
///     updateUI(with: state)
/// }
/// ```
public actor BufferedStatePublisher<State: AsyncState> {
    /// The current state value, if any has been emitted.
    public private(set) var currentState: State?

    /// The buffering strategy used by this publisher.
    private let buffer: any BufferingStrategy<State>

    /// The underlying continuation for emitting values to the stream.
    private var continuation: AsyncStream<State>.Continuation?

    /// The stream that subscribers can iterate over.
    private var _stream: AsyncStream<State>?

    /// Indicates whether the publisher has been terminated.
    private var isTerminated: Bool = false

    /// Task that bridges buffer to AsyncStream.
    private var bridgeTask: Task<Void, Never>?

    /// Creates a new BufferedStatePublisher with an unbounded buffer (default).
    public init() {
        self.buffer = UnboundedBuffer<State>()
    }

    /// Creates a new BufferedStatePublisher with a custom buffering strategy.
    ///
    /// - Parameter buffer: The buffering strategy to use.
    public init<B: BufferingStrategy>(buffer: B) where B.Element == State {
        self.buffer = buffer
    }

    /// The AsyncStream for subscribing to state updates.
    ///
    /// Creates the stream lazily on first access and starts the bridge task
    /// that transfers elements from the buffer to the stream.
    ///
    /// - Important: This publisher is single-consumer. Multiple accesses return
    ///   the same stream instance. If multiple callers iterate concurrently,
    ///   each element is delivered to only one consumer. Use `StatePublisher`
    ///   for multi-consumer scenarios.
    ///
    /// - Returns: A StateStream that emits State values.
    public var stream: StateStream<State> {
        if _stream == nil {
            let (stream, continuation) = AsyncStream<State>.makeStream(
                bufferingPolicy: .unbounded
            )
            self._stream = stream
            self.continuation = continuation

            // Start bridge task to transfer buffer elements to stream
            startBridgeTask()
        }
        return StateStream(sequence: _stream!)
    }

    /// Starts the background task that bridges buffer to AsyncStream.
    private func startBridgeTask() {
        bridgeTask = Task { [weak self] in
            guard let self = self else { return }

            while !Task.isCancelled {
                guard let element = await self.buffer.dequeue() else {
                    // Check if terminated
                    if await self.checkTerminated() {
                        break
                    }
                    // Small yield to avoid busy-waiting
                    try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
                    continue
                }

                await self.yieldToStream(element)
            }
        }
    }

    /// Yields an element to the stream.
    private func yieldToStream(_ element: State) {
        continuation?.yield(element)
    }

    /// Checks if the publisher is terminated.
    private func checkTerminated() -> Bool {
        isTerminated
    }

    /// Emits a new state to all subscribers.
    ///
    /// The behavior depends on the buffering strategy:
    /// - UnboundedBuffer: Always succeeds immediately
    /// - BoundedBuffer: May suspend if buffer is full
    /// - DroppingBuffer: May drop oldest element if full
    ///
    /// - Parameter state: The state to emit.
    /// - Returns: The result of the enqueue operation.
    @discardableResult
    public func send(_ state: State) async -> BufferEnqueueResult {
        guard !isTerminated else { return .terminated }

        currentState = state
        return await buffer.enqueue(state)
    }

    /// Emits a new state only if it differs from the current state.
    ///
    /// Useful for reducing redundant UI updates when states may be
    /// emitted multiple times with the same value.
    ///
    /// - Parameter state: The state to emit if different from current.
    /// - Returns: The enqueue result, or nil if deduplicated.
    @discardableResult
    public func sendIfChanged(_ state: State) async -> BufferEnqueueResult? {
        guard !isTerminated else { return .terminated }

        if let current = currentState, current == state {
            return nil
        }

        currentState = state
        return await buffer.enqueue(state)
    }

    /// Terminates the publisher, completing the stream for all subscribers.
    ///
    /// After calling finish(), no more states can be emitted. Subscribers
    /// iterating the stream will complete their iteration after consuming
    /// any buffered elements.
    ///
    /// This method is idempotent - calling it multiple times has no effect.
    public func finish() async {
        guard !isTerminated else { return }

        isTerminated = true
        await buffer.clear()
        bridgeTask?.cancel()
        bridgeTask = nil
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
    public func finish(throwing error: any Error) async {
        guard !isTerminated else { return }

        isTerminated = true
        await buffer.clear()
        bridgeTask?.cancel()
        bridgeTask = nil
        continuation?.finish()
        continuation = nil
    }

    /// The current number of elements waiting in the buffer.
    public var bufferCount: Int {
        get async {
            await buffer.count
        }
    }

    /// Whether the buffer is currently full.
    public var isBufferFull: Bool {
        get async {
            await buffer.isFull
        }
    }
}

// MARK: - Convenience Factory Methods

extension BufferedStatePublisher {
    /// Creates a BufferedStatePublisher with a bounded buffer.
    ///
    /// - Parameter capacity: Maximum buffer capacity.
    /// - Returns: A new publisher with bounded buffering.
    public static func bounded(capacity: Int) -> BufferedStatePublisher<State> {
        BufferedStatePublisher(buffer: BoundedBuffer<State>(capacity: capacity))
    }

    /// Creates a BufferedStatePublisher with a dropping buffer.
    ///
    /// - Parameter capacity: Maximum buffer capacity.
    /// - Returns: A new publisher with dropping buffering.
    public static func dropping(capacity: Int) -> BufferedStatePublisher<State> {
        BufferedStatePublisher(buffer: DroppingBuffer<State>(capacity: capacity))
    }

    /// Creates a BufferedStatePublisher with an unbounded buffer.
    ///
    /// This is equivalent to using the default initializer.
    ///
    /// - Returns: A new publisher with unbounded buffering.
    public static func unbounded() -> BufferedStatePublisher<State> {
        BufferedStatePublisher()
    }
}
