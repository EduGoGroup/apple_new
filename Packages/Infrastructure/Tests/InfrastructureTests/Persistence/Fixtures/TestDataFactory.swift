import Foundation
import EduCore

/// Factory for creating test data
///
/// Provides helper methods for creating valid User, Document, and other entities
/// for use in unit tests.
enum TestDataFactory {
    /// Creates a valid User with default or custom values
    ///
    /// - Parameters:
    ///   - id: User ID (defaults to new UUID)
    ///   - firstName: User first name (defaults to "Test")
    ///   - lastName: User last name (defaults to "User")
    ///   - email: User email (defaults to unique email based on ID)
    ///   - isActive: Active status (defaults to true)
    ///   - createdAt: Creation timestamp (defaults to now)
    ///   - updatedAt: Last update timestamp (defaults to now)
    /// - Returns: A valid User entity
    static func makeUser(
        id: UUID = UUID(),
        firstName: String = "Test",
        lastName: String = "User",
        email: String? = nil,
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) throws -> User {
        let finalEmail = email ?? "test-\(id.uuidString.prefix(8))@example.com"
        return try User(
            id: id,
            firstName: firstName,
            lastName: lastName,
            email: finalEmail,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// Creates a valid School with default or custom values
    static func makeSchool(
        id: UUID = UUID(),
        name: String = "Test School",
        code: String? = nil,
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) throws -> School {
        let finalCode = code ?? "SCH-\(id.uuidString.prefix(8))"
        return try School(
            id: id,
            name: name,
            code: finalCode,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// Creates a valid AcademicUnit with default or custom values
    static func makeAcademicUnit(
        id: UUID = UUID(),
        displayName: String = "Test Unit",
        type: AcademicUnitType = .grade,
        schoolID: UUID = UUID(),
        parentUnitID: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) throws -> AcademicUnit {
        return try AcademicUnit(
            id: id,
            displayName: displayName,
            type: type,
            parentUnitID: parentUnitID,
            schoolID: schoolID,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// Creates a valid Membership with default or custom values
    static func makeMembership(
        id: UUID = UUID(),
        userID: UUID = UUID(),
        unitID: UUID = UUID(),
        role: MembershipRole = .student,
        isActive: Bool = true,
        enrolledAt: Date = Date(),
        withdrawnAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) -> Membership {
        return Membership(
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

    /// Creates a valid Material with default or custom values
    static func makeMaterial(
        id: UUID = UUID(),
        title: String = "Test Material",
        status: MaterialStatus = .uploaded,
        schoolID: UUID = UUID(),
        isPublic: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) throws -> Material {
        return try Material(
            id: id,
            title: title,
            status: status,
            schoolID: schoolID,
            isPublic: isPublic,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// Creates a valid Document with default or custom values
    ///
    /// - Parameters:
    ///   - id: Document ID (defaults to new UUID)
    ///   - title: Document title (defaults to "Test Document")
    ///   - content: Document content (defaults to "Test content")
    ///   - type: Document type (defaults to .lesson)
    ///   - state: Document state (defaults to .draft)
    ///   - ownerID: Owner ID (defaults to new UUID)
    ///   - collaboratorIDs: Set of collaborator IDs (defaults to empty)
    ///   - version: Metadata version (defaults to 1)
    ///   - tags: Set of tags (defaults to empty)
    /// - Returns: A valid Document entity
    static func makeDocument(
        id: UUID = UUID(),
        title: String = "Test Document",
        content: String = "Test content",
        type: DocumentType = .lesson,
        state: DocumentState = .draft,
        ownerID: UUID = UUID(),
        collaboratorIDs: Set<UUID> = [],
        version: Int = 1,
        tags: Set<String> = []
    ) throws -> Document {
        let metadata = DocumentMetadata(
            createdAt: Date(),
            modifiedAt: Date(),
            version: version,
            tags: tags
        )
        return try Document(
            id: id,
            title: title,
            content: content,
            type: type,
            state: state,
            metadata: metadata,
            ownerID: ownerID,
            collaboratorIDs: collaboratorIDs
        )
    }

    /// Creates multiple users with unique data
    ///
    /// - Parameter count: Number of users to create
    /// - Returns: Array of valid User entities
    static func makeUsers(count: Int) throws -> [User] {
        try (0..<count).map { index in
            try makeUser(
                firstName: "User",
                lastName: "\(index)",
                email: "user\(index)@example.com"
            )
        }
    }

    /// Creates multiple documents with unique data
    ///
    /// - Parameters:
    ///   - count: Number of documents to create
    ///   - ownerID: Owner ID for all documents
    /// - Returns: Array of valid Document entities
    static func makeDocuments(count: Int, ownerID: UUID = UUID()) throws -> [Document] {
        try (0..<count).map { index in
            try makeDocument(
                title: "Document \(index)",
                content: "Content for document \(index)",
                ownerID: ownerID
            )
        }
    }

    // MARK: - Batch Creation Methods

    /// Creates multiple schools with unique data
    ///
    /// - Parameter count: Number of schools to create
    /// - Returns: Array of valid School entities
    static func makeSchools(count: Int) throws -> [School] {
        try (0..<count).map { index in
            try makeSchool(
                name: "School \(index)",
                code: "SCH-\(index)"
            )
        }
    }

    /// Creates multiple academic units with unique data
    ///
    /// - Parameters:
    ///   - count: Number of units to create
    ///   - schoolID: School ID for all units
    /// - Returns: Array of valid AcademicUnit entities
    static func makeAcademicUnits(count: Int, schoolID: UUID = UUID()) throws -> [AcademicUnit] {
        try (0..<count).map { index in
            try makeAcademicUnit(
                displayName: "Unit \(index)",
                type: .grade,
                schoolID: schoolID
            )
        }
    }

    /// Creates multiple memberships with unique data
    ///
    /// - Parameters:
    ///   - count: Number of memberships to create
    ///   - userID: Optional fixed user ID
    ///   - unitID: Optional fixed unit ID
    /// - Returns: Array of Membership entities
    static func makeMemberships(count: Int, userID: UUID? = nil, unitID: UUID? = nil) -> [Membership] {
        (0..<count).map { index in
            makeMembership(
                userID: userID ?? UUID(),
                unitID: unitID ?? UUID(),
                role: MembershipRole.allCases[index % MembershipRole.allCases.count]
            )
        }
    }

    /// Creates multiple materials with unique data
    ///
    /// - Parameters:
    ///   - count: Number of materials to create
    ///   - schoolID: School ID for all materials
    /// - Returns: Array of valid Material entities
    static func makeMaterials(count: Int, schoolID: UUID = UUID()) throws -> [Material] {
        try (0..<count).map { index in
            try makeMaterial(
                title: "Material \(index)",
                status: MaterialStatus.allCases[index % MaterialStatus.allCases.count],
                schoolID: schoolID
            )
        }
    }

    // MARK: - Relationship Creation Methods

    /// Creates a complete school hierarchy with units and memberships
    ///
    /// - Parameter schoolName: Name for the school
    /// - Returns: Tuple containing school, units, and memberships
    static func makeSchoolHierarchy(
        schoolName: String = "Test School"
    ) throws -> (school: School, units: [AcademicUnit], memberships: [Membership]) {
        let school = try makeSchool(name: schoolName)

        // Create grade units
        let grade1 = try makeAcademicUnit(
            displayName: "Grade 1",
            type: .grade,
            schoolID: school.id
        )
        let grade2 = try makeAcademicUnit(
            displayName: "Grade 2",
            type: .grade,
            schoolID: school.id
        )

        // Create section under grade 1
        let section1A = try makeAcademicUnit(
            displayName: "Section 1-A",
            type: .section,
            schoolID: school.id,
            parentUnitID: grade1.id
        )

        let units = [grade1, grade2, section1A]

        // Create memberships for the section
        let teacherMembership = makeMembership(
            unitID: section1A.id,
            role: .teacher
        )
        let studentMembership1 = makeMembership(
            unitID: section1A.id,
            role: .student
        )
        let studentMembership2 = makeMembership(
            unitID: section1A.id,
            role: .student
        )

        let memberships = [teacherMembership, studentMembership1, studentMembership2]

        return (school, units, memberships)
    }

    /// Creates a user with multiple memberships across different units
    ///
    /// - Parameters:
    ///   - membershipCount: Number of memberships to create
    /// - Returns: Tuple containing user and their memberships
    static func makeUserWithMemberships(
        membershipCount: Int = 3
    ) throws -> (user: User, memberships: [Membership]) {
        let user = try makeUser()

        let memberships = (0..<membershipCount).map { index in
            makeMembership(
                userID: user.id,
                unitID: UUID(),
                role: MembershipRole.allCases[index % MembershipRole.allCases.count]
            )
        }

        return (user, memberships)
    }

    /// Creates materials with all possible status values
    ///
    /// - Parameter schoolID: School ID for all materials
    /// - Returns: Array of materials with each status
    static func makeMaterialsWithAllStatuses(schoolID: UUID = UUID()) throws -> [Material] {
        try MaterialStatus.allCases.map { status in
            try makeMaterial(
                title: "Material - \(status.rawValue)",
                status: status,
                schoolID: schoolID
            )
        }
    }

    /// Creates memberships with all possible role values
    ///
    /// - Parameter unitID: Unit ID for all memberships
    /// - Returns: Array of memberships with each role
    static func makeMembershipsWithAllRoles(unitID: UUID = UUID()) -> [Membership] {
        MembershipRole.allCases.map { role in
            makeMembership(
                unitID: unitID,
                role: role
            )
        }
    }

    /// Creates academic units with all possible type values
    ///
    /// - Parameter schoolID: School ID for all units
    /// - Returns: Array of units with each type
    static func makeAcademicUnitsWithAllTypes(schoolID: UUID = UUID()) throws -> [AcademicUnit] {
        try AcademicUnitType.allCases.map { type in
            try makeAcademicUnit(
                displayName: "Unit - \(type.rawValue)",
                type: type,
                schoolID: schoolID
            )
        }
    }

    // MARK: - Edge Case Methods

    /// Creates a user with minimal required data
    static func makeMinimalUser() throws -> User {
        try User(
            firstName: "A",
            lastName: "B",
            email: "a@b.co"
        )
    }

    /// Creates a school with minimal required data
    static func makeMinimalSchool() throws -> School {
        try School(
            name: "S",
            code: "S1"
        )
    }

    /// Creates a material with all optional fields populated
    static func makeFullMaterial(schoolID: UUID = UUID()) throws -> Material {
        let academicUnitID = UUID()
        let teacherID = UUID()
        let url = URL(string: "https://example.com/materials/test.pdf")!

        return try Material(
            title: "Complete Material",
            description: "A fully populated material for testing",
            status: .ready,
            fileURL: url,
            fileType: "application/pdf",
            fileSizeBytes: 1024000,
            schoolID: schoolID,
            academicUnitID: academicUnitID,
            uploadedByTeacherID: teacherID,
            subject: "Mathematics",
            grade: "5th Grade",
            isPublic: true,
            processingStartedAt: Date().addingTimeInterval(-3600),
            processingCompletedAt: Date()
        )
    }

    /// Creates a school with all optional fields populated
    static func makeFullSchool() throws -> School {
        try School(
            name: "Complete Academy",
            code: "COMP-001",
            address: "123 Education Lane",
            city: "Learning City",
            country: "Knowledge Nation",
            contactEmail: "admin@completeacademy.edu",
            contactPhone: "+1-555-123-4567",
            maxStudents: 1000,
            maxTeachers: 100,
            subscriptionTier: "enterprise",
            metadata: [
                "founded": .integer(1990),
                "accredited": .bool(true),
                "website": .string("https://completeacademy.edu")
            ]
        )
    }

    /// Creates an academic unit with metadata
    static func makeAcademicUnitWithMetadata(
        schoolID: UUID = UUID()
    ) throws -> AcademicUnit {
        try AcademicUnit(
            displayName: "Advanced Mathematics",
            type: .course,
            schoolID: schoolID,
            metadata: [
                "credits": .integer(4),
                "required": .bool(true),
                "level": .string("advanced")
            ]
        )
    }

    /// Creates a withdrawn membership
    static func makeWithdrawnMembership(
        userID: UUID = UUID(),
        unitID: UUID = UUID()
    ) -> Membership {
        Membership(
            userID: userID,
            unitID: unitID,
            role: .student,
            isActive: false,
            enrolledAt: Date().addingTimeInterval(-86400 * 365), // 1 year ago
            withdrawnAt: Date().addingTimeInterval(-86400 * 30) // 30 days ago
        )
    }
}
