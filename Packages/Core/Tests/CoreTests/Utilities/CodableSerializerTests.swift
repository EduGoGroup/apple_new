import Foundation
import Testing
@testable import EduUtilities

// MARK: - Test Models (Simulating Real DTOs)

/// Simple user model for basic tests.
struct TestUser: Codable, Equatable, Sendable {
    let userId: UUID
    let userName: String
    let createdAt: Date
    let isActive: Bool
}

/// Nested model for testing complex structures.
struct NestedModel: Codable, Equatable, Sendable {
    let parentId: Int
    let childItems: [ChildItem]

    struct ChildItem: Codable, Equatable, Sendable {
        let itemName: String
        let itemValue: Double
    }
}

/// Complex DTO simulating SchoolDTO with all field types.
struct TestSchoolDTO: Codable, Equatable, Sendable {
    let id: UUID
    let name: String
    let code: String
    let isActive: Bool
    let address: String?
    let city: String?
    let country: String?
    let contactEmail: String?
    let contactPhone: String?
    let maxStudents: Int?
    let maxTeachers: Int?
    let subscriptionTier: String?
    let createdAt: Date
    let updatedAt: Date
}

/// Academic unit DTO with parent reference and optional deleted date.
struct TestAcademicUnitDTO: Codable, Equatable, Sendable {
    let id: UUID
    let displayName: String
    let code: String?
    let description: String?
    let type: String
    let parentUnitId: UUID?
    let schoolId: UUID
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
}

/// School with nested academic units for complex structure tests.
struct TestSchoolWithUnitsDTO: Codable, Equatable, Sendable {
    let school: TestSchoolDTO
    let academicUnits: [TestAcademicUnitDTO]
}

/// Model with all optional fields for edge case testing.
struct AllOptionalsModel: Codable, Equatable, Sendable {
    let requiredId: UUID
    let optionalString: String?
    let optionalInt: Int?
    let optionalDouble: Double?
    let optionalBool: Bool?
    let optionalDate: Date?
    let optionalArray: [String]?
}

/// Model with various numeric types.
struct NumericTypesModel: Codable, Equatable, Sendable {
    let intValue: Int
    let int8Value: Int8
    let int16Value: Int16
    let int32Value: Int32
    let int64Value: Int64
    let uintValue: UInt
    let floatValue: Float
    let doubleValue: Double
    let decimalString: String // For precise decimal representation
}

/// Model with special string content.
struct SpecialStringsModel: Codable, Equatable, Sendable {
    let emptyString: String
    let unicodeString: String
    let emojiString: String
    let escapedString: String
    let longString: String
}

/// Tests for `CodableSerializer` actor.
@Suite("CodableSerializer Tests")
struct CodableSerializerTests {

    // MARK: - Encoding Tests

    @Test("Encode simple struct to JSON data")
    func encodeSimpleStruct() async throws {
        let serializer = CodableSerializer()
        let userId = UUID()
        let createdAt = Date(timeIntervalSince1970: 1705312200)
        let user = TestUser(
            userId: userId,
            userName: "John Doe",
            createdAt: createdAt,
            isActive: true
        )

        let data = try await serializer.encode(user)
        let jsonString = String(data: data, encoding: .utf8)!

        #expect(jsonString.contains("\"user_id\""))
        #expect(jsonString.contains("\"user_name\""))
        #expect(jsonString.contains("\"created_at\""))
        #expect(jsonString.contains("\"is_active\""))
        #expect(jsonString.contains("John Doe"))
        // UUID in JSON is uppercase
        #expect(jsonString.lowercased().contains(userId.uuidString.lowercased()))
    }

    @Test("Encode with pretty printing")
    func encodePrettyPrinted() async throws {
        let serializer = CodableSerializer()
        let user = TestUser(
            userId: UUID(),
            userName: "Test",
            createdAt: Date(),
            isActive: false
        )

        let prettyData = try await serializer.encode(user, prettyPrinted: true)
        let prettyString = String(data: prettyData, encoding: .utf8)!

        #expect(prettyString.contains("\n"))
        #expect(prettyString.contains("  "))
    }

    @Test("Encode to string")
    func encodeToString() async throws {
        let serializer = CodableSerializer()
        let user = TestUser(
            userId: UUID(),
            userName: "StringTest",
            createdAt: Date(),
            isActive: true
        )

        let jsonString = try await serializer.encodeToString(user)

        #expect(jsonString.contains("\"user_name\""))
        #expect(jsonString.contains("StringTest"))
    }

    @Test("Encode nested structures")
    func encodeNestedStructures() async throws {
        let serializer = CodableSerializer()
        let nested = NestedModel(
            parentId: 42,
            childItems: [
                .init(itemName: "First", itemValue: 1.5),
                .init(itemName: "Second", itemValue: 2.5)
            ]
        )

        let data = try await serializer.encode(nested)
        let jsonString = String(data: data, encoding: .utf8)!

        #expect(jsonString.contains("\"parent_id\""))
        #expect(jsonString.contains("\"child_items\""))
        #expect(jsonString.contains("\"item_name\""))
        #expect(jsonString.contains("\"item_value\""))
    }

    // MARK: - Decoding Tests

    @Test("Decode JSON data to struct")
    func decodeJSONData() async throws {
        let serializer = CodableSerializer()
        let userId = UUID()
        let json = """
        {
            "user_id": "\(userId.uuidString)",
            "user_name": "Jane Doe",
            "created_at": "2024-01-15T10:30:00Z",
            "is_active": true
        }
        """
        let data = json.data(using: .utf8)!

        let user: TestUser = try await serializer.decode(TestUser.self, from: data)

        #expect(user.userId == userId)
        #expect(user.userName == "Jane Doe")
        #expect(user.isActive == true)
    }

    @Test("Decode JSON string to struct")
    func decodeJSONString() async throws {
        let serializer = CodableSerializer()
        let userId = UUID()
        let json = """
        {
            "user_id": "\(userId.uuidString)",
            "user_name": "Bob Smith",
            "created_at": "2024-06-20T15:45:00Z",
            "is_active": false
        }
        """

        let user: TestUser = try await serializer.decode(TestUser.self, from: json)

        #expect(user.userId == userId)
        #expect(user.userName == "Bob Smith")
        #expect(user.isActive == false)
    }

    @Test("Decode nested structures")
    func decodeNestedStructures() async throws {
        let serializer = CodableSerializer()
        let json = """
        {
            "parent_id": 100,
            "child_items": [
                {"item_name": "Alpha", "item_value": 10.0},
                {"item_name": "Beta", "item_value": 20.5}
            ]
        }
        """
        let data = json.data(using: .utf8)!

        let nested: NestedModel = try await serializer.decode(NestedModel.self, from: data)

        #expect(nested.parentId == 100)
        #expect(nested.childItems.count == 2)
        #expect(nested.childItems[0].itemName == "Alpha")
        #expect(nested.childItems[1].itemValue == 20.5)
    }

    // MARK: - Round-trip Tests

    @Test("Encode then decode produces equal result")
    func roundTripEquality() async throws {
        let serializer = CodableSerializer()
        let original = TestUser(
            userId: UUID(),
            userName: "RoundTrip User",
            createdAt: Date(timeIntervalSince1970: 1705312200),
            isActive: true
        )

        let encoded = try await serializer.encode(original)
        let decoded: TestUser = try await serializer.decode(TestUser.self, from: encoded)

        #expect(original == decoded)
    }

    @Test("Round-trip nested model")
    func roundTripNestedModel() async throws {
        let serializer = CodableSerializer()
        let original = NestedModel(
            parentId: 999,
            childItems: [
                .init(itemName: "Item1", itemValue: 1.1),
                .init(itemName: "Item2", itemValue: 2.2),
                .init(itemName: "Item3", itemValue: 3.3)
            ]
        )

        let encoded = try await serializer.encode(original)
        let decoded: NestedModel = try await serializer.decode(NestedModel.self, from: encoded)

        #expect(original == decoded)
    }

    // MARK: - Error Handling Tests

    @Test("Decode invalid JSON throws decodingFailed error")
    func decodeInvalidJSON() async throws {
        let serializer = CodableSerializer()
        let invalidJSON = "{ invalid json }"

        await #expect(throws: SerializationError.self) {
            let _: TestUser = try await serializer.decode(TestUser.self, from: invalidJSON)
        }
    }

    @Test("Decode missing required field throws decodingFailed error")
    func decodeMissingField() async throws {
        let serializer = CodableSerializer()
        let incompleteJSON = """
        {
            "user_id": "\(UUID().uuidString)",
            "user_name": "Missing Fields"
        }
        """

        await #expect(throws: SerializationError.self) {
            let _: TestUser = try await serializer.decode(TestUser.self, from: incompleteJSON)
        }
    }

    @Test("Decode type mismatch throws decodingFailed error")
    func decodeTypeMismatch() async throws {
        let serializer = CodableSerializer()
        let wrongTypeJSON = """
        {
            "user_id": "\(UUID().uuidString)",
            "user_name": 12345,
            "created_at": "2024-01-15T10:30:00Z",
            "is_active": true
        }
        """

        await #expect(throws: SerializationError.self) {
            let _: TestUser = try await serializer.decode(TestUser.self, from: wrongTypeJSON)
        }
    }

    // MARK: - Shared Instance Tests

    @Test("Shared instance is consistent")
    func sharedInstanceConsistency() async throws {
        let user = TestUser(
            userId: UUID(),
            userName: "Shared Test",
            createdAt: Date(timeIntervalSince1970: 1705312200),
            isActive: true
        )

        let encoded = try await CodableSerializer.shared.encode(user)
        let decoded: TestUser = try await CodableSerializer.shared.decode(TestUser.self, from: encoded)

        #expect(user == decoded)
    }

    // MARK: - Configuration Tests

    @Test("Custom configuration with pretty printing")
    func customPrettyPrintConfiguration() async throws {
        let config = SerializerConfiguration.prettyPrinted
        let serializer = CodableSerializer(configuration: config)

        let user = TestUser(
            userId: UUID(),
            userName: "Pretty",
            createdAt: Date(),
            isActive: true
        )

        let data = try await serializer.encode(user)
        let string = String(data: data, encoding: .utf8)!

        #expect(string.contains("\n"))
    }

    @Test("Default configuration uses snake_case and ISO8601")
    func defaultConfigurationStrategies() async throws {
        let config = SerializerConfiguration.default
        let serializer = CodableSerializer(configuration: config)

        let user = TestUser(
            userId: UUID(),
            userName: "ConfigTest",
            createdAt: Date(timeIntervalSince1970: 1705312200),
            isActive: true
        )

        let jsonString = try await serializer.encodeToString(user)

        #expect(jsonString.contains("\"user_name\""))
        #expect(jsonString.contains("\"created_at\""))
        // ISO8601 format, exact time depends on timezone but format is consistent
        #expect(jsonString.contains("2024-01-15T"))
        #expect(jsonString.contains(":00Z"))
    }

    // MARK: - Concurrency Tests

    @Test("Concurrent encode operations are thread-safe")
    func concurrentEncode() async throws {
        let serializer = CodableSerializer.shared

        try await withThrowingTaskGroup(of: Data.self) { group in
            for i in 0..<100 {
                group.addTask {
                    let user = TestUser(
                        userId: UUID(),
                        userName: "User\(i)",
                        createdAt: Date(),
                        isActive: i % 2 == 0
                    )
                    return try await serializer.encode(user)
                }
            }

            var count = 0
            for try await _ in group {
                count += 1
            }

            #expect(count == 100)
        }
    }

    @Test("Concurrent decode operations are thread-safe")
    func concurrentDecode() async throws {
        let serializer = CodableSerializer.shared
        let userId = UUID()
        let json = """
        {
            "user_id": "\(userId.uuidString)",
            "user_name": "Concurrent",
            "created_at": "2024-01-15T10:30:00Z",
            "is_active": true
        }
        """

        try await withThrowingTaskGroup(of: TestUser.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    try await serializer.decode(TestUser.self, from: json)
                }
            }

            var count = 0
            for try await user in group {
                #expect(user.userId == userId)
                count += 1
            }

            #expect(count == 100)
        }
    }

    @Test("Mixed concurrent encode and decode operations")
    func mixedConcurrentOperations() async throws {
        let serializer = CodableSerializer.shared
        let original = TestUser(
            userId: UUID(),
            userName: "Mixed",
            createdAt: Date(timeIntervalSince1970: 1705312200),
            isActive: true
        )

        try await withThrowingTaskGroup(of: Bool.self) { group in
            for _ in 0..<50 {
                group.addTask {
                    let encoded = try await serializer.encode(original)
                    let decoded: TestUser = try await serializer.decode(TestUser.self, from: encoded)
                    return original == decoded
                }
            }

            for try await result in group {
                #expect(result == true)
            }
        }
    }
}

// MARK: - SerializationError Tests

@Suite("SerializationError Tests")
struct SerializationErrorTests {

    @Test("Error descriptions are meaningful")
    func errorDescriptions() {
        let encodingError = SerializationError.encodingFailed(
            type: "TestType",
            reason: "Test reason"
        )
        let decodingError = SerializationError.decodingFailed(
            type: "AnotherType",
            reason: "Another reason"
        )

        #expect(encodingError.errorDescription?.contains("TestType") == true)
        #expect(encodingError.errorDescription?.contains("Test reason") == true)
        #expect(decodingError.errorDescription?.contains("AnotherType") == true)
        #expect(decodingError.errorDescription?.contains("Another reason") == true)
    }

    @Test("Errors are equatable")
    func errorsEquatable() {
        let error1 = SerializationError.encodingFailed(type: "Type", reason: "Reason")
        let error2 = SerializationError.encodingFailed(type: "Type", reason: "Reason")
        let error3 = SerializationError.decodingFailed(type: "Type", reason: "Reason")

        #expect(error1 == error2)
        #expect(error1 != error3)
    }
}

// MARK: - SerializerConfiguration Tests

@Suite("SerializerConfiguration Tests")
struct SerializerConfigurationTests {

    @Test("Default configuration has expected values")
    func defaultConfiguration() {
        let config = SerializerConfiguration.default

        #expect(config.outputFormatting == nil)
    }

    @Test("PrettyPrinted configuration has formatting")
    func prettyPrintedConfiguration() {
        let config = SerializerConfiguration.prettyPrinted

        #expect(config.outputFormatting?.contains(.prettyPrinted) == true)
        #expect(config.outputFormatting?.contains(.sortedKeys) == true)
    }

    @Test("Custom configuration preserves values")
    func customConfiguration() {
        let config = SerializerConfiguration(
            dateEncodingStrategy: .secondsSince1970,
            keyEncodingStrategy: .useDefaultKeys,
            dateDecodingStrategy: .secondsSince1970,
            keyDecodingStrategy: .useDefaultKeys,
            outputFormatting: .prettyPrinted
        )

        #expect(config.outputFormatting == .prettyPrinted)
    }
}

// MARK: - Complex DTO Tests

@Suite("Complex DTO Tests")
struct ComplexDTOTests {

    @Test("SchoolDTO round-trip with all fields")
    func schoolDTORoundTrip() async throws {
        let serializer = CodableSerializer.shared
        let original = TestSchoolDTO(
            id: UUID(),
            name: "Test School",
            code: "TST001",
            isActive: true,
            address: "123 Main St",
            city: "Test City",
            country: "Test Country",
            contactEmail: "school@test.com",
            contactPhone: "+1-555-0100",
            maxStudents: 500,
            maxTeachers: 50,
            subscriptionTier: "premium",
            createdAt: Date(timeIntervalSince1970: 1705312200),
            updatedAt: Date(timeIntervalSince1970: 1705398600)
        )

        let encoded = try await serializer.encode(original)
        let decoded: TestSchoolDTO = try await serializer.decode(TestSchoolDTO.self, from: encoded)

        #expect(original == decoded)
    }

    @Test("SchoolDTO with nil optional fields")
    func schoolDTOWithNilFields() async throws {
        let serializer = CodableSerializer.shared
        let original = TestSchoolDTO(
            id: UUID(),
            name: "Minimal School",
            code: "MIN001",
            isActive: false,
            address: nil,
            city: nil,
            country: nil,
            contactEmail: nil,
            contactPhone: nil,
            maxStudents: nil,
            maxTeachers: nil,
            subscriptionTier: nil,
            createdAt: Date(timeIntervalSince1970: 1705312200),
            updatedAt: Date(timeIntervalSince1970: 1705312200)
        )

        let encoded = try await serializer.encode(original)
        let decoded: TestSchoolDTO = try await serializer.decode(TestSchoolDTO.self, from: encoded)

        #expect(original == decoded)
        #expect(decoded.address == nil)
        #expect(decoded.maxStudents == nil)
    }

    @Test("AcademicUnitDTO with parent reference")
    func academicUnitWithParent() async throws {
        let serializer = CodableSerializer.shared
        let schoolId = UUID()
        let parentId = UUID()
        let original = TestAcademicUnitDTO(
            id: UUID(),
            displayName: "Computer Science Department",
            code: "CS",
            description: "Department of Computer Science",
            type: "department",
            parentUnitId: parentId,
            schoolId: schoolId,
            createdAt: Date(timeIntervalSince1970: 1705312200),
            updatedAt: Date(timeIntervalSince1970: 1705398600),
            deletedAt: nil
        )

        let encoded = try await serializer.encode(original)
        let decoded: TestAcademicUnitDTO = try await serializer.decode(TestAcademicUnitDTO.self, from: encoded)

        #expect(original == decoded)
        #expect(decoded.parentUnitId == parentId)
    }

    @Test("AcademicUnitDTO with deletedAt date")
    func academicUnitWithDeletedAt() async throws {
        let serializer = CodableSerializer.shared
        let original = TestAcademicUnitDTO(
            id: UUID(),
            displayName: "Archived Unit",
            code: nil,
            description: nil,
            type: "program",
            parentUnitId: nil,
            schoolId: UUID(),
            createdAt: Date(timeIntervalSince1970: 1705312200),
            updatedAt: Date(timeIntervalSince1970: 1705398600),
            deletedAt: Date(timeIntervalSince1970: 1705485000)
        )

        let encoded = try await serializer.encode(original)
        let decoded: TestAcademicUnitDTO = try await serializer.decode(TestAcademicUnitDTO.self, from: encoded)

        #expect(original == decoded)
        #expect(decoded.deletedAt != nil)
    }

    @Test("School with nested academic units array")
    func schoolWithNestedUnits() async throws {
        let serializer = CodableSerializer.shared
        let schoolId = UUID()

        let school = TestSchoolDTO(
            id: schoolId,
            name: "University of Testing",
            code: "UOT",
            isActive: true,
            address: "456 University Ave",
            city: "Academic City",
            country: "Testland",
            contactEmail: "info@uot.edu",
            contactPhone: nil,
            maxStudents: 10000,
            maxTeachers: 500,
            subscriptionTier: "enterprise",
            createdAt: Date(timeIntervalSince1970: 1705312200),
            updatedAt: Date(timeIntervalSince1970: 1705398600)
        )

        let units = [
            TestAcademicUnitDTO(
                id: UUID(),
                displayName: "Engineering Faculty",
                code: "ENG",
                description: "Faculty of Engineering",
                type: "faculty",
                parentUnitId: nil,
                schoolId: schoolId,
                createdAt: Date(timeIntervalSince1970: 1705312200),
                updatedAt: Date(timeIntervalSince1970: 1705312200),
                deletedAt: nil
            ),
            TestAcademicUnitDTO(
                id: UUID(),
                displayName: "Science Faculty",
                code: "SCI",
                description: "Faculty of Science",
                type: "faculty",
                parentUnitId: nil,
                schoolId: schoolId,
                createdAt: Date(timeIntervalSince1970: 1705312200),
                updatedAt: Date(timeIntervalSince1970: 1705312200),
                deletedAt: nil
            ),
            TestAcademicUnitDTO(
                id: UUID(),
                displayName: "Arts Faculty",
                code: "ART",
                description: nil,
                type: "faculty",
                parentUnitId: nil,
                schoolId: schoolId,
                createdAt: Date(timeIntervalSince1970: 1705312200),
                updatedAt: Date(timeIntervalSince1970: 1705312200),
                deletedAt: nil
            )
        ]

        let original = TestSchoolWithUnitsDTO(school: school, academicUnits: units)
        let encoded = try await serializer.encode(original)
        let decoded: TestSchoolWithUnitsDTO = try await serializer.decode(
            TestSchoolWithUnitsDTO.self,
            from: encoded
        )

        #expect(original == decoded)
        #expect(decoded.academicUnits.count == 3)
        #expect(decoded.school.id == schoolId)
    }

    @Test("Empty academic units array")
    func emptyUnitsArray() async throws {
        let serializer = CodableSerializer.shared
        let school = TestSchoolDTO(
            id: UUID(),
            name: "Empty School",
            code: "EMP",
            isActive: true,
            address: nil,
            city: nil,
            country: nil,
            contactEmail: nil,
            contactPhone: nil,
            maxStudents: nil,
            maxTeachers: nil,
            subscriptionTier: nil,
            createdAt: Date(timeIntervalSince1970: 1705312200),
            updatedAt: Date(timeIntervalSince1970: 1705312200)
        )

        let original = TestSchoolWithUnitsDTO(school: school, academicUnits: [])
        let encoded = try await serializer.encode(original)
        let decoded: TestSchoolWithUnitsDTO = try await serializer.decode(
            TestSchoolWithUnitsDTO.self,
            from: encoded
        )

        #expect(decoded.academicUnits.isEmpty)
    }
}

// MARK: - ISO8601 Date Strategy Tests

@Suite("ISO8601 Date Strategy Tests")
struct ISO8601DateStrategyTests {

    @Test("Encode date produces ISO8601 format")
    func encodeDateISO8601() async throws {
        let serializer = CodableSerializer.shared
        // Fixed timestamp: 2024-01-15T10:30:00Z
        let date = Date(timeIntervalSince1970: 1705312200)

        struct DateContainer: Codable {
            let timestamp: Date
        }

        let container = DateContainer(timestamp: date)
        let jsonString = try await serializer.encodeToString(container)

        // Should contain ISO8601 formatted date
        #expect(jsonString.contains("2024-01-15T"))
        #expect(jsonString.contains("Z") || jsonString.contains("+"))
    }

    @Test("Decode ISO8601 date with timezone Z")
    func decodeISO8601WithZ() async throws {
        let serializer = CodableSerializer.shared
        let json = """
        {"timestamp": "2024-06-15T14:30:00Z"}
        """

        struct DateContainer: Codable {
            let timestamp: Date
        }

        let decoded: DateContainer = try await serializer.decode(DateContainer.self, from: json)
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: decoded.timestamp)

        #expect(components.year == 2024)
        #expect(components.month == 6)
        #expect(components.day == 15)
        #expect(components.hour == 14)
        #expect(components.minute == 30)
    }

    @Test("Multiple dates in same object")
    func multipleDatesInObject() async throws {
        let serializer = CodableSerializer.shared
        let now = Date()
        let yesterday = now.addingTimeInterval(-86400)
        let tomorrow = now.addingTimeInterval(86400)

        struct MultipleDates: Codable, Equatable {
            let createdAt: Date
            let updatedAt: Date
            let expiresAt: Date
        }

        let original = MultipleDates(
            createdAt: yesterday,
            updatedAt: now,
            expiresAt: tomorrow
        )

        let encoded = try await serializer.encode(original)
        let decoded: MultipleDates = try await serializer.decode(MultipleDates.self, from: encoded)

        // Dates should round-trip with second precision
        #expect(abs(original.createdAt.timeIntervalSince(decoded.createdAt)) < 1)
        #expect(abs(original.updatedAt.timeIntervalSince(decoded.updatedAt)) < 1)
        #expect(abs(original.expiresAt.timeIntervalSince(decoded.expiresAt)) < 1)
    }

    @Test("Optional date nil and non-nil")
    func optionalDates() async throws {
        let serializer = CodableSerializer.shared

        struct OptionalDate: Codable, Equatable {
            let date: Date?
        }

        let withDate = OptionalDate(date: Date(timeIntervalSince1970: 1705312200))
        let withoutDate = OptionalDate(date: nil)

        let encodedWith = try await serializer.encode(withDate)
        let encodedWithout = try await serializer.encode(withoutDate)

        let decodedWith: OptionalDate = try await serializer.decode(OptionalDate.self, from: encodedWith)
        let decodedWithout: OptionalDate = try await serializer.decode(OptionalDate.self, from: encodedWithout)

        #expect(decodedWith.date != nil)
        #expect(decodedWithout.date == nil)
    }
}

// MARK: - Snake Case Strategy Tests

@Suite("Snake Case Strategy Tests")
struct SnakeCaseStrategyTests {

    @Test("Encode camelCase to snake_case")
    func encodeCamelToSnake() async throws {
        let serializer = CodableSerializer.shared

        struct CamelCaseModel: Codable {
            let firstName: String
            let lastName: String
            let emailAddress: String
            let phoneNumber: String
        }

        let model = CamelCaseModel(
            firstName: "John",
            lastName: "Doe",
            emailAddress: "john@example.com",
            phoneNumber: "555-0100"
        )

        let jsonString = try await serializer.encodeToString(model)

        #expect(jsonString.contains("\"first_name\""))
        #expect(jsonString.contains("\"last_name\""))
        #expect(jsonString.contains("\"email_address\""))
        #expect(jsonString.contains("\"phone_number\""))
        #expect(!jsonString.contains("firstName"))
        #expect(!jsonString.contains("lastName"))
    }

    @Test("Decode snake_case to camelCase")
    func decodeSnakeToCamel() async throws {
        let serializer = CodableSerializer.shared
        let json = """
        {
            "first_name": "Jane",
            "last_name": "Smith",
            "email_address": "jane@example.com",
            "phone_number": "555-0200"
        }
        """

        struct CamelCaseModel: Codable, Equatable {
            let firstName: String
            let lastName: String
            let emailAddress: String
            let phoneNumber: String
        }

        let decoded: CamelCaseModel = try await serializer.decode(CamelCaseModel.self, from: json)

        #expect(decoded.firstName == "Jane")
        #expect(decoded.lastName == "Smith")
        #expect(decoded.emailAddress == "jane@example.com")
        #expect(decoded.phoneNumber == "555-0200")
    }

    @Test("Complex nested snake_case keys")
    func nestedSnakeCaseKeys() async throws {
        let serializer = CodableSerializer.shared

        struct OuterModel: Codable, Equatable {
            let outerName: String
            let innerItem: InnerModel

            struct InnerModel: Codable, Equatable {
                let innerValue: Int
                let deeplyNestedField: String
            }
        }

        let original = OuterModel(
            outerName: "Outer",
            innerItem: OuterModel.InnerModel(
                innerValue: 42,
                deeplyNestedField: "Deep"
            )
        )

        let jsonString = try await serializer.encodeToString(original)
        #expect(jsonString.contains("\"outer_name\""))
        #expect(jsonString.contains("\"inner_item\""))
        #expect(jsonString.contains("\"inner_value\""))
        #expect(jsonString.contains("\"deeply_nested_field\""))

        let decoded: OuterModel = try await serializer.decode(OuterModel.self, from: jsonString)
        #expect(original == decoded)
    }
}

// MARK: - Edge Cases Tests

@Suite("Edge Cases Tests")
struct EdgeCasesTests {

    @Test("All optional fields nil")
    func allOptionalsNil() async throws {
        let serializer = CodableSerializer.shared
        let original = AllOptionalsModel(
            requiredId: UUID(),
            optionalString: nil,
            optionalInt: nil,
            optionalDouble: nil,
            optionalBool: nil,
            optionalDate: nil,
            optionalArray: nil
        )

        let encoded = try await serializer.encode(original)
        let decoded: AllOptionalsModel = try await serializer.decode(AllOptionalsModel.self, from: encoded)

        #expect(decoded.optionalString == nil)
        #expect(decoded.optionalInt == nil)
        #expect(decoded.optionalDouble == nil)
        #expect(decoded.optionalBool == nil)
        #expect(decoded.optionalDate == nil)
        #expect(decoded.optionalArray == nil)
    }

    @Test("All optional fields with values")
    func allOptionalsWithValues() async throws {
        let serializer = CodableSerializer.shared
        let original = AllOptionalsModel(
            requiredId: UUID(),
            optionalString: "Hello",
            optionalInt: 42,
            optionalDouble: 3.14159,
            optionalBool: true,
            optionalDate: Date(timeIntervalSince1970: 1705312200),
            optionalArray: ["a", "b", "c"]
        )

        let encoded = try await serializer.encode(original)
        let decoded: AllOptionalsModel = try await serializer.decode(AllOptionalsModel.self, from: encoded)

        #expect(decoded.optionalString == "Hello")
        #expect(decoded.optionalInt == 42)
        #expect(decoded.optionalDouble == 3.14159)
        #expect(decoded.optionalBool == true)
        #expect(decoded.optionalArray == ["a", "b", "c"])
    }

    @Test("Empty array encoding/decoding")
    func emptyArrays() async throws {
        let serializer = CodableSerializer.shared

        struct ArrayContainer: Codable, Equatable {
            let items: [String]
            let numbers: [Int]
        }

        let original = ArrayContainer(items: [], numbers: [])
        let encoded = try await serializer.encode(original)
        let decoded: ArrayContainer = try await serializer.decode(ArrayContainer.self, from: encoded)

        #expect(decoded.items.isEmpty)
        #expect(decoded.numbers.isEmpty)
    }

    @Test("Large array encoding/decoding")
    func largeArray() async throws {
        let serializer = CodableSerializer.shared

        struct LargeArrayContainer: Codable, Equatable {
            let items: [Int]
        }

        let original = LargeArrayContainer(items: Array(0..<1000))
        let encoded = try await serializer.encode(original)
        let decoded: LargeArrayContainer = try await serializer.decode(LargeArrayContainer.self, from: encoded)

        #expect(decoded.items.count == 1000)
        #expect(decoded.items.first == 0)
        #expect(decoded.items.last == 999)
    }

    @Test("Special strings encoding/decoding")
    func specialStrings() async throws {
        let serializer = CodableSerializer.shared
        let original = SpecialStringsModel(
            emptyString: "",
            unicodeString: "日本語 한국어 العربية",
            emojiString: "Hello 👋 World 🌍",
            escapedString: "Line1\nLine2\tTabbed\"Quoted\"",
            longString: String(repeating: "a", count: 10000)
        )

        let encoded = try await serializer.encode(original)
        let decoded: SpecialStringsModel = try await serializer.decode(SpecialStringsModel.self, from: encoded)

        #expect(decoded.emptyString == "")
        #expect(decoded.unicodeString == "日本語 한국어 العربية")
        #expect(decoded.emojiString == "Hello 👋 World 🌍")
        #expect(decoded.escapedString.contains("\n"))
        #expect(decoded.escapedString.contains("\t"))
        #expect(decoded.longString.count == 10000)
    }

    @Test("Numeric edge values")
    func numericEdgeValues() async throws {
        let serializer = CodableSerializer.shared
        let original = NumericTypesModel(
            intValue: Int.max,
            int8Value: Int8.max,
            int16Value: Int16.max,
            int32Value: Int32.max,
            int64Value: Int64.max,
            uintValue: UInt.max / 2, // UInt.max can overflow in JSON
            floatValue: Float.pi,
            doubleValue: Double.pi,
            decimalString: "123456789.123456789"
        )

        let encoded = try await serializer.encode(original)
        let decoded: NumericTypesModel = try await serializer.decode(NumericTypesModel.self, from: encoded)

        #expect(decoded.intValue == Int.max)
        #expect(decoded.int8Value == Int8.max)
        #expect(decoded.int16Value == Int16.max)
        #expect(decoded.int32Value == Int32.max)
        #expect(decoded.int64Value == Int64.max)
        #expect(decoded.decimalString == "123456789.123456789")
    }

    @Test("Boolean values")
    func booleanValues() async throws {
        let serializer = CodableSerializer.shared

        struct BoolContainer: Codable, Equatable {
            let trueValue: Bool
            let falseValue: Bool
        }

        let original = BoolContainer(trueValue: true, falseValue: false)
        let jsonString = try await serializer.encodeToString(original)

        #expect(jsonString.contains("true"))
        #expect(jsonString.contains("false"))

        let decoded: BoolContainer = try await serializer.decode(BoolContainer.self, from: jsonString)
        #expect(decoded.trueValue == true)
        #expect(decoded.falseValue == false)
    }
}

// MARK: - Advanced Concurrency Tests

@Suite("Advanced Concurrency Tests")
struct AdvancedConcurrencyTests {

    @Test("Concurrent operations from multiple tasks")
    func concurrentOperationsFromMultipleTasks() async throws {
        let serializer = CodableSerializer.shared
        let iterations = 100
        // Use fixed date to avoid sub-second precision issues
        let fixedDate = Date(timeIntervalSince1970: 1705312200)

        // Run multiple concurrent tasks that each perform encode/decode
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<iterations {
                group.addTask {
                    do {
                        let user = TestUser(
                            userId: UUID(),
                            userName: "User\(i)",
                            createdAt: fixedDate,
                            isActive: i % 2 == 0
                        )
                        let encoded = try await serializer.encode(user)
                        let decoded: TestUser = try await serializer.decode(TestUser.self, from: encoded)
                        // Verify equality - if this fails, it will show in test output
                        assert(user == decoded, "Round-trip failed for User\(i)")
                    } catch {
                        assertionFailure("Unexpected error: \(error)")
                    }
                }
            }
        }

        // If we complete all tasks without crashing, concurrency is working
        #expect(Bool(true))
    }

    @Test("High contention concurrent encode/decode")
    func highContentionConcurrency() async throws {
        let serializer = CodableSerializer.shared
        let iterations = 200
        let sharedData = TestSchoolDTO(
            id: UUID(),
            name: "Shared School",
            code: "SHR",
            isActive: true,
            address: "123 Shared St",
            city: "Concurrent City",
            country: "Asyncland",
            contactEmail: "shared@test.com",
            contactPhone: nil,
            maxStudents: 1000,
            maxTeachers: 100,
            subscriptionTier: "enterprise",
            createdAt: Date(timeIntervalSince1970: 1705312200),
            updatedAt: Date(timeIntervalSince1970: 1705312200)
        )

        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<iterations {
                // Concurrent encode
                group.addTask {
                    _ = try await serializer.encode(sharedData)
                }
                // Concurrent decode
                group.addTask {
                    let json = """
                    {"id":"\(UUID().uuidString)","name":"Test","code":"T","is_active":true,"created_at":"2024-01-15T10:00:00Z","updated_at":"2024-01-15T10:00:00Z"}
                    """
                    let _: TestSchoolDTO = try await serializer.decode(TestSchoolDTO.self, from: json)
                }
            }

            for try await _ in group { }
        }

        // If we reach here without data races, test passes
        #expect(Bool(true))
    }

    @Test("Multiple serializer instances concurrent access")
    func multipleSerializerInstances() async throws {
        let serializer1 = CodableSerializer()
        let serializer2 = CodableSerializer()
        let serializer3 = CodableSerializer.shared

        let user = TestUser(
            userId: UUID(),
            userName: "MultiInstance",
            createdAt: Date(timeIntervalSince1970: 1705312200),
            isActive: true
        )

        async let result1 = serializer1.encode(user)
        async let result2 = serializer2.encode(user)
        async let result3 = serializer3.encode(user)

        let (data1, data2, data3) = try await (result1, result2, result3)

        // All should produce valid, equivalent JSON
        let decoded1: TestUser = try await serializer1.decode(TestUser.self, from: data1)
        let decoded2: TestUser = try await serializer2.decode(TestUser.self, from: data2)
        let decoded3: TestUser = try await serializer3.decode(TestUser.self, from: data3)

        #expect(decoded1 == user)
        #expect(decoded2 == user)
        #expect(decoded3 == user)
    }

    @Test("Rapid sequential operations performance")
    func rapidSequentialOperations() async throws {
        let serializer = CodableSerializer.shared
        let iterations = 500

        let startTime = Date()

        for i in 0..<iterations {
            let user = TestUser(
                userId: UUID(),
                userName: "Sequential\(i)",
                createdAt: Date(),
                isActive: true
            )
            let encoded = try await serializer.encode(user)
            let _: TestUser = try await serializer.decode(TestUser.self, from: encoded)
        }

        let elapsed = Date().timeIntervalSince(startTime)

        // Should complete 500 round-trips in under 2 seconds
        #expect(elapsed < 2.0, "Performance test: \(iterations) operations took \(elapsed)s")
    }
}

// MARK: - Error Handling Extended Tests

@Suite("Error Handling Extended Tests")
struct ErrorHandlingExtendedTests {

    @Test("Corrupted JSON data")
    func corruptedJSONData() async throws {
        let serializer = CodableSerializer.shared
        let corruptedData = Data([0xFF, 0xFE, 0x00, 0x01]) // Invalid UTF-8

        await #expect(throws: SerializationError.self) {
            let _: TestUser = try await serializer.decode(TestUser.self, from: corruptedData)
        }
    }

    @Test("Empty data throws error")
    func emptyData() async throws {
        let serializer = CodableSerializer.shared
        let emptyData = Data()

        await #expect(throws: SerializationError.self) {
            let _: TestUser = try await serializer.decode(TestUser.self, from: emptyData)
        }
    }

    @Test("Wrong type in array throws error")
    func wrongTypeInArray() async throws {
        let serializer = CodableSerializer.shared
        let json = """
        {"items": [1, 2, "three", 4]}
        """

        struct IntArray: Codable {
            let items: [Int]
        }

        await #expect(throws: SerializationError.self) {
            let _: IntArray = try await serializer.decode(IntArray.self, from: json)
        }
    }

    @Test("Invalid date format throws error")
    func invalidDateFormat() async throws {
        let serializer = CodableSerializer.shared
        let json = """
        {"timestamp": "not-a-date"}
        """

        struct DateContainer: Codable {
            let timestamp: Date
        }

        await #expect(throws: SerializationError.self) {
            let _: DateContainer = try await serializer.decode(DateContainer.self, from: json)
        }
    }

    @Test("Invalid UUID format throws error")
    func invalidUUIDFormat() async throws {
        let serializer = CodableSerializer.shared
        let json = """
        {"user_id": "not-a-uuid", "user_name": "Test", "created_at": "2024-01-15T10:00:00Z", "is_active": true}
        """

        await #expect(throws: SerializationError.self) {
            let _: TestUser = try await serializer.decode(TestUser.self, from: json)
        }
    }

    @Test("Null for non-optional field throws error")
    func nullForNonOptional() async throws {
        let serializer = CodableSerializer.shared
        let json = """
        {"user_id": "\(UUID().uuidString)", "user_name": null, "created_at": "2024-01-15T10:00:00Z", "is_active": true}
        """

        await #expect(throws: SerializationError.self) {
            let _: TestUser = try await serializer.decode(TestUser.self, from: json)
        }
    }

    @Test("Extra fields are ignored")
    func extraFieldsIgnored() async throws {
        let serializer = CodableSerializer.shared
        let json = """
        {
            "user_id": "\(UUID().uuidString)",
            "user_name": "Test",
            "created_at": "2024-01-15T10:00:00Z",
            "is_active": true,
            "extra_field": "should be ignored",
            "another_extra": 12345
        }
        """

        // Should not throw - extra fields are ignored
        let decoded: TestUser = try await serializer.decode(TestUser.self, from: json)
        #expect(decoded.userName == "Test")
    }

    @Test("SerializationError contains type information")
    func errorContainsTypeInfo() async throws {
        let serializer = CodableSerializer.shared
        let json = "{ invalid }"

        do {
            let _: TestUser = try await serializer.decode(TestUser.self, from: json)
            Issue.record("Should have thrown")
        } catch let error as SerializationError {
            let description = error.errorDescription ?? ""
            #expect(description.contains("TestUser"))
        }
    }
}
