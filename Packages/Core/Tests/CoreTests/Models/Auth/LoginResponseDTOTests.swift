import Testing
import Foundation
@testable import EduModels

@Suite("LoginResponseDTO Tests")
struct LoginResponseDTOTests {

    // MARK: - Full Login Response

    @Test("Decodes full login response from backend JSON")
    func testDecodeFullLoginResponse() throws {
        let json = """
        {
          "access_token": "eyJhbGciOiJIUzI1NiJ9.test",
          "refresh_token": "eyJhbGciOiJIUzI1NiJ9.refresh",
          "expires_in": 3600,
          "token_type": "Bearer",
          "user": {
            "id": "user-123",
            "email": "test@example.com",
            "first_name": "John",
            "last_name": "Doe",
            "full_name": "John Doe",
            "school_id": "school-1"
          },
          "schools": [
            {"id": "school-1", "name": "Test School", "code": "TS01"}
          ],
          "active_context": {
            "role_id": "role-admin",
            "role_name": "admin",
            "school_id": "school-1",
            "school_name": "Test School",
            "academic_unit_id": null,
            "permissions": ["schools:read", "schools:create", "users:read"]
          }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(LoginResponseDTO.self, from: json)

        #expect(response.accessToken == "eyJhbGciOiJIUzI1NiJ9.test")
        #expect(response.refreshToken == "eyJhbGciOiJIUzI1NiJ9.refresh")
        #expect(response.expiresIn == 3600)
        #expect(response.tokenType == "Bearer")

        // User
        #expect(response.user.id == "user-123")
        #expect(response.user.email == "test@example.com")
        #expect(response.user.firstName == "John")
        #expect(response.user.lastName == "Doe")
        #expect(response.user.fullName == "John Doe")
        #expect(response.user.schoolId == "school-1")

        // Schools
        #expect(response.schools.count == 1)
        #expect(response.schools[0].id == "school-1")
        #expect(response.schools[0].name == "Test School")
        #expect(response.schools[0].code == "TS01")

        // Active Context
        #expect(response.activeContext.roleId == "role-admin")
        #expect(response.activeContext.roleName == "admin")
        #expect(response.activeContext.schoolId == "school-1")
        #expect(response.activeContext.schoolName == "Test School")
        #expect(response.activeContext.academicUnitId == nil)
        #expect(response.activeContext.permissions == ["schools:read", "schools:create", "users:read"])
    }

    @Test("Decodes response with null optional fields")
    func testDecodeWithNullOptionals() throws {
        let json = """
        {
          "access_token": "token",
          "refresh_token": "refresh",
          "expires_in": 1800,
          "token_type": "Bearer",
          "user": {
            "id": "user-456",
            "email": "admin@test.com",
            "first_name": "Admin",
            "last_name": "User",
            "full_name": "Admin User",
            "school_id": null
          },
          "schools": [],
          "active_context": {
            "role_id": "role-superadmin",
            "role_name": "superadmin",
            "school_id": null,
            "school_name": null,
            "academic_unit_id": null,
            "permissions": []
          }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(LoginResponseDTO.self, from: json)

        #expect(response.user.schoolId == nil)
        #expect(response.schools.isEmpty)
        #expect(response.activeContext.schoolId == nil)
        #expect(response.activeContext.schoolName == nil)
        #expect(response.activeContext.academicUnitId == nil)
        #expect(response.activeContext.permissions.isEmpty)
    }

    // MARK: - RefreshTokenRequestDTO

    @Test("RefreshTokenRequestDTO encodes with snake_case")
    func testRefreshTokenRequestEncoding() throws {
        let request = RefreshTokenRequestDTO(refreshToken: "my-refresh-token")
        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(dict["refresh_token"] as? String == "my-refresh-token")
        #expect(dict["refreshToken"] == nil)
    }

    // MARK: - SwitchContextRequestDTO

    @Test("SwitchContextRequestDTO encodes with roleId present")
    func testSwitchContextWithRoleId() throws {
        let request = SwitchContextRequestDTO(schoolId: "school-1", roleId: "role-teacher")
        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(dict["school_id"] as? String == "school-1")
        #expect(dict["role_id"] as? String == "role-teacher")
    }

    @Test("SwitchContextRequestDTO encodes with roleId nil")
    func testSwitchContextWithoutRoleId() throws {
        let request = SwitchContextRequestDTO(schoolId: "school-1", roleId: nil)
        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(dict["school_id"] as? String == "school-1")
        // nil optional encodes as JSON null
        #expect(dict["role_id"] == nil || dict["role_id"] is NSNull)
    }

    // MARK: - LoginRequestDTO

    @Test("LoginRequestDTO encodes email and password")
    func testLoginRequestEncoding() throws {
        let request = LoginRequestDTO(email: "test@example.com", password: "secret123")
        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        #expect(dict["email"] as? String == "test@example.com")
        #expect(dict["password"] as? String == "secret123")
    }

    // MARK: - RefreshTokenResponseDTO

    @Test("RefreshTokenResponseDTO decodes correctly")
    func testRefreshTokenResponseDecoding() throws {
        let json = """
        {
          "access_token": "new-access",
          "refresh_token": "new-refresh",
          "expires_in": 7200,
          "token_type": "Bearer"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(RefreshTokenResponseDTO.self, from: json)

        #expect(response.accessToken == "new-access")
        #expect(response.refreshToken == "new-refresh")
        #expect(response.expiresIn == 7200)
        #expect(response.tokenType == "Bearer")
    }
}
