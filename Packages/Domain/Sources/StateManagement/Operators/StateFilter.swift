/// An AsyncSequence that filters elements from a base sequence using a predicate.
///
/// StateFilter wraps any AsyncSequence and emits only elements that satisfy the predicate.
/// It propagates cancellation correctly and ensures thread-safety via @Sendable closures.
///
/// # Usage
/// ```swift
/// let activeStates = stateStream.filter { !$0.isLoading }
///
/// for await state in activeStates {
///     handleActiveState(state)
/// }
/// ```
///
/// # Cancellation
/// When the consuming task is cancelled, iteration terminates at the next
/// suspension point. The underlying base sequence is also cancelled.
public struct StateFilter<Base: AsyncSequence & Sendable>: AsyncSequence, Sendable
where Base.Element: Sendable {
    public typealias Element = Base.Element

    private let base: Base
    private let predicate: @Sendable (Base.Element) async -> Bool

    /// Creates a StateFilter sequence with a predicate closure.
    ///
    /// - Parameters:
    ///   - base: The underlying sequence to filter.
    ///   - predicate: A sendable closure that returns true for elements to include.
    public init(base: Base, predicate: @escaping @Sendable (Base.Element) async -> Bool) {
        self.base = base
        self.predicate = predicate
    }

    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(iterator: base.makeAsyncIterator(), predicate: predicate)
    }

    /// The iterator type for StateFilter.
    public struct AsyncIterator: AsyncIteratorProtocol {
        private var iterator: Base.AsyncIterator
        private let predicate: @Sendable (Base.Element) async -> Bool

        internal init(
            iterator: Base.AsyncIterator,
            predicate: @escaping @Sendable (Base.Element) async -> Bool
        ) {
            self.iterator = iterator
            self.predicate = predicate
        }

        public mutating func next() async rethrows -> Base.Element? {
            // Loop until we find an element that passes the predicate or the stream ends
            while !Task.isCancelled {
                guard let element = try await iterator.next() else {
                    return nil
                }

                // Check for cancellation after getting element
                guard !Task.isCancelled else { return nil }

                if await predicate(element) {
                    return element
                }
            }

            return nil
        }
    }
}
