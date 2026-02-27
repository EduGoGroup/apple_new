import Testing
import Foundation
@testable import EduModels

@Suite("UserMapper Tests")
struct UserMapperTests {

    // MARK: - toDomain Tests

    @Test("toDomain with valid DTO returns User")
    func toDomainWithValidDTO() throws {
        let createdAt = Date(timeIntervalSince1970: 1000)
        let updatedAt = Date(timeIntervalSince1970: 2000)
        let dto = UserDTO(
            id: UUID(),
            firstName: "John",
            lastName: "Doe",
            fullName: "John Doe",
            email: "john@example.com",
            isActive: true,
            role: "teacher",
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        let user = try UserMapper.toDomain(dto)

        #expect(user.id == dto.id)
        #expect(user.firstName == "John")
        #expect(user.lastName == "Doe")
        #expect(user.fullName == "John Doe")
        #expect(user.email == "john@example.com")
        #expect(user.isActive == true)
        #expect(user.createdAt == createdAt)
        #expect(user.updatedAt == updatedAt)
    }

    @Test("toDomain with invalid email throws validation error")
    func toDomainWithInvalidEmail() {
        let dto = UserDTO(
            id: UUID(),
            firstName: "Test",
            lastName: "User",
            email: "invalid-email",
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        #expect(throws: (any Error).self) {
            _ = try UserMapper.toDomain(dto)
        }
    }

    @Test("toDomain with empty firstName throws validation error")
    func toDomainWithEmptyFirstName() {
        let dto = UserDTO(
            id: UUID(),
            firstName: "   ",
            lastName: "User",
            email: "test@example.com",
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        #expect(throws: (any Error).self) {
            _ = try UserMapper.toDomain(dto)
        }
    }

    @Test("toDomain with empty lastName throws validation error")
    func toDomainWithEmptyLastName() {
        let dto = UserDTO(
            id: UUID(),
            firstName: "Test",
            lastName: "   ",
            email: "test@example.com",
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        #expect(throws: (any Error).self) {
            _ = try UserMapper.toDomain(dto)
        }
    }

    @Test("toDomain normalizes email to lowercase")
    func toDomainNormalizesEmail() throws {
        let dto = UserDTO(
            id: UUID(),
            firstName: "Test",
            lastName: "User",
            email: "John.Doe@Example.COM",
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        let user = try UserMapper.toDomain(dto)

        #expect(user.email == "john.doe@example.com")
    }

    @Test("toDomain trims firstName whitespace")
    func toDomainTrimsFirstName() throws {
        let dto = UserDTO(
            id: UUID(),
            firstName: "  John  ",
            lastName: "Doe",
            email: "john@example.com",
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        let user = try UserMapper.toDomain(dto)

        #expect(user.firstName == "John")
    }

    @Test("toDomain trims lastName whitespace")
    func toDomainTrimsLastName() throws {
        let dto = UserDTO(
            id: UUID(),
            firstName: "John",
            lastName: "  Doe  ",
            email: "john@example.com",
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        let user = try UserMapper.toDomain(dto)

        #expect(user.lastName == "Doe")
    }

    // MARK: - toDTO Tests

    @Test("toDTO converts User correctly")
    func toDTOConvertsCorrectly() throws {
        let createdAt = Date(timeIntervalSince1970: 1000)
        let updatedAt = Date(timeIntervalSince1970: 2000)
        let user = try User(
            id: UUID(),
            firstName: "Jane",
            lastName: "Smith",
            email: "jane@test.com",
            isActive: false,
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        let dto = UserMapper.toDTO(user)

        #expect(dto.id == user.id)
        #expect(dto.firstName == user.firstName)
        #expect(dto.lastName == user.lastName)
        #expect(dto.fullName == user.fullName)
        #expect(dto.email == user.email)
        #expect(dto.isActive == false)
        #expect(dto.role == nil)
        #expect(dto.createdAt == createdAt)
        #expect(dto.updatedAt == updatedAt)
    }

    // MARK: - Roundtrip Tests

    @Test("roundtrip preserves data")
    func roundtripPreservesData() throws {
        let createdAt = Date(timeIntervalSince1970: 1000)
        let updatedAt = Date(timeIntervalSince1970: 2000)
        let original = try User(
            id: UUID(),
            firstName: "Test",
            lastName: "User",
            email: "test@test.com",
            isActive: true,
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        let dto = UserMapper.toDTO(original)
        let converted = try UserMapper.toDomain(dto)

        #expect(original == converted)
    }

    // MARK: - Extension Method Tests

    @Test("UserDTO.toDomain() works correctly")
    func dtoToDomainExtension() throws {
        let dto = UserDTO(
            id: UUID(),
            firstName: "John",
            lastName: "Doe",
            email: "john@example.com",
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        let user = try dto.toDomain()

        #expect(user.id == dto.id)
        #expect(user.firstName == dto.firstName)
        #expect(user.lastName == dto.lastName)
    }

    @Test("User.toDTO() works correctly")
    func userToDTOExtension() throws {
        let user = try User(
            firstName: "Jane",
            lastName: "Smith",
            email: "jane@test.com"
        )

        let dto = user.toDTO()

        #expect(dto.id == user.id)
        #expect(dto.firstName == user.firstName)
        #expect(dto.lastName == user.lastName)
    }

    // MARK: - JSON Serialization Tests

    @Test("UserDTO encodes to JSON with snake_case keys")
    func dtoEncodesToSnakeCaseJSON() throws {
        let id = UUID()
        let createdAt = Date(timeIntervalSince1970: 1705318200)
        let updatedAt = Date(timeIntervalSince1970: 1705459500)
        let dto = UserDTO(
            id: id,
            firstName: "John",
            lastName: "Doe",
            fullName: "John Doe",
            email: "john@example.com",
            isActive: true,
            role: "teacher",
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(dto)
        let json = String(data: data, encoding: .utf8)!

        #expect(json.contains("\"first_name\""))
        #expect(json.contains("\"last_name\""))
        #expect(json.contains("\"full_name\""))
        #expect(json.contains("\"is_active\""))
        #expect(json.contains("\"role\""))
        #expect(json.contains("\"created_at\""))
        #expect(json.contains("\"updated_at\""))
        #expect(!json.contains("\"firstName\""))
        #expect(!json.contains("\"lastName\""))
    }

    @Test("UserDTO decodes from JSON with snake_case keys")
    func dtoDecodesFromSnakeCaseJSON() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "first_name": "John",
            "last_name": "Doe",
            "full_name": "John Doe",
            "email": "john@example.com",
            "is_active": true,
            "role": "teacher",
            "created_at": "2024-01-15T10:30:00Z",
            "updated_at": "2024-01-20T14:45:00Z"
        }
        """
        let data = json.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dto = try decoder.decode(UserDTO.self, from: data)

        #expect(dto.firstName == "John")
        #expect(dto.lastName == "Doe")
        #expect(dto.fullName == "John Doe")
        #expect(dto.email == "john@example.com")
        #expect(dto.isActive == true)
        #expect(dto.role == "teacher")
    }

    // MARK: - Backend Fixture Tests

    @Test("User decodes from backend valid JSON fixture")
    func userDecodesFromBackendValidFixture() throws {
        let json = BackendFixtures.userValidJSON
        let data = json.data(using: .utf8)!

        let decoder = BackendFixtures.backendDecoder
        let dto = try decoder.decode(UserDTO.self, from: data)
        let user = try dto.toDomain()

        #expect(user.firstName == "Juan")
        #expect(user.lastName == "García")
        #expect(user.email == "juan.garcia@edugo.com")
        #expect(user.isActive == true)
    }

    @Test("User decodes from backend minimal JSON fixture")
    func userDecodesFromBackendMinimalFixture() throws {
        let json = BackendFixtures.userMinimalJSON
        let data = json.data(using: .utf8)!

        let decoder = BackendFixtures.backendDecoder
        let dto = try decoder.decode(UserDTO.self, from: data)
        let user = try dto.toDomain()

        #expect(user.firstName == "María")
        #expect(user.lastName == "López")
        #expect(dto.fullName == nil)
        #expect(dto.role == nil)
    }

    @Test("User decodes from backend JSON with nulls")
    func userDecodesFromBackendWithNullsFixture() throws {
        let json = BackendFixtures.userWithNullsJSON
        let data = json.data(using: .utf8)!

        let decoder = BackendFixtures.backendDecoder
        let dto = try decoder.decode(UserDTO.self, from: data)

        #expect(dto.fullName == nil)
        #expect(dto.role == nil)
        #expect(dto.isActive == false)

        let user = try dto.toDomain()
        #expect(user.isActive == false)
    }

    @Test("User inactive decodes from backend JSON fixture")
    func userInactiveDecodesFromBackendFixture() throws {
        let json = BackendFixtures.userInactiveJSON
        let data = json.data(using: .utf8)!

        let decoder = BackendFixtures.backendDecoder
        let dto = try decoder.decode(UserDTO.self, from: data)
        let user = try dto.toDomain()

        #expect(user.firstName == "Ana")
        #expect(user.lastName == "Rodríguez")
        #expect(user.isActive == false)
    }

    @Test("User full serialization roundtrip with backend fixture")
    func userFullSerializationRoundtrip() throws {
        // Deserialize from backend JSON
        let json = BackendFixtures.userValidJSON
        let data = json.data(using: .utf8)!

        let decoder = BackendFixtures.backendDecoder
        let dto = try decoder.decode(UserDTO.self, from: data)
        let user = try dto.toDomain()

        // Serialize back to DTO and JSON
        let backToDTO = user.toDTO()
        let encoder = BackendFixtures.backendEncoder
        let encodedData = try encoder.encode(backToDTO)
        let encodedJSON = String(data: encodedData, encoding: .utf8)!

        // Verify snake_case keys in encoded JSON
        #expect(encodedJSON.contains("\"first_name\""))
        #expect(encodedJSON.contains("\"last_name\""))
        #expect(encodedJSON.contains("\"is_active\""))
        #expect(encodedJSON.contains("\"created_at\""))
        #expect(encodedJSON.contains("\"updated_at\""))

        // Deserialize again and verify equality
        let decodedDTO = try decoder.decode(UserDTO.self, from: encodedData)
        let decodedUser = try decodedDTO.toDomain()

        #expect(user.id == decodedUser.id)
        #expect(user.firstName == decodedUser.firstName)
        #expect(user.lastName == decodedUser.lastName)
        #expect(user.email == decodedUser.email)
        #expect(user.isActive == decodedUser.isActive)
    }

    @Test("User JSON keys match backend specification")
    func userJSONKeysMatchBackendSpec() throws {
        let user = try User(
            id: UUID(),
            firstName: "Test",
            lastName: "User",
            email: "test@example.com",
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        let dto = user.toDTO()
        let encoder = BackendFixtures.backendEncoder
        let data = try encoder.encode(dto)
        let json = String(data: data, encoding: .utf8)!

        // These are the expected keys from edu-admin swagger.json
        #expect(json.contains("\"id\""))
        #expect(json.contains("\"first_name\""))
        #expect(json.contains("\"last_name\""))
        #expect(json.contains("\"email\""))
        #expect(json.contains("\"is_active\""))
        #expect(json.contains("\"created_at\""))
        #expect(json.contains("\"updated_at\""))

        // Should NOT contain camelCase keys
        #expect(!json.contains("\"firstName\""))
        #expect(!json.contains("\"lastName\""))
        #expect(!json.contains("\"isActive\""))
        #expect(!json.contains("\"createdAt\""))
        #expect(!json.contains("\"updatedAt\""))
    }
}
