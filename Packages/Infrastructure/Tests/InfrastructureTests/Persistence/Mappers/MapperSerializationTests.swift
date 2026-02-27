import Testing
import Foundation
import EduCore
import EduCore
import EduFoundation
@testable import EduPersistence

/// Tests for validating that persistence mappers work correctly with CodableSerializer.
///
/// These tests verify:
/// - Round-trip serialization: Domain → DTO → JSON → DTO → Domain
/// - Metadata serialization preserves all JSONValue types
/// - CodableSerializer strategies (ISO8601) work with DTOs
/// - Concurrent serialization operations are thread-safe
///
/// Note: DTOs have explicit CodingKeys for snake_case mapping, so we use
/// `CodableSerializer.dtoSerializer` which does NOT apply key conversion.
@Suite("Mapper Serialization Tests")
struct MapperSerializationTests {

    /// Serializer for DTOs with explicit CodingKeys (no key conversion).
    private var serializer: CodableSerializer { CodableSerializer.dtoSerializer }

    // MARK: - SchoolDTO Round-Trip Tests

    @Test("SchoolDTO round-trip serialization preserves all fields")
    func testSchoolDTORoundTrip() async throws {
        let now = Date(timeIntervalSince1970: 1705312200) // Fixed date
        let originalDTO = SchoolDTO(
            id: UUID(),
            name: "Test School",
            code: "TST-001",
            isActive: true,
            address: "123 Test Street",
            city: "Test City",
            country: "Test Country",
            contactEmail: "test@school.edu",
            contactPhone: "+1-555-0123",
            maxStudents: 500,
            maxTeachers: 50,
            subscriptionTier: "premium",
            metadata: [
                "region": .string("north"),
                "priority": .integer(1),
                "verified": .bool(true)
            ],
            createdAt: now,
            updatedAt: now
        )

        // DTO → JSON
        let jsonData = try await serializer.encode(originalDTO)

        // JSON → DTO
        let restoredDTO = try await serializer.decode(SchoolDTO.self, from: jsonData)

        // Verify all fields
        #expect(restoredDTO.id == originalDTO.id)
        #expect(restoredDTO.name == originalDTO.name)
        #expect(restoredDTO.code == originalDTO.code)
        #expect(restoredDTO.isActive == originalDTO.isActive)
        #expect(restoredDTO.address == originalDTO.address)
        #expect(restoredDTO.city == originalDTO.city)
        #expect(restoredDTO.country == originalDTO.country)
        #expect(restoredDTO.contactEmail == originalDTO.contactEmail)
        #expect(restoredDTO.contactPhone == originalDTO.contactPhone)
        #expect(restoredDTO.maxStudents == originalDTO.maxStudents)
        #expect(restoredDTO.maxTeachers == originalDTO.maxTeachers)
        #expect(restoredDTO.subscriptionTier == originalDTO.subscriptionTier)
        #expect(restoredDTO.metadata == originalDTO.metadata)
    }

    @Test("School Domain → DTO → JSON → DTO → Domain round-trip")
    func testSchoolFullRoundTrip() async throws {
        let now = Date(timeIntervalSince1970: 1705312200)
        let originalDomain = try School(
            name: "Full Round Trip School",
            code: "FRT-001",
            isActive: true,
            address: "456 Round Trip Ave",
            city: "Cycle City",
            country: "Testland",
            contactEmail: "roundtrip@school.edu",
            contactPhone: "+1-555-9999",
            maxStudents: 1000,
            maxTeachers: 100,
            subscriptionTier: "enterprise",
            metadata: [
                "founded_year": .integer(2020),
                "accredited": .bool(true),
                "rating": .double(4.5)
            ],
            createdAt: now,
            updatedAt: now
        )

        // Domain → DTO
        let dto = originalDomain.toDTO()

        // DTO → JSON
        let jsonData = try await serializer.encode(dto)

        // JSON → DTO
        let restoredDTO = try await serializer.decode(SchoolDTO.self, from: jsonData)

        // DTO → Domain
        let restoredDomain = try restoredDTO.toDomain()

        // Verify domain equality
        #expect(restoredDomain.id == originalDomain.id)
        #expect(restoredDomain.name == originalDomain.name)
        #expect(restoredDomain.code == originalDomain.code)
        #expect(restoredDomain.isActive == originalDomain.isActive)
        #expect(restoredDomain.address == originalDomain.address)
        #expect(restoredDomain.city == originalDomain.city)
        #expect(restoredDomain.country == originalDomain.country)
        #expect(restoredDomain.contactEmail == originalDomain.contactEmail)
        #expect(restoredDomain.contactPhone == originalDomain.contactPhone)
        #expect(restoredDomain.maxStudents == originalDomain.maxStudents)
        #expect(restoredDomain.maxTeachers == originalDomain.maxTeachers)
        #expect(restoredDomain.subscriptionTier == originalDomain.subscriptionTier)
        #expect(restoredDomain.metadata == originalDomain.metadata)
    }

    // MARK: - AcademicUnitDTO Round-Trip Tests

    @Test("AcademicUnitDTO round-trip serialization preserves all fields")
    func testAcademicUnitDTORoundTrip() async throws {
        let now = Date(timeIntervalSince1970: 1705312200)
        let originalDTO = AcademicUnitDTO(
            id: UUID(),
            displayName: "Grade 10",
            code: "G10-A",
            description: "Tenth grade section A",
            type: "grade",
            parentUnitID: nil,
            schoolID: UUID(),
            metadata: [
                "capacity": .integer(30),
                "room": .string("Building A, Floor 2")
            ],
            createdAt: now,
            updatedAt: now,
            deletedAt: nil
        )

        // DTO → JSON
        let jsonData = try await serializer.encode(originalDTO)

        // JSON → DTO
        let restoredDTO = try await serializer.decode(AcademicUnitDTO.self, from: jsonData)

        // Verify all fields
        #expect(restoredDTO.id == originalDTO.id)
        #expect(restoredDTO.displayName == originalDTO.displayName)
        #expect(restoredDTO.code == originalDTO.code)
        #expect(restoredDTO.description == originalDTO.description)
        #expect(restoredDTO.type == originalDTO.type)
        #expect(restoredDTO.parentUnitID == originalDTO.parentUnitID)
        #expect(restoredDTO.schoolID == originalDTO.schoolID)
        #expect(restoredDTO.metadata == originalDTO.metadata)
    }

    @Test("AcademicUnit Domain → DTO → JSON → DTO → Domain round-trip")
    func testAcademicUnitFullRoundTrip() async throws {
        let now = Date(timeIntervalSince1970: 1705312200)
        let schoolID = UUID()
        let parentUnitID = UUID()

        let originalDomain = try AcademicUnit(
            displayName: "Section 10-B",
            code: "S10B",
            description: "Section B of Grade 10",
            type: .section,
            parentUnitID: parentUnitID,
            schoolID: schoolID,
            metadata: [
                "teacher_count": .integer(5),
                "active": .bool(true)
            ],
            createdAt: now,
            updatedAt: now
        )

        // Domain → DTO
        let dto = originalDomain.toDTO()

        // DTO → JSON
        let jsonData = try await serializer.encode(dto)

        // JSON → DTO
        let restoredDTO = try await serializer.decode(AcademicUnitDTO.self, from: jsonData)

        // DTO → Domain
        let restoredDomain = try restoredDTO.toDomain()

        // Verify domain equality
        #expect(restoredDomain.id == originalDomain.id)
        #expect(restoredDomain.displayName == originalDomain.displayName)
        #expect(restoredDomain.code == originalDomain.code)
        #expect(restoredDomain.description == originalDomain.description)
        #expect(restoredDomain.type == originalDomain.type)
        #expect(restoredDomain.parentUnitID == originalDomain.parentUnitID)
        #expect(restoredDomain.schoolID == originalDomain.schoolID)
        #expect(restoredDomain.metadata == originalDomain.metadata)
    }

    // MARK: - UserDTO Round-Trip Tests

    @Test("UserDTO round-trip serialization preserves all fields")
    func testUserDTORoundTrip() async throws {
        let now = Date(timeIntervalSince1970: 1705312200)
        let originalDTO = UserDTO(
            id: UUID(),
            firstName: "John",
            lastName: "Doe",
            fullName: "John Doe",
            email: "john.doe@test.com",
            isActive: true,
            role: "teacher",
            createdAt: now,
            updatedAt: now
        )

        // DTO → JSON
        let jsonData = try await serializer.encode(originalDTO)

        // JSON → DTO
        let restoredDTO = try await serializer.decode(UserDTO.self, from: jsonData)

        // Verify all fields
        #expect(restoredDTO.id == originalDTO.id)
        #expect(restoredDTO.firstName == originalDTO.firstName)
        #expect(restoredDTO.lastName == originalDTO.lastName)
        #expect(restoredDTO.fullName == originalDTO.fullName)
        #expect(restoredDTO.email == originalDTO.email)
        #expect(restoredDTO.isActive == originalDTO.isActive)
        #expect(restoredDTO.role == originalDTO.role)
    }

    // MARK: - MembershipDTO Round-Trip Tests

    @Test("MembershipDTO round-trip serialization preserves all fields")
    func testMembershipDTORoundTrip() async throws {
        let now = Date(timeIntervalSince1970: 1705312200)
        let originalDTO = MembershipDTO(
            id: UUID(),
            userID: UUID(),
            unitID: UUID(),
            role: "student",
            isActive: true,
            enrolledAt: now,
            withdrawnAt: nil,
            createdAt: now,
            updatedAt: now
        )

        // DTO → JSON
        let jsonData = try await serializer.encode(originalDTO)

        // JSON → DTO
        let restoredDTO = try await serializer.decode(MembershipDTO.self, from: jsonData)

        // Verify all fields
        #expect(restoredDTO.id == originalDTO.id)
        #expect(restoredDTO.userID == originalDTO.userID)
        #expect(restoredDTO.unitID == originalDTO.unitID)
        #expect(restoredDTO.role == originalDTO.role)
        #expect(restoredDTO.isActive == originalDTO.isActive)
        #expect(restoredDTO.enrolledAt == originalDTO.enrolledAt)
        #expect(restoredDTO.withdrawnAt == originalDTO.withdrawnAt)
    }

    // MARK: - MaterialDTO Round-Trip Tests

    @Test("MaterialDTO round-trip serialization preserves all fields")
    func testMaterialDTORoundTrip() async throws {
        let now = Date(timeIntervalSince1970: 1705312200)
        let originalDTO = MaterialDTO(
            id: UUID(),
            title: "Physics Chapter 1",
            description: "Introduction to Mechanics",
            status: "ready",
            fileURL: "https://example.com/materials/physics-ch1.pdf",
            fileType: "application/pdf",
            fileSizeBytes: 2048576,
            schoolID: UUID(),
            academicUnitID: UUID(),
            uploadedByTeacherID: UUID(),
            subject: "Physics",
            grade: "10",
            isPublic: true,
            processingStartedAt: now.addingTimeInterval(-3600),
            processingCompletedAt: now.addingTimeInterval(-1800),
            createdAt: now,
            updatedAt: now,
            deletedAt: nil
        )

        // DTO → JSON
        let jsonData = try await serializer.encode(originalDTO)

        // JSON → DTO
        let restoredDTO = try await serializer.decode(MaterialDTO.self, from: jsonData)

        // Verify all fields
        #expect(restoredDTO.id == originalDTO.id)
        #expect(restoredDTO.title == originalDTO.title)
        #expect(restoredDTO.description == originalDTO.description)
        #expect(restoredDTO.status == originalDTO.status)
        #expect(restoredDTO.fileURL == originalDTO.fileURL)
        #expect(restoredDTO.fileType == originalDTO.fileType)
        #expect(restoredDTO.fileSizeBytes == originalDTO.fileSizeBytes)
        #expect(restoredDTO.schoolID == originalDTO.schoolID)
        #expect(restoredDTO.academicUnitID == originalDTO.academicUnitID)
        #expect(restoredDTO.uploadedByTeacherID == originalDTO.uploadedByTeacherID)
        #expect(restoredDTO.subject == originalDTO.subject)
        #expect(restoredDTO.grade == originalDTO.grade)
        #expect(restoredDTO.isPublic == originalDTO.isPublic)
    }

    // MARK: - Metadata JSONValue Tests

    @Test("All JSONValue types serialize correctly")
    func testAllJSONValueTypes() async throws {
        let now = Date(timeIntervalSince1970: 1705312200)
        let dto = SchoolDTO(
            id: UUID(),
            name: "JSONValue Test School",
            code: "JVT-001",
            isActive: true,
            address: nil,
            city: nil,
            country: nil,
            contactEmail: nil,
            contactPhone: nil,
            maxStudents: nil,
            maxTeachers: nil,
            subscriptionTier: nil,
            metadata: [
                "string_value": .string("test string"),
                "int_value": .integer(42),
                "double_value": .double(3.14159),
                "bool_true": .bool(true),
                "bool_false": .bool(false),
                "null_value": .null,
                "array_value": .array([
                    .string("item1"),
                    .integer(2),
                    .bool(true)
                ]),
                "object_value": .object([
                    "nested_string": .string("nested"),
                    "nested_int": .integer(100)
                ])
            ],
            createdAt: now,
            updatedAt: now
        )

        // DTO → JSON
        let jsonData = try await serializer.encode(dto)

        // JSON → DTO
        let restored = try await serializer.decode(SchoolDTO.self, from: jsonData)

        // Verify all JSONValue types
        #expect(restored.metadata?["string_value"] == JSONValue.string("test string"))
        #expect(restored.metadata?["int_value"] == JSONValue.integer(42))
        #expect(restored.metadata?["double_value"] == JSONValue.double(3.14159))
        #expect(restored.metadata?["bool_true"] == JSONValue.bool(true))
        #expect(restored.metadata?["bool_false"] == JSONValue.bool(false))
        #expect(restored.metadata?["null_value"] == JSONValue.null)
        #expect(restored.metadata?["array_value"] == JSONValue.array([.string("item1"), .integer(2), .bool(true)]))
        #expect(restored.metadata?["object_value"] == JSONValue.object(["nested_string": .string("nested"), "nested_int": .integer(100)]))
    }

    // MARK: - Snake Case Strategy Tests

    @Test("Snake case keys are correctly decoded from JSON")
    func testSnakeCaseDecoding() async throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "first_name": "Jane",
            "last_name": "Smith",
            "full_name": "Jane Smith",
            "email": "jane@test.com",
            "is_active": true,
            "created_at": "2024-01-15T10:30:00Z",
            "updated_at": "2024-01-15T10:30:00Z"
        }
        """

        let dto = try await serializer.decode(UserDTO.self, from: Data(json.utf8))

        #expect(dto.firstName == "Jane")
        #expect(dto.lastName == "Smith")
        #expect(dto.fullName == "Jane Smith")
        #expect(dto.isActive == true)
    }

    @Test("Snake case keys are correctly encoded to JSON")
    func testSnakeCaseEncoding() async throws {
        let now = Date(timeIntervalSince1970: 1705312200)
        let dto = UserDTO(
            id: UUID(),
            firstName: "Test",
            lastName: "User",
            fullName: "Test User",
            email: "test@user.com",
            isActive: true,
            role: nil,
            createdAt: now,
            updatedAt: now
        )

        let jsonData = try await serializer.encode(dto)
        let jsonString = String(data: jsonData, encoding: .utf8)!

        #expect(jsonString.contains("first_name"))
        #expect(jsonString.contains("last_name"))
        #expect(jsonString.contains("full_name"))
        #expect(jsonString.contains("is_active"))
        #expect(jsonString.contains("created_at"))
        #expect(jsonString.contains("updated_at"))
    }

    // MARK: - ISO8601 Date Strategy Tests

    @Test("ISO8601 dates are correctly decoded")
    func testISO8601Decoding() async throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "first_name": "Date",
            "last_name": "Test",
            "email": "date@test.com",
            "is_active": true,
            "created_at": "2024-01-15T10:30:00Z",
            "updated_at": "2024-06-20T15:45:30Z"
        }
        """

        let dto = try await serializer.decode(UserDTO.self, from: Data(json.utf8))

        // Verify dates were parsed correctly
        let calendar = Calendar(identifier: .gregorian)
        var components = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: dto.createdAt)
        #expect(components.year == 2024)
        #expect(components.month == 1)
        #expect(components.day == 15)

        components = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: dto.updatedAt)
        #expect(components.year == 2024)
        #expect(components.month == 6)
        #expect(components.day == 20)
    }

    @Test("ISO8601 dates are correctly encoded")
    func testISO8601Encoding() async throws {
        let now = Date(timeIntervalSince1970: 1705312200) // 2024-01-15T10:30:00Z
        let dto = UserDTO(
            id: UUID(),
            firstName: "Encode",
            lastName: "Test",
            fullName: "Encode Test",
            email: "encode@test.com",
            isActive: true,
            role: nil,
            createdAt: now,
            updatedAt: now
        )

        let jsonData = try await serializer.encode(dto)
        let jsonString = String(data: jsonData, encoding: .utf8)!

        // Verify ISO8601 format
        #expect(jsonString.contains("2024-01-15T"))
        #expect(jsonString.contains(":00Z") || jsonString.contains(":00+00:00"))
    }

    // MARK: - Concurrent Serialization Tests

    @Test("Concurrent serialization operations are thread-safe")
    func testConcurrentSerialization() async throws {
        let now = Date(timeIntervalSince1970: 1705312200)
        let iterations = 100

        // Generate DTOs
        let dtos = (0..<iterations).map { i in
            SchoolDTO(
                id: UUID(),
                name: "Concurrent School \(i)",
                code: "CS-\(i)",
                isActive: true,
                address: nil,
                city: nil,
                country: nil,
                contactEmail: nil,
                contactPhone: nil,
                maxStudents: nil,
                maxTeachers: nil,
                subscriptionTier: nil,
                metadata: ["index": .integer(i)],
                createdAt: now,
                updatedAt: now
            )
        }

        // Concurrent encode/decode
        let results = try await withThrowingTaskGroup(of: SchoolDTO.self, returning: [SchoolDTO].self) { group in
            for dto in dtos {
                group.addTask {
                    let encoded = try await serializer.encode(dto)
                    return try await serializer.decode(SchoolDTO.self, from: encoded)
                }
            }

            var collected: [SchoolDTO] = []
            for try await result in group {
                collected.append(result)
            }
            return collected
        }

        #expect(results.count == iterations)

        // Verify each result has correct metadata
        for result in results {
            #expect(result.metadata != nil)
            if let indexValue = result.metadata?["index"], case .integer(let index) = indexValue {
                #expect(result.name == "Concurrent School \(index)")
            }
        }
    }

    @Test("Batch serialization maintains data integrity")
    func testBatchSerialization() async throws {
        let now = Date(timeIntervalSince1970: 1705312200)
        let batchSize = 50

        // Create batch of mixed entities
        let schools = (0..<batchSize).map { i in
            SchoolDTO(
                id: UUID(),
                name: "Batch School \(i)",
                code: "BS-\(i)",
                isActive: i % 2 == 0,
                address: nil,
                city: nil,
                country: nil,
                contactEmail: nil,
                contactPhone: nil,
                maxStudents: nil,
                maxTeachers: nil,
                subscriptionTier: nil,
                metadata: ["batch_index": .integer(i)],
                createdAt: now,
                updatedAt: now
            )
        }

        // Serialize all
        var encodedData: [Data] = []
        for school in schools {
            let data = try await serializer.encode(school)
            encodedData.append(data)
        }

        // Deserialize all
        var restoredSchools: [SchoolDTO] = []
        for data in encodedData {
            let school = try await serializer.decode(SchoolDTO.self, from: data)
            restoredSchools.append(school)
        }

        // Verify integrity
        #expect(restoredSchools.count == batchSize)
        for (index, restored) in restoredSchools.enumerated() {
            let original = schools[index]
            #expect(restored.id == original.id)
            #expect(restored.name == original.name)
            #expect(restored.code == original.code)
            #expect(restored.isActive == original.isActive)
            #expect(restored.metadata == original.metadata)
        }
    }

    // MARK: - Edge Cases

    @Test("Empty metadata serializes correctly")
    func testEmptyMetadata() async throws {
        let now = Date(timeIntervalSince1970: 1705312200)
        let dto = SchoolDTO(
            id: UUID(),
            name: "No Metadata School",
            code: "NM-001",
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
            createdAt: now,
            updatedAt: now
        )

        let encoded = try await serializer.encode(dto)
        let restored = try await serializer.decode(SchoolDTO.self, from: encoded)

        #expect(restored.metadata == [:])
    }

    @Test("Nil metadata serializes correctly")
    func testNilMetadata() async throws {
        let now = Date(timeIntervalSince1970: 1705312200)
        let dto = SchoolDTO(
            id: UUID(),
            name: "Nil Metadata School",
            code: "NL-001",
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
            createdAt: now,
            updatedAt: now
        )

        let encoded = try await serializer.encode(dto)
        let restored = try await serializer.decode(SchoolDTO.self, from: encoded)

        #expect(restored.metadata == nil)
    }

    @Test("Special characters in strings serialize correctly")
    func testSpecialCharacters() async throws {
        let now = Date(timeIntervalSince1970: 1705312200)
        let dto = SchoolDTO(
            id: UUID(),
            name: "School with \"quotes\" and \\ backslash",
            code: "SP-001",
            isActive: true,
            address: "123 Test St.\nSecond Line",
            city: nil,
            country: nil,
            contactEmail: nil,
            contactPhone: nil,
            maxStudents: nil,
            maxTeachers: nil,
            subscriptionTier: nil,
            metadata: [
                "unicode": .string("Hello 世界 🌍"),
                "newlines": .string("Line1\nLine2\tTab")
            ],
            createdAt: now,
            updatedAt: now
        )

        let encoded = try await serializer.encode(dto)
        let restored = try await serializer.decode(SchoolDTO.self, from: encoded)

        #expect(restored.name == dto.name)
        #expect(restored.address == dto.address)
        #expect(restored.metadata?["unicode"] == JSONValue.string("Hello 世界 🌍"))
        #expect(restored.metadata?["newlines"] == JSONValue.string("Line1\nLine2\tTab"))
    }
}
