import Testing
import Foundation
import SwiftData
import EduCore
import EduFoundation
@testable import EduPersistence

@Suite("LocalAcademicUnitRepository Tests", .serialized)
struct LocalAcademicUnitRepositoryTests {
    // MARK: - Setup Helper

    private func setupRepository() async throws -> LocalAcademicUnitRepository {
        let provider = PersistenceContainerProvider()
        try await provider.configure(
            with: .testing,
            schema: LocalPersistenceSchema.current
        )
        return LocalAcademicUnitRepository(containerProvider: provider)
    }

    // MARK: - CRUD Tests

    @Test("Save and get academic unit")
    func testSaveAndGet() async throws {
        let repository = try await setupRepository()
        let unit = try TestDataFactory.makeAcademicUnit(displayName: "Grade 10")

        try await repository.save(unit)
        let fetched = try await repository.get(id: unit.id)

        #expect(fetched != nil)
        #expect(fetched?.id == unit.id)
        #expect(fetched?.displayName == "Grade 10")
    }

    @Test("Get returns nil for non-existent unit")
    func testGetReturnsNilForNonExistent() async throws {
        let repository = try await setupRepository()

        let fetched = try await repository.get(id: UUID())

        #expect(fetched == nil)
    }

    @Test("List returns saved units")
    func testListReturnsSavedUnits() async throws {
        let repository = try await setupRepository()
        let unit1 = try TestDataFactory.makeAcademicUnit(displayName: "Unit One")
        let unit2 = try TestDataFactory.makeAcademicUnit(displayName: "Unit Two")

        try await repository.save(unit1)
        try await repository.save(unit2)

        let listed = try await repository.list()

        #expect(listed.contains { $0.id == unit1.id })
        #expect(listed.contains { $0.id == unit2.id })
    }

    @Test("Delete removes unit")
    func testDeleteRemovesUnit() async throws {
        let repository = try await setupRepository()
        let unit = try TestDataFactory.makeAcademicUnit()

        try await repository.save(unit)
        try await repository.delete(id: unit.id)

        let fetched = try await repository.get(id: unit.id)
        #expect(fetched == nil)
    }

    @Test("Delete throws for non-existent unit")
    func testDeleteThrowsForNonExistent() async throws {
        let repository = try await setupRepository()

        do {
            try await repository.delete(id: UUID())
            Issue.record("Expected deleteFailed error")
        } catch let error as RepositoryError {
            if case .deleteFailed = error {
                // Expected
            } else {
                Issue.record("Expected deleteFailed, got \(error)")
            }
        }
    }

    // MARK: - Upsert Tests

    @Test("Save same unit twice updates instead of duplicating")
    func testUpsertUpdatesExisting() async throws {
        let repository = try await setupRepository()
        let unit = try TestDataFactory.makeAcademicUnit(displayName: "Original")

        try await repository.save(unit)

        let updatedUnit = try AcademicUnit(
            id: unit.id,
            displayName: "Updated",
            type: unit.type,
            parentUnitID: unit.parentUnitID,
            schoolID: unit.schoolID,
            createdAt: unit.createdAt,
            updatedAt: Date()
        )
        try await repository.save(updatedUnit)

        let fetched = try await repository.get(id: unit.id)
        #expect(fetched?.displayName == "Updated")
    }

    // MARK: - Query Tests

    @Test("List by school returns only units for that school")
    func testListBySchool() async throws {
        let repository = try await setupRepository()
        let schoolID = UUID()
        let otherSchoolID = UUID()

        let unit1 = try TestDataFactory.makeAcademicUnit(displayName: "School Unit", schoolID: schoolID)
        let unit2 = try TestDataFactory.makeAcademicUnit(displayName: "Other Unit", schoolID: otherSchoolID)

        try await repository.save(unit1)
        try await repository.save(unit2)

        let schoolUnits = try await repository.listBySchool(schoolID: schoolID)

        #expect(schoolUnits.count == 1)
        #expect(schoolUnits.first?.id == unit1.id)
    }

    @Test("List roots returns only units without parent")
    func testListRoots() async throws {
        let repository = try await setupRepository()
        let schoolID = UUID()

        let rootUnit = try TestDataFactory.makeAcademicUnit(
            displayName: "Root Unit",
            schoolID: schoolID,
            parentUnitID: nil
        )

        try await repository.save(rootUnit)

        let roots = try await repository.listRoots(schoolID: schoolID)

        #expect(roots.count == 1)
        #expect(roots.first?.id == rootUnit.id)
    }

    // MARK: - Extended Repository Tests

    @Test("Save and retrieve units with all types")
    func testSaveAndRetrieveAllTypes() async throws {
        let repository = try await setupRepository()
        let schoolID = UUID()
        let units = try TestDataFactory.makeAcademicUnitsWithAllTypes(schoolID: schoolID)

        for unit in units {
            try await repository.save(unit)
        }

        let schoolUnits = try await repository.listBySchool(schoolID: schoolID)

        #expect(schoolUnits.count == units.count)
        for unit in units {
            #expect(schoolUnits.contains { $0.type == unit.type })
        }
    }

    @Test("Batch save and verify units")
    func testBatchSaveAndVerify() async throws {
        let repository = try await setupRepository()
        let schoolID = UUID()
        let units = try TestDataFactory.makeAcademicUnits(count: 50, schoolID: schoolID)

        for unit in units {
            try await repository.save(unit)
        }

        for unit in units {
            let fetched = try await repository.get(id: unit.id)
            #expect(fetched != nil)
            #expect(fetched?.id == unit.id)
            #expect(fetched?.displayName == unit.displayName)
        }
    }

    @Test("Save and retrieve unit with metadata")
    func testSaveAndRetrieveUnitWithMetadata() async throws {
        let repository = try await setupRepository()
        let unit = try TestDataFactory.makeAcademicUnitWithMetadata()

        try await repository.save(unit)
        let fetched = try await repository.get(id: unit.id)

        #expect(fetched != nil)
        #expect(fetched?.metadata == unit.metadata)
    }

    @Test("List children returns only child units")
    func testListChildrenReturnsOnlyChildUnits() async throws {
        let repository = try await setupRepository()
        let schoolID = UUID()

        let parentUnit = try TestDataFactory.makeAcademicUnit(
            displayName: "Parent Grade",
            type: .grade,
            schoolID: schoolID
        )

        let child1 = try TestDataFactory.makeAcademicUnit(
            displayName: "Section A",
            type: .section,
            schoolID: schoolID,
            parentUnitID: parentUnit.id
        )

        let child2 = try TestDataFactory.makeAcademicUnit(
            displayName: "Section B",
            type: .section,
            schoolID: schoolID,
            parentUnitID: parentUnit.id
        )

        let unrelatedUnit = try TestDataFactory.makeAcademicUnit(
            displayName: "Other Grade",
            type: .grade,
            schoolID: schoolID
        )

        try await repository.save(parentUnit)
        try await repository.save(child1)
        try await repository.save(child2)
        try await repository.save(unrelatedUnit)

        let children = try await repository.listChildren(parentID: parentUnit.id)

        #expect(children.count == 2)
        #expect(children.contains { $0.id == child1.id })
        #expect(children.contains { $0.id == child2.id })
        #expect(!children.contains { $0.id == unrelatedUnit.id })
    }

    @Test("List roots with hierarchy")
    func testListRootsWithHierarchy() async throws {
        let repository = try await setupRepository()
        let schoolID = UUID()

        let root1 = try TestDataFactory.makeAcademicUnit(
            displayName: "Grade 1",
            type: .grade,
            schoolID: schoolID,
            parentUnitID: nil
        )

        let root2 = try TestDataFactory.makeAcademicUnit(
            displayName: "Grade 2",
            type: .grade,
            schoolID: schoolID,
            parentUnitID: nil
        )

        let childOfRoot1 = try TestDataFactory.makeAcademicUnit(
            displayName: "Section 1-A",
            type: .section,
            schoolID: schoolID,
            parentUnitID: root1.id
        )

        try await repository.save(root1)
        try await repository.save(root2)
        try await repository.save(childOfRoot1)

        let roots = try await repository.listRoots(schoolID: schoolID)

        #expect(roots.count == 2)
        #expect(roots.contains { $0.id == root1.id })
        #expect(roots.contains { $0.id == root2.id })
        #expect(!roots.contains { $0.id == childOfRoot1.id })
    }

    @Test("Update unit type")
    func testUpdateUnitType() async throws {
        let repository = try await setupRepository()
        let unit = try TestDataFactory.makeAcademicUnit(displayName: "Test Unit", type: .grade)

        try await repository.save(unit)

        let updatedUnit = try AcademicUnit(
            id: unit.id,
            displayName: unit.displayName,
            type: .section,
            parentUnitID: unit.parentUnitID,
            schoolID: unit.schoolID,
            createdAt: unit.createdAt,
            updatedAt: Date()
        )
        try await repository.save(updatedUnit)

        let fetched = try await repository.get(id: unit.id)
        #expect(fetched?.type == .section)
    }

    @Test("Delete unit from school list")
    func testDeleteUnitFromSchoolList() async throws {
        let repository = try await setupRepository()
        let schoolID = UUID()

        let unit1 = try TestDataFactory.makeAcademicUnit(displayName: "Unit 1", schoolID: schoolID)
        let unit2 = try TestDataFactory.makeAcademicUnit(displayName: "Unit 2", schoolID: schoolID)

        try await repository.save(unit1)
        try await repository.save(unit2)

        try await repository.delete(id: unit1.id)

        let schoolUnits = try await repository.listBySchool(schoolID: schoolID)

        #expect(schoolUnits.count == 1)
        #expect(schoolUnits.first?.id == unit2.id)
    }

    @Test("List returns empty array when no units exist")
    func testListReturnsEmptyArrayWhenNoUnits() async throws {
        let repository = try await setupRepository()

        let listed = try await repository.list()

        #expect(listed.isEmpty)
    }

    @Test("List by school with multiple unit types")
    func testListBySchoolWithMultipleUnitTypes() async throws {
        let repository = try await setupRepository()
        let schoolID = UUID()

        let grade = try TestDataFactory.makeAcademicUnit(displayName: "Grade 5", type: .grade, schoolID: schoolID)
        let section = try TestDataFactory.makeAcademicUnit(displayName: "Section A", type: .section, schoolID: schoolID)
        let club = try TestDataFactory.makeAcademicUnit(displayName: "Chess Club", type: .club, schoolID: schoolID)
        let department = try TestDataFactory.makeAcademicUnit(displayName: "Math Dept", type: .department, schoolID: schoolID)
        let course = try TestDataFactory.makeAcademicUnit(displayName: "Algebra", type: .course, schoolID: schoolID)

        try await repository.save(grade)
        try await repository.save(section)
        try await repository.save(club)
        try await repository.save(department)
        try await repository.save(course)

        let schoolUnits = try await repository.listBySchool(schoolID: schoolID)

        #expect(schoolUnits.count == 5)
        #expect(schoolUnits.contains { $0.type == .grade })
        #expect(schoolUnits.contains { $0.type == .section })
        #expect(schoolUnits.contains { $0.type == .club })
        #expect(schoolUnits.contains { $0.type == .department })
        #expect(schoolUnits.contains { $0.type == .course })
    }
}
