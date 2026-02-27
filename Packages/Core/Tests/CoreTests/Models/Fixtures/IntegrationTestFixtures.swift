// IntegrationTestFixtures.swift
// ModelsTests
//
// Test fixtures for end-to-end integration tests.
// Provides batch data generators and transformation helpers.

import Foundation
@testable import EduModels

/// Integration test fixtures for end-to-end transformation tests.
///
/// Provides:
/// - Batch generation of entities for performance testing
/// - Pre-configured JSON data for complete transformation chains
/// - Helper methods for creating complex entity graphs
enum IntegrationTestFixtures {

    // MARK: - Batch User Generation

    /// Generates a batch of valid user JSON strings.
    ///
    /// - Parameter count: Number of users to generate
    /// - Returns: Array of JSON strings representing users
    static func generateUserJSONBatch(count: Int) -> [String] {
        (0..<count).map { i in
            """
            {
                "id": "\(UUID().uuidString)",
                "first_name": "User\(i)",
                "last_name": "Test\(i)",
                "email": "user\(i)@integration.test",
                "is_active": \(i % 3 != 0),
                "created_at": "2024-01-15T10:30:00Z",
                "updated_at": "2024-01-20T14:45:00Z"
            }
            """
        }
    }

    /// Generates valid UserDTO instances for batch testing.
    ///
    /// - Parameter count: Number of DTOs to generate
    /// - Returns: Array of UserDTO instances
    static func generateUserDTOBatch(count: Int) -> [UserDTO] {
        (0..<count).map { i in
            UserDTO(
                id: UUID(),
                firstName: "User\(i)",
                lastName: "Test\(i)",
                email: "user\(i)@integration.test",
                isActive: i % 3 != 0,
                createdAt: Date(),
                updatedAt: Date()
            )
        }
    }

    // MARK: - Batch School Generation

    /// Generates a batch of valid school JSON strings.
    ///
    /// - Parameter count: Number of schools to generate
    /// - Returns: Array of JSON strings representing schools
    static func generateSchoolJSONBatch(count: Int) -> [String] {
        (0..<count).map { i in
            """
            {
                "id": "\(UUID().uuidString)",
                "name": "School \(i)",
                "code": "SCH-\(String(format: "%04d", i))",
                "is_active": true,
                "address": "Address \(i)",
                "city": "City \(i % 10)",
                "country": "CO",
                "max_students": \(100 + i * 10),
                "max_teachers": \(10 + i),
                "subscription_tier": "\(["free", "basic", "premium"][i % 3])",
                "created_at": "2024-01-15T10:30:00Z",
                "updated_at": "2024-01-20T14:45:00Z"
            }
            """
        }
    }

    /// Generates valid SchoolDTO instances for batch testing.
    ///
    /// - Parameter count: Number of DTOs to generate
    /// - Returns: Array of SchoolDTO instances
    static func generateSchoolDTOBatch(count: Int) -> [SchoolDTO] {
        (0..<count).map { i in
            SchoolDTO(
                id: UUID(),
                name: "School \(i)",
                code: "SCH-\(String(format: "%04d", i))",
                isActive: true,
                address: "Address \(i)",
                city: "City \(i % 10)",
                country: "CO",
                contactEmail: "school\(i)@test.com",
                contactPhone: nil,
                maxStudents: 100 + i * 10,
                maxTeachers: 10 + i,
                subscriptionTier: ["free", "basic", "premium"][i % 3],
                metadata: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
        }
    }

    // MARK: - Batch Membership Generation

    /// Generates a batch of valid membership JSON strings.
    ///
    /// - Parameters:
    ///   - count: Number of memberships to generate
    ///   - userIDs: Optional array of user IDs to cycle through
    ///   - unitIDs: Optional array of unit IDs to cycle through
    /// - Returns: Array of JSON strings representing memberships
    static func generateMembershipJSONBatch(
        count: Int,
        userIDs: [UUID]? = nil,
        unitIDs: [UUID]? = nil
    ) -> [String] {
        let roles = ["owner", "teacher", "assistant", "student", "guardian"]
        let users = userIDs ?? (0..<10).map { _ in UUID() }
        let units = unitIDs ?? (0..<5).map { _ in UUID() }

        return (0..<count).map { i in
            """
            {
                "id": "\(UUID().uuidString)",
                "user_id": "\(users[i % users.count].uuidString)",
                "unit_id": "\(units[i % units.count].uuidString)",
                "role": "\(roles[i % roles.count])",
                "is_active": \(i % 4 != 0),
                "enrolled_at": "2024-01-15T10:30:00Z",
                "withdrawn_at": \(i % 4 == 0 ? "\"2024-06-15T16:00:00Z\"" : "null"),
                "created_at": "2024-01-15T10:30:00Z",
                "updated_at": "2024-01-20T14:45:00Z"
            }
            """
        }
    }

    /// Generates valid MembershipDTO instances for batch testing.
    ///
    /// - Parameter count: Number of DTOs to generate
    /// - Returns: Array of MembershipDTO instances
    static func generateMembershipDTOBatch(count: Int) -> [MembershipDTO] {
        let roles = ["owner", "teacher", "assistant", "student", "guardian"]

        return (0..<count).map { i in
            MembershipDTO(
                id: UUID(),
                userID: UUID(),
                unitID: UUID(),
                role: roles[i % roles.count],
                isActive: i % 4 != 0,
                enrolledAt: Date(),
                withdrawnAt: i % 4 == 0 ? Date() : nil,
                createdAt: Date(),
                updatedAt: Date()
            )
        }
    }

    // MARK: - Batch Material Generation

    /// Generates a batch of valid material JSON strings.
    ///
    /// - Parameters:
    ///   - count: Number of materials to generate
    ///   - schoolID: Optional school ID for all materials
    /// - Returns: Array of JSON strings representing materials
    static func generateMaterialJSONBatch(count: Int, schoolID: UUID? = nil) -> [String] {
        let statuses = ["uploaded", "processing", "ready", "failed"]
        let subjects = ["Matemáticas", "Ciencias", "Historia", "Física", "Química"]
        let school = schoolID ?? UUID()

        return (0..<count).map { i in
            let status = statuses[i % statuses.count]
            let hasFileURL = status == "ready" || status == "processing"

            return """
            {
                "id": "\(UUID().uuidString)",
                "title": "Material \(i)",
                "description": \(i % 2 == 0 ? "\"Descripción del material \(i)\"" : "null"),
                "status": "\(status)",
                "file_url": \(hasFileURL ? "\"https://example.com/materials/\(i).pdf\"" : "null"),
                "file_type": \(hasFileURL ? "\"application/pdf\"" : "null"),
                "file_size_bytes": \(hasFileURL ? "\(1024 * (i + 1))" : "null"),
                "school_id": "\(school.uuidString)",
                "academic_unit_id": null,
                "uploaded_by_teacher_id": null,
                "subject": "\(subjects[i % subjects.count])",
                "grade": "\(10 + i % 3)° Grado",
                "is_public": \(i % 5 == 0),
                "processing_started_at": \(status != "uploaded" ? "\"2024-01-20T10:00:00Z\"" : "null"),
                "processing_completed_at": \(status == "ready" || status == "failed" ? "\"2024-01-20T10:05:00Z\"" : "null"),
                "created_at": "2024-01-20T10:00:00Z",
                "updated_at": "2024-01-20T10:05:00Z",
                "deleted_at": null
            }
            """
        }
    }

    /// Generates valid MaterialDTO instances for batch testing.
    ///
    /// - Parameters:
    ///   - count: Number of DTOs to generate
    ///   - schoolID: Optional school ID for all materials
    /// - Returns: Array of MaterialDTO instances
    static func generateMaterialDTOBatch(count: Int, schoolID: UUID? = nil) -> [MaterialDTO] {
        let statuses = ["uploaded", "processing", "ready", "failed"]
        let subjects = ["Matemáticas", "Ciencias", "Historia", "Física", "Química"]
        let school = schoolID ?? UUID()

        return (0..<count).map { i in
            let status = statuses[i % statuses.count]
            let hasFileURL = status == "ready" || status == "processing"

            return MaterialDTO(
                id: UUID(),
                title: "Material \(i)",
                description: i % 2 == 0 ? "Descripción del material \(i)" : nil,
                status: status,
                fileURL: hasFileURL ? "https://example.com/materials/\(i).pdf" : nil,
                fileType: hasFileURL ? "application/pdf" : nil,
                fileSizeBytes: hasFileURL ? 1024 * (i + 1) : nil,
                schoolID: school,
                academicUnitID: nil,
                uploadedByTeacherID: nil,
                subject: subjects[i % subjects.count],
                grade: "\(10 + i % 3)° Grado",
                isPublic: i % 5 == 0,
                processingStartedAt: status != "uploaded" ? Date() : nil,
                processingCompletedAt: (status == "ready" || status == "failed") ? Date() : nil,
                createdAt: Date(),
                updatedAt: Date(),
                deletedAt: nil
            )
        }
    }

    // MARK: - Batch AcademicUnit Generation

    /// Generates a batch of valid academic unit JSON strings.
    ///
    /// - Parameters:
    ///   - count: Number of units to generate
    ///   - schoolID: Optional school ID for all units
    /// - Returns: Array of JSON strings representing academic units
    static func generateAcademicUnitJSONBatch(count: Int, schoolID: UUID? = nil) -> [String] {
        let types = ["grade", "section", "club", "department", "course"]
        let school = schoolID ?? UUID()

        return (0..<count).map { i in
            """
            {
                "id": "\(UUID().uuidString)",
                "display_name": "Unit \(i)",
                "code": "UNIT-\(String(format: "%04d", i))",
                "description": \(i % 2 == 0 ? "\"Description for unit \(i)\"" : "null"),
                "type": "\(types[i % types.count])",
                "parent_unit_id": null,
                "school_id": "\(school.uuidString)",
                "metadata": null,
                "created_at": "2024-01-15T10:30:00Z",
                "updated_at": "2024-01-20T14:45:00Z",
                "deleted_at": null
            }
            """
        }
    }

    /// Generates valid AcademicUnitDTO instances for batch testing.
    ///
    /// - Parameters:
    ///   - count: Number of DTOs to generate
    ///   - schoolID: Optional school ID for all units
    /// - Returns: Array of AcademicUnitDTO instances
    static func generateAcademicUnitDTOBatch(count: Int, schoolID: UUID? = nil) -> [AcademicUnitDTO] {
        let types = ["grade", "section", "club", "department", "course"]
        let school = schoolID ?? UUID()

        return (0..<count).map { i in
            AcademicUnitDTO(
                id: UUID(),
                displayName: "Unit \(i)",
                code: "UNIT-\(String(format: "%04d", i))",
                description: i % 2 == 0 ? "Description for unit \(i)" : nil,
                type: types[i % types.count],
                parentUnitID: nil,
                schoolID: school,
                metadata: nil,
                createdAt: Date(),
                updatedAt: Date(),
                deletedAt: nil
            )
        }
    }

    // MARK: - Complete Entity Graph

    /// Generates a complete entity graph for integration testing.
    ///
    /// Creates a school with academic units and memberships.
    ///
    /// - Returns: Tuple containing all generated entities
    static func generateCompleteEntityGraph() throws -> (
        school: School,
        units: [AcademicUnit],
        users: [User],
        memberships: [Membership],
        materials: [Material]
    ) {
        // Create school
        let school = try School(
            name: "Integration Test School",
            code: "INT-TEST-001",
            isActive: true,
            address: "123 Test Street",
            city: "Test City",
            country: "CO"
        )

        // Create academic units
        let grade = try AcademicUnit(
            displayName: "Grade 10",
            type: .grade,
            schoolID: school.id
        )

        let section = try AcademicUnit(
            displayName: "Section A",
            type: .section,
            parentUnitID: grade.id,
            schoolID: school.id
        )

        let club = try AcademicUnit(
            displayName: "Math Club",
            type: .club,
            schoolID: school.id
        )

        let units = [grade, section, club]

        // Create users
        let users = try (0..<5).map { i in
            try User(
                firstName: "User",
                lastName: "\(i)",
                email: "user\(i)@integration.test"
            )
        }

        // Create memberships
        var memberships: [Membership] = []
        let roles: [MembershipRole] = [.teacher, .student, .student, .student, .guardian]
        for (index, user) in users.enumerated() {
            let membership = Membership(
                userID: user.id,
                unitID: section.id,
                role: roles[index]
            )
            memberships.append(membership)
        }

        // Create materials
        let materials = try (0..<3).map { i in
            try Material(
                title: "Material \(i)",
                status: MaterialStatus.allCases[i % MaterialStatus.allCases.count],
                schoolID: school.id,
                academicUnitID: grade.id,
                uploadedByTeacherID: users[0].id,
                isPublic: i == 0
            )
        }

        return (school, units, users, memberships, materials)
    }

    // MARK: - JSON Decoder/Encoder

    /// Configured JSON decoder for integration tests.
    static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    /// Configured JSON encoder for integration tests.
    static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}
