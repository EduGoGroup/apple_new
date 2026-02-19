/// A bounded buffering strategy that drops the oldest elements when full.
///
/// DroppingBuffer maintains a fixed capacity by removing the oldest
/// element when a new one is added to a full buffer. This ensures
/// producers never block, at the cost of potentially losing data.
///
/// # Dropping Behavior
/// When the buffer is full:
/// - `enqueue` removes the oldest element
/// - The new element is added at the end
/// - Returns `.droppedOldest` to indicate data loss
///
/// # Use Cases
/// - UI progress updates where only the latest matters
/// - Real-time telemetry where old data becomes stale
/// - High-frequency sensors where gaps are acceptable
///
/// # Example
/// ```swift
/// let buffer = DroppingBuffer<ProgressState>(capacity: 5)
///
/// // If buffer is full, oldest is dropped
/// let result = await buffer.enqueue(currentProgress)
/// if result == .droppedOldest {
///     print("Dropped an old progress update")
/// }
/// ```
public actor DroppingBuffer<Element: Sendable>: BufferingStrategy {
    /// Internal storage for buffered elements.
    private var elements: [Element] = []

    /// The maximum number of elements the buffer can hold.
    public let capacity: Int

    /// Indicates whether the buffer has been terminated.
    private var isTerminated = false

    /// Continuations waiting for elements to become available.
    private var waitingConsumers: [CheckedContinuation<Element?, Never>] = []

    /// Creates a dropping buffer with the specified capacity.
    ///
    /// - Parameter capacity: Maximum number of elements (must be > 0).
    /// - Precondition: capacity > 0
    public init(capacity: Int) {
        precondition(capacity > 0, "DroppingBuffer capacity must be greater than 0")
        self.capacity = capacity
    }

    /// Adds an element to the buffer, dropping the oldest if full.
    ///
    /// This method never blocks. If the buffer is at capacity, the oldest
    /// element is removed before adding the new one.
    ///
    /// - Parameter element: The element to add.
    /// - Returns: `.enqueued` if space was available, `.droppedOldest` if an element was dropped.
    @discardableResult
    public func enqueue(_ element: Element) async -> BufferEnqueueResult {
        guard !isTerminated else { return .terminated }

        // If there's a waiting consumer, deliver directly
        if !waitingConsumers.isEmpty {
            let consumer = waitingConsumers.removeFirst()
            consumer.resume(returning: element)
            return .enqueued
        }

        // If buffer is full, drop the oldest
        if elements.count >= capacity {
            elements.removeFirst()
            elements.append(element)
            return .droppedOldest
        }

        // Buffer has space
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

    /// Waits for an element to become available.
    ///
    /// Use this when you want to block until an element is available.
    ///
    /// - Returns: The next element, or nil if the buffer is terminated.
    public func dequeueWaiting() async -> Element? {
        // If we have elements, return one
        if !elements.isEmpty {
            return elements.removeFirst()
        }

        // If terminated and empty, return nil
        if isTerminated {
            return nil
        }

        // Wait for an element
        return await withCheckedContinuation { continuation in
            waitingConsumers.append(continuation)
        }
    }

    /// Returns true if the buffer has reached its capacity.
    ///
    /// Note: For DroppingBuffer, being "full" doesn't block producers.
    public var isFull: Bool {
        elements.count >= capacity
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

        // Resume waiting consumers with nil
        for consumer in waitingConsumers {
            consumer.resume(returning: nil)
        }
        waitingConsumers.removeAll()
    }

    /// Terminates the buffer, preventing further enqueues.
    public func terminate() async {
        isTerminated = true

        // If no elements, resume waiting consumers with nil
        if elements.isEmpty {
            for consumer in waitingConsumers {
                consumer.resume(returning: nil)
            }
            waitingConsumers.removeAll()
        }
    }

    /// Returns the number of elements that have been dropped since creation.
    ///
    /// Useful for monitoring and debugging buffer overflow situations.
    private var droppedCount: Int = 0
}
