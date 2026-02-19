import XCTest
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

final class CommandTests: XCTestCase {

    func testCommandHasAssociatedResultType() {
        let command = TestCommand(value: "test")
        XCTAssertEqual(command.value, "test")
    }

    func testCommandConformsToSendable() {
        let command: any Sendable = TestCommand(value: "test")
        XCTAssertTrue(command is TestCommand)
    }
}

final class QueryTests: XCTestCase {

    func testQueryHasAssociatedResultType() {
        let query = TestQuery(filter: "active")
        XCTAssertEqual(query.filter, "active")
    }
}

final class DomainEventTests: XCTestCase {

    func testEventProperties() {
        let event = TestEvent(message: "Hello")
        XCTAssertEqual(event.message, "Hello")
        XCTAssertNotNil(event.eventId)
        XCTAssertNotNil(event.occurredAt)
    }

    func testEventTypeDefaultsToTypeName() {
        let event = TestEvent(message: "Hello")
        XCTAssertEqual(event.eventType, "TestEvent")
    }

    func testEventMetadataDefaultsToEmpty() {
        let event = TestEvent(message: "Hello")
        XCTAssertTrue(event.metadata.isEmpty)
    }
}

// MARK: - Event Bus Tests

final class EventBusTests: XCTestCase {

    func testSubscribeAndPublishWithSubscriber() async {
        let bus = EventBus(loggingEnabled: false, metricsEnabled: false)
        let subscriber = TestSubscriber()

        await bus.subscribe(subscriber)
        await bus.publish(TestEvent(message: "test"))
        try? await Task.sleep(for: .milliseconds(50))

        let count = await subscriber.receivedEvents.count
        XCTAssertEqual(count, 1)
    }

    func testUnsubscribe() async {
        let bus = EventBus(loggingEnabled: false, metricsEnabled: false)
        let subscriber = TestSubscriber()

        let subId = await bus.subscribe(subscriber)
        let removed = await bus.unsubscribe(subId)
        XCTAssertTrue(removed)

        await bus.publish(TestEvent(message: "test"))
        try? await Task.sleep(for: .milliseconds(50))

        let count = await subscriber.receivedEvents.count
        XCTAssertEqual(count, 0)
    }

    func testSubscriberCountForEventType() async {
        let bus = EventBus(loggingEnabled: false, metricsEnabled: false)
        let subscriber = TestSubscriber()
        await bus.subscribe(subscriber)

        let count = await bus.subscriberCount(for: TestEvent.self)
        XCTAssertEqual(count, 1)
    }

    func testTotalSubscriptions() async {
        let bus = EventBus(loggingEnabled: false, metricsEnabled: false)
        let sub1 = TestSubscriber()
        let sub2 = TestSubscriber()
        await bus.subscribe(sub1)
        await bus.subscribe(sub2)

        let total = await bus.totalSubscriptions
        XCTAssertEqual(total, 2)
    }
}

// MARK: - Mediator Tests

final class MediatorErrorTests: XCTestCase {

    func testHandlerNotFoundHasDescription() {
        let error = MediatorError.handlerNotFound(type: "TestCommand")
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.description.contains("TestCommand"))
    }

    func testAllCases() {
        let errors: [MediatorError] = [
            .handlerNotFound(type: "Test"),
            .executionError(message: "Failed", underlyingError: nil),
            .validationError(message: "Invalid", underlyingError: nil),
            .registrationError(message: "Duplicate")
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription)
        }
    }
}

// MARK: - State Management Tests

final class StatePublisherTests: XCTestCase {

    func testStartsWithNilState() async {
        let publisher = StatePublisher<TestState>()
        let state = await publisher.currentState
        XCTAssertNil(state)
    }

    func testEmitsUpdates() async {
        let publisher = StatePublisher<TestState>()
        await publisher.send(TestState(count: 42))
        let state = await publisher.currentState
        XCTAssertEqual(state?.count, 42)
    }

    func testSendIfChangedDeduplicates() async {
        let publisher = StatePublisher<TestState>()
        await publisher.send(TestState(count: 1))
        let changed = await publisher.sendIfChanged(TestState(count: 1))
        XCTAssertFalse(changed)

        let changed2 = await publisher.sendIfChanged(TestState(count: 2))
        XCTAssertTrue(changed2)
    }

    func testFinishStopsEmissions() async {
        let publisher = StatePublisher<TestState>()
        await publisher.send(TestState(count: 1))
        await publisher.finish()
        await publisher.send(TestState(count: 99))
        let state = await publisher.currentState
        XCTAssertEqual(state?.count, 1)
    }
}

final class BufferingStrategyTests: XCTestCase {

    func testUnboundedBufferAcceptsElements() async {
        let buffer = UnboundedBuffer<Int>()
        await buffer.enqueue(1)
        await buffer.enqueue(2)
        let value = await buffer.dequeue()
        XCTAssertEqual(value, 1)
    }

    func testUnboundedBufferIsNeverFull() async {
        let buffer = UnboundedBuffer<Int>()
        let isFull = await buffer.isFull
        XCTAssertFalse(isFull)
    }

    func testBoundedBufferRespectsCapacity() async {
        let buffer = BoundedBuffer<Int>(capacity: 2)
        await buffer.enqueue(1)
        await buffer.enqueue(2)
        let value = await buffer.dequeue()
        XCTAssertEqual(value, 1)
    }

    func testDroppingBufferDropsOldestWhenFull() async {
        let buffer = DroppingBuffer<Int>(capacity: 2)
        await buffer.enqueue(1)
        await buffer.enqueue(2)
        await buffer.enqueue(3)
        let value = await buffer.dequeue()
        XCTAssertEqual(value, 2)
    }

    func testBufferClear() async {
        let buffer = UnboundedBuffer<Int>()
        await buffer.enqueue(1)
        await buffer.enqueue(2)
        await buffer.clear()
        let isEmpty = await buffer.isEmpty
        XCTAssertTrue(isEmpty)
    }
}

// MARK: - Metrics Tests

final class CQRSMetricsTests: XCTestCase {

    func testCanRecordAndRetrieveErrors() async {
        let metrics = CQRSMetrics()
        let count = await metrics.getErrorCount(for: "TestHandler")
        XCTAssertEqual(count, 0)
    }

    func testGeneratesReport() async {
        let metrics = CQRSMetrics()
        let report = await metrics.generateReport()
        XCTAssertTrue(report.queryStats.isEmpty)
        XCTAssertTrue(report.commandStats.isEmpty)
    }

    func testRecordCacheHitAndMiss() async {
        let metrics = CQRSMetrics()
        await metrics.recordCacheHit(queryType: "TestQuery")
        await metrics.recordCacheMiss(queryType: "TestQuery")
        let cacheMetrics = await metrics.getCacheMetrics(for: "TestQuery")
        XCTAssertNotNil(cacheMetrics)
        XCTAssertEqual(cacheMetrics?.hits, 1)
        XCTAssertEqual(cacheMetrics?.misses, 1)
    }
}

final class CacheMetricsTests: XCTestCase {

    func testTracksHitsAndMisses() {
        var metrics = CacheMetrics(handlerType: "TestQuery")
        metrics.recordHit()
        metrics.recordMiss()
        XCTAssertEqual(metrics.hits, 1)
        XCTAssertEqual(metrics.misses, 1)
        XCTAssertEqual(metrics.totalAccesses, 2)
    }

    func testHitRatio() {
        var metrics = CacheMetrics(handlerType: "TestQuery")
        metrics.recordHit()
        metrics.recordHit()
        metrics.recordMiss()
        XCTAssertGreaterThan(metrics.hitRatio, 0.6)
        XCTAssertLessThan(metrics.hitRatio, 0.7)
    }

    func testReset() {
        var metrics = CacheMetrics(handlerType: "TestQuery")
        metrics.recordHit()
        metrics.recordMiss()
        metrics.reset()
        XCTAssertEqual(metrics.hits, 0)
        XCTAssertEqual(metrics.misses, 0)
    }
}

// MARK: - ReadModelStore Tests

final class ReadModelStoreTests: XCTestCase {

    func testSaveAndGet() async {
        let store = ReadModelStore<TestReadModel>(loggingEnabled: false)
        let model = TestReadModel(id: "1", name: "Test")
        await store.save(model)
        let retrieved = await store.get(id: "1")
        XCTAssertEqual(retrieved?.name, "Test")
    }

    func testReturnsNilForMissingKeys() async {
        let store = ReadModelStore<TestReadModel>(loggingEnabled: false)
        let value = await store.get(id: "missing")
        XCTAssertNil(value)
    }

    func testCanInvalidate() async {
        let store = ReadModelStore<TestReadModel>(loggingEnabled: false)
        let model = TestReadModel(id: "1", name: "Test")
        await store.save(model)
        let removed = await store.invalidate(id: "1")
        XCTAssertTrue(removed)
        let value = await store.get(id: "1")
        XCTAssertNil(value)
    }

    func testTracksCount() async {
        let store = ReadModelStore<TestReadModel>(loggingEnabled: false)
        await store.save(TestReadModel(id: "1", name: "A"))
        await store.save(TestReadModel(id: "2", name: "B"))
        let count = await store.count
        XCTAssertEqual(count, 2)
    }

    func testInvalidateByTag() async {
        let store = ReadModelStore<TestReadModel>(loggingEnabled: false)
        await store.save(TestReadModel(id: "1", name: "A", tags: ["group1"]))
        await store.save(TestReadModel(id: "2", name: "B", tags: ["group1"]))
        await store.save(TestReadModel(id: "3", name: "C", tags: ["group2"]))
        let removed = await store.invalidateByTag("group1")
        XCTAssertEqual(removed, 2)
        let count = await store.count
        XCTAssertEqual(count, 1)
    }

    func testInvalidateAll() async {
        let store = ReadModelStore<TestReadModel>(loggingEnabled: false)
        await store.save(TestReadModel(id: "1", name: "A"))
        await store.save(TestReadModel(id: "2", name: "B"))
        await store.invalidateAll()
        let count = await store.count
        XCTAssertEqual(count, 0)
    }
}

// MARK: - AnyDomainEvent Tests

final class AnyDomainEventTests: XCTestCase {

    func testWrapsAndUnwraps() {
        let original = TestEvent(message: "wrapped")
        let any = AnyDomainEvent(original)
        XCTAssertEqual(any.eventType, "TestEvent")

        let unwrapped = any.unwrap(as: TestEvent.self)
        XCTAssertNotNil(unwrapped)
        XCTAssertEqual(unwrapped?.message, "wrapped")
    }

    func testUnwrapReturnsNilForWrongType() {
        let event = TestEvent(message: "test")
        let any = AnyDomainEvent(event)
        // Use a different DomainEvent type to test wrong type unwrap
        struct OtherEvent: DomainEvent {
            let eventId = UUID()
            let occurredAt = Date()
        }
        let wrong = any.unwrap(as: OtherEvent.self)
        XCTAssertNil(wrong)
    }
}
