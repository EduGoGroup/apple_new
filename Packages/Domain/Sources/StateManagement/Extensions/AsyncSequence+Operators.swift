/// Extension providing functional operators for AsyncSequence.
///
/// These operators allow composable transformation of async streams while
/// maintaining strict concurrency safety through @Sendable closures.
///
/// # Usage
/// ```swift
/// let viewModelStream = stateStream
///     .map { $0.toViewModel() }
///     .filter { !$0.isLoading }
///
/// for await viewModel in viewModelStream {
///     updateUI(viewModel)
/// }
/// ```
extension AsyncSequence where Self: Sendable, Element: Sendable {

    /// Transforms each element of the sequence using the given closure.
    ///
    /// Use `map(_:)` to convert elements from one type to another while
    /// preserving the async nature of the sequence.
    ///
    /// - Parameter transform: A sendable closure that takes an element of this sequence
    ///   and returns a transformed value.
    /// - Returns: A StateMap sequence that applies the transformation to each element.
    ///
    /// # Example
    /// ```swift
    /// let names = users.map { $0.name }
    /// ```
    public func map<Output: Sendable>(
        _ transform: @escaping @Sendable (Element) async -> Output
    ) -> StateMap<Self, Output> {
        StateMap(base: self, transform: transform)
    }

    /// Filters elements of the sequence using the given predicate.
    ///
    /// Use `filter(_:)` to include only elements that satisfy a condition.
    /// Elements that don't satisfy the predicate are skipped.
    ///
    /// - Parameter predicate: A sendable closure that takes an element and returns
    ///   true if the element should be included.
    /// - Returns: A StateFilter sequence containing only elements that satisfy the predicate.
    ///
    /// # Example
    /// ```swift
    /// let activeUsers = users.filter { $0.isActive }
    /// ```
    public func filter(
        _ predicate: @escaping @Sendable (Element) async -> Bool
    ) -> StateFilter<Self> {
        StateFilter(base: self, predicate: predicate)
    }

    /// Transforms elements by accumulating values using the given closure.
    ///
    /// Use `scan(initialState:_:)` to build up state progressively, emitting
    /// each intermediate result. This is similar to `reduce`, but emits all
    /// partial accumulated values instead of just the final result.
    ///
    /// - Parameters:
    ///   - initialState: The initial value for the accumulated state.
    ///   - accumulator: A sendable closure that combines the current accumulated value
    ///     with the next element to produce a new accumulated value.
    /// - Returns: A StateScan sequence that emits each accumulated value.
    ///
    /// # Example
    /// ```swift
    /// // Running total of scores
    /// let runningTotal = scores.scan(initialState: 0) { total, score in
    ///     total + score
    /// }
    /// ```
    public func scan<Output: Sendable>(
        initialState: Output,
        _ accumulator: @escaping @Sendable (Output, Element) async -> Output
    ) -> StateScan<Self, Output> {
        StateScan(base: self, initialState: initialState, accumulator: accumulator)
    }
}
