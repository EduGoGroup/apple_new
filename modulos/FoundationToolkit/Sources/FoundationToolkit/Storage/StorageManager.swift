import Foundation

/// StorageManager - Local persistence using UserDefaults
///
/// Provides local storage capabilities with thread-safe actor-based access.
/// Uses JSONEncoder/JSONDecoder for complex types.
///
/// ## Usage
/// ```swift
/// let storage = StorageManager.shared
///
/// // Save
/// try await storage.save(user, forKey: "current_user")
///
/// // Retrieve
/// let user: User? = try await storage.retrieve(User.self, forKey: "current_user")
///
/// // Remove
/// await storage.remove(forKey: "current_user")
/// ```
public actor StorageManager: Sendable {
    public static let shared = StorageManager()

    private let userDefaults: UserDefaults

    private init() {
        self.userDefaults = .standard
    }

    /// Save a value to storage
    public func save<T: Encodable>(_ value: T, forKey key: String) throws {
        let data = try JSONEncoder().encode(value)
        userDefaults.set(data, forKey: key)
    }

    /// Retrieve a value from storage
    public func retrieve<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    /// Remove a value from storage
    public func remove(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }
}
