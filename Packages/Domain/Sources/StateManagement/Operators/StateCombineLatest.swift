/// Completion policy for combineLatest operations.
///
/// Determines when the combined stream should complete based on source stream completion.
public enum CombineLatestCompletionPolicy: Sendable {
    /// Complete when ANY source stream completes.
    case any
    /// Complete only when ALL source streams complete.
    case all
}

/// An AsyncSequence that combines the latest values from two source sequences.
///
/// StateCombineLatest2 waits until both source sequences have emitted at least one value,
/// then emits a tuple containing the latest value from each. When either source emits
/// a new value, a new combined tuple is emitted.
///
/// # Usage
/// ```swift
/// let combined = StateCombineLatest2(stream1, stream2, policy: .all)
///
/// for try await (a, b) in combined {
///     handleCombined(a, b)
/// }
/// ```
///
/// # Completion Behavior
/// - `.any`: Completes when ANY source stream completes
/// - `.all`: Completes only when ALL source streams complete
///
/// # Cancellation
/// When the consuming task is cancelled, all source streams are cancelled.
public struct StateCombineLatest2<A: Sendable, B: Sendable>: AsyncSequence, Sendable {
    public typealias Element = (A, B)
    public typealias AsyncIterator = Iterator

    private let source1: AnyAsyncSequence<A>
    private let source2: AnyAsyncSequence<B>
    private let policy: CombineLatestCompletionPolicy

    /// Creates a StateCombineLatest2 from two async sequences.
    ///
    /// - Parameters:
    ///   - s1: First source sequence.
    ///   - s2: Second source sequence.
    ///   - policy: Completion policy (default: .all).
    public init<S1: AsyncSequence & Sendable, S2: AsyncSequence & Sendable>(
        _ s1: S1,
        _ s2: S2,
        policy: CombineLatestCompletionPolicy = .all
    ) where S1.Element == A, S2.Element == B {
        self.source1 = AnyAsyncSequence(s1)
        self.source2 = AnyAsyncSequence(s2)
        self.policy = policy
    }

    public func makeAsyncIterator() -> Iterator {
        Iterator(source1: source1, source2: source2, policy: policy)
    }

    /// The iterator type for StateCombineLatest2.
    public struct Iterator: AsyncIteratorProtocol {
        private var iterator: AsyncThrowingStream<(A, B), any Error>.AsyncIterator
        private let task: Task<Void, Never>

        init(
            source1: AnyAsyncSequence<A>,
            source2: AnyAsyncSequence<B>,
            policy: CombineLatestCompletionPolicy
        ) {
            let (stream, continuation) = AsyncThrowingStream<(A, B), any Error>.makeStream()
            self.iterator = stream.makeAsyncIterator()

            self.task = Task {
                await withTaskGroup(of: Void.self) { group in
                    // Shared state actor
                    let state = CombineLatestState2<A, B>(
                        continuation: continuation,
                        policy: policy
                    )

                    // Consume first source
                    group.addTask {
                        do {
                            for try await value in source1 {
                                guard !Task.isCancelled else { return }
                                await state.update(first: value)
                            }
                            await state.complete(source: 0)
                        } catch {
                            await state.fail(with: error)
                        }
                    }

                    // Consume second source
                    group.addTask {
                        do {
                            for try await value in source2 {
                                guard !Task.isCancelled else { return }
                                await state.update(second: value)
                            }
                            await state.complete(source: 1)
                        } catch {
                            await state.fail(with: error)
                        }
                    }

                    await group.waitForAll()
                }
            }
        }

        public mutating func next() async throws -> (A, B)? {
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

/// Internal actor to manage combine latest state for 2 sources.
private actor CombineLatestState2<A: Sendable, B: Sendable> {
    private var latestA: A?
    private var latestB: B?
    private var completedSources: Set<Int> = []
    private var isFinished = false
    private var hasEmitted = false
    private let continuation: AsyncThrowingStream<(A, B), any Error>.Continuation
    private let policy: CombineLatestCompletionPolicy

    init(
        continuation: AsyncThrowingStream<(A, B), any Error>.Continuation,
        policy: CombineLatestCompletionPolicy
    ) {
        self.continuation = continuation
        self.policy = policy
    }

    func update(first value: A) {
        guard !isFinished else { return }
        latestA = value
        emitIfReady()
    }

    func update(second value: B) {
        guard !isFinished else { return }
        latestB = value
        emitIfReady()
    }

    private func emitIfReady() {
        guard let a = latestA, let b = latestB else { return }
        hasEmitted = true
        continuation.yield((a, b))

        // Check if we should finish after emitting (for .any policy with completed sources)
        checkDeferredCompletion()
    }

    private func checkDeferredCompletion() {
        guard hasEmitted, !completedSources.isEmpty else { return }

        switch policy {
        case .any:
            finish()
        case .all:
            if completedSources.count >= 2 {
                finish()
            }
        }
    }

    func complete(source: Int) {
        guard !isFinished else { return }
        completedSources.insert(source)

        switch policy {
        case .any:
            // Only finish immediately if we've already emitted
            // Otherwise, defer until we can emit
            if hasEmitted {
                finish()
            } else if completedSources.count >= 2 {
                // Both completed without any emission - finish with no results
                finish()
            }
            // If only one completed and we haven't emitted yet, wait
        case .all:
            if completedSources.count >= 2 {
                finish()
            }
        }
    }

    func fail(with error: any Error) {
        guard !isFinished else { return }
        isFinished = true
        continuation.finish(throwing: error)
    }

    private func finish() {
        guard !isFinished else { return }
        isFinished = true
        continuation.finish()
    }
}

// MARK: - StateCombineLatest3

/// An AsyncSequence that combines the latest values from three source sequences.
public struct StateCombineLatest3<A: Sendable, B: Sendable, C: Sendable>: AsyncSequence, Sendable {
    public typealias Element = (A, B, C)
    public typealias AsyncIterator = Iterator

    private let source1: AnyAsyncSequence<A>
    private let source2: AnyAsyncSequence<B>
    private let source3: AnyAsyncSequence<C>
    private let policy: CombineLatestCompletionPolicy

    /// Creates a StateCombineLatest3 from three async sequences.
    public init<
        S1: AsyncSequence & Sendable,
        S2: AsyncSequence & Sendable,
        S3: AsyncSequence & Sendable
    >(
        _ s1: S1,
        _ s2: S2,
        _ s3: S3,
        policy: CombineLatestCompletionPolicy = .all
    ) where S1.Element == A, S2.Element == B, S3.Element == C {
        self.source1 = AnyAsyncSequence(s1)
        self.source2 = AnyAsyncSequence(s2)
        self.source3 = AnyAsyncSequence(s3)
        self.policy = policy
    }

    public func makeAsyncIterator() -> Iterator {
        Iterator(source1: source1, source2: source2, source3: source3, policy: policy)
    }

    public struct Iterator: AsyncIteratorProtocol {
        private var iterator: AsyncThrowingStream<(A, B, C), any Error>.AsyncIterator
        private let task: Task<Void, Never>

        init(
            source1: AnyAsyncSequence<A>,
            source2: AnyAsyncSequence<B>,
            source3: AnyAsyncSequence<C>,
            policy: CombineLatestCompletionPolicy
        ) {
            let (stream, continuation) = AsyncThrowingStream<(A, B, C), any Error>.makeStream()
            self.iterator = stream.makeAsyncIterator()

            self.task = Task {
                await withTaskGroup(of: Void.self) { group in
                    let state = CombineLatestState3<A, B, C>(
                        continuation: continuation,
                        policy: policy
                    )

                    group.addTask {
                        do {
                            for try await value in source1 {
                                guard !Task.isCancelled else { return }
                                await state.update(first: value)
                            }
                            await state.complete(source: 0)
                        } catch {
                            await state.fail(with: error)
                        }
                    }

                    group.addTask {
                        do {
                            for try await value in source2 {
                                guard !Task.isCancelled else { return }
                                await state.update(second: value)
                            }
                            await state.complete(source: 1)
                        } catch {
                            await state.fail(with: error)
                        }
                    }

                    group.addTask {
                        do {
                            for try await value in source3 {
                                guard !Task.isCancelled else { return }
                                await state.update(third: value)
                            }
                            await state.complete(source: 2)
                        } catch {
                            await state.fail(with: error)
                        }
                    }

                    await group.waitForAll()
                }
            }
        }

        public mutating func next() async throws -> (A, B, C)? {
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

/// Internal actor to manage combine latest state for 3 sources.
private actor CombineLatestState3<A: Sendable, B: Sendable, C: Sendable> {
    private var latestA: A?
    private var latestB: B?
    private var latestC: C?
    private var completedSources: Set<Int> = []
    private var isFinished = false
    private var hasEmitted = false
    private let continuation: AsyncThrowingStream<(A, B, C), any Error>.Continuation
    private let policy: CombineLatestCompletionPolicy

    init(
        continuation: AsyncThrowingStream<(A, B, C), any Error>.Continuation,
        policy: CombineLatestCompletionPolicy
    ) {
        self.continuation = continuation
        self.policy = policy
    }

    func update(first value: A) {
        guard !isFinished else { return }
        latestA = value
        emitIfReady()
    }

    func update(second value: B) {
        guard !isFinished else { return }
        latestB = value
        emitIfReady()
    }

    func update(third value: C) {
        guard !isFinished else { return }
        latestC = value
        emitIfReady()
    }

    private func emitIfReady() {
        guard let a = latestA, let b = latestB, let c = latestC else { return }
        hasEmitted = true
        continuation.yield((a, b, c))

        // Check if we should finish after emitting (for .any policy with completed sources)
        checkDeferredCompletion()
    }

    private func checkDeferredCompletion() {
        guard hasEmitted, !completedSources.isEmpty else { return }

        switch policy {
        case .any:
            finish()
        case .all:
            if completedSources.count >= 3 {
                finish()
            }
        }
    }

    func complete(source: Int) {
        guard !isFinished else { return }
        completedSources.insert(source)

        switch policy {
        case .any:
            // Only finish immediately if we've already emitted
            // Otherwise, defer until we can emit
            if hasEmitted {
                finish()
            } else if completedSources.count >= 3 {
                // All completed without any emission - finish with no results
                finish()
            }
            // If not all completed and we haven't emitted yet, wait
        case .all:
            if completedSources.count >= 3 {
                finish()
            }
        }
    }

    func fail(with error: any Error) {
        guard !isFinished else { return }
        isFinished = true
        continuation.finish(throwing: error)
    }

    private func finish() {
        guard !isFinished else { return }
        isFinished = true
        continuation.finish()
    }
}

// MARK: - Convenience Factory Functions

/// Combines the latest values from two async sequences.
///
/// Waits until both sequences have emitted at least once, then emits a tuple
/// with the latest value from each whenever either emits a new value.
///
/// - Parameters:
///   - s1: First sequence.
///   - s2: Second sequence.
///   - policy: Completion policy (default: .all).
/// - Returns: A sequence emitting tuples of the latest values.
public func combineLatest<
    S1: AsyncSequence & Sendable,
    S2: AsyncSequence & Sendable
>(
    _ s1: S1,
    _ s2: S2,
    policy: CombineLatestCompletionPolicy = .all
) -> StateCombineLatest2<S1.Element, S2.Element>
where S1.Element: Sendable, S2.Element: Sendable {
    StateCombineLatest2(s1, s2, policy: policy)
}

/// Combines the latest values from three async sequences.
///
/// Waits until all three sequences have emitted at least once, then emits a tuple
/// with the latest value from each whenever any emits a new value.
///
/// - Parameters:
///   - s1: First sequence.
///   - s2: Second sequence.
///   - s3: Third sequence.
///   - policy: Completion policy (default: .all).
/// - Returns: A sequence emitting tuples of the latest values.
public func combineLatest<
    S1: AsyncSequence & Sendable,
    S2: AsyncSequence & Sendable,
    S3: AsyncSequence & Sendable
>(
    _ s1: S1,
    _ s2: S2,
    _ s3: S3,
    policy: CombineLatestCompletionPolicy = .all
) -> StateCombineLatest3<S1.Element, S2.Element, S3.Element>
where S1.Element: Sendable, S2.Element: Sendable, S3.Element: Sendable {
    StateCombineLatest3(s1, s2, s3, policy: policy)
}
