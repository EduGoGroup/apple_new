import Testing
import Foundation
@testable import EduModels
import EduFoundation

@Suite("SchoolMapper Tests")
struct SchoolMapperTests {

    // MARK: - toDomain Tests

    @Test("toDomain with valid DTO returns School")
    func toDomainWithValidDTO() throws {
        let createdAt = Date(timeIntervalSince1970: 1000)
        let updatedAt = Date(timeIntervalSince1970: 2000)

        let dto = SchoolDTO(
            id: UUID(),
            name: "Springfield Elementary",
            code: "SPR-ELEM-001",
            isActive: true,
            address: "123 Main St",
            city: "Springfield",
            country: "USA",
            contactEmail: "contact@school.edu",
            contactPhone: "+1-555-1234",
            maxStudents: 500,
            maxTeachers: 50,
            subscriptionTier: "premium",
            metadata: ["region": .string("midwest")],
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        let school = try SchoolMapper.toDomain(dto)

        #expect(school.id == dto.id)
        #expect(school.name == "Springfield Elementary")
        #expect(school.code == "SPR-ELEM-001")
        #expect(school.isActive == true)
        #expect(school.address == "123 Main St")
        #expect(school.city == "Springfield")
        #expect(school.country == "USA")
        #expect(school.contactEmail == "contact@school.edu")
        #expect(school.contactPhone == "+1-555-1234")
        #expect(school.maxStudents == 500)
        #expect(school.maxTeachers == 50)
        #expect(school.subscriptionTier == "premium")
    }

    @Test("toDomain with minimal data")
    func toDomainWithMinimalData() throws {
        let dto = SchoolDTO(
            id: UUID(),
            name: "Test School",
            code: "TEST-001",
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

        let school = try SchoolMapper.toDomain(dto)

        #expect(school.name == "Test School")
        #expect(school.address == nil)
        #expect(school.subscriptionTier == nil)
    }

    @Test("toDomain with empty name throws error")
    func toDomainWithEmptyNameThrows() {
        let dto = SchoolDTO(
            id: UUID(),
            name: "",
            code: "CODE",
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
            _ = try SchoolMapper.toDomain(dto)
        }
    }

    // MARK: - toDTO Tests

    @Test("toDTO converts School correctly")
    func toDTOConvertsSchoolCorrectly() throws {
        let school = try School(
            id: UUID(),
            name: "Springfield Elementary",
            code: "SPR-001",
            isActive: true,
            address: "123 Main St",
            city: "Springfield",
            country: "USA",
            contactEmail: "test@school.edu",
            contactPhone: "+1-555-1234",
            maxStudents: 500,
            maxTeachers: 50,
            subscriptionTier: "premium",
            metadata: nil,
            createdAt: Date(timeIntervalSince1970: 1000),
            updatedAt: Date(timeIntervalSince1970: 2000)
        )

        let dto = SchoolMapper.toDTO(school)

        #expect(dto.id == school.id)
        #expect(dto.name == "Springfield Elementary")
        #expect(dto.code == "SPR-001")
        #expect(dto.isActive == true)
        #expect(dto.subscriptionTier == "premium")
    }

    // MARK: - Roundtrip Tests

    @Test("roundtrip preserves data")
    func roundtripPreservesData() throws {
        let createdAt = Date(timeIntervalSince1970: 1000)
        let updatedAt = Date(timeIntervalSince1970: 2000)

        let original = try School(
            id: UUID(),
            name: "Test School",
            code: "TEST-001",
            isActive: true,
            address: "123 Main St",
            city: "Springfield",
            country: "USA",
            contactEmail: "test@school.edu",
            contactPhone: "+1-555-1234",
            maxStudents: 500,
            maxTeachers: 50,
            subscriptionTier: "premium",
            metadata: ["key": .string("value")],
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        let dto = SchoolMapper.toDTO(original)
        let converted = try SchoolMapper.toDomain(dto)

        #expect(original == converted)
    }

    @Test("roundtrip with minimal data preserves data")
    func roundtripWithMinimalData() throws {
        let createdAt = Date(timeIntervalSince1970: 1000)

        let original = try School(
            name: "Minimal School",
            code: "MIN-001",
            createdAt: createdAt,
            updatedAt: createdAt
        )

        let dto = SchoolMapper.toDTO(original)
        let converted = try SchoolMapper.toDomain(dto)

        #expect(original == converted)
    }

    // MARK: - Extension Method Tests

    @Test("SchoolDTO.toDomain() works correctly")
    func dtoToDomainExtension() throws {
        let dto = SchoolDTO(
            id: UUID(),
            name: "Test School",
            code: "TEST-001",
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

        let school = try dto.toDomain()

        #expect(school.id == dto.id)
        #expect(school.name == "Test School")
    }

    @Test("School.toDTO() works correctly")
    func schoolToDTOExtension() throws {
        let school = try School(
            name: "Test School",
            code: "TEST-001",
            subscriptionTier: "free"
        )

        let dto = school.toDTO()

        #expect(dto.id == school.id)
        #expect(dto.subscriptionTier == "free")
    }

    // MARK: - JSON Serialization Tests

    @Test("SchoolDTO encodes to JSON with snake_case keys")
    func dtoEncodesToSnakeCaseJSON() throws {
        let createdAt = Date(timeIntervalSince1970: 1705318200)
        let updatedAt = Date(timeIntervalSince1970: 1705459500)

        let dto = SchoolDTO(
            id: UUID(),
            name: "Test School",
            code: "TEST-001",
            isActive: true,
            address: "123 Main St",
            city: "Springfield",
            country: "USA",
            contactEmail: "test@school.edu",
            contactPhone: "+1-555-1234",
            maxStudents: 500,
            maxTeachers: 50,
            subscriptionTier: "premium",
            metadata: nil,
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(dto)
        let json = String(data: data, encoding: .utf8)!

        #expect(json.contains("\"is_active\""))
        #expect(json.contains("\"contact_email\""))
        #expect(json.contains("\"contact_phone\""))
        #expect(json.contains("\"max_students\""))
        #expect(json.contains("\"max_teachers\""))
        #expect(json.contains("\"subscription_tier\""))
        #expect(json.contains("\"created_at\""))
        #expect(json.contains("\"updated_at\""))
        #expect(!json.contains("\"isActive\""))
        #expect(!json.contains("\"contactEmail\""))
    }

    @Test("SchoolDTO decodes from JSON with snake_case keys")
    func dtoDecodesFromSnakeCaseJSON() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "name": "Springfield Elementary",
            "code": "SPR-001",
            "is_active": true,
            "address": "123 Main St",
            "city": "Springfield",
            "country": "USA",
            "contact_email": "contact@school.edu",
            "contact_phone": "+1-555-1234",
            "max_students": 500,
            "max_teachers": 50,
            "subscription_tier": "premium",
            "metadata": null,
            "created_at": "2024-01-15T10:30:00Z",
            "updated_at": "2024-01-20T14:45:00Z"
        }
        """
        let data = json.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dto = try decoder.decode(SchoolDTO.self, from: data)

        #expect(dto.name == "Springfield Elementary")
        #expect(dto.isActive == true)
        #expect(dto.contactEmail == "contact@school.edu")
        #expect(dto.maxStudents == 500)
        #expect(dto.subscriptionTier == "premium")
    }

    // MARK: - Backend Fixture Tests

    @Test("School valid decodes from backend JSON fixture")
    func schoolValidFromBackendFixture() throws {
        let json = BackendFixtures.schoolValidJSON
        let data = json.data(using: .utf8)!

        let decoder = BackendFixtures.backendDecoder
        let dto = try decoder.decode(SchoolDTO.self, from: data)
        let school = try dto.toDomain()

        #expect(school.name == "Colegio San José")
        #expect(school.code == "COL-SJ-001")
        #expect(school.isActive == true)
        #expect(school.address == "Calle 123 #45-67")
        #expect(school.city == "Bogotá")
        #expect(school.country == "CO")
        #expect(school.contactEmail == "contacto@colegiosanjose.edu.co")
        #expect(school.contactPhone == "+57-1-555-1234")
        #expect(school.maxStudents == 500)
        #expect(school.maxTeachers == 50)
        #expect(school.subscriptionTier == "premium")
    }

    @Test("School minimal decodes from backend JSON fixture")
    func schoolMinimalFromBackendFixture() throws {
        let json = BackendFixtures.schoolMinimalJSON
        let data = json.data(using: .utf8)!

        let decoder = BackendFixtures.backendDecoder
        let dto = try decoder.decode(SchoolDTO.self, from: data)
        let school = try dto.toDomain()

        #expect(school.name == "Escuela Nueva")
        #expect(school.code == "ESC-N-001")
        #expect(school.address == nil)
        #expect(school.city == nil)
        #expect(school.subscriptionTier == nil)
    }

    @Test("School with nulls decodes from backend JSON fixture")
    func schoolWithNullsFromBackendFixture() throws {
        let json = BackendFixtures.schoolWithNullsJSON
        let data = json.data(using: .utf8)!

        let decoder = BackendFixtures.backendDecoder
        let dto = try decoder.decode(SchoolDTO.self, from: data)
        let school = try dto.toDomain()

        #expect(school.name == "Instituto ABC")
        #expect(school.address == nil)
        #expect(school.city == nil)
        #expect(school.country == nil)
        #expect(school.contactEmail == nil)
        #expect(school.contactPhone == nil)
        #expect(school.maxStudents == nil)
        #expect(school.maxTeachers == nil)
        #expect(school.subscriptionTier == nil)
        #expect(school.metadata == nil)
    }

    @Test("School free tier decodes from backend JSON fixture")
    func schoolFreeTierFromBackendFixture() throws {
        let json = BackendFixtures.schoolFreeTierJSON
        let data = json.data(using: .utf8)!

        let decoder = BackendFixtures.backendDecoder
        let dto = try decoder.decode(SchoolDTO.self, from: data)
        let school = try dto.toDomain()

        #expect(school.subscriptionTier == "free")
        #expect(school.maxStudents == 100)
        #expect(school.maxTeachers == 10)
    }

    @Test("School with complex metadata decodes from backend JSON fixture")
    func schoolComplexMetadataFromBackendFixture() throws {
        let json = BackendFixtures.schoolComplexMetadataJSON
        let data = json.data(using: .utf8)!

        let decoder = BackendFixtures.backendDecoder
        let dto = try decoder.decode(SchoolDTO.self, from: data)
        let school = try dto.toDomain()

        #expect(school.metadata != nil)
        #expect(school.metadata?["string_value"] == .string("texto"))
        #expect(school.metadata?["number_value"] == .integer(42))
        #expect(school.metadata?["boolean_value"] == .bool(true))
    }

    @Test("School full serialization roundtrip with backend fixture")
    func schoolFullSerializationRoundtrip() throws {
        let json = BackendFixtures.schoolValidJSON
        let data = json.data(using: .utf8)!

        let decoder = BackendFixtures.backendDecoder
        let dto = try decoder.decode(SchoolDTO.self, from: data)
        let school = try dto.toDomain()

        // Serialize back to DTO and JSON
        let backToDTO = school.toDTO()
        let encoder = BackendFixtures.backendEncoder
        let encodedData = try encoder.encode(backToDTO)
        let encodedJSON = String(data: encodedData, encoding: .utf8)!

        // Verify snake_case keys
        #expect(encodedJSON.contains("\"is_active\""))
        #expect(encodedJSON.contains("\"contact_email\""))
        #expect(encodedJSON.contains("\"contact_phone\""))
        #expect(encodedJSON.contains("\"max_students\""))
        #expect(encodedJSON.contains("\"max_teachers\""))
        #expect(encodedJSON.contains("\"subscription_tier\""))
        #expect(encodedJSON.contains("\"created_at\""))
        #expect(encodedJSON.contains("\"updated_at\""))

        // Deserialize again and verify equality
        let decodedDTO = try decoder.decode(SchoolDTO.self, from: encodedData)
        let decodedSchool = try decodedDTO.toDomain()

        #expect(school == decodedSchool)
    }

    @Test("School JSON keys match backend specification")
    func schoolJSONKeysMatchBackendSpec() throws {
        let school = try School(
            id: UUID(),
            name: "Test School",
            code: "TEST-001",
            isActive: true,
            address: "123 Main St",
            city: "Springfield",
            country: "USA",
            contactEmail: "test@school.edu",
            contactPhone: "+1-555-1234",
            maxStudents: 500,
            maxTeachers: 50,
            subscriptionTier: "premium",
            metadata: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        let dto = school.toDTO()
        let encoder = BackendFixtures.backendEncoder
        let data = try encoder.encode(dto)
        let json = String(data: data, encoding: .utf8)!

        // Expected keys from edu-admin swagger.json
        #expect(json.contains("\"id\""))
        #expect(json.contains("\"name\""))
        #expect(json.contains("\"code\""))
        #expect(json.contains("\"is_active\""))
        #expect(json.contains("\"address\""))
        #expect(json.contains("\"city\""))
        #expect(json.contains("\"country\""))
        #expect(json.contains("\"contact_email\""))
        #expect(json.contains("\"contact_phone\""))
        #expect(json.contains("\"max_students\""))
        #expect(json.contains("\"max_teachers\""))
        #expect(json.contains("\"subscription_tier\""))
        #expect(json.contains("\"created_at\""))
        #expect(json.contains("\"updated_at\""))

        // Should NOT contain camelCase keys
        #expect(!json.contains("\"isActive\""))
        #expect(!json.contains("\"contactEmail\""))
        #expect(!json.contains("\"contactPhone\""))
        #expect(!json.contains("\"maxStudents\""))
        #expect(!json.contains("\"maxTeachers\""))
        #expect(!json.contains("\"subscriptionTier\""))
    }
}
