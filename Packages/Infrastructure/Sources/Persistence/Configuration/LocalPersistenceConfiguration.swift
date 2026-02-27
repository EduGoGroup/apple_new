import Foundation

/// Storage type configuration for LocalPersistence
///
/// Defines where data should be stored - either in memory for testing
/// or persistent storage for production use.
public enum StorageType: Sendable {
    /// In-memory storage, data is lost when app terminates.
    /// Useful for unit tests and previews.
    case inMemory

    /// Persistent storage at the specified URL.
    /// Data persists across app launches.
    case persistent(URL)

    /// Returns the default persistent storage URL for the current platform.
    ///
    /// - iOS: Uses the Documents directory
    /// - macOS: Uses the Application Support directory
    ///
    /// - Returns: The platform-appropriate storage URL
    public static func defaultPersistentURL() -> URL {
        #if os(iOS)
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("LocalPersistence", isDirectory: true)
        #elseif os(macOS)
        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("LocalPersistence", isDirectory: true)
        #endif
    }
}

/// Configuration for the LocalPersistence module
///
/// Provides settings for initializing the persistence layer including
/// storage type, model schema, and migration options.
public struct LocalPersistenceConfiguration: Sendable {
    /// The storage type to use
    public let storageType: StorageType

    /// Whether to enable CloudKit sync (future feature)
    public let cloudKitEnabled: Bool

    /// Creates a new configuration
    ///
    /// - Parameters:
    ///   - storageType: The storage type to use (default: persistent with platform default URL)
    ///   - cloudKitEnabled: Whether to enable CloudKit sync (default: false)
    public init(
        storageType: StorageType = .persistent(StorageType.defaultPersistentURL()),
        cloudKitEnabled: Bool = false
    ) {
        self.storageType = storageType
        self.cloudKitEnabled = cloudKitEnabled
    }

    /// Configuration for unit testing with in-memory storage
    public static let testing = LocalPersistenceConfiguration(
        storageType: .inMemory,
        cloudKitEnabled: false
    )

    /// Default production configuration
    public static let production = LocalPersistenceConfiguration(
        storageType: .persistent(StorageType.defaultPersistentURL()),
        cloudKitEnabled: false
    )
}
