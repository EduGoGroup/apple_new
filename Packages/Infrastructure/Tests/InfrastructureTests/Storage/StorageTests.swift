import Testing
import Foundation
@testable import EduStorage

@Suite("Storage Tests")
struct StorageTests {
    @Test("StorageManager shared instance is accessible")
    func testSharedInstance() {
        let storage = StorageManager.shared
        // Storage should be accessible
    }

    @Test("Save and retrieve string value")
    func testSaveRetrieveString() async throws {
        let storage = StorageManager.shared
        let testKey = "test_key"
        let testValue = "test_value"

        try await storage.save(testValue, forKey: testKey)
        let retrieved: String? = try await storage.retrieve(String.self, forKey: testKey)

        #expect(retrieved == testValue)

        await storage.remove(forKey: testKey)
    }
}
