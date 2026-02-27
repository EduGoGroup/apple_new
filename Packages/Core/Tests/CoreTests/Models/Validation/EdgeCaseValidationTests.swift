// EdgeCaseValidationTests.swift
// ModelsTests
//
// Tests for edge cases in Domain-DTO serialization/deserialization.
// Covers: nulls, empty strings, invalid UUIDs, malformed metadata, invalid URLs.

import Testing
import Foundation
import EduFoundation
@testable import EduModels

@Suite("Edge Case Validation Tests")
struct EdgeCaseValidationTests {

    // MARK: - JSON Decoder/Encoder

    private let decoder = BackendFixtures.backendDecoder
    private let encoder = BackendFixtures.backendEncoder

    // MARK: - Empty String Tests

    @Suite("Empty String Validation")
    struct EmptyStringValidation {

        @Test("User with empty first name fails domain conversion")
        func userEmptyFirstName() throws {
            let json = BackendFixtures.userEmptyStringsJSON
            let data = json.data(using: .utf8)!

            let decoder = BackendFixtures.backendDecoder
            let dto = try decoder.decode(UserDTO.self, from: data)

            #expect(throws: DomainError.self) {
                _ = try dto.toDomain()
            }
        }

        @Test("User with whitespace-only names fails domain conversion")
        func userWhitespaceNames() throws {
            let json = BackendFixtures.userWhitespaceNamesJSON
            let data = json.data(using: .utf8)!

            let decoder = BackendFixtures.backendDecoder
            let dto = try decoder.decode(UserDTO.self, from: data)

            #expect(throws: DomainError.self) {
                _ = try dto.toDomain()
            }
        }

        @Test("School with empty name fails domain conversion")
        func schoolEmptyName() throws {
            let dto = SchoolDTO(
                id: UUID(),
                name: "",
                code: "TEST",
                isActive: true,
                address: nil,
                city: nil,
                country: nil,
                contactEmail: nil,
                contactPhone: nil,
                maxStudents: nil,
                maxTeachers: nil,
                subscriptionTier: nil,
                metadata: nil,
                createdAt: Date(),
                updatedAt: Date()
            )

            #expect(throws: DomainError.self) {
                _ = try dto.toDomain()
            }
        }

        @Test("School with whitespace-only name fails domain conversion")
        func schoolWhitespaceName() throws {
            let dto = SchoolDTO(
                id: UUID(),
                name: "   ",
                code: "TEST",
                isActive: true,
                address: nil,
                city: nil,
                country: nil,
                contactEmail: nil,
                contactPhone: nil,
                maxStudents: nil,
                maxTeachers: nil,
                subscriptionTier: nil,
                metadata: nil,
                createdAt: Date(),
                updatedAt: Date()
            )

            #expect(throws: DomainError.self) {
                _ = try dto.toDomain()
            }
        }

        @Test("School with empty code fails domain conversion")
        func schoolEmptyCode() throws {
            let dto = SchoolDTO(
                id: UUID(),
                name: "Test School",
                code: "",
                isActive: true,
                address: nil,
                city: nil,
                country: nil,
                contactEmail: nil,
                contactPhone: nil,
                maxStudents: nil,
                maxTeachers: nil,
                subscriptionTier: nil,
                metadata: nil,
                createdAt: Date(),
                updatedAt: Date()
            )

            #expect(throws: DomainError.self) {
                _ = try dto.toDomain()
            }
        }

        @Test("Material with empty title fails domain conversion")
        func materialEmptyTitle() throws {
            let dto = MaterialDTO(
                id: UUID(),
                title: "",
                description: nil,
                status: "uploaded",
                fileURL: nil,
                fileType: nil,
                fileSizeBytes: nil,
                schoolID: UUID(),
                academicUnitID: nil,
                uploadedByTeacherID: nil,
                subject: nil,
                grade: nil,
                isPublic: false,
                processingStartedAt: nil,
                processingCompletedAt: nil,
                createdAt: Date(),
                updatedAt: Date(),
                deletedAt: nil
            )

            #expect(throws: DomainError.self) {
                _ = try dto.toDomain()
            }
        }

        @Test("AcademicUnit with empty displayName fails domain conversion")
        func academicUnitEmptyDisplayName() throws {
            let dto = AcademicUnitDTO(
                id: UUID(),
                displayName: "",
                code: nil,
                description: nil,
                type: "grade",
                parentUnitID: nil,
                schoolID: UUID(),
                metadata: nil,
                createdAt: Date(),
                updatedAt: Date(),
                deletedAt: nil
            )

            #expect(throws: DomainError.self) {
                _ = try dto.toDomain()
            }
        }
    }

    // MARK: - Invalid UUID Tests

    @Suite("Invalid UUID Validation")
    struct InvalidUUIDValidation {

        @Test("User with invalid UUID format fails JSON decoding")
        func userInvalidUUID() {
            let json = BackendFixtures.userInvalidUUIDJSON
            let data = json.data(using: .utf8)!

            let decoder = BackendFixtures.backendDecoder
            #expect(throws: DecodingError.self) {
                _ = try decoder.decode(UserDTO.self, from: data)
            }
        }

        @Test("Material with invalid school_id fails JSON decoding")
        func materialInvalidSchoolID() {
            let json = """
            {
                "id": "550e8400-e29b-41d4-a716-446655440400",
                "title": "Test",
                "status": "uploaded",
                "school_id": "invalid-uuid",
                "is_public": false,
                "created_at": "2024-01-15T10:30:00Z",
                "updated_at": "2024-01-15T10:30:00Z"
            }
            """
            let data = json.data(using: .utf8)!

            let decoder = BackendFixtures.backendDecoder
            #expect(throws: DecodingError.self) {
                _ = try decoder.decode(MaterialDTO.self, from: data)
            }
        }

        @Test("Membership with invalid user_id fails JSON decoding")
        func membershipInvalidUserID() {
            let json = """
            {
                "id": "550e8400-e29b-41d4-a716-446655440300",
                "user_id": "not-a-uuid",
                "unit_id": "550e8400-e29b-41d4-a716-446655440200",
                "role": "student",
                "is_active": true,
                "enrolled_at": "2024-01-15T10:30:00Z",
                "created_at": "2024-01-15T10:30:00Z",
                "updated_at": "2024-01-15T10:30:00Z"
            }
            """
            let data = json.data(using: .utf8)!

            let decoder = BackendFixtures.backendDecoder
            #expect(throws: DecodingError.self) {
                _ = try decoder.decode(MembershipDTO.self, from: data)
            }
        }
    }

    // MARK: - Invalid Date Tests

    @Suite("Invalid Date Validation")
    struct InvalidDateValidation {

        @Test("User with invalid date format fails JSON decoding")
        func userInvalidDate() {
            let json = BackendFixtures.userInvalidDateJSON
            let data = json.data(using: .utf8)!

            let decoder = BackendFixtures.backendDecoder
            #expect(throws: DecodingError.self) {
                _ = try decoder.decode(UserDTO.self, from: data)
            }
        }

        @Test("Material with malformed processing dates fails JSON decoding")
        func materialInvalidProcessingDate() {
            let json = """
            {
                "id": "550e8400-e29b-41d4-a716-446655440400",
                "title": "Test Material",
                "status": "processing",
                "school_id": "550e8400-e29b-41d4-a716-446655440100",
                "is_public": false,
                "processing_started_at": "2024/01/15",
                "created_at": "2024-01-15T10:30:00Z",
                "updated_at": "2024-01-15T10:30:00Z"
            }
            """
            let data = json.data(using: .utf8)!

            let decoder = BackendFixtures.backendDecoder
            #expect(throws: DecodingError.self) {
                _ = try decoder.decode(MaterialDTO.self, from: data)
            }
        }

        @Test("Membership with invalid enrolled_at fails JSON decoding")
        func membershipInvalidEnrolledAt() {
            let json = """
            {
                "id": "550e8400-e29b-41d4-a716-446655440300",
                "user_id": "550e8400-e29b-41d4-a716-446655440000",
                "unit_id": "550e8400-e29b-41d4-a716-446655440200",
                "role": "student",
                "is_active": true,
                "enrolled_at": "yesterday",
                "created_at": "2024-01-15T10:30:00Z",
                "updated_at": "2024-01-15T10:30:00Z"
            }
            """
            let data = json.data(using: .utf8)!

            let decoder = BackendFixtures.backendDecoder
            #expect(throws: DecodingError.self) {
                _ = try decoder.decode(MembershipDTO.self, from: data)
            }
        }
    }

    // MARK: - Invalid URL Tests

    @Suite("Invalid URL Validation")
    struct InvalidURLValidation {

        @Test("Material with invalid URL fails domain conversion")
        func materialInvalidURL() throws {
            let json = BackendFixtures.materialInvalidURLJSON
            let data = json.data(using: .utf8)!

            let decoder = BackendFixtures.backendDecoder
            let dto = try decoder.decode(MaterialDTO.self, from: data)

            #expect(throws: DomainError.self) {
                _ = try dto.toDomain()
            }
        }

        @Test("Material with URL without scheme fails domain conversion")
        func materialURLWithoutScheme() throws {
            let dto = MaterialDTO(
                id: UUID(),
                title: "Test",
                description: nil,
                status: "ready",
                fileURL: "example.com/file.pdf",
                fileType: nil,
                fileSizeBytes: nil,
                schoolID: UUID(),
                academicUnitID: nil,
                uploadedByTeacherID: nil,
                subject: nil,
                grade: nil,
                isPublic: false,
                processingStartedAt: nil,
                processingCompletedAt: nil,
                createdAt: Date(),
                updatedAt: Date(),
                deletedAt: nil
            )

            #expect(throws: DomainError.self) {
                _ = try dto.toDomain()
            }
        }

        @Test("Material with valid file URL succeeds")
        func materialValidFileURL() throws {
            let dto = MaterialDTO(
                id: UUID(),
                title: "Test",
                description: nil,
                status: "ready",
                fileURL: "file:///Users/test/file.pdf",
                fileType: nil,
                fileSizeBytes: nil,
                schoolID: UUID(),
                academicUnitID: nil,
                uploadedByTeacherID: nil,
                subject: nil,
                grade: nil,
                isPublic: false,
                processingStartedAt: nil,
                processingCompletedAt: nil,
                createdAt: Date(),
                updatedAt: Date(),
                deletedAt: nil
            )

            let material = try dto.toDomain()
            #expect(material.fileURL?.isFileURL == true)
        }

        @Test("Material with nil URL succeeds")
        func materialNilURL() throws {
            let dto = MaterialDTO(
                id: UUID(),
                title: "Test",
                description: nil,
                status: "uploaded",
                fileURL: nil,
                fileType: nil,
                fileSizeBytes: nil,
                schoolID: UUID(),
                academicUnitID: nil,
                uploadedByTeacherID: nil,
                subject: nil,
                grade: nil,
                isPublic: false,
                processingStartedAt: nil,
                processingCompletedAt: nil,
                createdAt: Date(),
                updatedAt: Date(),
                deletedAt: nil
            )

            let material = try dto.toDomain()
            #expect(material.fileURL == nil)
        }
    }

    // MARK: - Unknown Enum Value Tests

    @Suite("Unknown Enum Value Validation")
    struct UnknownEnumValidation {

        @Test("Membership with unknown role fails domain conversion")
        func membershipUnknownRole() throws {
            let json = BackendFixtures.membershipUnknownRoleJSON
            let data = json.data(using: .utf8)!

            let decoder = BackendFixtures.backendDecoder
            let dto = try decoder.decode(MembershipDTO.self, from: data)

            #expect(throws: DomainError.self) {
                _ = try dto.toDomain()
            }
        }

        @Test("Material with unknown status fails domain conversion")
        func materialUnknownStatus() throws {
            let json = BackendFixtures.materialUnknownStatusJSON
            let data = json.data(using: .utf8)!

            let decoder = BackendFixtures.backendDecoder
            let dto = try decoder.decode(MaterialDTO.self, from: data)

            #expect(throws: DomainError.self) {
                _ = try dto.toDomain()
            }
        }

        @Test("AcademicUnit with unknown type fails domain conversion")
        func academicUnitUnknownType() throws {
            let json = BackendFixtures.academicUnitUnknownTypeJSON
            let data = json.data(using: .utf8)!

            let decoder = BackendFixtures.backendDecoder
            let dto = try decoder.decode(AcademicUnitDTO.self, from: data)

            #expect(throws: DomainError.self) {
                _ = try dto.toDomain()
            }
        }

        @Test("All valid membership roles succeed")
        func allValidMembershipRoles() throws {
            let roles = ["owner", "teacher", "assistant", "student", "guardian"]

            for role in roles {
                let dto = MembershipDTO(
                    id: UUID(),
                    userID: UUID(),
                    unitID: UUID(),
                    role: role,
                    isActive: true,
                    enrolledAt: Date(),
                    withdrawnAt: nil,
                    createdAt: Date(),
                    updatedAt: Date()
                )

                let membership = try dto.toDomain()
                #expect(membership.role.rawValue == role)
            }
        }

        @Test("All valid material statuses succeed")
        func allValidMaterialStatuses() throws {
            let statuses = ["uploaded", "processing", "ready", "failed"]

            for status in statuses {
                let dto = MaterialDTO(
                    id: UUID(),
                    title: "Test",
                    description: nil,
                    status: status,
                    fileURL: nil,
                    fileType: nil,
                    fileSizeBytes: nil,
                    schoolID: UUID(),
                    academicUnitID: nil,
                    uploadedByTeacherID: nil,
                    subject: nil,
                    grade: nil,
                    isPublic: false,
                    processingStartedAt: nil,
                    processingCompletedAt: nil,
                    createdAt: Date(),
                    updatedAt: Date(),
                    deletedAt: nil
                )

                let material = try dto.toDomain()
                #expect(material.status.rawValue == status)
            }
        }

        @Test("All valid academic unit types succeed")
        func allValidAcademicUnitTypes() throws {
            let types = ["grade", "section", "club", "department", "course"]

            for type in types {
                let dto = AcademicUnitDTO(
                    id: UUID(),
                    displayName: "Test Unit",
                    code: nil,
                    description: nil,
                    type: type,
                    parentUnitID: nil,
                    schoolID: UUID(),
                    metadata: nil,
                    createdAt: Date(),
                    updatedAt: Date(),
                    deletedAt: nil
                )

                let unit = try dto.toDomain()
                #expect(unit.type.rawValue == type)
            }
        }
    }

    // MARK: - Invalid Email Tests

    @Suite("Invalid Email Validation")
    struct InvalidEmailValidation {

        @Test("User with invalid email format fails domain conversion")
        func userInvalidEmail() throws {
            let json = BackendFixtures.userInvalidEmailJSON
            let data = json.data(using: .utf8)!

            let decoder = BackendFixtures.backendDecoder
            let dto = try decoder.decode(UserDTO.self, from: data)

            #expect(throws: DomainError.self) {
                _ = try dto.toDomain()
            }
        }

        @Test("User with email missing @ fails domain conversion")
        func userEmailMissingAt() throws {
            let dto = UserDTO(
                id: UUID(),
                firstName: "Test",
                lastName: "User",
                fullName: nil,
                email: "test.example.com",
                isActive: true,
                role: nil,
                createdAt: Date(),
                updatedAt: Date()
            )

            #expect(throws: DomainError.self) {
                _ = try dto.toDomain()
            }
        }

        @Test("User with email missing domain fails domain conversion")
        func userEmailMissingDomain() throws {
            let dto = UserDTO(
                id: UUID(),
                firstName: "Test",
                lastName: "User",
                fullName: nil,
                email: "test@",
                isActive: true,
                role: nil,
                createdAt: Date(),
                updatedAt: Date()
            )

            #expect(throws: DomainError.self) {
                _ = try dto.toDomain()
            }
        }

        @Test("User with valid email succeeds")
        func userValidEmail() throws {
            let dto = UserDTO(
                id: UUID(),
                firstName: "Test",
                lastName: "User",
                fullName: nil,
                email: "test@example.com",
                isActive: true,
                role: nil,
                createdAt: Date(),
                updatedAt: Date()
            )

            let user = try dto.toDomain()
            #expect(user.email == "test@example.com")
        }

        @Test("User email is normalized to lowercase")
        func userEmailNormalizedToLowercase() throws {
            let dto = UserDTO(
                id: UUID(),
                firstName: "Test",
                lastName: "User",
                fullName: nil,
                email: "Test.User@Example.COM",
                isActive: true,
                role: nil,
                createdAt: Date(),
                updatedAt: Date()
            )

            let user = try dto.toDomain()
            #expect(user.email == "test.user@example.com")
        }
    }

    // MARK: - Null Optional Fields Tests

    @Suite("Null Optional Fields Validation")
    struct NullOptionalFieldsValidation {

        @Test("User with null optional fields decodes successfully")
        func userWithNulls() throws {
            let json = BackendFixtures.userWithNullsJSON
            let data = json.data(using: .utf8)!

            let decoder = BackendFixtures.backendDecoder
            let dto = try decoder.decode(UserDTO.self, from: data)

            #expect(dto.fullName == nil)
            #expect(dto.role == nil)

            let user = try dto.toDomain()
            #expect(user.firstName == "Pedro")
        }

        @Test("School with all null optional fields decodes successfully")
        func schoolWithNulls() throws {
            let json = BackendFixtures.schoolWithNullsJSON
            let data = json.data(using: .utf8)!

            let decoder = BackendFixtures.backendDecoder
            let dto = try decoder.decode(SchoolDTO.self, from: data)

            #expect(dto.address == nil)
            #expect(dto.city == nil)
            #expect(dto.country == nil)
            #expect(dto.contactEmail == nil)
            #expect(dto.contactPhone == nil)
            #expect(dto.maxStudents == nil)
            #expect(dto.maxTeachers == nil)
            #expect(dto.subscriptionTier == nil)
            #expect(dto.metadata == nil)

            let school = try dto.toDomain()
            #expect(school.name == "Instituto ABC")
        }

        @Test("Material with null optional fields decodes successfully")
        func materialWithNulls() throws {
            let json = BackendFixtures.materialMinimalJSON
            let data = json.data(using: .utf8)!

            let decoder = BackendFixtures.backendDecoder
            let dto = try decoder.decode(MaterialDTO.self, from: data)

            #expect(dto.description == nil)
            #expect(dto.fileURL == nil)
            #expect(dto.fileType == nil)
            #expect(dto.fileSizeBytes == nil)
            #expect(dto.academicUnitID == nil)
            #expect(dto.uploadedByTeacherID == nil)
            #expect(dto.subject == nil)
            #expect(dto.grade == nil)
            #expect(dto.processingStartedAt == nil)
            #expect(dto.processingCompletedAt == nil)
            #expect(dto.deletedAt == nil)

            let material = try dto.toDomain()
            #expect(material.title == "Material Básico")
        }

        @Test("Membership with null withdrawn_at decodes successfully")
        func membershipWithNullWithdrawnAt() throws {
            let json = BackendFixtures.membershipTeacherJSON
            let data = json.data(using: .utf8)!

            let decoder = BackendFixtures.backendDecoder
            let dto = try decoder.decode(MembershipDTO.self, from: data)

            #expect(dto.withdrawnAt == nil)

            let membership = try dto.toDomain()
            #expect(membership.withdrawnAt == nil)
            #expect(membership.isCurrentlyActive == true)
        }

        @Test("AcademicUnit with null optional fields decodes successfully")
        func academicUnitWithNulls() throws {
            let dto = AcademicUnitDTO(
                id: UUID(),
                displayName: "Test Unit",
                code: nil,
                description: nil,
                type: "grade",
                parentUnitID: nil,
                schoolID: UUID(),
                metadata: nil,
                createdAt: Date(),
                updatedAt: Date(),
                deletedAt: nil
            )

            let unit = try dto.toDomain()
            #expect(unit.code == nil)
            #expect(unit.description == nil)
            #expect(unit.parentUnitID == nil)
            #expect(unit.metadata == nil)
            #expect(unit.deletedAt == nil)
            #expect(unit.isTopLevel == true)
        }
    }

    // MARK: - Missing Required Fields Tests

    @Suite("Missing Required Fields Validation")
    struct MissingRequiredFieldsValidation {

        @Test("User missing required field fails JSON decoding")
        func userMissingEmail() {
            let json = """
            {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "first_name": "Test",
                "last_name": "User",
                "is_active": true,
                "created_at": "2024-01-15T10:30:00Z",
                "updated_at": "2024-01-15T10:30:00Z"
            }
            """
            let data = json.data(using: .utf8)!

            let decoder = BackendFixtures.backendDecoder
            #expect(throws: DecodingError.self) {
                _ = try decoder.decode(UserDTO.self, from: data)
            }
        }

        @Test("Material missing title fails JSON decoding")
        func materialMissingTitle() {
            let json = """
            {
                "id": "550e8400-e29b-41d4-a716-446655440400",
                "status": "uploaded",
                "school_id": "550e8400-e29b-41d4-a716-446655440100",
                "is_public": false,
                "created_at": "2024-01-15T10:30:00Z",
                "updated_at": "2024-01-15T10:30:00Z"
            }
            """
            let data = json.data(using: .utf8)!

            let decoder = BackendFixtures.backendDecoder
            #expect(throws: DecodingError.self) {
                _ = try decoder.decode(MaterialDTO.self, from: data)
            }
        }

        @Test("School missing name fails JSON decoding")
        func schoolMissingName() {
            let json = """
            {
                "id": "550e8400-e29b-41d4-a716-446655440100",
                "code": "TEST",
                "is_active": true,
                "created_at": "2024-01-15T10:30:00Z",
                "updated_at": "2024-01-15T10:30:00Z"
            }
            """
            let data = json.data(using: .utf8)!

            let decoder = BackendFixtures.backendDecoder
            #expect(throws: DecodingError.self) {
                _ = try decoder.decode(SchoolDTO.self, from: data)
            }
        }

        @Test("Membership missing role fails JSON decoding")
        func membershipMissingRole() {
            let json = """
            {
                "id": "550e8400-e29b-41d4-a716-446655440300",
                "user_id": "550e8400-e29b-41d4-a716-446655440000",
                "unit_id": "550e8400-e29b-41d4-a716-446655440200",
                "is_active": true,
                "enrolled_at": "2024-01-15T10:30:00Z",
                "created_at": "2024-01-15T10:30:00Z",
                "updated_at": "2024-01-15T10:30:00Z"
            }
            """
            let data = json.data(using: .utf8)!

            let decoder = BackendFixtures.backendDecoder
            #expect(throws: DecodingError.self) {
                _ = try decoder.decode(MembershipDTO.self, from: data)
            }
        }

        @Test("AcademicUnit missing type fails JSON decoding")
        func academicUnitMissingType() {
            let json = """
            {
                "id": "550e8400-e29b-41d4-a716-446655440200",
                "display_name": "Test Unit",
                "school_id": "550e8400-e29b-41d4-a716-446655440100",
                "created_at": "2024-01-15T10:30:00Z",
                "updated_at": "2024-01-15T10:30:00Z"
            }
            """
            let data = json.data(using: .utf8)!

            let decoder = BackendFixtures.backendDecoder
            #expect(throws: DecodingError.self) {
                _ = try decoder.decode(AcademicUnitDTO.self, from: data)
            }
        }
    }

    // MARK: - Metadata Edge Cases

    @Suite("Metadata Edge Cases Validation")
    struct MetadataEdgeCasesValidation {

        @Test("School with complex metadata decodes successfully")
        func schoolComplexMetadata() throws {
            let json = BackendFixtures.schoolComplexMetadataJSON
            let data = json.data(using: .utf8)!

            let decoder = BackendFixtures.backendDecoder
            let dto = try decoder.decode(SchoolDTO.self, from: data)

            #expect(dto.metadata != nil)
            #expect(dto.metadata?["string_value"] == .string("texto"))
            #expect(dto.metadata?["number_value"] == .integer(42))
            #expect(dto.metadata?["boolean_value"] == .bool(true))
            #expect(dto.metadata?["null_value"] == .null)

            let school = try dto.toDomain()
            #expect(school.metadata?["string_value"] == .string("texto"))
        }

        @Test("AcademicUnit metadata roundtrip preserves values")
        func academicUnitMetadataRoundtrip() throws {
            let metadata: [String: JSONValue] = [
                "capacity": .integer(120),
                "building": .string("A"),
                "active": .bool(true)
            ]

            let dto = AcademicUnitDTO(
                id: UUID(),
                displayName: "Test Unit",
                code: nil,
                description: nil,
                type: "grade",
                parentUnitID: nil,
                schoolID: UUID(),
                metadata: metadata,
                createdAt: Date(),
                updatedAt: Date(),
                deletedAt: nil
            )

            let unit = try dto.toDomain()
            let backToDTO = unit.toDTO()

            #expect(backToDTO.metadata?["capacity"] == .integer(120))
            #expect(backToDTO.metadata?["building"] == .string("A"))
            #expect(backToDTO.metadata?["active"] == .bool(true))
        }

        @Test("Empty metadata dictionary is preserved")
        func emptyMetadata() throws {
            let dto = SchoolDTO(
                id: UUID(),
                name: "Test",
                code: "TEST",
                isActive: true,
                address: nil,
                city: nil,
                country: nil,
                contactEmail: nil,
                contactPhone: nil,
                maxStudents: nil,
                maxTeachers: nil,
                subscriptionTier: nil,
                metadata: [:],
                createdAt: Date(),
                updatedAt: Date()
            )

            let school = try dto.toDomain()
            let backToDTO = school.toDTO()

            #expect(backToDTO.metadata?.isEmpty == true)
        }
    }

    // MARK: - Array Deserialization Tests

    @Suite("Array Deserialization Validation")
    struct ArrayDeserializationValidation {

        @Test("Materials array decodes successfully")
        func materialsArray() throws {
            let json = BackendFixtures.materialsArrayJSON
            let data = json.data(using: .utf8)!

            let decoder = BackendFixtures.backendDecoder
            let dtos = try decoder.decode([MaterialDTO].self, from: data)

            #expect(dtos.count == 2)
            #expect(dtos[0].title == "Material 1")
            #expect(dtos[0].status == "ready")
            #expect(dtos[1].title == "Material 2")
            #expect(dtos[1].status == "processing")
        }

        @Test("Materials array domain conversion succeeds")
        func materialsArrayToDomain() throws {
            let json = BackendFixtures.materialsArrayJSON
            let data = json.data(using: .utf8)!

            let decoder = BackendFixtures.backendDecoder
            let dtos = try decoder.decode([MaterialDTO].self, from: data)
            let materials = try dtos.map { try $0.toDomain() }

            #expect(materials.count == 2)
            #expect(materials[0].status == .ready)
            #expect(materials[1].status == .processing)
        }

        @Test("Memberships array decodes successfully")
        func membershipsArray() throws {
            let json = BackendFixtures.membershipsArrayJSON
            let data = json.data(using: .utf8)!

            let decoder = BackendFixtures.backendDecoder
            let dtos = try decoder.decode([MembershipDTO].self, from: data)

            #expect(dtos.count == 2)
            #expect(dtos[0].role == "teacher")
            #expect(dtos[1].role == "student")
        }

        @Test("Memberships array domain conversion succeeds")
        func membershipsArrayToDomain() throws {
            let json = BackendFixtures.membershipsArrayJSON
            let data = json.data(using: .utf8)!

            let decoder = BackendFixtures.backendDecoder
            let dtos = try decoder.decode([MembershipDTO].self, from: data)
            let memberships = try dtos.map { try $0.toDomain() }

            #expect(memberships.count == 2)
            #expect(memberships[0].role == .teacher)
            #expect(memberships[1].role == .student)
        }

        @Test("Empty array decodes successfully")
        func emptyArray() throws {
            let json = "[]"
            let data = json.data(using: .utf8)!

            let decoder = BackendFixtures.backendDecoder
            let dtos = try decoder.decode([MaterialDTO].self, from: data)

            #expect(dtos.isEmpty)
        }
    }
}
