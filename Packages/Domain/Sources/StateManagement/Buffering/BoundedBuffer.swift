/// A bounded buffering strategy with a fixed capacity that suspends producers when full.
///
/// BoundedBuffer provides backpressure by suspending the producer when
/// the buffer reaches its capacity. The producer is resumed when space
/// becomes available through consumption.
///
/// # Backpressure Behavior
/// When the buffer is full:
/// - `enqueue` suspends until space is available
/// - Consumer's `dequeue` makes space and resumes waiting producers
///
/// # Use Cases
/// - Rate-limiting high-frequency producers
/// - Preventing memory exhaustion from fast producers
/// - Synchronizing producer/consumer speeds
///
/// # Example
/// ```swift
/// let buffer = BoundedBuffer<UploadState>(capacity: 10)
///
/// // This may suspend if buffer is full
/// await buffer.enqueue(state)
///
/// // Consumer frees space
/// let state = await buffer.dequeue()
/// ```
public actor BoundedBuffer<Element: Sendable>: BufferingStrategy {
    /// Internal storage for buffered elements.
    private var elements: [Element] = []

    /// The maximum number of elements the buffer can hold.
    public let capacity: Int

    /// Indicates whether the buffer has been terminated.
    private var isTerminated = false

    /// Continuations waiting for space to become available.
    private var waitingProducers: [CheckedContinuation<BufferEnqueueResult, Never>] = []

    /// Continuations waiting for elements to become available.
    private var waitingConsumers: [CheckedContinuation<Element?, Never>] = []

    /// Creates a bounded buffer with the specified capacity.
    ///
    /// - Parameter capacity: Maximum number of elements (must be > 0).
    /// - Precondition: capacity > 0
    public init(capacity: Int) {
        precondition(capacity > 0, "BoundedBuffer capacity must be greater than 0")
        self.capacity = capacity
    }

    /// Adds an element to the buffer, suspending if full.
    ///
    /// If the buffer is at capacity, this method suspends until a consumer
    /// removes an element, making space available.
    ///
    /// - Parameter element: The element to add.
    /// - Returns: `.enqueued` if added immediately, `.enqueuedAfterWaiting` if suspended first.
    @discardableResult
    public func enqueue(_ element: Element) async -> BufferEnqueueResult {
        guard !isTerminated else { return .terminated }

        // If there's a waiting consumer, deliver directly
        if !waitingConsumers.isEmpty {
            let consumer = waitingConsumers.removeFirst()
            consumer.resume(returning: element)
            return .enqueued
        }

        // If buffer has space, add immediately
        if elements.count < capacity {
            elements.append(element)
            return .enqueued
        }

        // Buffer is full, suspend until space is available
        return await withCheckedContinuation { continuation in
            // Store element with the continuation for later processing
            let wrappedContinuation = continuation
            waitingProducers.append(wrappedContinuation)

            // Store the element to be added when space is available
            Task { [weak self] in
                guard let self = self else { return }
                await self.storeElementForProducer(element)
            }
        }
    }

    /// Internal helper to store element when producer resumes.
    private var pendingElements: [Element] = []

    private func storeElementForProducer(_ element: Element) {
        pendingElements.append(element)
    }

    /// Removes and returns the oldest element from the buffer.
    ///
    /// If producers are waiting for space, this resumes one of them.
    ///
    /// - Returns: The oldest element, or nil if buffer is empty and terminated.
    public func dequeue() async -> Element? {
        // If we have elements, return one
        if !elements.isEmpty {
            let element = elements.removeFirst()
            resumeWaitingProducerIfNeeded()
            return element
        }

        // If terminated and empty, return nil
        if isTerminated {
            return nil
        }

        // If producers are waiting with pending elements
        if !waitingProducers.isEmpty && !pendingElements.isEmpty {
            let element = pendingElements.removeFirst()
            let producer = waitingProducers.removeFirst()
            producer.resume(returning: .enqueuedAfterWaiting)
            return element
        }

        // No elements available, return nil (non-blocking)
        return nil
    }

    /// Waits for an element to become available.
    ///
    /// Use this when you want to block until an element is available.
    ///
    /// - Returns: The next element, or nil if the buffer is terminated.
    public func dequeueWaiting() async -> Element? {
        // If we have elements, return one
        if !elements.isEmpty {
            let element = elements.removeFirst()
            resumeWaitingProducerIfNeeded()
            return element
        }

        // If producers are waiting with pending elements
        if !waitingProducers.isEmpty && !pendingElements.isEmpty {
            let element = pendingElements.removeFirst()
            let producer = waitingProducers.removeFirst()
            producer.resume(returning: .enqueuedAfterWaiting)
            return element
        }

        // If terminated and empty, return nil
        if isTerminated && elements.isEmpty && pendingElements.isEmpty {
            return nil
        }

        // Wait for an element
        return await withCheckedContinuation { continuation in
            waitingConsumers.append(continuation)
        }
    }

    /// Resumes a waiting producer if there's space available.
    private func resumeWaitingProducerIfNeeded() {
        guard !waitingProducers.isEmpty && !pendingElements.isEmpty else { return }
        guard elements.count < capacity else { return }

        let element = pendingElements.removeFirst()
        elements.append(element)

        let producer = waitingProducers.removeFirst()
        producer.resume(returning: .enqueuedAfterWaiting)
    }

    /// Returns true if the buffer has reached its capacity.
    public var isFull: Bool {
        elements.count >= capacity
    }

    /// Returns true if the buffer contains no elements.
    public var isEmpty: Bool {
        elements.isEmpty && pendingElements.isEmpty
    }

    /// The current number of elements in the buffer.
    public var count: Int {
        elements.count + pendingElements.count
    }

    /// Removes all elements and resumes waiting producers with terminated result.
    public func clear() async {
        elements.removeAll()
        pendingElements.removeAll()

        // Resume all waiting producers with terminated
        for producer in waitingProducers {
            producer.resume(returning: .terminated)
        }
        waitingProducers.removeAll()

        // Resume all waiting consumers with nil
        for consumer in waitingConsumers {
            consumer.resume(returning: nil)
        }
        waitingConsumers.removeAll()
    }

    /// Terminates the buffer, preventing further enqueues.
    ///
    /// Waiting consumers will receive nil when all buffered elements are consumed.
    public func terminate() async {
        isTerminated = true

        // Resume waiting producers with terminated
        for producer in waitingProducers {
            producer.resume(returning: .terminated)
        }
        waitingProducers.removeAll()
        pendingElements.removeAll()

        // If no more elements, resume waiting consumers with nil
        if elements.isEmpty {
            for consumer in waitingConsumers {
                consumer.resume(returning: nil)
            }
            waitingConsumers.removeAll()
        }
    }
}
