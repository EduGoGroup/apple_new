/// LocalPersistence - SwiftData persistence module
///
/// Provides local persistence capabilities using SwiftData with thread-safe
/// actor-based container management. TIER-2 Infrastructure module.
///
/// ## Overview
///
/// LocalPersistence provides a thread-safe wrapper around SwiftData's
/// ModelContainer and ModelContext. It uses Swift actors to ensure
/// all database operations are properly isolated.
///
/// ## Quick Start
///
/// ```swift
/// import LocalPersistence
/// import SwiftData
///
/// // Define your models
/// @Model
/// final class Item {
///     var name: String
///     var timestamp: Date
///
///     init(name: String, timestamp: Date = .now) {
///         self.name = name
///         self.timestamp = timestamp
///     }
/// }
///
/// // Configure the persistence layer
/// let schema = Schema([Item.self])
/// try await PersistenceContainerProvider.shared.configure(
///     with: .production,
///     schema: schema
/// )
///
/// // Perform operations within the actor
/// try await PersistenceContainerProvider.shared.perform { context in
///     let newItem = Item(name: "Example")
///     context.insert(newItem)
///     try context.save()
/// }
/// ```
///
/// ## Testing
///
/// For unit tests, use the `.testing` configuration:
///
/// ```swift
/// try await PersistenceContainerProvider.shared.configure(
///     with: .testing,
///     schema: schema
/// )
/// ```

// MARK: - Public API Exports

@_exported import SwiftData

// MARK: - Module Components

// Configuration
public typealias PersistenceStorageType = StorageType
public typealias PersistenceConfiguration = LocalPersistenceConfiguration

// Container
public typealias PersistenceProvider = PersistenceContainerProvider

// Models - SwiftData @Model types for persistence
// (UserModel, DocumentModel are automatically public via @Model)

// Mappers - Convert between persistence models and domain entities
// (UserPersistenceMapper, DocumentPersistenceMapper are public structs)
