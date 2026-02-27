import Testing
import Foundation
import EduFoundation
@testable import EduModels

@Suite("User Entity Tests")
struct UserTests {

    // MARK: - Initialization Tests

    @Test("User creation with valid data")
    func testValidUserCreation() throws {
        let user = try User(
            firstName: "John",
            lastName: "Doe",
            email: "john@edugo.com"
        )

        #expect(user.firstName == "John")
        #expect(user.lastName == "Doe")
        #expect(user.fullName == "John Doe")
        #expect(user.email == "john@edugo.com")
        #expect(user.isActive == true)
    }

    @Test("User creation trims whitespace from firstName")
    func testFirstNameTrimming() throws {
        let user = try User(
            firstName: "  John  ",
            lastName: "Doe",
            email: "john@edugo.com"
        )

        #expect(user.firstName == "John")
    }

    @Test("User creation trims whitespace from lastName")
    func testLastNameTrimming() throws {
        let user = try User(
            firstName: "John",
            lastName: "  Doe  ",
            email: "john@edugo.com"
        )

        #expect(user.lastName == "Doe")
    }

    @Test("User creation lowercases email")
    func testEmailLowercase() throws {
        let user = try User(
            firstName: "John",
            lastName: "Doe",
            email: "John@EDUGO.com"
        )

        #expect(user.email == "john@edugo.com")
    }

    @Test("User creation trims whitespace from email")
    func testEmailTrimming() throws {
        let user = try User(
            firstName: "John",
            lastName: "Doe",
            email: "  John@EDUGO.com  "
        )

        #expect(user.email == "john@edugo.com")
    }

    @Test("User creation with custom ID")
    func testCustomID() throws {
        let customID = UUID()
        let user = try User(
            id: customID,
            firstName: "John",
            lastName: "Doe",
            email: "john@edugo.com"
        )

        #expect(user.id == customID)
    }

    @Test("User creation with inactive status")
    func testInactiveUser() throws {
        let user = try User(
            firstName: "John",
            lastName: "Doe",
            email: "john@edugo.com",
            isActive: false
        )

        #expect(user.isActive == false)
    }

    @Test("User creation with custom timestamps")
    func testCustomTimestamps() throws {
        let createdAt = Date(timeIntervalSince1970: 1000)
        let updatedAt = Date(timeIntervalSince1970: 2000)
        let user = try User(
            firstName: "John",
            lastName: "Doe",
            email: "john@edugo.com",
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        #expect(user.createdAt == createdAt)
        #expect(user.updatedAt == updatedAt)
    }

    @Test("fullName computed property combines firstName and lastName")
    func testFullName() throws {
        let user = try User(
            firstName: "María",
            lastName: "García López",
            email: "maria@edugo.com"
        )

        #expect(user.fullName == "María García López")
    }

    // MARK: - Validation Tests

    @Test("User creation fails with empty firstName")
    func testEmptyFirstNameFails() {
        #expect {
            _ = try User(firstName: "", lastName: "Doe", email: "john@edugo.com")
        } throws: { error in
            guard let domainError = error as? DomainError,
                  case .validationFailed(let field, _) = domainError,
                  field == "firstName" else {
                return false
            }
            return true
        }
    }

    @Test("User creation fails with whitespace-only firstName")
    func testWhitespaceFirstNameFails() {
        #expect {
            _ = try User(firstName: "   ", lastName: "Doe", email: "john@edugo.com")
        } throws: { error in
            guard let domainError = error as? DomainError,
                  case .validationFailed(let field, _) = domainError,
                  field == "firstName" else {
                return false
            }
            return true
        }
    }

    @Test("User creation fails with empty lastName")
    func testEmptyLastNameFails() {
        #expect {
            _ = try User(firstName: "John", lastName: "", email: "john@edugo.com")
        } throws: { error in
            guard let domainError = error as? DomainError,
                  case .validationFailed(let field, _) = domainError,
                  field == "lastName" else {
                return false
            }
            return true
        }
    }

    @Test("User creation fails with whitespace-only lastName")
    func testWhitespaceLastNameFails() {
        #expect {
            _ = try User(firstName: "John", lastName: "   ", email: "john@edugo.com")
        } throws: { error in
            guard let domainError = error as? DomainError,
                  case .validationFailed(let field, _) = domainError,
                  field == "lastName" else {
                return false
            }
            return true
        }
    }

    @Test("User creation fails with invalid email")
    func testInvalidEmailFails() {
        #expect {
            _ = try User(firstName: "John", lastName: "Doe", email: "notanemail")
        } throws: { error in
            guard let domainError = error as? DomainError,
                  case .validationFailed(let field, _) = domainError,
                  field == "email" else {
                return false
            }
            return true
        }
    }

    @Test("User creation fails with email missing domain")
    func testEmailMissingDomainFails() {
        #expect {
            _ = try User(firstName: "John", lastName: "Doe", email: "john@")
        } throws: { error in
            guard let domainError = error as? DomainError,
                  case .validationFailed(let field, _) = domainError,
                  field == "email" else {
                return false
            }
            return true
        }
    }

    @Test("Valid email formats are accepted")
    func testValidEmailFormats() throws {
        let validEmails = [
            "user@domain.com",
            "user.name@domain.com",
            "user+tag@domain.com",
            "user@sub.domain.com",
            "user123@domain.io"
        ]

        for email in validEmails {
            let user = try User(firstName: "Test", lastName: "User", email: email)
            #expect(user.email == email.lowercased())
        }
    }

    // MARK: - Copy Method Tests

    @Test("with(firstName:) creates copy with new firstName")
    func testWithFirstName() throws {
        let user = try User(firstName: "John", lastName: "Doe", email: "john@edugo.com")
        let updated = try user.with(firstName: "Jane")

        #expect(updated.firstName == "Jane")
        #expect(updated.lastName == "Doe")
        #expect(updated.id == user.id)
        #expect(updated.email == user.email)
    }

    @Test("with(lastName:) creates copy with new lastName")
    func testWithLastName() throws {
        let user = try User(firstName: "John", lastName: "Doe", email: "john@edugo.com")
        let updated = try user.with(lastName: "Smith")

        #expect(updated.firstName == "John")
        #expect(updated.lastName == "Smith")
        #expect(updated.id == user.id)
        #expect(updated.email == user.email)
    }

    @Test("with(email:) creates copy with new email")
    func testWithEmail() throws {
        let user = try User(firstName: "John", lastName: "Doe", email: "john@edugo.com")
        let updated = try user.with(email: "jane@edugo.com")

        #expect(updated.email == "jane@edugo.com")
        #expect(updated.id == user.id)
        #expect(updated.firstName == user.firstName)
    }

    @Test("with(email:) trims and lowercases new email")
    func testWithEmailNormalization() throws {
        let user = try User(firstName: "John", lastName: "Doe", email: "john@edugo.com")
        let updated = try user.with(email: "  Jane@EduGo.com  ")

        #expect(updated.email == "jane@edugo.com")
    }

    @Test("with(isActive:) creates copy with new status")
    func testWithIsActive() throws {
        let user = try User(firstName: "John", lastName: "Doe", email: "john@edugo.com")
        let deactivated = user.with(isActive: false)

        #expect(deactivated.isActive == false)
        #expect(deactivated.id == user.id)
    }

    @Test("copy methods update updatedAt timestamp")
    func testCopyMethodsUpdateTimestamp() throws {
        let originalDate = Date(timeIntervalSince1970: 1000)
        let user = try User(
            firstName: "John",
            lastName: "Doe",
            email: "john@edugo.com",
            createdAt: originalDate,
            updatedAt: originalDate
        )

        let updated = try user.with(firstName: "Jane")

        #expect(updated.createdAt == originalDate)
        #expect(updated.updatedAt > originalDate)
    }

    // MARK: - Protocol Conformance Tests

    @Test("User conforms to Equatable")
    func testEquatable() throws {
        let id = UUID()
        let createdAt = Date()
        let updatedAt = Date()
        let user1 = try User(
            id: id,
            firstName: "John",
            lastName: "Doe",
            email: "john@edugo.com",
            createdAt: createdAt,
            updatedAt: updatedAt
        )
        let user2 = try User(
            id: id,
            firstName: "John",
            lastName: "Doe",
            email: "john@edugo.com",
            createdAt: createdAt,
            updatedAt: updatedAt
        )
        let user3 = try User(firstName: "John", lastName: "Doe", email: "john@edugo.com")

        #expect(user1 == user2)
        #expect(user1 != user3)
    }

    @Test("User conforms to Identifiable")
    func testIdentifiable() throws {
        let user = try User(firstName: "John", lastName: "Doe", email: "john@edugo.com")
        #expect(user.id == user.id)
    }

    @Test("User conforms to Hashable")
    func testHashable() throws {
        let user1 = try User(firstName: "John", lastName: "Doe", email: "john@edugo.com")
        let user2 = try User(firstName: "Jane", lastName: "Smith", email: "jane@edugo.com")

        var userSet: Set<User> = []
        userSet.insert(user1)
        userSet.insert(user2)

        #expect(userSet.count == 2)
    }

    // MARK: - Error Description Tests

    @Test("DomainError has meaningful descriptions for validation failures")
    func testErrorDescriptions() {
        let emptyNameError = DomainError.validationFailed(field: "firstName", reason: "Name cannot be empty")
        let invalidEmailError = DomainError.validationFailed(field: "email", reason: "Invalid email: bad")

        #expect(emptyNameError.errorDescription?.contains("firstName") == true)
        #expect(emptyNameError.errorDescription?.contains("empty") == true)
        #expect(invalidEmailError.errorDescription?.contains("email") == true)
        #expect(invalidEmailError.errorDescription?.contains("bad") == true)
    }

    // MARK: - Codable Tests

    @Test("User encodes and decodes correctly")
    func testCodable() throws {
        let user = try User(
            firstName: "John",
            lastName: "Doe",
            email: "john@edugo.com",
            isActive: true
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(user)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(User.self, from: data)

        #expect(decoded == user)
    }
}
