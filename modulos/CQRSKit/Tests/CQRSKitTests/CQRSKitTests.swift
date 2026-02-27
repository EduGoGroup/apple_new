import Testing
import Foundation
@testable import CQRSKit

// MARK: - Test Types

struct TestCommand: Command {
    typealias Result = String
    let value: String
}

struct TestQuery: Query {
    typealias Result = Int
    let filter: String
}

struct TestEvent: DomainEvent {
    let eventId: UUID
    let occurredAt: Date
    let message: String

    init(message: String) {
        self.eventId = UUID()
        self.occurredAt = Date()
        self.message = message
    }
}

struct TestState: AsyncState {
    let count: Int
    static let initial = TestState(count: 0)
}

struct TestReadModel: ReadModel {
    let id: String
    let name: String
    let tags: Set<String>
    let cachedAt: Date
    let ttlSeconds: TimeInterval

    init(id: String, name: String, tags: Set<String> = [], ttlSeconds: TimeInterval = 300) {
        self.id = id
        self.name = name
        self.tags = tags
        self.cachedAt = Date()
        self.ttlSeconds = ttlSeconds
    }
}

// MARK: - Test Subscriber

actor TestSubscriber: EventSubscriber {
    typealias EventType = TestEvent
    private(set) var receivedEvents: [TestEvent] = []

    func handle(_ event: TestEvent) async {
        receivedEvents.append(event)
    }
}

// MARK: - CQRS Core Tests

@Suite struct CommandTests {

    @Test func testCommandHasAssociatedResultType() {
        let command = TestCommand(value: "test")
        #expect(command.value == "test")
    }

    @Test func testCommandConformsToSendable() {
        let command: any Sendable = TestCommand(value: "test")
        #expect(command is TestCommand)
    }
}

@Suite struct QueryTests {

    @Test func testQueryHasAssociatedResultType() {
        let query = TestQuery(filter: "active")
        #expect(query.filter == "active")
    }
}

@Suite struct DomainEventTests {

    @Test func testEventProperties() {
        let event = TestEvent(message: "Hello")
        #expect(event.message == "Hello")
        #expect(event.eventId != nil)
        #expect(event.occurredAt != nil)
    }

    @Test func testEventTypeDefaultsToTypeName() {
        let event = TestEvent(message: "Hello")
        #expect(event.eventType == "TestEvent")
    }

    @Test func testEventMetadataDefaultsToEmpty() {
        let event = TestEvent(message: "Hello")
        #expect(event.metadata.isEmpty)
    }
}

// MARK: - Event Bus Tests

@Suite struct EventBusTests {

    @Test func testSubscribeAndPublishWithSubscriber() async {
        let bus = EventBus(loggingEnabled: false, metricsEnabled: false)
        let subscriber = TestSubscriber()

        await bus.subscribe(subscriber)
        await bus.publish(TestEvent(message: "test"))
        try? await Task.sleep(for: .milliseconds(50))

        let count = await subscriber.receivedEvents.count
        #expect(count == 1)
    }

    @Test func testUnsubscribe() async {
        let bus = EventBus(loggingEnabled: false, metricsEnabled: false)
        let subscriber = TestSubscriber()

        let subId = await bus.subscribe(subscriber)
        let removed = await bus.unsubscribe(subId)
        #expect(removed)

        await bus.publish(TestEvent(message: "test"))
        try? await Task.sleep(for: .milliseconds(50))

        let count = await subscriber.receivedEvents.count
        #expect(count == 0)
    }

    @Test func testSubscriberCountForEventType() async {
        let bus = EventBus(loggingEnabled: false, metricsEnabled: false)
        let subscriber = TestSubscriber()
        await bus.subscribe(subscriber)

        let count = await bus.subscriberCount(for: TestEvent.self)
        #expect(count == 1)
    }

    @Test func testTotalSubscriptions() async {
        let bus = EventBus(loggingEnabled: false, metricsEnabled: false)
        let sub1 = TestSubscriber()
        let sub2 = TestSubscriber()
        await bus.subscribe(sub1)
        await bus.subscribe(sub2)

        let total = await bus.totalSubscriptions
        #expect(total == 2)
    }
}

// MARK: - Mediator Tests

@Suite struct MediatorErrorTests {

    @Test func testHandlerNotFoundHasDescription() {
        let error = MediatorError.handlerNotFound(type: "TestCommand")
        #expect(error.errorDescription != nil)
        #expect(error.description.contains("TestCommand"))
    }

    @Test func testAllCases() {
        let errors: [MediatorError] = [
            .handlerNotFound(type: "Test"),
            .executionError(message: "Failed", underlyingError: nil),
            .validationError(message: "Invalid", underlyingError: nil),
            .registrationError(message: "Duplicate")
        ]

        for error in errors {
            #expect(error.errorDescription != nil)
        }
    }
}

// MARK: - State Management Tests

@Suite struct StatePublisherTests {

    @Test func testStartsWithNilState() async {
        let publisher = StatePublisher<TestState>()
        let state = await publisher.currentState
        #expect(state == nil)
    }

    @Test func testEmitsUpdates() async {
        let publisher = StatePublisher<TestState>()
        await publisher.send(TestState(count: 42))
        let state = await publisher.currentState
        #expect(state?.count == 42)
    }

    @Test func testSendIfChangedDeduplicates() async {
        let publisher = StatePublisher<TestState>()
        await publisher.send(TestState(count: 1))
        let changed = await publisher.sendIfChanged(TestState(count: 1))
        #expect(!changed)

        let changed2 = await publisher.sendIfChanged(TestState(count: 2))
        #expect(changed2)
    }

    @Test func testFinishStopsEmissions() async {
        let publisher = StatePublisher<TestState>()
        await publisher.send(TestState(count: 1))
        await publisher.finish()
        await publisher.send(TestState(count: 99))
        let state = await publisher.currentState
        #expect(state?.count == 1)
    }
}

@Suite struct BufferingStrategyTests {

    @Test func testUnboundedBufferAcceptsElements() async {
        let buffer = UnboundedBuffer<Int>()
        await buffer.enqueue(1)
        await buffer.enqueue(2)
        let value = await buffer.dequeue()
        #expect(value == 1)
    }

    @Test func testUnboundedBufferIsNeverFull() async {
        let buffer = UnboundedBuffer<Int>()
        let isFull = await buffer.isFull
        #expect(!isFull)
    }

    @Test func testBoundedBufferRespectsCapacity() async {
        let buffer = BoundedBuffer<Int>(capacity: 2)
        await buffer.enqueue(1)
        await buffer.enqueue(2)
        let value = await buffer.dequeue()
        #expect(value == 1)
    }

    @Test func testDroppingBufferDropsOldestWhenFull() async {
        let buffer = DroppingBuffer<Int>(capacity: 2)
        await buffer.enqueue(1)
        await buffer.enqueue(2)
        await buffer.enqueue(3)
        let value = await buffer.dequeue()
        #expect(value == 2)
    }

    @Test func testBufferClear() async {
        let buffer = UnboundedBuffer<Int>()
        await buffer.enqueue(1)
        await buffer.enqueue(2)
        await buffer.clear()
        let isEmpty = await buffer.isEmpty
        #expect(isEmpty)
    }
}

// MARK: - Metrics Tests

@Suite struct CQRSMetricsTests {

    @Test func testCanRecordAndRetrieveErrors() async {
        let metrics = CQRSMetrics()
        let count = await metrics.getErrorCount(for: "TestHandler")
        #expect(count == 0)
    }

    @Test func testGeneratesReport() async {
        let metrics = CQRSMetrics()
        let report = await metrics.generateReport()
        #expect(report.queryStats.isEmpty)
        #expect(report.commandStats.isEmpty)
    }

    @Test func testRecordCacheHitAndMiss() async {
        let metrics = CQRSMetrics()
        await metrics.recordCacheHit(queryType: "TestQuery")
        await metrics.recordCacheMiss(queryType: "TestQuery")
        let cacheMetrics = await metrics.getCacheMetrics(for: "TestQuery")
        #expect(cacheMetrics != nil)
        #expect(cacheMetrics?.hits == 1)
        #expect(cacheMetrics?.misses == 1)
    }
}

@Suite struct CacheMetricsTests {

    @Test func testTracksHitsAndMisses() {
        var metrics = CacheMetrics(handlerType: "TestQuery")
        metrics.recordHit()
        metrics.recordMiss()
        #expect(metrics.hits == 1)
        #expect(metrics.misses == 1)
        #expect(metrics.totalAccesses == 2)
    }

    @Test func testHitRatio() {
        var metrics = CacheMetrics(handlerType: "TestQuery")
        metrics.recordHit()
        metrics.recordHit()
        metrics.recordMiss()
        #expect(metrics.hitRatio > 0.6)
        #expect(metrics.hitRatio < 0.7)
    }

    @Test func testReset() {
        var metrics = CacheMetrics(handlerType: "TestQuery")
        metrics.recordHit()
        metrics.recordMiss()
        metrics.reset()
        #expect(metrics.hits == 0)
        #expect(metrics.misses == 0)
    }
}

// MARK: - ReadModelStore Tests

@Suite struct ReadModelStoreTests {

    @Test func testSaveAndGet() async {
        let store = ReadModelStore<TestReadModel>(loggingEnabled: false)
        let model = TestReadModel(id: "1", name: "Test")
        await store.save(model)
        let retrieved = await store.get(id: "1")
        #expect(retrieved?.name == "Test")
    }

    @Test func testReturnsNilForMissingKeys() async {
        let store = ReadModelStore<TestReadModel>(loggingEnabled: false)
        let value = await store.get(id: "missing")
        #expect(value == nil)
    }

    @Test func testCanInvalidate() async {
        let store = ReadModelStore<TestReadModel>(loggingEnabled: false)
        let model = TestReadModel(id: "1", name: "Test")
        await store.save(model)
        let removed = await store.invalidate(id: "1")
        #expect(removed)
        let value = await store.get(id: "1")
        #expect(value == nil)
    }

    @Test func testTracksCount() async {
        let store = ReadModelStore<TestReadModel>(loggingEnabled: false)
        await store.save(TestReadModel(id: "1", name: "A"))
        await store.save(TestReadModel(id: "2", name: "B"))
        let count = await store.count
        #expect(count == 2)
    }

    @Test func testInvalidateByTag() async {
        let store = ReadModelStore<TestReadModel>(loggingEnabled: false)
        await store.save(TestReadModel(id: "1", name: "A", tags: ["group1"]))
        await store.save(TestReadModel(id: "2", name: "B", tags: ["group1"]))
        await store.save(TestReadModel(id: "3", name: "C", tags: ["group2"]))
        let removed = await store.invalidateByTag("group1")
        #expect(removed == 2)
        let count = await store.count
        #expect(count == 1)
    }

    @Test func testInvalidateAll() async {
        let store = ReadModelStore<TestReadModel>(loggingEnabled: false)
        await store.save(TestReadModel(id: "1", name: "A"))
        await store.save(TestReadModel(id: "2", name: "B"))
        await store.invalidateAll()
        let count = await store.count
        #expect(count == 0)
    }
}

// MARK: - AnyDomainEvent Tests

@Suite struct AnyDomainEventTests {

    @Test func testWrapsAndUnwraps() {
        let original = TestEvent(message: "wrapped")
        let any = AnyDomainEvent(original)
        #expect(any.eventType == "TestEvent")

        let unwrapped = any.unwrap(as: TestEvent.self)
        #expect(unwrapped != nil)
        #expect(unwrapped?.message == "wrapped")
    }

    @Test func testUnwrapReturnsNilForWrongType() {
        let event = TestEvent(message: "test")
        let any = AnyDomainEvent(event)
        // Use a different DomainEvent type to test wrong type unwrap
        struct OtherEvent: DomainEvent {
            let eventId = UUID()
            let occurredAt = Date()
        }
        let wrong = any.unwrap(as: OtherEvent.self)
        #expect(wrong == nil)
    }
}
