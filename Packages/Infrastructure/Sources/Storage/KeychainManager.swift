import Foundation
import Security

// MARK: - KeychainError

/// Typed errors for Keychain operations.
public enum KeychainError: Error, Sendable, Equatable {
    /// The item was not found in the Keychain.
    case itemNotFound
    /// Encoding the item to Data failed.
    case encodingFailed(String)
    /// Decoding the stored Data back to the expected type failed.
    case decodingFailed(String)
    /// A Security framework operation returned an unexpected status.
    case unhandledError(status: OSStatus)
    /// Duplicate item already exists (should not happen with upsert logic, but kept for safety).
    case duplicateItem
}

// MARK: - KeychainAccessibility

/// Maps to `kSecAttrAccessible` values, controlling when the Keychain item is accessible.
public enum KeychainAccessibility: Sendable {
    /// Item is accessible only while the device is unlocked, and is not included in backups.
    /// Recommended default for auth tokens.
    case whenUnlockedThisDeviceOnly
    /// Item is accessible after the first unlock until the next restart, not included in backups.
    case afterFirstUnlockThisDeviceOnly
    /// Item is accessible while the device is unlocked. Included in backups.
    case whenUnlocked

    var secAttrValue: CFString {
        switch self {
        case .whenUnlockedThisDeviceOnly:
            return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case .afterFirstUnlockThisDeviceOnly:
            return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        case .whenUnlocked:
            return kSecAttrAccessibleWhenUnlocked
        }
    }
}

// MARK: - KeychainManager

/// Thread-safe actor wrapping the Security framework Keychain Services.
///
/// Provides typed CRUD operations for `Codable` items stored securely in the
/// iOS/macOS Keychain using `kSecClassGenericPassword`.
///
/// ## Usage
/// ```swift
/// let keychain = KeychainManager()
/// try await keychain.save(myToken, for: "auth_token")
/// let token: AuthToken? = try await keychain.retrieve(AuthToken.self, for: "auth_token")
/// ```
public actor KeychainManager {

    /// Bundle identifier used as the Keychain service name.
    private let service: String

    /// JSON encoder used for serializing items.
    private let encoder: JSONEncoder

    /// JSON decoder used for deserializing items.
    private let decoder: JSONDecoder

    /// Creates a KeychainManager.
    ///
    /// - Parameter service: Service identifier for Keychain entries.
    ///   Defaults to `"com.edugo.app"`.
    public init(service: String = "com.edugo.app") {
        self.service = service

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    // MARK: - Public API

    /// Saves a `Codable` item to the Keychain. Overwrites if the key already exists.
    ///
    /// - Parameters:
    ///   - item: The item to store.
    ///   - key: Unique key identifying the item.
    ///   - accessibility: When the item should be accessible. Defaults to `.whenUnlockedThisDeviceOnly`.
    public func save<T: Codable>(
        _ item: T,
        for key: String,
        accessibility: KeychainAccessibility = .whenUnlockedThisDeviceOnly
    ) throws {
        let data: Data
        do {
            data = try encoder.encode(item)
        } catch {
            throw KeychainError.encodingFailed(error.localizedDescription)
        }

        // Build query for existing item check
        let query = baseQuery(for: key)

        // Try to update first
        let updateAttributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: accessibility.secAttrValue
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, updateAttributes as CFDictionary)

        if updateStatus == errSecSuccess {
            return
        }

        if updateStatus == errSecItemNotFound {
            // Item does not exist yet — add it
            var addQuery = query
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] = accessibility.secAttrValue

            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)

            guard addStatus == errSecSuccess else {
                throw KeychainError.unhandledError(status: addStatus)
            }
            return
        }

        throw KeychainError.unhandledError(status: updateStatus)
    }

    /// Retrieves a `Codable` item from the Keychain.
    ///
    /// - Parameters:
    ///   - type: The expected type to decode.
    ///   - key: The key the item was stored under.
    /// - Returns: The decoded item, or `nil` if no item exists for the key.
    public func retrieve<T: Codable>(_ type: T.Type, for key: String) throws -> T? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }

        guard let data = result as? Data else {
            return nil
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw KeychainError.decodingFailed(error.localizedDescription)
        }
    }

    /// Deletes an item from the Keychain. Does not throw if the item does not exist.
    ///
    /// - Parameter key: The key identifying the item to delete.
    public func delete(for key: String) throws {
        let query = baseQuery(for: key)
        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    /// Checks whether an item exists in the Keychain for the given key.
    ///
    /// - Parameter key: The key to check.
    /// - Returns: `true` if an item exists.
    public func exists(for key: String) throws -> Bool {
        var query = baseQuery(for: key)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = false

        let status = SecItemCopyMatching(query as CFDictionary, nil)

        if status == errSecSuccess {
            return true
        }
        if status == errSecItemNotFound {
            return false
        }
        throw KeychainError.unhandledError(status: status)
    }

    /// Deletes all items stored by this manager (matching the service).
    public func deleteAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    // MARK: - Private

    private func baseQuery(for key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
    }
}
