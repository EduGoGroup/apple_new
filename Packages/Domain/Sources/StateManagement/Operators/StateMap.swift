/// An AsyncSequence that transforms elements from a base sequence using a closure.
///
/// StateMap wraps any AsyncSequence and applies a transformation to each element.
/// It propagates cancellation correctly and ensures thread-safety via @Sendable closures.
///
/// # Usage
/// ```swift
/// let viewModels = stateStream.map { $0.toViewModel() }
///
/// for await viewModel in viewModels {
///     updateUI(viewModel)
/// }
/// ```
///
/// # Cancellation
/// When the consuming task is cancelled, iteration terminates at the next
/// suspension point. The underlying base sequence is also cancelled.
public struct StateMap<Base: AsyncSequence & Sendable, Output: Sendable>: AsyncSequence, Sendable
where Base.Element: Sendable {
    public typealias Element = Output

    private let base: Base
    private let transform: @Sendable (Base.Element) async -> Output

    /// Creates a StateMap sequence with a transformation closure.
    ///
    /// - Parameters:
    ///   - base: The underlying sequence to transform.
    ///   - transform: A sendable closure that transforms each element.
    public init(base: Base, transform: @escaping @Sendable (Base.Element) async -> Output) {
        self.base = base
        self.transform = transform
    }

    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(iterator: base.makeAsyncIterator(), transform: transform)
    }

    /// The iterator type for StateMap.
    public struct AsyncIterator: AsyncIteratorProtocol {
        private var iterator: Base.AsyncIterator
        private let transform: @Sendable (Base.Element) async -> Output

        internal init(
            iterator: Base.AsyncIterator,
            transform: @escaping @Sendable (Base.Element) async -> Output
        ) {
            self.iterator = iterator
            self.transform = transform
        }

        public mutating func next() async rethrows -> Output? {
            // Check for cancellation before attempting to get next element
            guard !Task.isCancelled else { return nil }

            guard let element = try await iterator.next() else {
                return nil
            }

            // Check for cancellation after getting element
            guard !Task.isCancelled else { return nil }

            return await transform(element)
        }
    }
}
