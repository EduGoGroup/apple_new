import Testing
import Foundation
@testable import EduModels

/// Integration tests for JSON serialization/deserialization of DTOs.
///
/// These tests validate that:
/// 1. JSON fixtures from swagger.json can be deserialized correctly
/// 2. DTOs serialize back to JSON with correct snake_case keys
/// 3. Full roundtrip (JSON → DTO → Domain → DTO → JSON) preserves data
@Suite("Model Serialization Integration Tests")
struct ModelSerializationTests {

    // MARK: - JSON Decoder/Encoder Setup

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    // MARK: - Helper to Load JSON Fixtures

    private func loadFixture(_ name: String) throws -> Data {
        guard let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "JSON") else {
            throw FixtureError.fileNotFound(name)
        }
        return try Data(contentsOf: url)
    }

    enum FixtureError: Error {
        case fileNotFound(String)
    }

    // MARK: - User Serialization Tests

    @Test("UserDTO deserializes from JSON fixture")
    func testUserDTODeserializesFromFixture() throws {
        let jsonData = try loadFixture("user_response")

        let dto = try decoder.decode(UserDTO.self, from: jsonData)

        #expect(dto.id == UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000"))
        #expect(dto.firstName == "John")
        #expect(dto.lastName == "Doe")
        #expect(dto.fullName == "John Doe")
        #expect(dto.email == "john.doe@example.com")
        #expect(dto.isActive == true)
        #expect(dto.role == "teacher")
    }

    @Test("UserDTO converts to domain entity")
    func testUserDTOToDomain() throws {
        let jsonData = try loadFixture("user_response")
        let dto = try decoder.decode(UserDTO.self, from: jsonData)

        let user = try dto.toDomain()

        #expect(user.firstName == "John")
        #expect(user.lastName == "Doe")
        #expect(user.email == "john.doe@example.com")
    }

    @Test("User roundtrip preserves data")
    func testUserRoundtrip() throws {
        let jsonData = try loadFixture("user_response")
        let originalDTO = try decoder.decode(UserDTO.self, from: jsonData)

        // DTO → Domain → DTO
        let domain = try originalDTO.toDomain()
        let resultDTO = domain.toDTO()

        #expect(resultDTO.id == originalDTO.id)
        #expect(resultDTO.firstName == originalDTO.firstName)
        #expect(resultDTO.lastName == originalDTO.lastName)
        #expect(resultDTO.email == originalDTO.email)
        #expect(resultDTO.isActive == originalDTO.isActive)
        #expect(resultDTO.fullName == originalDTO.fullName)
    }

    @Test("UserDTO serializes to JSON with snake_case keys")
    func testUserDTOSerializesToSnakeCase() throws {
        let dto = UserDTO(
            id: UUID(),
            firstName: "Jane",
            lastName: "Smith",
            fullName: "Jane Smith",
            email: "jane@example.com",
            isActive: true,
            role: "teacher",
            createdAt: Date(),
            updatedAt: Date()
        )

        let jsonData = try encoder.encode(dto)
        let jsonString = String(data: jsonData, encoding: .utf8)!

        #expect(jsonString.contains("\"first_name\""))
        #expect(jsonString.contains("\"last_name\""))
        #expect(jsonString.contains("\"full_name\""))
        #expect(jsonString.contains("\"is_active\""))
        #expect(jsonString.contains("\"role\""))
        #expect(jsonString.contains("\"created_at\""))
        #expect(jsonString.contains("\"updated_at\""))
        #expect(!jsonString.contains("\"firstName\""))
        #expect(!jsonString.contains("\"lastName\""))
    }

    // MARK: - School Serialization Tests

    @Test("SchoolDTO deserializes from JSON fixture")
    func testSchoolDTODeserializesFromFixture() throws {
        let jsonData = try loadFixture("school_response")

        let dto = try decoder.decode(SchoolDTO.self, from: jsonData)

        #expect(dto.id == UUID(uuidString: "660e8400-e29b-41d4-a716-446655440001"))
        #expect(dto.name == "Springfield Elementary")
        #expect(dto.code == "SPR-001")
        #expect(dto.isActive == true)
        #expect(dto.city == "Springfield")
        #expect(dto.maxStudents == 500)
        #expect(dto.subscriptionTier == "premium")
        #expect(dto.metadata?["founded"] == .string("1990"))
    }

    @Test("SchoolDTO converts to domain entity")
    func testSchoolDTOToDomain() throws {
        let jsonData = try loadFixture("school_response")
        let dto = try decoder.decode(SchoolDTO.self, from: jsonData)

        let school = try dto.toDomain()

        #expect(school.name == "Springfield Elementary")
        #expect(school.code == "SPR-001")
        #expect(school.city == "Springfield")
    }

    @Test("School roundtrip preserves data")
    func testSchoolRoundtrip() throws {
        let jsonData = try loadFixture("school_response")
        let originalDTO = try decoder.decode(SchoolDTO.self, from: jsonData)

        let domain = try originalDTO.toDomain()
        let resultDTO = domain.toDTO()

        #expect(resultDTO.id == originalDTO.id)
        #expect(resultDTO.name == originalDTO.name)
        #expect(resultDTO.code == originalDTO.code)
        #expect(resultDTO.isActive == originalDTO.isActive)
        #expect(resultDTO.maxStudents == originalDTO.maxStudents)
    }

    @Test("SchoolDTO serializes to JSON with snake_case keys")
    func testSchoolDTOSerializesToSnakeCase() throws {
        let dto = SchoolDTO(
            id: UUID(),
            name: "Test School",
            code: "TST-001",
            isActive: true,
            address: nil,
            city: nil,
            country: nil,
            contactEmail: "test@school.com",
            contactPhone: nil,
            maxStudents: 100,
            maxTeachers: 10,
            subscriptionTier: "basic",
            metadata: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        let jsonData = try encoder.encode(dto)
        let jsonString = String(data: jsonData, encoding: .utf8)!

        #expect(jsonString.contains("\"is_active\""))
        #expect(jsonString.contains("\"contact_email\""))
        #expect(jsonString.contains("\"max_students\""))
        #expect(jsonString.contains("\"max_teachers\""))
        #expect(jsonString.contains("\"subscription_tier\""))
        #expect(jsonString.contains("\"created_at\""))
    }

    // MARK: - AcademicUnit Serialization Tests

    @Test("AcademicUnitDTO deserializes from JSON fixture")
    func testAcademicUnitDTODeserializesFromFixture() throws {
        let jsonData = try loadFixture("academic_unit_response")

        let dto = try decoder.decode(AcademicUnitDTO.self, from: jsonData)

        #expect(dto.id == UUID(uuidString: "770e8400-e29b-41d4-a716-446655440002"))
        #expect(dto.displayName == "5th Grade - Section A")
        #expect(dto.code == "5A")
        #expect(dto.type == "section")
        #expect(dto.schoolID == UUID(uuidString: "660e8400-e29b-41d4-a716-446655440001"))
    }

    @Test("AcademicUnitDTO converts to domain entity")
    func testAcademicUnitDTOToDomain() throws {
        let jsonData = try loadFixture("academic_unit_response")
        let dto = try decoder.decode(AcademicUnitDTO.self, from: jsonData)

        let unit = try dto.toDomain()

        #expect(unit.displayName == "5th Grade - Section A")
        #expect(unit.type == .section)
        #expect(unit.metadata?["capacity"] == .string("30"))
    }

    @Test("AcademicUnit roundtrip preserves data")
    func testAcademicUnitRoundtrip() throws {
        let jsonData = try loadFixture("academic_unit_response")
        let originalDTO = try decoder.decode(AcademicUnitDTO.self, from: jsonData)

        let domain = try originalDTO.toDomain()
        let resultDTO = domain.toDTO()

        #expect(resultDTO.id == originalDTO.id)
        #expect(resultDTO.displayName == originalDTO.displayName)
        #expect(resultDTO.type == originalDTO.type)
        #expect(resultDTO.schoolID == originalDTO.schoolID)
    }

    @Test("AcademicUnitDTO serializes to JSON with snake_case keys")
    func testAcademicUnitDTOSerializesToSnakeCase() throws {
        // Use non-nil values to ensure keys appear in JSON output
        let dto = AcademicUnitDTO(
            id: UUID(),
            displayName: "Test Unit",
            code: "TU",
            description: "A test unit",
            type: "grade",
            parentUnitID: UUID(),
            schoolID: UUID(),
            metadata: ["key": .string("value")],
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: Date()
        )

        let jsonData = try encoder.encode(dto)
        let jsonString = String(data: jsonData, encoding: .utf8)!

        #expect(jsonString.contains("\"display_name\""))
        #expect(jsonString.contains("\"parent_unit_id\""))
        #expect(jsonString.contains("\"school_id\""))
        #expect(jsonString.contains("\"created_at\""))
        #expect(jsonString.contains("\"deleted_at\""))
        #expect(!jsonString.contains("\"displayName\""))
        #expect(!jsonString.contains("\"schoolID\""))
    }

    // MARK: - Membership Serialization Tests

    @Test("MembershipDTO deserializes from JSON fixture")
    func testMembershipDTODeserializesFromFixture() throws {
        let jsonData = try loadFixture("membership_response")

        let dto = try decoder.decode(MembershipDTO.self, from: jsonData)

        #expect(dto.id == UUID(uuidString: "990e8400-e29b-41d4-a716-446655440004"))
        #expect(dto.userID == UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000"))
        #expect(dto.unitID == UUID(uuidString: "770e8400-e29b-41d4-a716-446655440002"))
        #expect(dto.role == "teacher")
        #expect(dto.isActive == true)
    }

    @Test("MembershipDTO converts to domain entity")
    func testMembershipDTOToDomain() throws {
        let jsonData = try loadFixture("membership_response")
        let dto = try decoder.decode(MembershipDTO.self, from: jsonData)

        let membership = try dto.toDomain()

        #expect(membership.role == .teacher)
        #expect(membership.isActive == true)
    }

    @Test("Membership roundtrip preserves data")
    func testMembershipRoundtrip() throws {
        let jsonData = try loadFixture("membership_response")
        let originalDTO = try decoder.decode(MembershipDTO.self, from: jsonData)

        let domain = try originalDTO.toDomain()
        let resultDTO = domain.toDTO()

        #expect(resultDTO.id == originalDTO.id)
        #expect(resultDTO.userID == originalDTO.userID)
        #expect(resultDTO.unitID == originalDTO.unitID)
        #expect(resultDTO.role == originalDTO.role)
        #expect(resultDTO.isActive == originalDTO.isActive)
    }

    @Test("MembershipDTO serializes to JSON with snake_case keys")
    func testMembershipDTOSerializesToSnakeCase() throws {
        // Use non-nil values to ensure keys appear in JSON output
        let dto = MembershipDTO(
            id: UUID(),
            userID: UUID(),
            unitID: UUID(),
            role: "student",
            isActive: true,
            enrolledAt: Date(),
            withdrawnAt: Date(),
            createdAt: Date(),
            updatedAt: Date()
        )

        let jsonData = try encoder.encode(dto)
        let jsonString = String(data: jsonData, encoding: .utf8)!

        #expect(jsonString.contains("\"user_id\""))
        #expect(jsonString.contains("\"unit_id\""))
        #expect(jsonString.contains("\"is_active\""))
        #expect(jsonString.contains("\"enrolled_at\""))
        #expect(jsonString.contains("\"withdrawn_at\""))
        #expect(jsonString.contains("\"created_at\""))
        #expect(!jsonString.contains("\"userID\""))
        #expect(!jsonString.contains("\"unitID\""))
    }

    // MARK: - Material Serialization Tests

    @Test("MaterialDTO deserializes from JSON fixture")
    func testMaterialDTODeserializesFromFixture() throws {
        let jsonData = try loadFixture("material_response")

        let dto = try decoder.decode(MaterialDTO.self, from: jsonData)

        #expect(dto.id == UUID(uuidString: "aa0e8400-e29b-41d4-a716-446655440005"))
        #expect(dto.title == "Introduction to Calculus")
        #expect(dto.status == "ready")
        #expect(dto.fileType == "application/pdf")
        #expect(dto.fileSizeBytes == 1048576)
        #expect(dto.isPublic == false)
    }

    @Test("MaterialDTO converts to domain entity")
    func testMaterialDTOToDomain() throws {
        let jsonData = try loadFixture("material_response")
        let dto = try decoder.decode(MaterialDTO.self, from: jsonData)

        let material = try dto.toDomain()

        #expect(material.title == "Introduction to Calculus")
        #expect(material.status == .ready)
        #expect(material.fileURL?.absoluteString == "https://s3.amazonaws.com/bucket/materials/550e8400.pdf")
    }

    @Test("Material roundtrip preserves data")
    func testMaterialRoundtrip() throws {
        let jsonData = try loadFixture("material_response")
        let originalDTO = try decoder.decode(MaterialDTO.self, from: jsonData)

        let domain = try originalDTO.toDomain()
        let resultDTO = domain.toDTO()

        #expect(resultDTO.id == originalDTO.id)
        #expect(resultDTO.title == originalDTO.title)
        #expect(resultDTO.status == originalDTO.status)
        #expect(resultDTO.schoolID == originalDTO.schoolID)
        #expect(resultDTO.isPublic == originalDTO.isPublic)
    }

    @Test("MaterialDTO serializes to JSON with snake_case keys")
    func testMaterialDTOSerializesToSnakeCase() throws {
        // Use non-nil values to ensure keys appear in JSON output
        let dto = MaterialDTO(
            id: UUID(),
            title: "Test Material",
            description: "A description",
            status: "uploaded",
            fileURL: "https://example.com/file.pdf",
            fileType: "application/pdf",
            fileSizeBytes: 1024,
            schoolID: UUID(),
            academicUnitID: UUID(),
            uploadedByTeacherID: UUID(),
            subject: "Math",
            grade: "5th",
            isPublic: false,
            processingStartedAt: Date(),
            processingCompletedAt: Date(),
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: nil
        )

        let jsonData = try encoder.encode(dto)
        let jsonString = String(data: jsonData, encoding: .utf8)!

        #expect(jsonString.contains("\"file_url\""))
        #expect(jsonString.contains("\"file_type\""))
        #expect(jsonString.contains("\"file_size_bytes\""))
        #expect(jsonString.contains("\"school_id\""))
        #expect(jsonString.contains("\"academic_unit_id\""))
        #expect(jsonString.contains("\"uploaded_by_teacher_id\""))
        #expect(jsonString.contains("\"is_public\""))
        #expect(jsonString.contains("\"processing_started_at\""))
        #expect(jsonString.contains("\"processing_completed_at\""))
        #expect(!jsonString.contains("\"fileURL\""))
        #expect(!jsonString.contains("\"schoolID\""))
    }
}
