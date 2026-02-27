import Testing
import Foundation
@testable import EduModels

@Suite("Permission Entity Tests")
struct PermissionTests {

    // MARK: - Resource Tests

    @Test("Resource has all expected cases")
    func testResourceCases() {
        let allCases = Resource.allCases
        #expect(allCases.count == 7)
        #expect(allCases.contains(.users))
        #expect(allCases.contains(.roles))
        #expect(allCases.contains(.documents))
        #expect(allCases.contains(.courses))
        #expect(allCases.contains(.grades))
        #expect(allCases.contains(.settings))
        #expect(allCases.contains(.reports))
    }

    @Test("Resource has meaningful descriptions")
    func testResourceDescriptions() {
        #expect(Resource.users.description == "Users")
        #expect(Resource.roles.description == "Roles")
        #expect(Resource.documents.description == "Documents")
        #expect(Resource.courses.description == "Courses")
        #expect(Resource.grades.description == "Grades")
        #expect(Resource.settings.description == "Settings")
        #expect(Resource.reports.description == "Reports")
    }

    @Test("Resource raw values are valid identifiers")
    func testResourceRawValues() {
        for resource in Resource.allCases {
            #expect(!resource.rawValue.isEmpty)
            #expect(!resource.rawValue.contains(" "))
        }
    }

    // MARK: - Action Tests

    @Test("Action has all expected cases")
    func testActionCases() {
        let allCases = Action.allCases
        #expect(allCases.count == 8)
        #expect(allCases.contains(.create))
        #expect(allCases.contains(.read))
        #expect(allCases.contains(.update))
        #expect(allCases.contains(.delete))
        #expect(allCases.contains(.list))
        #expect(allCases.contains(.export))
        #expect(allCases.contains(.importData))
        #expect(allCases.contains(.approve))
    }

    @Test("Action has meaningful descriptions")
    func testActionDescriptions() {
        #expect(Action.create.description == "Create")
        #expect(Action.read.description == "Read")
        #expect(Action.update.description == "Update")
        #expect(Action.delete.description == "Delete")
        #expect(Action.list.description == "List")
        #expect(Action.export.description == "Export")
        #expect(Action.importData.description == "Import")
        #expect(Action.approve.description == "Approve")
    }

    @Test("Action importData has 'import' raw value")
    func testImportDataRawValue() {
        #expect(Action.importData.rawValue == "import")
    }

    // MARK: - Permission Initialization Tests

    @Test("Permission creation with valid data")
    func testValidPermissionCreation() throws {
        let permission = try Permission(
            code: "users.read",
            resource: .users,
            action: .read
        )

        #expect(permission.code == "users.read")
        #expect(permission.resource == .users)
        #expect(permission.action == .read)
    }

    @Test("Permission creation lowercases code")
    func testCodeLowercase() throws {
        let permission = try Permission(
            code: "Users.READ",
            resource: .users,
            action: .read
        )

        #expect(permission.code == "users.read")
    }

    @Test("Permission creation with custom ID")
    func testCustomID() throws {
        let customID = UUID()
        let permission = try Permission(
            id: customID,
            code: "users.read",
            resource: .users,
            action: .read
        )

        #expect(permission.id == customID)
    }

    // MARK: - Permission Validation Tests

    @Test("Permission creation fails with empty code")
    func testEmptyCodeFails() {
        #expect(throws: PermissionValidationError.emptyCode) {
            _ = try Permission(code: "", resource: .users, action: .read)
        }
    }

    @Test("Permission creation fails with whitespace-only code")
    func testWhitespaceCodeFails() {
        #expect(throws: PermissionValidationError.emptyCode) {
            _ = try Permission(code: "   ", resource: .users, action: .read)
        }
    }

    @Test("Permission creation fails with invalid code format - no dot")
    func testInvalidCodeNoDot() {
        #expect(throws: PermissionValidationError.invalidCodeFormat("usersread")) {
            _ = try Permission(code: "usersread", resource: .users, action: .read)
        }
    }

    @Test("Permission creation fails with invalid code format - multiple dots")
    func testInvalidCodeMultipleDots() {
        #expect(throws: PermissionValidationError.invalidCodeFormat("users.read.all")) {
            _ = try Permission(code: "users.read.all", resource: .users, action: .read)
        }
    }

    @Test("Permission creation fails with invalid code format - numbers")
    func testInvalidCodeWithNumbers() {
        #expect(throws: PermissionValidationError.invalidCodeFormat("users123.read")) {
            _ = try Permission(code: "users123.read", resource: .users, action: .read)
        }
    }

    @Test("Valid code formats are accepted")
    func testValidCodeFormats() throws {
        let validCodes = [
            "users.read",
            "documents.create",
            "roles.update",
            "courses_advanced.delete",
            "grade_reports.export"
        ]

        for code in validCodes {
            let permission = try Permission(code: code, resource: .users, action: .read)
            #expect(permission.code == code.lowercased())
        }
    }

    // MARK: - Factory Method Tests

    @Test("create factory generates correct code")
    func testCreateFactory() {
        let permission = Permission.create(resource: .users, action: .read)

        #expect(permission.code == "users.read")
        #expect(permission.resource == .users)
        #expect(permission.action == .read)
    }

    @Test("create factory with custom ID")
    func testCreateFactoryWithID() {
        let customID = UUID()
        let permission = Permission.create(id: customID, resource: .documents, action: .create)

        #expect(permission.id == customID)
        #expect(permission.code == "documents.create")
    }

    @Test("create factory works for all resource/action combinations")
    func testCreateFactoryAllCombinations() {
        for resource in Resource.allCases {
            for action in Action.allCases {
                let permission = Permission.create(resource: resource, action: action)
                let expectedCode = "\(resource.rawValue).\(action.rawValue)"
                #expect(permission.code == expectedCode)
            }
        }
    }

    // MARK: - Protocol Conformance Tests

    @Test("Permission conforms to Equatable")
    func testEquatable() throws {
        let id = UUID()
        let perm1 = try Permission(id: id, code: "users.read", resource: .users, action: .read)
        let perm2 = try Permission(id: id, code: "users.read", resource: .users, action: .read)
        let perm3 = try Permission(code: "users.read", resource: .users, action: .read)

        #expect(perm1 == perm2)
        #expect(perm1 != perm3)
    }

    @Test("Permission conforms to Hashable")
    func testHashable() throws {
        let perm1 = try Permission(code: "users.read", resource: .users, action: .read)
        let perm2 = try Permission(code: "users.create", resource: .users, action: .create)

        var permSet: Set<Permission> = []
        permSet.insert(perm1)
        permSet.insert(perm2)

        #expect(permSet.count == 2)
    }

    @Test("Permission conforms to Identifiable")
    func testIdentifiable() throws {
        let permission = try Permission(code: "users.read", resource: .users, action: .read)
        #expect(permission.id == permission.id)
    }

    // MARK: - Error Description Tests

    @Test("PermissionValidationError has meaningful descriptions")
    func testErrorDescriptions() {
        let emptyCodeError = PermissionValidationError.emptyCode
        let invalidFormatError = PermissionValidationError.invalidCodeFormat("bad")

        #expect(emptyCodeError.errorDescription?.contains("empty") == true)
        #expect(invalidFormatError.errorDescription?.contains("bad") == true)
        #expect(invalidFormatError.errorDescription?.contains("resource.action") == true)
    }
}
