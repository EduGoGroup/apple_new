import Testing
import Foundation
import SwiftData
import EduCore
import EduFoundation
@testable import EduPersistence

@Suite("SchoolPersistenceMapper Tests")
struct SchoolPersistenceMapperTests {

    // MARK: - Roundtrip Tests

    @Test("Domain to Model to Domain roundtrip produces identical school")
    func testRoundtrip() throws {
        let createdAt = Date()
        let updatedAt = Date()
        let original = try TestDataFactory.makeSchool(
            name: "Test Academy",
            code: "TA001",
            isActive: true,
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        // Domain -> Model
        let model = SchoolPersistenceMapper.toModel(original, existing: nil)

        // Model -> Domain
        let restored = try SchoolPersistenceMapper.toDomain(model)

        #expect(restored.id == original.id)
        #expect(restored.name == original.name)
        #expect(restored.code == original.code)
        #expect(restored.isActive == original.isActive)
        #expect(restored.createdAt == original.createdAt)
        #expect(restored.updatedAt == original.updatedAt)
    }

    @Test("Roundtrip with inactive school")
    func testRoundtripInactiveSchool() throws {
        let original = try TestDataFactory.makeSchool(isActive: false)

        let model = SchoolPersistenceMapper.toModel(original, existing: nil)
        let restored = try SchoolPersistenceMapper.toDomain(model)

        #expect(restored.isActive == false)
    }

    @Test("Roundtrip preserves all timestamps")
    func testRoundtripPreservesTimestamps() throws {
        let createdAt = Date(timeIntervalSince1970: 1000000)
        let updatedAt = Date(timeIntervalSince1970: 2000000)
        let original = try TestDataFactory.makeSchool(
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        let model = SchoolPersistenceMapper.toModel(original, existing: nil)
        let restored = try SchoolPersistenceMapper.toDomain(model)

        #expect(restored.createdAt == createdAt)
        #expect(restored.updatedAt == updatedAt)
    }

    @Test("Roundtrip preserves metadata")
    func testRoundtripPreservesMetadata() throws {
        let metadata: [String: JSONValue] = [
            "founded": .integer(1990),
            "public": .bool(true),
            "motto": .string("Learning is fun")
        ]
        let original = try School(
            name: "Metadata School",
            code: "META-001",
            metadata: metadata
        )

        let model = SchoolPersistenceMapper.toModel(original, existing: nil)
        let restored = try SchoolPersistenceMapper.toDomain(model)

        #expect(restored.metadata == metadata)
    }

    // MARK: - toModel Tests

    @Test("toModel creates new model when existing is nil")
    func testToModelCreatesNew() throws {
        let school = try TestDataFactory.makeSchool()

        let model = SchoolPersistenceMapper.toModel(school, existing: nil)

        #expect(model.id == school.id)
        #expect(model.name == school.name)
        #expect(model.code == school.code)
    }

    @Test("toModel updates existing model in place")
    func testToModelUpdatesExisting() throws {
        let school1 = try TestDataFactory.makeSchool(name: "Original School")
        let existingModel = SchoolPersistenceMapper.toModel(school1, existing: nil)

        let newUpdatedAt = Date()
        let school2 = try School(
            id: school1.id,
            name: "Updated School",
            code: school1.code,
            isActive: false,
            createdAt: school1.createdAt,
            updatedAt: newUpdatedAt
        )

        let updatedModel = SchoolPersistenceMapper.toModel(school2, existing: existingModel)

        // Should be the same instance
        #expect(updatedModel === existingModel)
        #expect(updatedModel.name == "Updated School")
        #expect(updatedModel.isActive == false)
        #expect(updatedModel.updatedAt == newUpdatedAt)
    }

    @Test("toModel preserves createdAt when updating")
    func testToModelPreservesCreatedAt() throws {
        let originalCreatedAt = Date(timeIntervalSince1970: 1000000)
        let school1 = try TestDataFactory.makeSchool(createdAt: originalCreatedAt)
        let existingModel = SchoolPersistenceMapper.toModel(school1, existing: nil)

        let school2 = try School(
            id: school1.id,
            name: "Updated School",
            code: school1.code,
            isActive: true,
            createdAt: originalCreatedAt,
            updatedAt: Date()
        )

        let updatedModel = SchoolPersistenceMapper.toModel(school2, existing: existingModel)

        #expect(updatedModel.createdAt == originalCreatedAt)
    }

    // MARK: - toDomain Tests

    @Test("toDomain creates valid domain school")
    func testToDomainCreatesValidSchool() throws {
        let model = SchoolModel(
            id: UUID(),
            name: "Test School",
            code: "TS001",
            isActive: true
        )

        let school = try SchoolPersistenceMapper.toDomain(model)

        #expect(school.id == model.id)
        #expect(school.name == model.name)
        #expect(school.code == model.code)
        #expect(school.isActive == model.isActive)
    }

    @Test("toDomain throws for empty name")
    func testToDomainThrowsForEmptyName() {
        let model = SchoolModel(
            id: UUID(),
            name: "",
            code: "TS001",
            isActive: true
        )

        #expect(throws: DomainError.self) {
            _ = try SchoolPersistenceMapper.toDomain(model)
        }
    }

    @Test("toDomain throws for empty code")
    func testToDomainThrowsForEmptyCode() {
        let model = SchoolModel(
            id: UUID(),
            name: "Test School",
            code: "",
            isActive: true
        )

        #expect(throws: DomainError.self) {
            _ = try SchoolPersistenceMapper.toDomain(model)
        }
    }

    @Test("toDomain handles optional properties")
    func testToDomainHandlesOptionalProperties() throws {
        let model = SchoolModel(
            id: UUID(),
            name: "Test School",
            code: "TS001",
            isActive: true,
            address: "123 Main St",
            city: "Test City",
            country: "Test Country",
            contactEmail: "school@example.com",
            contactPhone: "+1234567890",
            maxStudents: 500,
            maxTeachers: 50,
            subscriptionTier: "premium"
        )

        let school = try SchoolPersistenceMapper.toDomain(model)

        #expect(school.address == "123 Main St")
        #expect(school.city == "Test City")
        #expect(school.country == "Test Country")
        #expect(school.contactEmail == "school@example.com")
        #expect(school.contactPhone == "+1234567890")
        #expect(school.maxStudents == 500)
        #expect(school.maxTeachers == 50)
        #expect(school.subscriptionTier == "premium")
    }

    // MARK: - Extended Persistence Tests

    @Test("Roundtrip with full school")
    func testRoundtripFullSchool() throws {
        let original = try TestDataFactory.makeFullSchool()

        let model = SchoolPersistenceMapper.toModel(original, existing: nil)
        let restored = try SchoolPersistenceMapper.toDomain(model)

        #expect(restored.id == original.id)
        #expect(restored.name == original.name)
        #expect(restored.code == original.code)
        #expect(restored.address == original.address)
        #expect(restored.city == original.city)
        #expect(restored.country == original.country)
        #expect(restored.contactEmail == original.contactEmail)
        #expect(restored.contactPhone == original.contactPhone)
        #expect(restored.maxStudents == original.maxStudents)
        #expect(restored.maxTeachers == original.maxTeachers)
        #expect(restored.subscriptionTier == original.subscriptionTier)
        #expect(restored.metadata == original.metadata)
    }

    @Test("Roundtrip with minimal school")
    func testRoundtripMinimalSchool() throws {
        let original = try TestDataFactory.makeMinimalSchool()

        let model = SchoolPersistenceMapper.toModel(original, existing: nil)
        let restored = try SchoolPersistenceMapper.toDomain(model)

        #expect(restored.id == original.id)
        #expect(restored.name == original.name)
        #expect(restored.code == original.code)
    }

    @Test("Multiple roundtrips produce consistent results")
    func testMultipleRoundtrips() throws {
        let original = try TestDataFactory.makeSchool(name: "Roundtrip School")

        var current = original
        for _ in 0..<5 {
            let model = SchoolPersistenceMapper.toModel(current, existing: nil)
            current = try SchoolPersistenceMapper.toDomain(model)
        }

        #expect(current.id == original.id)
        #expect(current.name == original.name)
        #expect(current.code == original.code)
        #expect(current.isActive == original.isActive)
    }

    @Test("Batch school mapping maintains data integrity")
    func testBatchSchoolMapping() throws {
        let schools = try TestDataFactory.makeSchools(count: 50)

        let models = schools.map { SchoolPersistenceMapper.toModel($0, existing: nil) }
        let restored = try models.map { try SchoolPersistenceMapper.toDomain($0) }

        #expect(restored.count == schools.count)
        for (original, mapped) in zip(schools, restored) {
            #expect(mapped.id == original.id)
            #expect(mapped.name == original.name)
            #expect(mapped.code == original.code)
        }
    }

    @Test("toModel preserves instance across updates")
    func testToModelPreservesInstance() throws {
        let school1 = try TestDataFactory.makeSchool(name: "Original School", isActive: true)
        let existingModel = SchoolPersistenceMapper.toModel(school1, existing: nil)
        let originalModelID = ObjectIdentifier(existingModel)

        let school2 = try School(
            id: school1.id,
            name: "Updated School",
            code: school1.code,
            isActive: false,
            createdAt: school1.createdAt,
            updatedAt: Date()
        )

        let updatedModel = SchoolPersistenceMapper.toModel(school2, existing: existingModel)

        #expect(ObjectIdentifier(updatedModel) == originalModelID)
        #expect(updatedModel.name == "Updated School")
        #expect(updatedModel.isActive == false)
    }

    @Test("Roundtrip preserves exact timestamp precision")
    func testRoundtripPreservesTimestampPrecision() throws {
        let preciseCreatedAt = Date(timeIntervalSince1970: 1704067200.123456)
        let preciseUpdatedAt = Date(timeIntervalSince1970: 1704153600.789012)

        let original = try TestDataFactory.makeSchool(
            createdAt: preciseCreatedAt,
            updatedAt: preciseUpdatedAt
        )

        let model = SchoolPersistenceMapper.toModel(original, existing: nil)
        let restored = try SchoolPersistenceMapper.toDomain(model)

        #expect(restored.createdAt.timeIntervalSince1970 == preciseCreatedAt.timeIntervalSince1970)
        #expect(restored.updatedAt.timeIntervalSince1970 == preciseUpdatedAt.timeIntervalSince1970)
    }

    @Test("Roundtrip preserves complex metadata")
    func testRoundtripComplexMetadata() throws {
        let metadata: [String: JSONValue] = [
            "string_value": .string("test"),
            "integer_value": .integer(42),
            "bool_value": .bool(true),
            "null_value": .null,
            "array_value": .array([.integer(1), .integer(2), .integer(3)]),
            "nested_object": .object([
                "inner_key": .string("inner_value"),
                "inner_number": .integer(100)
            ])
        ]

        let original = try School(
            name: "Metadata School",
            code: "META-001",
            metadata: metadata
        )

        let model = SchoolPersistenceMapper.toModel(original, existing: nil)
        let restored = try SchoolPersistenceMapper.toDomain(model)

        #expect(restored.metadata == metadata)
    }

    @Test("toDomain handles whitespace in name")
    func testToDomainHandlesWhitespaceInName() {
        let model = SchoolModel(
            id: UUID(),
            name: "   ",
            code: "TS001",
            isActive: true
        )

        #expect(throws: DomainError.self) {
            _ = try SchoolPersistenceMapper.toDomain(model)
        }
    }

    @Test("toDomain handles whitespace in code")
    func testToDomainHandlesWhitespaceInCode() {
        let model = SchoolModel(
            id: UUID(),
            name: "Test School",
            code: "   ",
            isActive: true
        )

        #expect(throws: DomainError.self) {
            _ = try SchoolPersistenceMapper.toDomain(model)
        }
    }
}
