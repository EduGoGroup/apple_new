import Testing
import Foundation
@testable import EduStorage

// MARK: - Test Helpers

private struct TestToken: Codable, Equatable, Sendable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
}

// MARK: - KeychainManager Tests

@Suite("KeychainManager Tests")
struct KeychainManagerTests {

    /// Unique service per test run to avoid cross-test contamination.
    private let keychain = KeychainManager(service: "com.edugo.tests.keychain.\(UUID().uuidString)")

    @Test("Save and retrieve a Codable item")
    func testSaveAndRetrieve() async throws {
        let token = TestToken(
            accessToken: "access_123",
            refreshToken: "refresh_456",
            expiresAt: Date(timeIntervalSince1970: 1_700_000_000)
        )

        try await keychain.save(token, for: "auth_token")
        let retrieved = try await keychain.retrieve(TestToken.self, for: "auth_token")

        #expect(retrieved == token)

        // Cleanup
        try await keychain.delete(for: "auth_token")
    }

    @Test("Retrieve non-existent key returns nil")
    func testRetrieveNonExistent() async throws {
        let result = try await keychain.retrieve(TestToken.self, for: "nonexistent_key_\(UUID().uuidString)")
        #expect(result == nil)
    }

    @Test("Overwrite existing key with new value")
    func testOverwrite() async throws {
        let original = TestToken(
            accessToken: "old_access",
            refreshToken: "old_refresh",
            expiresAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let updated = TestToken(
            accessToken: "new_access",
            refreshToken: "new_refresh",
            expiresAt: Date(timeIntervalSince1970: 1_800_000_000)
        )

        try await keychain.save(original, for: "overwrite_key")
        try await keychain.save(updated, for: "overwrite_key")

        let retrieved = try await keychain.retrieve(TestToken.self, for: "overwrite_key")
        #expect(retrieved == updated)

        // Cleanup
        try await keychain.delete(for: "overwrite_key")
    }

    @Test("Delete non-existent key does not throw")
    func testDeleteNonExistent() async throws {
        // Should not throw
        try await keychain.delete(for: "nonexistent_delete_key_\(UUID().uuidString)")
    }

    @Test("Delete removes the item")
    func testDeleteRemovesItem() async throws {
        let token = TestToken(
            accessToken: "to_delete",
            refreshToken: "to_delete",
            expiresAt: Date(timeIntervalSince1970: 1_700_000_000)
        )

        try await keychain.save(token, for: "delete_me")
        try await keychain.delete(for: "delete_me")

        let result = try await keychain.retrieve(TestToken.self, for: "delete_me")
        #expect(result == nil)
    }

    @Test("Exists returns true for stored item")
    func testExistsTrue() async throws {
        try await keychain.save("hello", for: "exists_key")
        let exists = try await keychain.exists(for: "exists_key")
        #expect(exists == true)

        // Cleanup
        try await keychain.delete(for: "exists_key")
    }

    @Test("Exists returns false for missing item")
    func testExistsFalse() async throws {
        let exists = try await keychain.exists(for: "missing_key_\(UUID().uuidString)")
        #expect(exists == false)
    }

    @Test("Save with different accessibility levels")
    func testAccessibilityLevels() async throws {
        try await keychain.save("val1", for: "acc_unlocked", accessibility: .whenUnlocked)
        try await keychain.save("val2", for: "acc_first_unlock", accessibility: .afterFirstUnlockThisDeviceOnly)
        try await keychain.save("val3", for: "acc_default", accessibility: .whenUnlockedThisDeviceOnly)

        let r1: String? = try await keychain.retrieve(String.self, for: "acc_unlocked")
        let r2: String? = try await keychain.retrieve(String.self, for: "acc_first_unlock")
        let r3: String? = try await keychain.retrieve(String.self, for: "acc_default")

        #expect(r1 == "val1")
        #expect(r2 == "val2")
        #expect(r3 == "val3")

        // Cleanup
        try await keychain.deleteAll()
    }
}
