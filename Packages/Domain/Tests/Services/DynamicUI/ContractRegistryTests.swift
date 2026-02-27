import Testing
@testable import EduDomain

@Suite("ContractRegistry Tests")
struct ContractRegistryTests {

    @Test("Register and find contract")
    @MainActor
    func registerAndFind() {
        let registry = ContractRegistry()
        let contract = LoginContract()
        registry.register(contract)
        let found = registry.contract(for: "login")
        #expect(found != nil)
        #expect(found?.screenKey == "login")
    }

    @Test("Returns nil for unknown screenKey")
    @MainActor
    func unknownKey() {
        let registry = ContractRegistry()
        let found = registry.contract(for: "nonexistent")
        #expect(found == nil)
    }

    @Test("registerDefaults registers all contracts")
    @MainActor
    func defaultRegistration() {
        let registry = ContractRegistry()
        registry.registerDefaults()

        // Auth
        #expect(registry.contract(for: "login") != nil)
        #expect(registry.contract(for: "settings") != nil)

        // Dashboards
        #expect(registry.contract(for: "dashboard-superadmin") != nil)
        #expect(registry.contract(for: "dashboard-schooladmin") != nil)
        #expect(registry.contract(for: "dashboard-teacher") != nil)
        #expect(registry.contract(for: "dashboard-student") != nil)
        #expect(registry.contract(for: "dashboard-guardian") != nil)

        // CRUD
        #expect(registry.contract(for: "schools-list") != nil)
        #expect(registry.contract(for: "schools-crud") != nil)
        #expect(registry.contract(for: "users-list") != nil)
        #expect(registry.contract(for: "users-crud") != nil)
        #expect(registry.contract(for: "units-list") != nil)
        #expect(registry.contract(for: "units-crud") != nil)
        #expect(registry.contract(for: "subjects-list") != nil)
        #expect(registry.contract(for: "subjects-crud") != nil)
        #expect(registry.contract(for: "memberships-list") != nil)
        #expect(registry.contract(for: "memberships-crud") != nil)
        #expect(registry.contract(for: "materials-list") != nil)
        #expect(registry.contract(for: "materials-crud") != nil)
        #expect(registry.contract(for: "assessments-list") != nil)
        #expect(registry.contract(for: "roles-list") != nil)
        #expect(registry.contract(for: "permissions-list") != nil)
        #expect(registry.contract(for: "guardian-list") != nil)
    }

    @Test("registerDefaults registers at least 23 contracts")
    @MainActor
    func defaultCount() {
        let registry = ContractRegistry()
        registry.registerDefaults()
        #expect(registry.count >= 23)
    }

    @Test("Overwriting a contract replaces it")
    @MainActor
    func overwrite() {
        let registry = ContractRegistry()
        let first = BaseCrudContract(
            screenKey: "test",
            resource: "first",
            apiPrefix: "admin:",
            basePath: "/api/v1/first"
        )
        let second = BaseCrudContract(
            screenKey: "test",
            resource: "second",
            apiPrefix: "admin:",
            basePath: "/api/v1/second"
        )
        registry.register(first)
        registry.register(second)
        #expect(registry.contract(for: "test")?.resource == "second")
    }
}
