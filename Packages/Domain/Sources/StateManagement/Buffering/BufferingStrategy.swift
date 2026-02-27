/// Protocol defining a buffering strategy for async stream producers.
///
/// BufferingStrategy controls how elements are handled when a producer
/// emits faster than a consumer processes. Different strategies provide
/// varying trade-offs between memory usage, latency, and data loss.
///
/// # Thread Safety
/// All implementations must be thread-safe and Sendable, as they may be
/// accessed from multiple concurrent contexts.
///
/// # Available Strategies
/// - `UnboundedBuffer`: No limit on buffer size (default behavior)
/// - `BoundedBuffer`: Fixed capacity, suspends producer when full
/// - `DroppingBuffer`: Fixed capacity, drops oldest elements when full
///
/// # Example
/// ```swift
/// let publisher = StatePublisher<UploadState>(
///     bufferingStrategy: BoundedBuffer(capacity: 10)
/// )
/// ```
public protocol BufferingStrategy<Element>: Sendable {
    /// The type of elements stored in the buffer.
    associatedtype Element: Sendable

    /// Adds an element to the buffer.
    ///
    /// Behavior depends on the strategy:
    /// - UnboundedBuffer: Always succeeds immediately
    /// - BoundedBuffer: Suspends if buffer is full until space is available
    /// - DroppingBuffer: Drops oldest element if buffer is full
    ///
    /// - Parameter element: The element to add.
    /// - Returns: The result of the enqueue operation.
    @discardableResult
    func enqueue(_ element: Element) async -> BufferEnqueueResult

    /// Removes and returns the oldest element from the buffer.
    ///
    /// - Returns: The oldest element, or nil if the buffer is empty.
    func dequeue() async -> Element?

    /// Indicates whether the buffer has reached its capacity.
    ///
    /// For unbounded buffers, this always returns false.
    var isFull: Bool { get async }

    /// Indicates whether the buffer is empty.
    var isEmpty: Bool { get async }

    /// The current number of elements in the buffer.
    var count: Int { get async }

    /// Removes all elements from the buffer.
    func clear() async
}

/// Result of a buffer enqueue operation.
public enum BufferEnqueueResult: Sendable, Equatable {
    /// Element was successfully added to the buffer.
    case enqueued

    /// Element was added after waiting for space (BoundedBuffer only).
    case enqueuedAfterWaiting

    /// An old element was dropped to make room for the new one (DroppingBuffer only).
    case droppedOldest

    /// The buffer was terminated and the element was not added.
    case terminated
}

/// Indicates the buffer has been terminated and no more elements can be added.
public struct BufferTerminatedError: Error, Sendable {
    public init() {}
}
