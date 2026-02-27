import Testing
import Foundation
@testable import EduModels

@Suite("Models Module Tests")
struct ModelsTests {

    @Test("User model creation with new API")
    func testUserCreation() throws {
        let user = try User(
            firstName: "Test",
            lastName: "User",
            email: "test@edugo.com"
        )

        #expect(user.email == "test@edugo.com")
        #expect(user.firstName == "Test")
        #expect(user.lastName == "User")
        #expect(user.fullName == "Test User")
        #expect(user.isActive == true)
    }

    @Test("Role model creation")
    func testRoleCreation() throws {
        let role = try Role(
            name: "Administrator",
            level: .admin
        )

        #expect(role.name == "Administrator")
        #expect(role.level == .admin)
    }

    @Test("Permission model creation")
    func testPermissionCreation() {
        let permission = Permission.create(
            resource: .users,
            action: .read
        )

        #expect(permission.code == "users.read")
        #expect(permission.resource == .users)
        #expect(permission.action == .read)
    }

    @Test("Document model creation")
    func testDocumentCreation() throws {
        let ownerID = UUID()
        let document = try Document(
            title: "Test Document",
            content: "Test content",
            type: .lesson,
            ownerID: ownerID
        )

        #expect(document.title == "Test Document")
        #expect(document.type == .lesson)
        #expect(document.state == .draft)
        #expect(document.ownerID == ownerID)
    }
}
