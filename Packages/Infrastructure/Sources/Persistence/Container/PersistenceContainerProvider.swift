import Foundation
import SwiftData

/// PersistenceContainerProvider - Thread-safe SwiftData container management
///
/// An actor that manages the SwiftData ModelContainer and provides isolated
/// access to ModelContext instances. Uses the singleton pattern for shared access.
///
/// ## Usage
///
/// ```swift
/// // Perform database operations within the actor's isolation
/// let items = try await PersistenceContainerProvider.shared.perform { context in
///     try context.fetch(FetchDescriptor<MyModel>())
/// }
/// ```
///
/// ## Thread Safety
///
/// This actor ensures all container operations are serialized and thread-safe.
/// Operations are executed within the actor's isolation via the `perform` method.
public actor PersistenceContainerProvider: Sendable {
    /// Shared singleton instance
    public static let shared = PersistenceContainerProvider()

    /// The underlying SwiftData model container
    private var container: ModelContainer?

    /// Reused context for serialized operations
    private var context: ModelContext?

    /// The current configuration
    private var configuration: LocalPersistenceConfiguration

    /// Whether the container has been initialized
    public var isInitialized: Bool {
        container != nil
    }

    init() {
        self.configuration = .production
    }

    /// Configures the container with the specified configuration and schema
    ///
    /// Must be called before using `perform(_:)`. Can be called multiple times
    /// to reconfigure (e.g., switching from production to testing).
    ///
    /// - Parameters:
    ///   - configuration: The persistence configuration to use
    ///   - schema: The SwiftData schema containing the model types
    /// - Throws: If the container cannot be created
    public func configure(
        with configuration: LocalPersistenceConfiguration,
        schema: Schema
    ) throws {
        self.configuration = configuration

        let modelConfiguration: ModelConfiguration

        switch configuration.storageType {
        case .inMemory:
            modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
        case .persistent(let url):
            // Ensure directory exists
            try FileManager.default.createDirectory(
                at: url,
                withIntermediateDirectories: true,
                attributes: nil
            )
            modelConfiguration = ModelConfiguration(
                schema: schema,
                url: url.appendingPathComponent("LocalPersistence.store"),
                allowsSave: true
            )
        }

        let container = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
        self.container = container
        self.context = ModelContext(container)
    }

    /// Performs database operations within the actor's isolation
    ///
    /// Use this method to execute operations that require a ModelContext.
    /// The context is created, passed to your closure, and the result is returned.
    ///
    /// - Parameter operation: A closure that receives the ModelContext and returns a Sendable result
    /// - Returns: The result of the operation
    /// - Throws: `PersistenceError.notConfigured` if not configured, or any error from the operation
    ///
    /// ## Example
    ///
    /// ```swift
    /// let count = try await provider.perform { context in
    ///     let items = try context.fetch(FetchDescriptor<Item>())
    ///     return items.count
    /// }
    /// ```
    public func perform<T: Sendable>(
        _ operation: (ModelContext) throws -> T
    ) throws -> T {
        guard let container = container else {
            throw PersistenceError.notConfigured
        }
        if context == nil {
            context = ModelContext(container)
        }
        guard let context = context else {
            throw PersistenceError.notConfigured
        }
        return try operation(context)
    }

    /// Performs database operations that don't return a value
    ///
    /// Convenience method for operations that only perform side effects.
    ///
    /// - Parameter operation: A closure that receives the ModelContext
    /// - Throws: `PersistenceError.notConfigured` if not configured, or any error from the operation
    public func perform(_ operation: (ModelContext) throws -> Void) throws {
        guard let container = container else {
            throw PersistenceError.notConfigured
        }
        if context == nil {
            context = ModelContext(container)
        }
        guard let context = context else {
            throw PersistenceError.notConfigured
        }
        try operation(context)
    }

    /// Resets the container, removing all data
    ///
    /// Useful for testing or when user requests data deletion.
    /// After calling this, `configure(with:schema:)` must be called again.
    public func reset() {
        self.container = nil
        self.context = nil
    }
}

/// Errors that can occur during persistence operations
public enum PersistenceError: Error, Sendable {
    /// The container has not been configured. Call `configure(with:schema:)` first.
    case notConfigured

    /// Failed to create the storage directory
    case directoryCreationFailed(URL)

    /// Failed to save changes to the context
    case saveFailed(Error)
}
