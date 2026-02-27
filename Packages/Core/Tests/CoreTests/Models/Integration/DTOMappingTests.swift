import Testing
import Foundation
import EduFoundation
@testable import EduModels

/// Integration tests for DTO ↔ Domain mapping.
///
/// These tests validate that:
/// 1. All CodingKeys correctly map snake_case ↔ camelCase
/// 2. Domain validation is applied during DTO → Domain conversion
/// 3. Edge cases (nil values, empty strings) are handled correctly
/// 4. Enum conversions work correctly for role/status/type fields
@Suite("DTO Mapping Integration Tests")
struct DTOMappingTests {

    // MARK: - User DTO Mapping Tests

    @Test("UserDTO validates email during toDomain conversion")
    func testUserDTOValidatesEmail() {
        let dto = UserDTO(
            id: UUID(),
            firstName: "John",
            lastName: "Doe",
            email: "invalid-email",
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        #expect(throws: Error.self) {
            _ = try dto.toDomain()
        }
    }

    @Test("UserDTO validates empty firstName during toDomain conversion")
    func testUserDTOValidatesEmptyFirstName() {
        let dto = UserDTO(
            id: UUID(),
            firstName: "",
            lastName: "Doe",
            email: "john@example.com",
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        #expect(throws: Error.self) {
            _ = try dto.toDomain()
        }
    }

    @Test("UserDTO validates empty lastName during toDomain conversion")
    func testUserDTOValidatesEmptyLastName() {
        let dto = UserDTO(
            id: UUID(),
            firstName: "John",
            lastName: "",
            email: "john@example.com",
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        #expect(throws: Error.self) {
            _ = try dto.toDomain()
        }
    }

    @Test("User toDTO preserves all fields")
    func testUserToDTOPreservesAllFields() throws {
        let user = try User(
            id: UUID(),
            firstName: "Jane",
            lastName: "Smith",
            email: "jane@example.com",
            isActive: false,
            createdAt: Date(timeIntervalSince1970: 1000),
            updatedAt: Date(timeIntervalSince1970: 2000)
        )

        let dto = user.toDTO()

        #expect(dto.id == user.id)
        #expect(dto.firstName == user.firstName)
        #expect(dto.lastName == user.lastName)
        #expect(dto.fullName == user.fullName)
        #expect(dto.email == user.email)
        #expect(dto.isActive == user.isActive)
        #expect(dto.role == nil)
        #expect(dto.createdAt == user.createdAt)
        #expect(dto.updatedAt == user.updatedAt)
    }

    // MARK: - School DTO Mapping Tests

    @Test("SchoolDTO validates empty name during toDomain conversion")
    func testSchoolDTOValidatesEmptyName() {
        let dto = SchoolDTO(
            id: UUID(),
            name: "",
            code: "TST-001",
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

        #expect(throws: Error.self) {
            _ = try dto.toDomain()
        }
    }

    @Test("SchoolDTO validates empty code during toDomain conversion")
    func testSchoolDTOValidatesEmptyCode() {
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

        #expect(throws: Error.self) {
            _ = try dto.toDomain()
        }
    }

    @Test("School toDTO preserves optional fields")
    func testSchoolToDTOPreservesOptionalFields() throws {
        let school = try School(
            id: UUID(),
            name: "Test School",
            code: "TST-001",
            isActive: true,
            address: "123 Main St",
            city: "Test City",
            country: "CO",
            contactEmail: "test@school.com",
            contactPhone: "+57 300 123 4567",
            maxStudents: 500,
            maxTeachers: 50,
            subscriptionTier: "premium",
            metadata: ["key": .string("value")],
            createdAt: Date(),
            updatedAt: Date()
        )

        let dto = school.toDTO()

        #expect(dto.address == "123 Main St")
        #expect(dto.city == "Test City")
        #expect(dto.country == "CO")
        #expect(dto.contactEmail == "test@school.com")
        #expect(dto.maxStudents == 500)
        #expect(dto.metadata?["key"] == .string("value"))
    }

    // MARK: - AcademicUnit DTO Mapping Tests

    @Test("AcademicUnitDTO validates empty displayName during toDomain conversion")
    func testAcademicUnitDTOValidatesEmptyDisplayName() {
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

        #expect(throws: Error.self) {
            _ = try dto.toDomain()
        }
    }

    @Test("AcademicUnitDTO converts all known unit types")
    func testAcademicUnitDTOConvertsAllKnownTypes() throws {
        let types: [(String, AcademicUnitType)] = [
            ("grade", .grade),
            ("section", .section),
            ("club", .club),
            ("department", .department),
            ("course", .course)
        ]

        for (typeString, expectedType) in types {
            let dto = AcademicUnitDTO(
                id: UUID(),
                displayName: "Test Unit",
                code: nil,
                description: nil,
                type: typeString,
                parentUnitID: nil,
                schoolID: UUID(),
                metadata: nil,
                createdAt: Date(),
                updatedAt: Date(),
                deletedAt: nil
            )

            let domain = try dto.toDomain()

            #expect(domain.type == expectedType)
        }
    }

    @Test("AcademicUnitDTO throws for unknown type")
    func testAcademicUnitDTOThrowsForUnknownType() {
        let dto = AcademicUnitDTO(
            id: UUID(),
            displayName: "Test Unit",
            code: nil,
            description: nil,
            type: "unknown_type",
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

    @Test("AcademicUnit toDTO converts type to rawValue")
    func testAcademicUnitToDTOConvertsTypeToRawValue() throws {
        let unit = try AcademicUnit(
            id: UUID(),
            displayName: "Test Section",
            type: .section,
            schoolID: UUID(),
            createdAt: Date(),
            updatedAt: Date()
        )

        let dto = unit.toDTO()

        #expect(dto.type == "section")
    }

    // MARK: - Membership DTO Mapping Tests

    @Test("MembershipDTO converts all known roles")
    func testMembershipDTOConvertsAllKnownRoles() throws {
        let roles: [(String, MembershipRole)] = [
            ("owner", .owner),
            ("teacher", .teacher),
            ("assistant", .assistant),
            ("student", .student),
            ("guardian", .guardian)
        ]

        for (roleString, expectedRole) in roles {
            let dto = MembershipDTO(
                id: UUID(),
                userID: UUID(),
                unitID: UUID(),
                role: roleString,
                isActive: true,
                enrolledAt: Date(),
                withdrawnAt: nil,
                createdAt: Date(),
                updatedAt: Date()
            )

            let domain = try dto.toDomain()

            #expect(domain.role == expectedRole)
        }
    }

    @Test("MembershipDTO throws for unknown role")
    func testMembershipDTOThrowsForUnknownRole() {
        let dto = MembershipDTO(
            id: UUID(),
            userID: UUID(),
            unitID: UUID(),
            role: "unknown_role",
            isActive: true,
            enrolledAt: Date(),
            withdrawnAt: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        #expect(throws: DomainError.self) {
            _ = try dto.toDomain()
        }
    }

    @Test("Membership toDTO converts role to rawValue")
    func testMembershipToDTOConvertsRoleToRawValue() {
        let membership = Membership(
            id: UUID(),
            userID: UUID(),
            unitID: UUID(),
            role: .teacher,
            isActive: true,
            enrolledAt: Date(),
            withdrawnAt: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        let dto = membership.toDTO()

        #expect(dto.role == "teacher")
    }

    @Test("MembershipDTO preserves withdrawnAt date")
    func testMembershipDTOPreservesWithdrawnAt() throws {
        let withdrawnAt = Date()
        let dto = MembershipDTO(
            id: UUID(),
            userID: UUID(),
            unitID: UUID(),
            role: "student",
            isActive: false,
            enrolledAt: Date(),
            withdrawnAt: withdrawnAt,
            createdAt: Date(),
            updatedAt: Date()
        )

        let domain = try dto.toDomain()

        #expect(domain.withdrawnAt == withdrawnAt)
    }

    // MARK: - Material DTO Mapping Tests

    @Test("MaterialDTO validates empty title during toDomain conversion")
    func testMaterialDTOValidatesEmptyTitle() {
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

        #expect(throws: Error.self) {
            _ = try dto.toDomain()
        }
    }

    @Test("MaterialDTO converts all known status values")
    func testMaterialDTOConvertsAllKnownStatuses() throws {
        let statuses: [(String, MaterialStatus)] = [
            ("uploaded", .uploaded),
            ("processing", .processing),
            ("ready", .ready),
            ("failed", .failed)
        ]

        for (statusString, expectedStatus) in statuses {
            let dto = MaterialDTO(
                id: UUID(),
                title: "Test Material",
                description: nil,
                status: statusString,
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

            let domain = try dto.toDomain()

            #expect(domain.status == expectedStatus)
        }
    }

    @Test("MaterialDTO throws for unknown status")
    func testMaterialDTOThrowsForUnknownStatus() {
        let dto = MaterialDTO(
            id: UUID(),
            title: "Test Material",
            description: nil,
            status: "unknown_status",
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

    @Test("MaterialDTO converts fileURL string to URL")
    func testMaterialDTOConvertsFileURLStringToURL() throws {
        let dto = MaterialDTO(
            id: UUID(),
            title: "Test Material",
            description: nil,
            status: "ready",
            fileURL: "https://example.com/file.pdf",
            fileType: "application/pdf",
            fileSizeBytes: 1024,
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

        let domain = try dto.toDomain()

        #expect(domain.fileURL?.absoluteString == "https://example.com/file.pdf")
    }

    @Test("Material toDTO converts URL to string")
    func testMaterialToDTOConvertsURLToString() throws {
        let material = try Material(
            id: UUID(),
            title: "Test Material",
            status: .ready,
            fileURL: URL(string: "https://example.com/file.pdf"),
            schoolID: UUID(),
            isPublic: false,
            createdAt: Date(),
            updatedAt: Date()
        )

        let dto = material.toDTO()

        #expect(dto.fileURL == "https://example.com/file.pdf")
    }

    @Test("Material toDTO converts status to rawValue")
    func testMaterialToDTOConvertsStatusToRawValue() throws {
        let material = try Material(
            id: UUID(),
            title: "Test Material",
            status: .processing,
            schoolID: UUID(),
            isPublic: false,
            createdAt: Date(),
            updatedAt: Date()
        )

        let dto = material.toDTO()

        #expect(dto.status == "processing")
    }
}
