/// An AsyncSequence that accumulates values from a base sequence, emitting each partial result.
///
/// StateScan is similar to reduce, but instead of producing a single final value,
/// it emits each intermediate accumulated value. This is useful for building up
/// state progressively.
///
/// # Usage
/// ```swift
/// // Sum all values emitted so far
/// let runningTotal = numberStream.scan(0) { accumulated, next in
///     accumulated + next
/// }
///
/// for await total in runningTotal {
///     print("Running total: \(total)")
/// }
/// ```
///
/// # Cancellation
/// When the consuming task is cancelled, iteration terminates at the next
/// suspension point. The underlying base sequence is also cancelled.
public struct StateScan<Base: AsyncSequence & Sendable, Output: Sendable>: AsyncSequence, Sendable
where Base.Element: Sendable {
    public typealias Element = Output

    private let base: Base
    private let initialState: Output
    private let accumulator: @Sendable (Output, Base.Element) async -> Output

    /// Creates a StateScan sequence with an initial state and accumulator closure.
    ///
    /// - Parameters:
    ///   - base: The underlying sequence to scan.
    ///   - initialState: The initial accumulated value.
    ///   - accumulator: A sendable closure that combines the current accumulated value with the next element.
    public init(
        base: Base,
        initialState: Output,
        accumulator: @escaping @Sendable (Output, Base.Element) async -> Output
    ) {
        self.base = base
        self.initialState = initialState
        self.accumulator = accumulator
    }

    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(
            iterator: base.makeAsyncIterator(),
            currentState: initialState,
            accumulator: accumulator
        )
    }

    /// The iterator type for StateScan.
    public struct AsyncIterator: AsyncIteratorProtocol {
        private var iterator: Base.AsyncIterator
        private var currentState: Output
        private let accumulator: @Sendable (Output, Base.Element) async -> Output

        internal init(
            iterator: Base.AsyncIterator,
            currentState: Output,
            accumulator: @escaping @Sendable (Output, Base.Element) async -> Output
        ) {
            self.iterator = iterator
            self.currentState = currentState
            self.accumulator = accumulator
        }

        public mutating func next() async rethrows -> Output? {
            // Check for cancellation before attempting to get next element
            guard !Task.isCancelled else { return nil }

            guard let element = try await iterator.next() else {
                return nil
            }

            // Check for cancellation after getting element
            guard !Task.isCancelled else { return nil }

            currentState = await accumulator(currentState, element)
            return currentState
        }
    }
}
