import XCTest
import Foundation
@testable import FoundationToolkit

/// Comprehensive test suite for the Entity protocol.
final class EntityTests: XCTestCase {

    // MARK: - Constants

    private static let concurrentEntityCount = 50

    // MARK: - Test Fixtures

    private struct MockEntity: Entity {
        let id: UUID
        let createdAt: Date
        let updatedAt: Date
        let name: String

        init(id: UUID = UUID(), createdAt: Date = Date(), updatedAt: Date = Date(), name: String = "Test") {
            self.id = id
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.name = name
        }
    }

    private actor EntityStore {
        private var entities: [UUID: MockEntity] = [:]
        func store(_ entity: MockEntity) { entities[entity.id] = entity }
        func retrieve(id: UUID) -> MockEntity? { entities[id] }
        func count() -> Int { entities.count }
    }

    // MARK: - Identifiable Tests

    func testEntityHasStableID() {
        let id = UUID()
        let entity = MockEntity(id: id)
        XCTAssertEqual(entity.id, id)
        XCTAssertEqual(entity.id, entity.id)
    }

    func testDifferentEntitiesHaveUniqueIDs() {
        let entity1 = MockEntity()
        let entity2 = MockEntity()
        XCTAssertNotEqual(entity1.id, entity2.id)
    }

    func testIDIsUUIDType() {
        let entity = MockEntity()
        XCTAssertTrue(type(of: entity.id) == UUID.self)
    }

    // MARK: - Equatable Tests

    func testEntitiesWithSamePropertiesAreEqual() {
        let id = UUID()
        let date = Date()
        let e1 = MockEntity(id: id, createdAt: date, updatedAt: date, name: "A")
        let e2 = MockEntity(id: id, createdAt: date, updatedAt: date, name: "A")
        XCTAssertEqual(e1, e2)
    }

    func testEntitiesWithDifferentIDsAreNotEqual() {
        let date = Date()
        let e1 = MockEntity(id: UUID(), createdAt: date, updatedAt: date)
        let e2 = MockEntity(id: UUID(), createdAt: date, updatedAt: date)
        XCTAssertNotEqual(e1, e2)
    }

    func testEntitiesWithDifferentNamesAreNotEqual() {
        let id = UUID()
        let date = Date()
        let e1 = MockEntity(id: id, createdAt: date, updatedAt: date, name: "A")
        let e2 = MockEntity(id: id, createdAt: date, updatedAt: date, name: "B")
        XCTAssertNotEqual(e1, e2)
    }

    func testEqualityIsReflexive() {
        let entity = MockEntity()
        XCTAssertEqual(entity, entity)
    }

    func testEqualityIsSymmetric() {
        let id = UUID()
        let date = Date()
        let e1 = MockEntity(id: id, createdAt: date, updatedAt: date)
        let e2 = MockEntity(id: id, createdAt: date, updatedAt: date)
        XCTAssertEqual(e1, e2)
        XCTAssertEqual(e2, e1)
    }

    // MARK: - Date Tests

    func testEntityHasTimestamps() {
        let created = Date()
        let updated = Date()
        let entity = MockEntity(createdAt: created, updatedAt: updated)
        XCTAssertEqual(entity.createdAt, created)
        XCTAssertEqual(entity.updatedAt, updated)
    }

    func testCreatedAtCanBePastDate() {
        let pastDate = Date(timeIntervalSince1970: 0)
        let entity = MockEntity(createdAt: pastDate)
        XCTAssertEqual(entity.createdAt, pastDate)
    }

    func testUpdatedAtCanBeFutureDate() {
        let futureDate = Date(timeIntervalSinceNow: 86400 * 365)
        let entity = MockEntity(updatedAt: futureDate)
        XCTAssertEqual(entity.updatedAt, futureDate)
    }

    // MARK: - Sendable Tests (Concurrency)

    func testEntityCanBeSentToActor() async {
        let entity = MockEntity(name: "Concurrent")
        let store = EntityStore()
        await store.store(entity)
        let retrieved = await store.retrieve(id: entity.id)
        XCTAssertEqual(retrieved, entity)
    }

    func testEntityCanBeUsedInTask() async {
        let entity = MockEntity(name: "Task")
        let result = await Task { entity }.value
        XCTAssertEqual(result, entity)
    }

    func testMultipleEntitiesProcessedConcurrently() async {
        let entities = (0..<Self.concurrentEntityCount).map { MockEntity(name: "E\($0)") }
        let store = EntityStore()

        await withTaskGroup(of: Void.self) { group in
            for entity in entities {
                group.addTask { await store.store(entity) }
            }
        }

        let count = await store.count()
        XCTAssertEqual(count, Self.concurrentEntityCount)
    }

    func testEntityCanBeSharedBetweenTasks() async throws {
        let entity = MockEntity(name: "Shared")

        async let task1 = Task { entity.id }.value
        async let task2 = Task { entity.name }.value

        let (id, name) = try await (task1, task2)
        XCTAssertEqual(id, entity.id)
        XCTAssertEqual(name, entity.name)
    }

    // MARK: - Protocol Conformance

    func testEntityConformsToIdentifiable() {
        let entity = MockEntity()
        XCTAssertTrue(entity is any Identifiable)
    }

    func testEntityConformsToEquatable() {
        let entity = MockEntity()
        XCTAssertTrue(entity is any Equatable)
    }

    func testEntityConformsToSendable() {
        func requiresSendable<T: Sendable>(_ value: T) {}
        let entity = MockEntity()
        requiresSendable(entity)
    }

    // MARK: - Edge Cases

    func testEntityWithMinUUID() throws {
        let minUUID = try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
        let entity = MockEntity(id: minUUID)
        XCTAssertEqual(entity.id, minUUID)
    }

    func testEntityWithMaxUUID() throws {
        let maxUUID = try XCTUnwrap(UUID(uuidString: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF"))
        let entity = MockEntity(id: maxUUID)
        XCTAssertEqual(entity.id, maxUUID)
    }

    func testEntityInCollection() {
        let entities = [MockEntity(), MockEntity(), MockEntity()]
        let ids = entities.map(\.id)
        XCTAssertEqual(Set(ids).count, 3)
    }

    func testEntityInDictionary() {
        let e1 = MockEntity(name: "E1")
        let e2 = MockEntity(name: "E2")
        var dict: [UUID: MockEntity] = [:]
        dict[e1.id] = e1
        dict[e2.id] = e2
        XCTAssertEqual(dict.count, 2)
        XCTAssertEqual(dict[e1.id], e1)
    }

    func testEntityCanBeFiltered() {
        let now = Date()
        let pastDate = Date(timeIntervalSince1970: 0)
        let entities = [
            MockEntity(createdAt: now, name: "Recent"),
            MockEntity(createdAt: pastDate, name: "Old"),
            MockEntity(createdAt: now, name: "Also Recent")
        ]
        let recentEntities = entities.filter { $0.createdAt > pastDate }
        XCTAssertEqual(recentEntities.count, 2)
    }
}
