import Foundation
@testable import EduModels

/// Factory methods for creating test DTOs with sensible defaults.
enum TestFixtures {

    // MARK: - UserDTO

    static func makeUserDTO(
        id: UUID = UUID(),
        firstName: String = "Test",
        lastName: String = "User",
        fullName: String? = nil,
        email: String = "test@example.com",
        isActive: Bool = true,
        role: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) -> UserDTO {
        UserDTO(
            id: id,
            firstName: firstName,
            lastName: lastName,
            fullName: fullName,
            email: email,
            isActive: isActive,
            role: role,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    // MARK: - RoleDTO

    static func makeRoleDTO(
        id: UUID = UUID(),
        name: String = "Test Role",
        level: Int = 1,
        permissionIDs: [UUID] = []
    ) -> RoleDTO {
        RoleDTO(
            id: id,
            name: name,
            level: level,
            permissionIDs: permissionIDs
        )
    }

    // MARK: - PermissionDTO

    static func makePermissionDTO(
        id: UUID = UUID(),
        code: String = "users.read",
        resource: String = "users",
        action: String = "read"
    ) -> PermissionDTO {
        PermissionDTO(
            id: id,
            code: code,
            resource: resource,
            action: action
        )
    }

    // MARK: - DocumentDTO

    static func makeDocumentDTO(
        id: UUID = UUID(),
        title: String = "Test Document",
        content: String = "Test content",
        type: String = "lesson",
        state: String = "draft",
        ownerID: UUID = UUID(),
        collaboratorIDs: [UUID] = [],
        createdAt: String = "2024-01-15T10:30:00.000Z",
        modifiedAt: String = "2024-01-15T10:30:00.000Z",
        version: Int = 1,
        tags: [String] = []
    ) -> DocumentDTO {
        let metadata = DocumentMetadataDTO(
            createdAt: createdAt,
            modifiedAt: modifiedAt,
            version: version,
            tags: tags
        )
        return DocumentDTO(
            id: id,
            title: title,
            content: content,
            type: type,
            state: state,
            ownerID: ownerID,
            collaboratorIDs: collaboratorIDs,
            metadata: metadata
        )
    }

    // MARK: - DocumentMetadataDTO

    static func makeDocumentMetadataDTO(
        createdAt: String = "2024-01-15T10:30:00.000Z",
        modifiedAt: String = "2024-01-15T10:30:00.000Z",
        version: Int = 1,
        tags: [String] = []
    ) -> DocumentMetadataDTO {
        DocumentMetadataDTO(
            createdAt: createdAt,
            modifiedAt: modifiedAt,
            version: version,
            tags: tags
        )
    }

    // MARK: - MembershipDTO

    static func makeMembershipDTO(
        id: UUID = UUID(),
        userID: UUID = UUID(),
        unitID: UUID = UUID(),
        role: String = "student",
        isActive: Bool = true,
        enrolledAt: Date = Date(),
        withdrawnAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) -> MembershipDTO {
        MembershipDTO(
            id: id,
            userID: userID,
            unitID: unitID,
            role: role,
            isActive: isActive,
            enrolledAt: enrolledAt,
            withdrawnAt: withdrawnAt,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    // MARK: - MaterialDTO

    static func makeMaterialDTO(
        id: UUID = UUID(),
        title: String = "Test Material",
        description: String? = nil,
        status: String = "uploaded",
        fileURL: String? = nil,
        fileType: String? = nil,
        fileSizeBytes: Int? = nil,
        schoolID: UUID = UUID(),
        academicUnitID: UUID? = nil,
        uploadedByTeacherID: UUID? = nil,
        subject: String? = nil,
        grade: String? = nil,
        isPublic: Bool = false,
        processingStartedAt: Date? = nil,
        processingCompletedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil
    ) -> MaterialDTO {
        MaterialDTO(
            id: id,
            title: title,
            description: description,
            status: status,
            fileURL: fileURL,
            fileType: fileType,
            fileSizeBytes: fileSizeBytes,
            schoolID: schoolID,
            academicUnitID: academicUnitID,
            uploadedByTeacherID: uploadedByTeacherID,
            subject: subject,
            grade: grade,
            isPublic: isPublic,
            processingStartedAt: processingStartedAt,
            processingCompletedAt: processingCompletedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt
        )
    }

    // MARK: - SchoolDTO

    static func makeSchoolDTO(
        id: UUID = UUID(),
        name: String = "Test School",
        code: String = "TEST-001",
        isActive: Bool = true,
        address: String? = nil,
        city: String? = nil,
        country: String? = nil,
        contactEmail: String? = nil,
        contactPhone: String? = nil,
        maxStudents: Int? = nil,
        maxTeachers: Int? = nil,
        subscriptionTier: String? = nil,
        metadata: [String: JSONValue]? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) -> SchoolDTO {
        SchoolDTO(
            id: id,
            name: name,
            code: code,
            isActive: isActive,
            address: address,
            city: city,
            country: country,
            contactEmail: contactEmail,
            contactPhone: contactPhone,
            maxStudents: maxStudents,
            maxTeachers: maxTeachers,
            subscriptionTier: subscriptionTier,
            metadata: metadata,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    // MARK: - AcademicUnitDTO

    static func makeAcademicUnitDTO(
        id: UUID = UUID(),
        displayName: String = "Test Unit",
        code: String? = nil,
        description: String? = nil,
        type: String = "grade",
        parentUnitID: UUID? = nil,
        schoolID: UUID = UUID(),
        metadata: [String: JSONValue]? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil
    ) -> AcademicUnitDTO {
        AcademicUnitDTO(
            id: id,
            displayName: displayName,
            code: code,
            description: description,
            type: type,
            parentUnitID: parentUnitID,
            schoolID: schoolID,
            metadata: metadata,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt
        )
    }
}
