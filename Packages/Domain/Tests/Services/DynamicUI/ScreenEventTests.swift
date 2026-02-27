import Testing
@testable import EduDomain
import EduCore

@Suite("ScreenEvent Tests")
struct ScreenEventTests {

    @Test("All event cases have rawValue")
    func eventRawValues() {
        #expect(ScreenEvent.loadData.rawValue == "loadData")
        #expect(ScreenEvent.saveNew.rawValue == "saveNew")
        #expect(ScreenEvent.saveExisting.rawValue == "saveExisting")
        #expect(ScreenEvent.delete.rawValue == "delete")
        #expect(ScreenEvent.search.rawValue == "search")
        #expect(ScreenEvent.selectItem.rawValue == "selectItem")
        #expect(ScreenEvent.refresh.rawValue == "refresh")
        #expect(ScreenEvent.loadMore.rawValue == "loadMore")
        #expect(ScreenEvent.create.rawValue == "create")
    }

    @Test("ScreenUserContext hasPermission works correctly")
    func userContextPermissions() {
        let ctx = ScreenUserContext(
            roleId: "1",
            roleName: "admin",
            permissions: ["schools:read", "schools:create"]
        )
        #expect(ctx.hasPermission("schools:read") == true)
        #expect(ctx.hasPermission("schools:create") == true)
        #expect(ctx.hasPermission("schools:delete") == false)
    }

    @Test("ScreenUserContext anonymous has no permissions")
    func anonymousContext() {
        let ctx = ScreenUserContext.anonymous
        #expect(ctx.hasPermission("anything") == false)
        #expect(ctx.roleName == "anonymous")
    }

    @Test("ScreenUserContext from DTO")
    func userContextFromDTO() {
        let dto = UserContextDTO(
            roleId: "r1",
            roleName: "teacher",
            schoolId: "s1",
            permissions: ["materials:read"]
        )
        let ctx = ScreenUserContext(dto: dto)
        #expect(ctx.roleId == "r1")
        #expect(ctx.roleName == "teacher")
        #expect(ctx.schoolId == "s1")
        #expect(ctx.hasPermission("materials:read") == true)
    }

    @Test("EventContext default values")
    func eventContextDefaults() {
        let ctx = EventContext(
            screenKey: "test",
            userContext: .anonymous
        )
        #expect(ctx.selectedItem == nil)
        #expect(ctx.fieldValues.isEmpty)
        #expect(ctx.searchQuery == nil)
        #expect(ctx.paginationOffset == 0)
    }
}
