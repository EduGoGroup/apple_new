/// An unbounded buffering strategy with no capacity limit.
///
/// UnboundedBuffer stores all elements until they are consumed. This is
/// the default behavior for StatePublisher, suitable for UI-driven
/// consumption where states are typically processed quickly.
///
/// # Memory Considerations
/// Since there's no limit, memory can grow indefinitely if the producer
/// emits faster than the consumer processes. Use BoundedBuffer or
/// DroppingBuffer for high-frequency producers.
///
/// # Thread Safety
/// All operations are actor-isolated for thread-safe access.
///
/// # Example
/// ```swift
/// let buffer = UnboundedBuffer<UploadState>()
/// await buffer.enqueue(UploadState(progress: 0.5))
/// let state = await buffer.dequeue()
/// ```
public actor UnboundedBuffer<Element: Sendable>: BufferingStrategy {
    /// Internal storage for buffered elements.
    private var elements: [Element] = []

    /// Indicates whether the buffer has been terminated.
    private var isTerminated = false

    /// Creates a new unbounded buffer.
    public init() {}

    /// Adds an element to the buffer.
    ///
    /// Always succeeds immediately since there's no capacity limit.
    ///
    /// - Parameter element: The element to add.
    /// - Returns: `.enqueued` on success, `.terminated` if buffer is closed.
    @discardableResult
    public func enqueue(_ element: Element) async -> BufferEnqueueResult {
        guard !isTerminated else { return .terminated }
        elements.append(element)
        return .enqueued
    }

    /// Removes and returns the oldest element from the buffer.
    ///
    /// - Returns: The oldest element, or nil if the buffer is empty.
    public func dequeue() async -> Element? {
        guard !elements.isEmpty else { return nil }
        return elements.removeFirst()
    }

    /// Always returns false since unbounded buffers have no capacity limit.
    public var isFull: Bool {
        false
    }

    /// Returns true if the buffer contains no elements.
    public var isEmpty: Bool {
        elements.isEmpty
    }

    /// The current number of elements in the buffer.
    public var count: Int {
        elements.count
    }

    /// Removes all elements from the buffer.
    public func clear() async {
        elements.removeAll()
    }

    /// Terminates the buffer, preventing further enqueues.
    public func terminate() {
        isTerminated = true
    }
}
