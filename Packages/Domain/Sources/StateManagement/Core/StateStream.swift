/// A wrapper around AsyncSequence that provides type-safe state streaming.
///
/// StateStream encapsulates the underlying AsyncStream to provide a clean
/// API for consuming states. It conforms to AsyncSequence, allowing direct
/// use in for-await-in loops.
///
/// # Usage
/// ```swift
/// let stream: StateStream<UploadState> = await publisher.stream
///
/// for await state in stream {
///     print("Progress: \(state.progress)")
/// }
/// ```
///
/// # Cancellation
/// The stream respects task cancellation. When the consuming task is
/// cancelled, iteration terminates cleanly.
public struct StateStream<State: AsyncState>: AsyncSequence, Sendable {
    public typealias Element = State

    /// The underlying async sequence that emits states.
    private let sequence: AsyncStream<State>

    /// Creates a StateStream wrapping an AsyncStream.
    ///
    /// - Parameter sequence: The underlying AsyncStream to wrap.
    public init(sequence: AsyncStream<State>) {
        self.sequence = sequence
    }

    /// Creates an iterator for consuming states.
    ///
    /// - Returns: An AsyncIterator that yields State values.
    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(iterator: sequence.makeAsyncIterator())
    }

    /// The iterator type for StateStream.
    public struct AsyncIterator: AsyncIteratorProtocol {
        private var iterator: AsyncStream<State>.AsyncIterator

        internal init(iterator: AsyncStream<State>.AsyncIterator) {
            self.iterator = iterator
        }

        /// Advances to and returns the next state, or nil if finished.
        ///
        /// - Returns: The next State value, or nil if the stream is complete.
        public mutating func next() async -> State? {
            await iterator.next()
        }
    }
}

// MARK: - Convenience Extensions

extension StateStream {
    /// Creates a StateStream from an array of states (useful for testing).
    ///
    /// - Parameter states: The array of states to emit.
    /// - Returns: A StateStream that emits the provided states.
    public static func from(_ states: [State]) -> StateStream<State> {
        let stream = AsyncStream<State> { continuation in
            for state in states {
                continuation.yield(state)
            }
            continuation.finish()
        }
        return StateStream(sequence: stream)
    }

    /// Creates an empty StateStream that completes immediately.
    ///
    /// - Returns: A StateStream with no elements.
    public static func empty() -> StateStream<State> {
        let stream = AsyncStream<State> { continuation in
            continuation.finish()
        }
        return StateStream(sequence: stream)
    }

    /// Creates a StateStream that emits a single state.
    ///
    /// - Parameter state: The single state to emit.
    /// - Returns: A StateStream that emits one state then completes.
    public static func just(_ state: State) -> StateStream<State> {
        from([state])
    }
}
