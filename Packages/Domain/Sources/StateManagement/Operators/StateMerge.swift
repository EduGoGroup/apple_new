/// An AsyncSequence that merges multiple source sequences into a single stream.
///
/// StateMerge combines elements from multiple AsyncSequences, emitting each element
/// as soon as it arrives from any source. This is useful for combining parallel
/// operations like concurrent API calls.
///
/// # Usage
/// ```swift
/// let merged = StateMerge.merge(
///     stream1.map { .units($0) },
///     stream2.map { .materials($0) },
///     stream3.map { .progress($0) }
/// )
///
/// for try await event in merged {
///     handleEvent(event)
/// }
/// ```
///
/// # Completion Behavior
/// - The merged stream completes only when ALL source streams complete
/// - If any source stream throws an error, the merge cancels all others and propagates the error
///
/// # Cancellation
/// When the consuming task is cancelled, all source streams are cancelled.
public struct StateMerge<Element: Sendable>: AsyncSequence, Sendable {
    public typealias AsyncIterator = Iterator

    private let sources: [AnyAsyncSequence<Element>]

    /// Creates a StateMerge from an array of type-erased async sequences.
    ///
    /// - Parameter sequences: Array of type-erased sequences to merge.
    public init(sequences: [AnyAsyncSequence<Element>]) {
        self.sources = sequences
    }

    public func makeAsyncIterator() -> Iterator {
        Iterator(sources: sources)
    }

    /// The iterator type for StateMerge.
    public struct Iterator: AsyncIteratorProtocol {
        private var iterator: AsyncThrowingStream<Element, any Error>.AsyncIterator
        private let task: Task<Void, Never>

        init(sources: [AnyAsyncSequence<Element>]) {
            let (stream, continuation) = AsyncThrowingStream<Element, any Error>.makeStream()
            self.iterator = stream.makeAsyncIterator()

            // Start consuming all sources concurrently
            self.task = Task {
                await withTaskGroup(of: Void.self) { group in
                    for source in sources {
                        group.addTask {
                            do {
                                for try await element in source {
                                    guard !Task.isCancelled else { return }
                                    continuation.yield(element)
                                }
                            } catch {
                                continuation.finish(throwing: error)
                            }
                        }
                    }

                    // Wait for all to complete
                    await group.waitForAll()

                    // Only finish if not already finished by error
                    if !Task.isCancelled {
                        continuation.finish()
                    }
                }
            }
        }

        public mutating func next() async throws -> Element? {
            guard !Task.isCancelled else {
                task.cancel()
                return nil
            }

            do {
                return try await iterator.next()
            } catch {
                task.cancel()
                throw error
            }
        }
    }
}

// MARK: - Type Erasure

/// A type-erased AsyncSequence wrapper.
///
/// Use this to store heterogeneous async sequences with the same element type.
public struct AnyAsyncSequence<Element: Sendable>: AsyncSequence, Sendable {
    public typealias AsyncIterator = AnyAsyncIterator

    private let makeIteratorClosure: @Sendable () -> AnyAsyncIterator

    /// Creates a type-erased async sequence.
    ///
    /// - Parameter sequence: The concrete async sequence to wrap.
    public init<S: AsyncSequence & Sendable>(_ sequence: S) where S.Element == Element {
        self.makeIteratorClosure = {
            AnyAsyncIterator(sequence.makeAsyncIterator())
        }
    }

    public func makeAsyncIterator() -> AnyAsyncIterator {
        makeIteratorClosure()
    }

    /// A type-erased AsyncIterator.
    public struct AnyAsyncIterator: AsyncIteratorProtocol {
        private var nextClosure: () async throws -> Element?

        init<I: AsyncIteratorProtocol>(_ iterator: I) where I.Element == Element {
            var mutableIterator = iterator
            self.nextClosure = {
                try await mutableIterator.next()
            }
        }

        public mutating func next() async throws -> Element? {
            try await nextClosure()
        }
    }
}

// MARK: - Convenience Factory Methods

extension StateMerge {
    /// Creates a StateMerge from two async sequences.
    ///
    /// - Parameters:
    ///   - s1: First sequence.
    ///   - s2: Second sequence.
    /// - Returns: A merged sequence emitting elements from both sources.
    public static func merge<S1: AsyncSequence & Sendable, S2: AsyncSequence & Sendable>(
        _ s1: S1,
        _ s2: S2
    ) -> StateMerge<Element>
    where S1.Element == Element, S2.Element == Element {
        StateMerge(sequences: [AnyAsyncSequence(s1), AnyAsyncSequence(s2)])
    }

    /// Creates a StateMerge from three async sequences.
    ///
    /// - Parameters:
    ///   - s1: First sequence.
    ///   - s2: Second sequence.
    ///   - s3: Third sequence.
    /// - Returns: A merged sequence emitting elements from all sources.
    public static func merge<
        S1: AsyncSequence & Sendable,
        S2: AsyncSequence & Sendable,
        S3: AsyncSequence & Sendable
    >(
        _ s1: S1,
        _ s2: S2,
        _ s3: S3
    ) -> StateMerge<Element>
    where S1.Element == Element, S2.Element == Element, S3.Element == Element {
        StateMerge(sequences: [
            AnyAsyncSequence(s1),
            AnyAsyncSequence(s2),
            AnyAsyncSequence(s3)
        ])
    }

    /// Creates a StateMerge from four async sequences.
    ///
    /// - Parameters:
    ///   - s1: First sequence.
    ///   - s2: Second sequence.
    ///   - s3: Third sequence.
    ///   - s4: Fourth sequence.
    /// - Returns: A merged sequence emitting elements from all sources.
    public static func merge<
        S1: AsyncSequence & Sendable,
        S2: AsyncSequence & Sendable,
        S3: AsyncSequence & Sendable,
        S4: AsyncSequence & Sendable
    >(
        _ s1: S1,
        _ s2: S2,
        _ s3: S3,
        _ s4: S4
    ) -> StateMerge<Element>
    where S1.Element == Element, S2.Element == Element, S3.Element == Element, S4.Element == Element {
        StateMerge(sequences: [
            AnyAsyncSequence(s1),
            AnyAsyncSequence(s2),
            AnyAsyncSequence(s3),
            AnyAsyncSequence(s4)
        ])
    }
}
