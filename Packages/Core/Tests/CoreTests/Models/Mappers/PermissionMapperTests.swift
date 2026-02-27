import Testing
import Foundation
import EduFoundation
@testable import EduModels

@Suite("PermissionMapper Tests")
struct PermissionMapperTests {

    // MARK: - toDomain Tests (Valid Resources)

    @Test("toDomain with all valid resources succeeds")
    func toDomainWithAllValidResources() throws {
        let resources = ["users", "roles", "documents", "courses", "grades", "settings", "reports"]

        for resource in resources {
            let dto = PermissionDTO(id: UUID(), code: "\(resource).read", resource: resource, action: "read")

            let permission = try PermissionMapper.toDomain(dto)

            #expect(permission.resource.rawValue == resource)
        }
    }

    // MARK: - toDomain Tests (Valid Actions)

    @Test("toDomain with all valid actions succeeds")
    func toDomainWithAllValidActions() throws {
        let actions = ["create", "read", "update", "delete", "list", "export", "import", "approve"]

        for action in actions {
            let dto = PermissionDTO(id: UUID(), code: "users.\(action)", resource: "users", action: action)

            let permission = try PermissionMapper.toDomain(dto)

            #expect(permission.action.rawValue == action)
        }
    }

    // MARK: - toDomain Tests (Invalid Values)

    @Test("toDomain with unknown resource throws DomainError")
    func toDomainWithUnknownResource() {
        let dto = PermissionDTO(id: UUID(), code: "unknown.read", resource: "unknown_resource", action: "read")

        #expect(throws: DomainError.self) {
            _ = try PermissionMapper.toDomain(dto)
        }
    }

    @Test("toDomain with unknown action throws DomainError")
    func toDomainWithUnknownAction() {
        let dto = PermissionDTO(id: UUID(), code: "users.unknown", resource: "users", action: "unknown_action")

        #expect(throws: DomainError.self) {
            _ = try PermissionMapper.toDomain(dto)
        }
    }

    @Test("toDomain with empty resource throws DomainError")
    func toDomainWithEmptyResource() {
        let dto = PermissionDTO(id: UUID(), code: ".read", resource: "", action: "read")

        #expect(throws: DomainError.self) {
            _ = try PermissionMapper.toDomain(dto)
        }
    }

    @Test("toDomain with empty action throws DomainError")
    func toDomainWithEmptyAction() {
        let dto = PermissionDTO(id: UUID(), code: "users.", resource: "users", action: "")

        #expect(throws: DomainError.self) {
            _ = try PermissionMapper.toDomain(dto)
        }
    }

    // MARK: - toDomain Tests (Code Generation)

    @Test("toDomain generates code from resource and action ignoring DTO code")
    func toDomainGeneratesCode() throws {
        let dto = PermissionDTO(id: UUID(), code: "ignored_code", resource: "documents", action: "create")

        let permission = try PermissionMapper.toDomain(dto)

        #expect(permission.code == "documents.create")
    }

    @Test("toDomain preserves ID from DTO")
    func toDomainPreservesID() throws {
        let id = UUID()
        let dto = PermissionDTO(id: id, code: "users.read", resource: "users", action: "read")

        let permission = try PermissionMapper.toDomain(dto)

        #expect(permission.id == id)
    }

    // MARK: - toDTO Tests

    @Test("toDTO converts Permission correctly")
    func toDTOConvertsCorrectly() {
        let permission = Permission.create(id: UUID(), resource: .users, action: .read)

        let dto = PermissionMapper.toDTO(permission)

        #expect(dto.id == permission.id)
        #expect(dto.code == "users.read")
        #expect(dto.resource == "users")
        #expect(dto.action == "read")
    }

    @Test("toDTO with importData action uses 'import' raw value")
    func toDTOWithImportAction() {
        let permission = Permission.create(id: UUID(), resource: .grades, action: .importData)

        let dto = PermissionMapper.toDTO(permission)

        #expect(dto.action == "import")
    }

    @Test("toDTO converts all resource types correctly")
    func toDTOConvertsAllResources() {
        let resources: [Resource] = [.users, .roles, .documents, .courses, .grades, .settings, .reports]

        for resource in resources {
            let permission = Permission.create(id: UUID(), resource: resource, action: .read)
            let dto = PermissionMapper.toDTO(permission)

            #expect(dto.resource == resource.rawValue)
        }
    }

    @Test("toDTO converts all action types correctly")
    func toDTOConvertsAllActions() {
        let actions: [Action] = [.create, .read, .update, .delete, .list, .export, .importData, .approve]

        for action in actions {
            let permission = Permission.create(id: UUID(), resource: .users, action: action)
            let dto = PermissionMapper.toDTO(permission)

            #expect(dto.action == action.rawValue)
        }
    }

    // MARK: - Roundtrip Tests

    @Test("roundtrip preserves data")
    func roundtripPreservesData() throws {
        let original = Permission.create(id: UUID(), resource: .documents, action: .update)

        let dto = PermissionMapper.toDTO(original)
        let converted = try PermissionMapper.toDomain(dto)

        #expect(original == converted)
    }

    @Test("roundtrip preserves all resource-action combinations")
    func roundtripPreservesAllCombinations() throws {
        let resources: [Resource] = [.users, .documents, .roles]
        let actions: [Action] = [.create, .read, .update, .delete]

        for resource in resources {
            for action in actions {
                let original = Permission.create(id: UUID(), resource: resource, action: action)
                let dto = PermissionMapper.toDTO(original)
                let converted = try PermissionMapper.toDomain(dto)

                #expect(original == converted)
            }
        }
    }
}
