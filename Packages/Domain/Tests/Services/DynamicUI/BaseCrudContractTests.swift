import Testing
@testable import EduDomain
import EduCore

@Suite("BaseCrudContract Tests")
struct BaseCrudContractTests {

    let contract = BaseCrudContract(
        screenKey: "schools-list",
        resource: "schools",
        apiPrefix: "admin:",
        basePath: "/api/v1/schools"
    )

    let context = EventContext(
        screenKey: "schools-list",
        userContext: ScreenUserContext(roleId: "1", roleName: "admin", permissions: ["schools:read"])
    )

    @Test("loadData returns correct endpoint")
    func loadDataEndpoint() {
        let endpoint = contract.endpointFor(event: .loadData, context: context)
        #expect(endpoint == "admin:/api/v1/schools")
    }

    @Test("refresh returns correct endpoint")
    func refreshEndpoint() {
        let endpoint = contract.endpointFor(event: .refresh, context: context)
        #expect(endpoint == "admin:/api/v1/schools")
    }

    @Test("loadMore returns correct endpoint")
    func loadMoreEndpoint() {
        let endpoint = contract.endpointFor(event: .loadMore, context: context)
        #expect(endpoint == "admin:/api/v1/schools")
    }

    @Test("search returns endpoint with query")
    func searchEndpoint() {
        let ctx = EventContext(
            screenKey: "schools-list",
            userContext: .anonymous,
            searchQuery: "Lincoln"
        )
        let endpoint = contract.endpointFor(event: .search, context: ctx)
        #expect(endpoint == "admin:/api/v1/schools?search=Lincoln")
    }

    @Test("saveNew returns base endpoint")
    func saveNewEndpoint() {
        let endpoint = contract.endpointFor(event: .saveNew, context: context)
        #expect(endpoint == "admin:/api/v1/schools")
    }

    @Test("saveExisting returns endpoint with ID")
    func saveExistingEndpoint() {
        let ctx = EventContext(
            screenKey: "schools-list",
            userContext: .anonymous,
            selectedItem: ["id": .string("123")]
        )
        let endpoint = contract.endpointFor(event: .saveExisting, context: ctx)
        #expect(endpoint == "admin:/api/v1/schools/123")
    }

    @Test("saveExisting returns nil without ID")
    func saveExistingNoId() {
        let endpoint = contract.endpointFor(event: .saveExisting, context: context)
        #expect(endpoint == nil)
    }

    @Test("delete returns endpoint with ID")
    func deleteEndpoint() {
        let ctx = EventContext(
            screenKey: "schools-list",
            userContext: .anonymous,
            selectedItem: ["id": .string("456")]
        )
        let endpoint = contract.endpointFor(event: .delete, context: ctx)
        #expect(endpoint == "admin:/api/v1/schools/456")
    }

    @Test("selectItem returns nil")
    func selectItemEndpoint() {
        let endpoint = contract.endpointFor(event: .selectItem, context: context)
        #expect(endpoint == nil)
    }

    @Test("create returns nil")
    func createEndpoint() {
        let endpoint = contract.endpointFor(event: .create, context: context)
        #expect(endpoint == nil)
    }

    // MARK: - Permissions

    @Test("read events require read permission")
    func readPermissions() {
        #expect(contract.permissionFor(event: .loadData) == "schools:read")
        #expect(contract.permissionFor(event: .refresh) == "schools:read")
        #expect(contract.permissionFor(event: .loadMore) == "schools:read")
        #expect(contract.permissionFor(event: .search) == "schools:read")
        #expect(contract.permissionFor(event: .selectItem) == "schools:read")
    }

    @Test("create events require create permission")
    func createPermissions() {
        #expect(contract.permissionFor(event: .saveNew) == "schools:create")
        #expect(contract.permissionFor(event: .create) == "schools:create")
    }

    @Test("update events require update permission")
    func updatePermissions() {
        #expect(contract.permissionFor(event: .saveExisting) == "schools:update")
    }

    @Test("delete events require delete permission")
    func deletePermissions() {
        #expect(contract.permissionFor(event: .delete) == "schools:delete")
    }
}
