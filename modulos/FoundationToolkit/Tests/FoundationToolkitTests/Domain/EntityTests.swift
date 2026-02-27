import Testing
import Foundation
@testable import FoundationToolkit

/// Comprehensive test suite for the Entity protocol.
@Suite struct EntityTests {

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

    @Test func testEntityHasStableID() {
        let id = UUID()
        let entity = MockEntity(id: id)
        #expect(entity.id == id)
        #expect(entity.id == entity.id)
    }

    @Test func testDifferentEntitiesHaveUniqueIDs() {
        let entity1 = MockEntity()
        let entity2 = MockEntity()
        #expect(entity1.id != entity2.id)
    }

    @Test func testIDIsUUIDType() {
        let entity = MockEntity()
        #expect(type(of: entity.id) == UUID.self)
    }

    // MARK: - Equatable Tests

    @Test func testEntitiesWithSamePropertiesAreEqual() {
        let id = UUID()
        let date = Date()
        let e1 = MockEntity(id: id, createdAt: date, updatedAt: date, name: "A")
        let e2 = MockEntity(id: id, createdAt: date, updatedAt: date, name: "A")
        #expect(e1 == e2)
    }

    @Test func testEntitiesWithDifferentIDsAreNotEqual() {
        let date = Date()
        let e1 = MockEntity(id: UUID(), createdAt: date, updatedAt: date)
        let e2 = MockEntity(id: UUID(), createdAt: date, updatedAt: date)
        #expect(e1 != e2)
    }

    @Test func testEntitiesWithDifferentNamesAreNotEqual() {
        let id = UUID()
        let date = Date()
        let e1 = MockEntity(id: id, createdAt: date, updatedAt: date, name: "A")
        let e2 = MockEntity(id: id, createdAt: date, updatedAt: date, name: "B")
        #expect(e1 != e2)
    }

    @Test func testEqualityIsReflexive() {
        let entity = MockEntity()
        #expect(entity == entity)
    }

    @Test func testEqualityIsSymmetric() {
        let id = UUID()
        let date = Date()
        let e1 = MockEntity(id: id, createdAt: date, updatedAt: date)
        let e2 = MockEntity(id: id, createdAt: date, updatedAt: date)
        #expect(e1 == e2)
        #expect(e2 == e1)
    }

    // MARK: - Date Tests

    @Test func testEntityHasTimestamps() {
        let created = Date()
        let updated = Date()
        let entity = MockEntity(createdAt: created, updatedAt: updated)
        #expect(entity.createdAt == created)
        #expect(entity.updatedAt == updated)
    }

    @Test func testCreatedAtCanBePastDate() {
        let pastDate = Date(timeIntervalSince1970: 0)
        let entity = MockEntity(createdAt: pastDate)
        #expect(entity.createdAt == pastDate)
    }

    @Test func testUpdatedAtCanBeFutureDate() {
        let futureDate = Date(timeIntervalSinceNow: 86400 * 365)
        let entity = MockEntity(updatedAt: futureDate)
        #expect(entity.updatedAt == futureDate)
    }

    // MARK: - Sendable Tests (Concurrency)

    @Test func testEntityCanBeSentToActor() async {
        let entity = MockEntity(name: "Concurrent")
        let store = EntityStore()
        await store.store(entity)
        let retrieved = await store.retrieve(id: entity.id)
        #expect(retrieved == entity)
    }

    @Test func testEntityCanBeUsedInTask() async {
        let entity = MockEntity(name: "Task")
        let result = await Task { entity }.value
        #expect(result == entity)
    }

    @Test func testMultipleEntitiesProcessedConcurrently() async {
        let entities = (0..<Self.concurrentEntityCount).map { MockEntity(name: "E\($0)") }
        let store = EntityStore()

        await withTaskGroup(of: Void.self) { group in
            for entity in entities {
                group.addTask { await store.store(entity) }
            }
        }

        let count = await store.count()
        #expect(count == Self.concurrentEntityCount)
    }

    @Test func testEntityCanBeSharedBetweenTasks() async throws {
        let entity = MockEntity(name: "Shared")

        async let task1 = Task { entity.id }.value
        async let task2 = Task { entity.name }.value

        let (id, name) = try await (task1, task2)
        #expect(id == entity.id)
        #expect(name == entity.name)
    }

    // MARK: - Protocol Conformance

    @Test func testEntityConformsToIdentifiable() {
        let entity = MockEntity()
        #expect(entity is any Identifiable)
    }

    @Test func testEntityConformsToEquatable() {
        let entity = MockEntity()
        #expect(entity is any Equatable)
    }

    @Test func testEntityConformsToSendable() {
        func requiresSendable<T: Sendable>(_ value: T) {}
        let entity = MockEntity()
        requiresSendable(entity)
    }

    // MARK: - Edge Cases

    @Test func testEntityWithMinUUID() throws {
        let minUUID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
        let entity = MockEntity(id: minUUID)
        #expect(entity.id == minUUID)
    }

    @Test func testEntityWithMaxUUID() throws {
        let maxUUID = try #require(UUID(uuidString: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF"))
        let entity = MockEntity(id: maxUUID)
        #expect(entity.id == maxUUID)
    }

    @Test func testEntityInCollection() {
        let entities = [MockEntity(), MockEntity(), MockEntity()]
        let ids = entities.map(\.id)
        #expect(Set(ids).count == 3)
    }

    @Test func testEntityInDictionary() {
        let e1 = MockEntity(name: "E1")
        let e2 = MockEntity(name: "E2")
        var dict: [UUID: MockEntity] = [:]
        dict[e1.id] = e1
        dict[e2.id] = e2
        #expect(dict.count == 2)
        #expect(dict[e1.id] == e1)
    }

    @Test func testEntityCanBeFiltered() {
        let now = Date()
        let pastDate = Date(timeIntervalSince1970: 0)
        let entities = [
            MockEntity(createdAt: now, name: "Recent"),
            MockEntity(createdAt: pastDate, name: "Old"),
            MockEntity(createdAt: now, name: "Also Recent")
        ]
        let recentEntities = entities.filter { $0.createdAt > pastDate }
        #expect(recentEntities.count == 2)
    }
}
