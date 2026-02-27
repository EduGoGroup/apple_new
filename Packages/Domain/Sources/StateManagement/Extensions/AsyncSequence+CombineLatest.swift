/// Extension providing combineLatest operators for AsyncSequence.
///
/// These operators combine the latest values from multiple async streams,
/// emitting a tuple whenever any source emits a new value (after all have emitted at least once).
///
/// # Usage
/// ```swift
/// let combined = userStream.combineLatest(with: unitsStream, materialsStream)
///
/// for try await (user, units, materials) in combined {
///     updateDashboard(user: user, units: units, materials: materials)
/// }
/// ```

extension AsyncSequence where Self: Sendable, Element: Sendable {

    /// Combines the latest value from this sequence with another sequence.
    ///
    /// Waits until both sequences have emitted at least once, then emits a tuple
    /// with the latest value from each whenever either emits a new value.
    ///
    /// - Parameters:
    ///   - other: Another async sequence to combine with.
    ///   - policy: Completion policy (default: .all).
    /// - Returns: A StateCombineLatest2 that emits tuples of the latest values.
    ///
    /// # Example
    /// ```swift
    /// let combined = userStream.combineLatest(with: settingsStream)
    ///
    /// for try await (user, settings) in combined {
    ///     updateUI(user: user, settings: settings)
    /// }
    /// ```
    public func combineLatest<S: AsyncSequence & Sendable>(
        with other: S,
        policy: CombineLatestCompletionPolicy = .all
    ) -> StateCombineLatest2<Element, S.Element> where S.Element: Sendable {
        StateCombineLatest2(self, other, policy: policy)
    }

    /// Combines the latest value from this sequence with two other sequences.
    ///
    /// Waits until all three sequences have emitted at least once, then emits a tuple
    /// with the latest value from each whenever any emits a new value.
    ///
    /// - Parameters:
    ///   - second: Second async sequence to combine.
    ///   - third: Third async sequence to combine.
    ///   - policy: Completion policy (default: .all).
    /// - Returns: A StateCombineLatest3 that emits tuples of the latest values.
    ///
    /// # Example
    /// ```swift
    /// let combined = userStream.combineLatest(with: unitsStream, materialsStream)
    ///
    /// for try await (user, units, materials) in combined {
    ///     renderDashboard(user, units, materials)
    /// }
    /// ```
    public func combineLatest<
        S2: AsyncSequence & Sendable,
        S3: AsyncSequence & Sendable
    >(
        with second: S2,
        _ third: S3,
        policy: CombineLatestCompletionPolicy = .all
    ) -> StateCombineLatest3<Element, S2.Element, S3.Element>
    where S2.Element: Sendable, S3.Element: Sendable {
        StateCombineLatest3(self, second, third, policy: policy)
    }
}
