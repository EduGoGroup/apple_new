/// Extension providing merge operators for AsyncSequence.
///
/// These operators allow combining multiple async streams into one,
/// emitting elements as they arrive from any source.
///
/// # Usage
/// ```swift
/// let merged = stream1.merge(with: stream2, stream3)
///
/// for try await element in merged {
///     handle(element)
/// }
/// ```

// MARK: - Merge Two Sequences

extension AsyncSequence where Self: Sendable, Element: Sendable {

    /// Merges this sequence with another sequence of the same element type.
    ///
    /// Elements are emitted as they arrive from either sequence.
    /// The merged sequence completes when both source sequences complete.
    ///
    /// - Parameter other: Another async sequence to merge with.
    /// - Returns: A StateMerge that emits elements from both sequences.
    ///
    /// # Example
    /// ```swift
    /// let merged = unitsStream.merge(with: materialsStream)
    /// ```
    public func merge<S: AsyncSequence & Sendable>(
        with other: S
    ) -> StateMerge<Element> where S.Element == Element {
        StateMerge<Element>.merge(self, other)
    }

    /// Merges this sequence with two other sequences of the same element type.
    ///
    /// Elements are emitted as they arrive from any sequence.
    /// The merged sequence completes when all source sequences complete.
    ///
    /// - Parameters:
    ///   - second: Second async sequence to merge.
    ///   - third: Third async sequence to merge.
    /// - Returns: A StateMerge that emits elements from all three sequences.
    ///
    /// # Example
    /// ```swift
    /// let merged = unitsStream.merge(with: materialsStream, progressStream)
    /// ```
    public func merge<S2: AsyncSequence & Sendable, S3: AsyncSequence & Sendable>(
        with second: S2,
        _ third: S3
    ) -> StateMerge<Element> where S2.Element == Element, S3.Element == Element {
        StateMerge<Element>.merge(self, second, third)
    }

    /// Merges this sequence with three other sequences of the same element type.
    ///
    /// Elements are emitted as they arrive from any sequence.
    /// The merged sequence completes when all source sequences complete.
    ///
    /// - Parameters:
    ///   - second: Second async sequence to merge.
    ///   - third: Third async sequence to merge.
    ///   - fourth: Fourth async sequence to merge.
    /// - Returns: A StateMerge that emits elements from all four sequences.
    public func merge<
        S2: AsyncSequence & Sendable,
        S3: AsyncSequence & Sendable,
        S4: AsyncSequence & Sendable
    >(
        with second: S2,
        _ third: S3,
        _ fourth: S4
    ) -> StateMerge<Element>
    where S2.Element == Element, S3.Element == Element, S4.Element == Element {
        StateMerge<Element>.merge(self, second, third, fourth)
    }
}

// MARK: - Free Functions

/// Merges two async sequences into a single sequence.
///
/// - Parameters:
///   - s1: First sequence.
///   - s2: Second sequence.
/// - Returns: A StateMerge emitting elements from both sequences.
public func merge<S1: AsyncSequence & Sendable, S2: AsyncSequence & Sendable>(
    _ s1: S1,
    _ s2: S2
) -> StateMerge<S1.Element> where S1.Element == S2.Element, S1.Element: Sendable {
    StateMerge<S1.Element>.merge(s1, s2)
}

/// Merges three async sequences into a single sequence.
///
/// - Parameters:
///   - s1: First sequence.
///   - s2: Second sequence.
///   - s3: Third sequence.
/// - Returns: A StateMerge emitting elements from all sequences.
public func merge<
    S1: AsyncSequence & Sendable,
    S2: AsyncSequence & Sendable,
    S3: AsyncSequence & Sendable
>(
    _ s1: S1,
    _ s2: S2,
    _ s3: S3
) -> StateMerge<S1.Element>
where S1.Element == S2.Element, S2.Element == S3.Element, S1.Element: Sendable {
    StateMerge<S1.Element>.merge(s1, s2, s3)
}

/// Merges four async sequences into a single sequence.
///
/// - Parameters:
///   - s1: First sequence.
///   - s2: Second sequence.
///   - s3: Third sequence.
///   - s4: Fourth sequence.
/// - Returns: A StateMerge emitting elements from all sequences.
public func merge<
    S1: AsyncSequence & Sendable,
    S2: AsyncSequence & Sendable,
    S3: AsyncSequence & Sendable,
    S4: AsyncSequence & Sendable
>(
    _ s1: S1,
    _ s2: S2,
    _ s3: S3,
    _ s4: S4
) -> StateMerge<S1.Element>
where S1.Element == S2.Element, S2.Element == S3.Element, S3.Element == S4.Element, S1.Element: Sendable {
    StateMerge<S1.Element>.merge(s1, s2, s3, s4)
}
