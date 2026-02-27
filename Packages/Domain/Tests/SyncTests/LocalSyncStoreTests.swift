import Testing
import Foundation
import EduCore
@testable import EduDomain

@Suite("LocalSyncStore Tests", .serialized)
struct LocalSyncStoreTests {

    // MARK: - Fixtures

    private static func makeBundle(
        permissions: [String] = ["read"],
        hashes: [String: String] = ["menu": "h1"]
    ) -> UserDataBundle {
        UserDataBundle(
            menu: [
                MenuItemDTO(
                    key: "dashboard",
                    displayName: "Dashboard",
                    scope: "student",
                    sortOrder: 1,
                    permissions: ["view_dashboard"],
                    screens: ["main": "dashboard_main"]
                )
            ],
            permissions: permissions,
            screens: [:],
            availableContexts: [
                UserContextDTO(roleId: "role-1", roleName: "student")
            ],
            hashes: hashes,
            syncedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }

    // MARK: - Save & Restore

    @Test("save and restore round-trip preserves bundle data")
    func saveRestoreRoundTrip() async throws {
        let store = LocalSyncStore()
        await store.clear()

        let bundle = Self.makeBundle(
            permissions: ["read", "write"],
            hashes: ["menu": "abc", "screens": "def"]
        )
        try await store.save(bundle: bundle)

        let restored = await store.restore()

        #expect(restored != nil)
        #expect(restored?.permissions == ["read", "write"])
        #expect(restored?.hashes["menu"] == "abc")
        #expect(restored?.hashes["screens"] == "def")
        #expect(restored?.menu.count == 1)
        #expect(restored?.menu[0].key == "dashboard")
        #expect(restored?.availableContexts.count == 1)

        await store.clear()
    }

    @Test("restore returns nil when no stored data")
    func restoreReturnsNilWhenEmpty() async {
        let store = LocalSyncStore()
        await store.clear()

        let result = await store.restore()
        #expect(result == nil)
    }

    @Test("save overwrites previous bundle")
    func saveOverwritesPrevious() async throws {
        let store = LocalSyncStore()
        await store.clear()

        let first = Self.makeBundle(permissions: ["read"])
        try await store.save(bundle: first)

        let second = Self.makeBundle(permissions: ["read", "write", "delete"])
        try await store.save(bundle: second)

        let restored = await store.restore()
        #expect(restored?.permissions == ["read", "write", "delete"])

        await store.clear()
    }

    // MARK: - updateBucket

    @Test("updateBucket updates hash for known bucket")
    func updateBucketUpdatesHash() async throws {
        let store = LocalSyncStore()
        await store.clear()

        let bundle = Self.makeBundle(hashes: ["menu": "old-hash"])
        try await store.save(bundle: bundle)

        // Update permissions bucket with new hash
        let newPermissions: JSONValue = .array([.string("admin"), .string("edit")])
        try await store.updateBucket(name: "permissions", data: newPermissions, hash: "new-perm-hash")

        let restored = await store.restore()
        #expect(restored?.hashes["permissions"] == "new-perm-hash")
        #expect(restored?.hashes["menu"] == "old-hash")

        await store.clear()
    }

    @Test("updateBucket updates permissions data")
    func updateBucketUpdatesPermissions() async throws {
        let store = LocalSyncStore()
        await store.clear()

        let bundle = Self.makeBundle(permissions: ["read"])
        try await store.save(bundle: bundle)

        let newPermissions: JSONValue = .array([.string("admin"), .string("write")])
        try await store.updateBucket(name: "permissions", data: newPermissions, hash: "h2")

        let restored = await store.restore()
        #expect(restored?.permissions == ["admin", "write"])

        await store.clear()
    }

    @Test("updateBucket for unknown bucket only updates hash")
    func updateBucketUnknownBucket() async throws {
        let store = LocalSyncStore()
        await store.clear()

        let bundle = Self.makeBundle(permissions: ["read"])
        try await store.save(bundle: bundle)

        try await store.updateBucket(name: "custom_bucket", data: .string("data"), hash: "custom-hash")

        let restored = await store.restore()
        #expect(restored?.hashes["custom_bucket"] == "custom-hash")
        #expect(restored?.permissions == ["read"])

        await store.clear()
    }

    @Test("updateBucket throws when no active bundle")
    func updateBucketThrowsWhenEmpty() async {
        let store = LocalSyncStore()
        await store.clear()

        do {
            try await store.updateBucket(name: "menu", data: .null, hash: "h1")
            Issue.record("Expected updateBucket to throw")
        } catch {
            #expect(error is SyncError)
        }
    }

    // MARK: - Clear

    @Test("clear removes persisted data")
    func clearRemovesData() async throws {
        let store = LocalSyncStore()
        await store.clear()

        let bundle = Self.makeBundle()
        try await store.save(bundle: bundle)

        let beforeClear = await store.restore()
        #expect(beforeClear != nil)

        await store.clear()

        let afterClear = await store.restore()
        #expect(afterClear == nil)
    }

    @Test("clear followed by restore returns nil from memory cache")
    func clearResetsMemoryCache() async throws {
        let store = LocalSyncStore()
        await store.clear()

        let bundle = Self.makeBundle()
        try await store.save(bundle: bundle)

        await store.clear()

        // Same store instance — memory cache should be cleared
        let restored = await store.restore()
        #expect(restored == nil)
    }
}
