import Foundation
import EduCore
import EduCore

/// Fixtures for integration tests supporting complete transformation chains.
///
/// Provides batch generation methods for all entity types with JSON, DTO, and Domain formats.
/// Used for end-to-end transformation tests: JSON → DTO → Domain → SwiftData → Domain → DTO → JSON.
enum IntegrationTestFixtures {

    // MARK: - CodableSerializer Access

    /// Thread-safe serializer for encoding/decoding DTOs.
    /// Uses CodableSerializer.dtoSerializer with ISO8601 dates.
    /// DTOs have explicit CodingKeys for snake_case, so no key conversion needed.
    static var serializer: CodableSerializer {
        CodableSerializer.dtoSerializer
    }

    /// Decodes a DTO from JSON data using the shared CodableSerializer.
    /// - Parameters:
    ///   - type: The type to decode.
    ///   - data: The JSON data.
    /// - Returns: The decoded value.
    static func decode<T: Decodable & Sendable>(_ type: T.Type, from data: Data) async throws -> T {
        try await serializer.decode(type, from: data)
    }

    /// Encodes a value to JSON data using the shared CodableSerializer.
    /// - Parameters:
    ///   - value: The value to encode.
    ///   - prettyPrinted: Whether to format the output.
    /// - Returns: The encoded JSON data.
    static func encode<T: Encodable & Sendable>(_ value: T, prettyPrinted: Bool = false) async throws -> Data {
        try await serializer.encode(value, prettyPrinted: prettyPrinted)
    }

    // MARK: - User Generators

    /// Generates batch of User JSON strings.
    ///
    /// - Parameter count: Number of JSON strings to generate.
    /// - Returns: Array of valid User JSON strings.
    static func generateUserJSONBatch(count: Int) -> [String] {
        let now = ISO8601DateFormatter().string(from: Date())
        return (0..<count).map { index in
            """
            {
                "id": "\(UUID().uuidString)",
                "first_name": "User",
                "last_name": "\(index)",
                "full_name": "User \(index)",
                "email": "user\(index)@integration.test",
                "is_active": true,
                "created_at": "\(now)",
                "updated_at": "\(now)"
            }
            """
        }
    }

    /// Generates batch of UserDTO objects.
    ///
    /// - Parameter count: Number of DTOs to generate.
    /// - Returns: Array of UserDTO objects.
    static func generateUserDTOBatch(count: Int) -> [UserDTO] {
        let now = Date()
        return (0..<count).map { index in
            UserDTO(
                id: UUID(),
                firstName: "User",
                lastName: "\(index)",
                fullName: "User \(index)",
                email: "user\(index)@integration.test",
                isActive: true,
                role: nil,
                createdAt: now,
                updatedAt: now
            )
        }
    }

    // MARK: - School Generators

    /// Generates batch of School JSON strings.
    ///
    /// - Parameter count: Number of JSON strings to generate.
    /// - Returns: Array of valid School JSON strings.
    static func generateSchoolJSONBatch(count: Int) -> [String] {
        let now = ISO8601DateFormatter().string(from: Date())
        return (0..<count).map { index in
            """
            {
                "id": "\(UUID().uuidString)",
                "name": "School \(index)",
                "code": "SCH-\(index)",
                "is_active": true,
                "address": "Address \(index)",
                "city": "City \(index)",
                "country": "Country",
                "contact_email": "school\(index)@integration.test",
                "contact_phone": "+1-555-\(String(format: "%04d", index))",
                "max_students": \(100 + index * 10),
                "max_teachers": \(10 + index),
                "subscription_tier": "standard",
                "metadata": {"test_index": \(index)},
                "created_at": "\(now)",
                "updated_at": "\(now)"
            }
            """
        }
    }

    /// Generates batch of SchoolDTO objects.
    ///
    /// - Parameter count: Number of DTOs to generate.
    /// - Returns: Array of SchoolDTO objects.
    static func generateSchoolDTOBatch(count: Int) -> [SchoolDTO] {
        let now = Date()
        return (0..<count).map { index in
            SchoolDTO(
                id: UUID(),
                name: "School \(index)",
                code: "SCH-\(index)",
                isActive: true,
                address: "Address \(index)",
                city: "City \(index)",
                country: "Country",
                contactEmail: "school\(index)@integration.test",
                contactPhone: "+1-555-\(String(format: "%04d", index))",
                maxStudents: 100 + index * 10,
                maxTeachers: 10 + index,
                subscriptionTier: "standard",
                metadata: ["test_index": .integer(index)],
                createdAt: now,
                updatedAt: now
            )
        }
    }

    // MARK: - Membership Generators

    /// Generates batch of Membership JSON strings.
    ///
    /// - Parameters:
    ///   - count: Number of JSON strings to generate.
    ///   - userIDs: Optional array of user IDs to cycle through.
    ///   - unitIDs: Optional array of unit IDs to cycle through.
    /// - Returns: Array of valid Membership JSON strings.
    static func generateMembershipJSONBatch(
        count: Int,
        userIDs: [UUID]? = nil,
        unitIDs: [UUID]? = nil
    ) -> [String] {
        let now = ISO8601DateFormatter().string(from: Date())
        let roles = ["student", "teacher", "owner", "assistant", "guardian"]

        return (0..<count).map { index in
            let userID = userIDs?[index % (userIDs?.count ?? 1)] ?? UUID()
            let unitID = unitIDs?[index % (unitIDs?.count ?? 1)] ?? UUID()
            let role = roles[index % roles.count]

            return """
            {
                "id": "\(UUID().uuidString)",
                "user_id": "\(userID.uuidString)",
                "unit_id": "\(unitID.uuidString)",
                "role": "\(role)",
                "is_active": true,
                "enrolled_at": "\(now)",
                "withdrawn_at": null,
                "created_at": "\(now)",
                "updated_at": "\(now)"
            }
            """
        }
    }

    /// Generates batch of MembershipDTO objects.
    ///
    /// - Parameter count: Number of DTOs to generate.
    /// - Returns: Array of MembershipDTO objects.
    static func generateMembershipDTOBatch(count: Int) -> [MembershipDTO] {
        let now = Date()
        let roles = MembershipRole.allCases

        return (0..<count).map { index in
            MembershipDTO(
                id: UUID(),
                userID: UUID(),
                unitID: UUID(),
                role: roles[index % roles.count].rawValue,
                isActive: true,
                enrolledAt: now,
                withdrawnAt: nil,
                createdAt: now,
                updatedAt: now
            )
        }
    }

    // MARK: - Material Generators

    /// Generates batch of Material JSON strings.
    ///
    /// - Parameters:
    ///   - count: Number of JSON strings to generate.
    ///   - schoolID: Optional school ID for all materials.
    /// - Returns: Array of valid Material JSON strings.
    static func generateMaterialJSONBatch(count: Int, schoolID: UUID? = nil) -> [String] {
        let now = ISO8601DateFormatter().string(from: Date())
        let statuses = ["uploaded", "processing", "ready", "failed"]
        let finalSchoolID = schoolID ?? UUID()

        return (0..<count).map { index in
            let status = statuses[index % statuses.count]
            return """
            {
                "id": "\(UUID().uuidString)",
                "title": "Material \(index)",
                "description": "Description for material \(index)",
                "status": "\(status)",
                "file_url": "https://example.com/materials/\(index).pdf",
                "file_type": "application/pdf",
                "file_size_bytes": \(1024 * (index + 1)),
                "school_id": "\(finalSchoolID.uuidString)",
                "is_public": \(index % 2 == 0),
                "created_at": "\(now)",
                "updated_at": "\(now)"
            }
            """
        }
    }

    /// Generates batch of MaterialDTO objects.
    ///
    /// - Parameters:
    ///   - count: Number of DTOs to generate.
    ///   - schoolID: Optional school ID for all materials.
    /// - Returns: Array of MaterialDTO objects.
    static func generateMaterialDTOBatch(count: Int, schoolID: UUID? = nil) -> [MaterialDTO] {
        let now = Date()
        let statuses = MaterialStatus.allCases
        let finalSchoolID = schoolID ?? UUID()

        return (0..<count).map { index in
            MaterialDTO(
                id: UUID(),
                title: "Material \(index)",
                description: "Description for material \(index)",
                status: statuses[index % statuses.count].rawValue,
                fileURL: "https://example.com/materials/\(index).pdf",
                fileType: "application/pdf",
                fileSizeBytes: 1024 * (index + 1),
                schoolID: finalSchoolID,
                academicUnitID: nil,
                uploadedByTeacherID: nil,
                subject: "Subject \(index % 5)",
                grade: "Grade \(index % 12 + 1)",
                isPublic: index % 2 == 0,
                processingStartedAt: nil,
                processingCompletedAt: nil,
                createdAt: now,
                updatedAt: now,
                deletedAt: nil
            )
        }
    }

    // MARK: - AcademicUnit Generators

    /// Generates batch of AcademicUnit JSON strings.
    ///
    /// - Parameters:
    ///   - count: Number of JSON strings to generate.
    ///   - schoolID: Optional school ID for all units.
    /// - Returns: Array of valid AcademicUnit JSON strings.
    static func generateAcademicUnitJSONBatch(count: Int, schoolID: UUID? = nil) -> [String] {
        let now = ISO8601DateFormatter().string(from: Date())
        let types = ["grade", "section", "course", "department", "club"]
        let finalSchoolID = schoolID ?? UUID()

        return (0..<count).map { index in
            let type = types[index % types.count]
            return """
            {
                "id": "\(UUID().uuidString)",
                "display_name": "Unit \(index)",
                "type": "\(type)",
                "school_id": "\(finalSchoolID.uuidString)",
                "parent_unit_id": null,
                "metadata": {"order": \(index)},
                "created_at": "\(now)",
                "updated_at": "\(now)"
            }
            """
        }
    }

    /// Generates batch of AcademicUnitDTO objects.
    ///
    /// - Parameters:
    ///   - count: Number of DTOs to generate.
    ///   - schoolID: Optional school ID for all units.
    /// - Returns: Array of AcademicUnitDTO objects.
    static func generateAcademicUnitDTOBatch(count: Int, schoolID: UUID? = nil) -> [AcademicUnitDTO] {
        let now = Date()
        let types = AcademicUnitType.allCases
        let finalSchoolID = schoolID ?? UUID()

        return (0..<count).map { index in
            AcademicUnitDTO(
                id: UUID(),
                displayName: "Unit \(index)",
                code: "UNIT-\(index)",
                description: "Description for unit \(index)",
                type: types[index % types.count].rawValue,
                parentUnitID: nil,
                schoolID: finalSchoolID,
                metadata: ["order": .integer(index)],
                createdAt: now,
                updatedAt: now,
                deletedAt: nil
            )
        }
    }

    // MARK: - Complete Entity Graph Generator

    /// Generates a complete entity graph for end-to-end testing.
    ///
    /// Creates a school with academic units, users, memberships, and materials
    /// that are properly related to each other.
    ///
    /// - Returns: Tuple containing all related entities.
    static func generateCompleteEntityGraph() throws -> (
        school: School,
        units: [AcademicUnit],
        users: [User],
        memberships: [Membership],
        materials: [Material]
    ) {
        let now = Date()

        // Create school
        let school = try School(
            name: "Integration Test School",
            code: "INT-001",
            isActive: true,
            address: "123 Test Street",
            city: "Test City",
            country: "Test Country",
            contactEmail: "integration@test.school",
            contactPhone: "+1-555-0001",
            maxStudents: 500,
            maxTeachers: 50,
            subscriptionTier: "premium",
            metadata: ["integration_test": .bool(true)],
            createdAt: now,
            updatedAt: now
        )

        // Create academic units (grades and sections)
        var units: [AcademicUnit] = []
        for gradeIndex in 1...3 {
            let grade = try AcademicUnit(
                displayName: "Grade \(gradeIndex)",
                type: .grade,
                schoolID: school.id,
                metadata: ["level": .integer(gradeIndex)],
                createdAt: now,
                updatedAt: now
            )
            units.append(grade)

            // Create sections under each grade
            for sectionIndex in 1...2 {
                let section = try AcademicUnit(
                    displayName: "Section \(gradeIndex)-\(sectionIndex)",
                    type: .section,
                    parentUnitID: grade.id,
                    schoolID: school.id,
                    createdAt: now,
                    updatedAt: now
                )
                units.append(section)
            }
        }

        // Create users
        var users: [User] = []
        for i in 0..<10 {
            let user = try User(
                firstName: "Integration",
                lastName: "User\(i)",
                email: "integration.user\(i)@test.school",
                isActive: true,
                createdAt: now,
                updatedAt: now
            )
            users.append(user)
        }

        // Create memberships (connect users to units)
        var memberships: [Membership] = []
        let roles = MembershipRole.allCases
        for (index, user) in users.enumerated() {
            let unit = units[index % units.count]
            let membership = Membership(
                userID: user.id,
                unitID: unit.id,
                role: roles[index % roles.count],
                isActive: true,
                enrolledAt: now,
                createdAt: now,
                updatedAt: now
            )
            memberships.append(membership)
        }

        // Create materials
        var materials: [Material] = []
        let statuses = MaterialStatus.allCases
        for i in 0..<5 {
            let material = try Material(
                title: "Integration Material \(i)",
                description: "Material for integration testing",
                status: statuses[i % statuses.count],
                fileURL: URL(string: "https://example.com/integration/material\(i).pdf"),
                fileType: "application/pdf",
                fileSizeBytes: 1024 * (i + 1),
                schoolID: school.id,
                academicUnitID: units[i % units.count].id,
                isPublic: i % 2 == 0,
                createdAt: now,
                updatedAt: now
            )
            materials.append(material)
        }

        return (school, units, users, memberships, materials)
    }

    // MARK: - Invalid JSON Generators (for error testing)

    /// Generates invalid User JSON for error testing.
    static func generateInvalidUserJSON() -> [String] {
        [
            // Missing required field
            """
            {
                "id": "\(UUID().uuidString)",
                "first_name": "Test",
                "email": "test@test.com",
                "is_active": true,
                "created_at": "2024-01-01T00:00:00Z",
                "updated_at": "2024-01-01T00:00:00Z"
            }
            """,
            // Invalid UUID
            """
            {
                "id": "not-a-uuid",
                "first_name": "Test",
                "last_name": "User",
                "email": "test@test.com",
                "is_active": true,
                "created_at": "2024-01-01T00:00:00Z",
                "updated_at": "2024-01-01T00:00:00Z"
            }
            """,
            // Invalid date format
            """
            {
                "id": "\(UUID().uuidString)",
                "first_name": "Test",
                "last_name": "User",
                "email": "test@test.com",
                "is_active": true,
                "created_at": "2024/01/01",
                "updated_at": "2024-01-01T00:00:00Z"
            }
            """
        ]
    }

    /// Generates JSON with invalid enum values for error testing.
    static func generateInvalidEnumJSON() -> [String] {
        let now = ISO8601DateFormatter().string(from: Date())
        return [
            // Invalid membership role
            """
            {
                "id": "\(UUID().uuidString)",
                "user_id": "\(UUID().uuidString)",
                "unit_id": "\(UUID().uuidString)",
                "role": "invalid_role",
                "is_active": true,
                "enrolled_at": "\(now)",
                "created_at": "\(now)",
                "updated_at": "\(now)"
            }
            """,
            // Invalid material status
            """
            {
                "id": "\(UUID().uuidString)",
                "title": "Test Material",
                "status": "invalid_status",
                "school_id": "\(UUID().uuidString)",
                "is_public": false,
                "created_at": "\(now)",
                "updated_at": "\(now)"
            }
            """,
            // Invalid academic unit type
            """
            {
                "id": "\(UUID().uuidString)",
                "display_name": "Test Unit",
                "type": "invalid_type",
                "school_id": "\(UUID().uuidString)",
                "created_at": "\(now)",
                "updated_at": "\(now)"
            }
            """
        ]
    }
}
