import Testing
import Foundation
import SwiftData
@testable import EduPersistence

// MARK: - Test Model

@Model
final class TestItem {
    var name: String
    var timestamp: Date

    init(name: String, timestamp: Date = .now) {
        self.name = name
        self.timestamp = timestamp
    }
}

// MARK: - Configuration Tests (No shared state)

@Suite("LocalPersistenceConfiguration Tests")
struct LocalPersistenceConfigurationTests {
    @Test("Testing configuration uses inMemory storage")
    func testTestingConfiguration() {
        let config = LocalPersistenceConfiguration.testing

        if case .inMemory = config.storageType {
            // Expected
        } else {
            Issue.record("Testing configuration should use inMemory storage")
        }

        #expect(config.cloudKitEnabled == false)
    }

    @Test("Production configuration uses persistent storage")
    func testProductionConfiguration() {
        let config = LocalPersistenceConfiguration.production

        if case .persistent = config.storageType {
            // Expected
        } else {
            Issue.record("Production configuration should use persistent storage")
        }

        #expect(config.cloudKitEnabled == false)
    }

    @Test("Default persistent URL is platform appropriate")
    func testDefaultPersistentURL() {
        let url = StorageType.defaultPersistentURL()

        #if os(iOS)
        #expect(url.path.contains("Documents"))
        #elseif os(macOS)
        #expect(url.path.contains("Application Support"))
        #endif

        #expect(url.path.contains("LocalPersistence"))
    }
}

// MARK: - Container Provider Tests (All tests that use shared singleton)

@Suite("PersistenceContainerProvider Tests", .serialized)
struct PersistenceContainerProviderTests {
    private let schema = Schema([TestItem.self])

    @Test("Shared instance is accessible")
    func testSharedInstance() async {
        let provider = PersistenceContainerProvider.shared
        _ = provider
    }

    @Test("Configure with inMemory storage succeeds")
    func testConfigureInMemory() async throws {
        let provider = PersistenceContainerProvider()
        try await provider.configure(
            with: .testing,
            schema: schema
        )

        let isInitialized = await provider.isInitialized
        #expect(isInitialized == true)
    }

    @Test("perform executes operation after configuration")
    func testPerformOperation() async throws {
        let provider = PersistenceContainerProvider()
        try await provider.configure(
            with: .testing,
            schema: schema
        )

        let result = try await provider.perform { _ in
            return 42
        }

        #expect(result == 42)
    }

    @Test("Can insert and fetch items using perform")
    func testInsertAndFetch() async throws {
        let provider = PersistenceContainerProvider()
        try await provider.configure(
            with: .testing,
            schema: schema
        )

        let itemName = "TestItem-\(UUID().uuidString.prefix(8))"

        try await provider.perform { context in
            let testItem = TestItem(name: itemName)
            context.insert(testItem)
            try context.save()
        }

        let fetchedName = try await provider.perform { context in
            let descriptor = FetchDescriptor<TestItem>()
            let items = try context.fetch(descriptor)
            return items.first(where: { $0.name == itemName })?.name
        }

        #expect(fetchedName == itemName)
    }

    @Test("Reset clears the container")
    func testResetClearsContainer() async throws {
        let provider = PersistenceContainerProvider()
        try await provider.configure(
            with: .testing,
            schema: schema
        )

        await provider.reset()

        let isInitialized = await provider.isInitialized
        #expect(isInitialized == false)
    }

    @Test("perform throws notConfigured when not configured")
    func testPerformThrowsWhenNotConfigured() async throws {
        let provider = PersistenceContainerProvider()

        do {
            _ = try await provider.perform { _ in
                return 1
            }
            Issue.record("Expected notConfigured error")
        } catch let error as PersistenceError {
            if case .notConfigured = error {
                // Expected
            } else {
                Issue.record("Expected notConfigured error, got \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}
