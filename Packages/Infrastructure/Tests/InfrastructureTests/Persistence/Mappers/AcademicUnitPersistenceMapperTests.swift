import Testing
import Foundation
import SwiftData
import EduCore
import EduFoundation
@testable import EduPersistence

@Suite("AcademicUnitPersistenceMapper Tests")
struct AcademicUnitPersistenceMapperTests {

    // MARK: - Roundtrip Tests

    @Test("Domain to Model to Domain roundtrip produces identical unit")
    func testRoundtrip() throws {
        let schoolID = UUID()
        let createdAt = Date()
        let updatedAt = Date()
        let original = try TestDataFactory.makeAcademicUnit(
            displayName: "Grade 5",
            type: .grade,
            schoolID: schoolID,
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        // Domain -> Model
        let model = AcademicUnitPersistenceMapper.toModel(original, existing: nil)

        // Model -> Domain
        let restored = try AcademicUnitPersistenceMapper.toDomain(model)

        #expect(restored.id == original.id)
        #expect(restored.displayName == original.displayName)
        #expect(restored.type == original.type)
        #expect(restored.schoolID == original.schoolID)
        #expect(restored.createdAt == original.createdAt)
        #expect(restored.updatedAt == original.updatedAt)
    }

    @Test("Roundtrip preserves all unit types")
    func testRoundtripPreservesUnitTypes() throws {
        let types: [AcademicUnitType] = [.grade, .section, .club, .department, .course]

        for unitType in types {
            let original = try TestDataFactory.makeAcademicUnit(type: unitType)
            let model = AcademicUnitPersistenceMapper.toModel(original, existing: nil)
            let restored = try AcademicUnitPersistenceMapper.toDomain(model)

            #expect(restored.type == unitType)
        }
    }

    @Test("Roundtrip preserves timestamps")
    func testRoundtripPreservesTimestamps() throws {
        let createdAt = Date(timeIntervalSince1970: 1000000)
        let updatedAt = Date(timeIntervalSince1970: 2000000)
        let original = try TestDataFactory.makeAcademicUnit(
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        let model = AcademicUnitPersistenceMapper.toModel(original, existing: nil)
        let restored = try AcademicUnitPersistenceMapper.toDomain(model)

        #expect(restored.createdAt == createdAt)
        #expect(restored.updatedAt == updatedAt)
    }

    @Test("Roundtrip preserves metadata")
    func testRoundtripPreservesMetadata() throws {
        let metadata: [String: JSONValue] = [
            "capacity": .integer(30),
            "room": .string("101"),
            "active": .bool(true)
        ]
        let original = try AcademicUnit(
            displayName: "Grade 5 - Section A",
            type: .section,
            schoolID: UUID(),
            metadata: metadata
        )

        let model = AcademicUnitPersistenceMapper.toModel(original, existing: nil)
        let restored = try AcademicUnitPersistenceMapper.toDomain(model)

        #expect(restored.metadata == metadata)
    }

    // MARK: - toModel Tests

    @Test("toModel creates new model when existing is nil")
    func testToModelCreatesNew() throws {
        let unit = try TestDataFactory.makeAcademicUnit()

        let model = AcademicUnitPersistenceMapper.toModel(unit, existing: nil)

        #expect(model.id == unit.id)
        #expect(model.displayName == unit.displayName)
        #expect(model.type == unit.type.rawValue)
        #expect(model.schoolID == unit.schoolID)
    }

    @Test("toModel updates existing model in place")
    func testToModelUpdatesExisting() throws {
        let unit1 = try TestDataFactory.makeAcademicUnit(displayName: "Original Unit")
        let existingModel = AcademicUnitPersistenceMapper.toModel(unit1, existing: nil)

        let newUpdatedAt = Date()
        let unit2 = try AcademicUnit(
            id: unit1.id,
            displayName: "Updated Unit",
            type: .section,
            parentUnitID: nil,
            schoolID: unit1.schoolID,
            createdAt: unit1.createdAt,
            updatedAt: newUpdatedAt
        )

        let updatedModel = AcademicUnitPersistenceMapper.toModel(unit2, existing: existingModel)

        // Should be the same instance
        #expect(updatedModel === existingModel)
        #expect(updatedModel.displayName == "Updated Unit")
        #expect(updatedModel.type == "section")
        #expect(updatedModel.updatedAt == newUpdatedAt)
    }

    @Test("toModel converts type enum to string")
    func testToModelConvertsTypeToString() throws {
        let unit = try TestDataFactory.makeAcademicUnit(type: .department)

        let model = AcademicUnitPersistenceMapper.toModel(unit, existing: nil)

        #expect(model.type == "department")
    }

    // MARK: - toDomain Tests

    @Test("toDomain creates valid domain unit")
    func testToDomainCreatesValidUnit() throws {
        let schoolID = UUID()
        let model = AcademicUnitModel(
            id: UUID(),
            displayName: "Test Unit",
            type: "grade",
            schoolID: schoolID
        )

        let unit = try AcademicUnitPersistenceMapper.toDomain(model)

        #expect(unit.id == model.id)
        #expect(unit.displayName == model.displayName)
        #expect(unit.type == .grade)
        #expect(unit.schoolID == schoolID)
    }

    @Test("toDomain throws for empty displayName")
    func testToDomainThrowsForEmptyDisplayName() {
        let model = AcademicUnitModel(
            id: UUID(),
            displayName: "",
            type: "grade",
            schoolID: UUID()
        )

        #expect(throws: DomainError.self) {
            _ = try AcademicUnitPersistenceMapper.toDomain(model)
        }
    }

    @Test("toDomain throws for unknown type")
    func testToDomainThrowsForUnknownType() {
        let model = AcademicUnitModel(
            id: UUID(),
            displayName: "Test Unit",
            type: "unknown_type",
            schoolID: UUID()
        )

        #expect(throws: DomainError.self) {
            _ = try AcademicUnitPersistenceMapper.toDomain(model)
        }
    }

    @Test("toDomain converts all known type strings")
    func testToDomainConvertsAllKnownTypes() throws {
        let typeMapping: [(String, AcademicUnitType)] = [
            ("grade", .grade),
            ("section", .section),
            ("club", .club),
            ("department", .department),
            ("course", .course)
        ]

        for (typeString, expectedType) in typeMapping {
            let model = AcademicUnitModel(
                id: UUID(),
                displayName: "Test Unit",
                type: typeString,
                schoolID: UUID()
            )

            let unit = try AcademicUnitPersistenceMapper.toDomain(model)

            #expect(unit.type == expectedType)
        }
    }

    // MARK: - Extended Persistence Tests

    @Test("Roundtrip with unit hierarchy preserves schoolID")
    func testRoundtripWithHierarchy() throws {
        let schoolID = UUID()
        let parentUnit = try TestDataFactory.makeAcademicUnit(
            displayName: "Parent Grade",
            type: .grade,
            schoolID: schoolID
        )
        let childUnit = try TestDataFactory.makeAcademicUnit(
            displayName: "Child Section",
            type: .section,
            schoolID: schoolID,
            parentUnitID: parentUnit.id
        )

        let model = AcademicUnitPersistenceMapper.toModel(childUnit, existing: nil)
        let restored = try AcademicUnitPersistenceMapper.toDomain(model)

        // Note: parentUnitID is derived from parentUnit relationship in SwiftData,
        // so it won't be preserved in direct mapper roundtrip without persistence.
        // This test validates that other fields are preserved correctly.
        #expect(restored.schoolID == schoolID)
        #expect(restored.displayName == childUnit.displayName)
        #expect(restored.type == childUnit.type)
    }

    @Test("Roundtrip with unit metadata")
    func testRoundtripWithMetadata() throws {
        let original = try TestDataFactory.makeAcademicUnitWithMetadata()

        let model = AcademicUnitPersistenceMapper.toModel(original, existing: nil)
        let restored = try AcademicUnitPersistenceMapper.toDomain(model)

        #expect(restored.metadata == original.metadata)
    }

    @Test("Multiple roundtrips produce consistent results")
    func testMultipleRoundtrips() throws {
        let original = try TestDataFactory.makeAcademicUnit(displayName: "Roundtrip Unit")

        var current = original
        for _ in 0..<5 {
            let model = AcademicUnitPersistenceMapper.toModel(current, existing: nil)
            current = try AcademicUnitPersistenceMapper.toDomain(model)
        }

        #expect(current.id == original.id)
        #expect(current.displayName == original.displayName)
        #expect(current.type == original.type)
        #expect(current.schoolID == original.schoolID)
    }

    @Test("Batch academic unit mapping maintains data integrity")
    func testBatchAcademicUnitMapping() throws {
        let schoolID = UUID()
        let units = try TestDataFactory.makeAcademicUnits(count: 50, schoolID: schoolID)

        let models = units.map { AcademicUnitPersistenceMapper.toModel($0, existing: nil) }
        let restored = try models.map { try AcademicUnitPersistenceMapper.toDomain($0) }

        #expect(restored.count == units.count)
        for (original, mapped) in zip(units, restored) {
            #expect(mapped.id == original.id)
            #expect(mapped.displayName == original.displayName)
            #expect(mapped.type == original.type)
            #expect(mapped.schoolID == original.schoolID)
        }
    }

    @Test("Roundtrip preserves all types with factory")
    func testRoundtripAllTypesWithFactory() throws {
        let schoolID = UUID()
        let units = try TestDataFactory.makeAcademicUnitsWithAllTypes(schoolID: schoolID)

        for original in units {
            let model = AcademicUnitPersistenceMapper.toModel(original, existing: nil)
            let restored = try AcademicUnitPersistenceMapper.toDomain(model)

            #expect(restored.type == original.type)
        }
    }

    @Test("toModel preserves instance across updates")
    func testToModelPreservesInstance() throws {
        let unit1 = try TestDataFactory.makeAcademicUnit(displayName: "Original Unit", type: .grade)
        let existingModel = AcademicUnitPersistenceMapper.toModel(unit1, existing: nil)
        let originalModelID = ObjectIdentifier(existingModel)

        let unit2 = try AcademicUnit(
            id: unit1.id,
            displayName: "Updated Unit",
            type: .section,
            parentUnitID: nil,
            schoolID: unit1.schoolID,
            createdAt: unit1.createdAt,
            updatedAt: Date()
        )

        let updatedModel = AcademicUnitPersistenceMapper.toModel(unit2, existing: existingModel)

        #expect(ObjectIdentifier(updatedModel) == originalModelID)
        #expect(updatedModel.displayName == "Updated Unit")
        #expect(updatedModel.type == "section")
    }

    @Test("Roundtrip preserves exact timestamp precision")
    func testRoundtripPreservesTimestampPrecision() throws {
        let preciseCreatedAt = Date(timeIntervalSince1970: 1704067200.123456)
        let preciseUpdatedAt = Date(timeIntervalSince1970: 1704153600.789012)

        let original = try TestDataFactory.makeAcademicUnit(
            createdAt: preciseCreatedAt,
            updatedAt: preciseUpdatedAt
        )

        let model = AcademicUnitPersistenceMapper.toModel(original, existing: nil)
        let restored = try AcademicUnitPersistenceMapper.toDomain(model)

        #expect(restored.createdAt.timeIntervalSince1970 == preciseCreatedAt.timeIntervalSince1970)
        #expect(restored.updatedAt.timeIntervalSince1970 == preciseUpdatedAt.timeIntervalSince1970)
    }

    @Test("toDomain with case-sensitive type strings")
    func testToDomainCaseSensitiveType() {
        let model = AcademicUnitModel(
            id: UUID(),
            displayName: "Test Unit",
            type: "GRADE",
            schoolID: UUID()
        )

        #expect(throws: DomainError.self) {
            _ = try AcademicUnitPersistenceMapper.toDomain(model)
        }
    }

    @Test("toDomain handles whitespace in displayName")
    func testToDomainHandlesWhitespaceInDisplayName() {
        let model = AcademicUnitModel(
            id: UUID(),
            displayName: "   ",
            type: "grade",
            schoolID: UUID()
        )

        #expect(throws: DomainError.self) {
            _ = try AcademicUnitPersistenceMapper.toDomain(model)
        }
    }

    @Test("Roundtrip preserves complex metadata")
    func testRoundtripComplexMetadata() throws {
        let metadata: [String: JSONValue] = [
            "capacity": .integer(30),
            "room_number": .string("101A"),
            "is_computer_lab": .bool(true),
            "schedule": .array([.string("Mon"), .string("Wed"), .string("Fri")]),
            "teachers": .object([
                "main": .string("Prof. Smith"),
                "assistant": .string("Ms. Johnson")
            ])
        ]

        let original = try AcademicUnit(
            displayName: "Computer Science Lab",
            type: .course,
            schoolID: UUID(),
            metadata: metadata
        )

        let model = AcademicUnitPersistenceMapper.toModel(original, existing: nil)
        let restored = try AcademicUnitPersistenceMapper.toDomain(model)

        #expect(restored.metadata == metadata)
    }
}
