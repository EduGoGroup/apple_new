import Foundation

/// Storage - Local persistence module
///
/// Provides local storage capabilities including UserDefaults, file system, and caching.
/// TIER-2 Infrastructure module.
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
