import Foundation

/// Protocol for persisting state machine states for crash recovery.
///
/// StatePersistence provides an abstraction for saving and loading state
/// machine states, enabling recovery after app crashes or restarts.
///
/// # Thread Safety
/// Implementations must be thread-safe and work correctly when called
/// from actor-isolated contexts.
///
/// # Example
/// ```swift
/// let persistence = UserDefaultsStatePersistence()
/// try await persistence.save(state, forKey: "assessment_123")
/// let recovered: AssessmentState? = try await persistence.load(forKey: "assessment_123")
/// ```
public protocol StatePersistence: Sendable {
    /// Saves a state for later recovery.
    ///
    /// - Parameters:
    ///   - state: The state to persist.
    ///   - key: A unique key identifying this state (e.g., assessment ID).
    func save<State: Codable & Sendable>(_ state: State, forKey key: String) async throws

    /// Loads a previously saved state.
    ///
    /// - Parameter key: The key used when saving the state.
    /// - Returns: The recovered state, or nil if none exists.
    func load<State: Codable & Sendable>(forKey key: String) async throws -> State?

    /// Removes a saved state.
    ///
    /// - Parameter key: The key of the state to remove.
    func remove(forKey key: String) async

    /// Checks if a state exists for the given key.
    ///
    /// - Parameter key: The key to check.
    /// - Returns: true if a state exists, false otherwise.
    func exists(forKey key: String) async -> Bool
}

// MARK: - UserDefaults Implementation

/// A StatePersistence implementation using UserDefaults.
///
/// UserDefaultsStatePersistence provides simple, reliable state persistence
/// using the system's UserDefaults. Suitable for small state objects.
///
/// # Thread Safety
/// This implementation is Sendable and thread-safe. UserDefaults.standard
/// is internally thread-safe for read/write operations.
///
/// # Example
/// ```swift
/// let persistence = UserDefaultsStatePersistence()
/// try await persistence.save(AssessmentState.inProgress(answeredCount: 5, totalQuestions: 10), forKey: "assessment_123")
/// ```
public struct UserDefaultsStatePersistence: StatePersistence, Sendable {
    /// The suite name for UserDefaults (nil uses standard).
    private let suiteName: String?

    /// Prefix for all keys to avoid conflicts.
    private let keyPrefix: String

    /// Accesses the UserDefaults instance.
    private var defaults: UserDefaults {
        if let suiteName {
            return UserDefaults(suiteName: suiteName) ?? .standard
        }
        return .standard
    }

    /// Creates a new UserDefaultsStatePersistence.
    ///
    /// - Parameters:
    ///   - suiteName: The suite name for UserDefaults. Nil uses standard.
    ///   - keyPrefix: Prefix for all keys. Defaults to "StateManagement.".
    public init(
        suiteName: String? = nil,
        keyPrefix: String = "StateManagement."
    ) {
        self.suiteName = suiteName
        self.keyPrefix = keyPrefix
    }

    public func save<State: Codable & Sendable>(_ state: State, forKey key: String) async throws {
        let prefixedKey = keyPrefix + key
        let data = try JSONEncoder().encode(state)
        defaults.set(data, forKey: prefixedKey)
    }

    public func load<State: Codable & Sendable>(forKey key: String) async throws -> State? {
        let prefixedKey = keyPrefix + key

        guard let data = defaults.data(forKey: prefixedKey) else {
            return nil
        }

        return try JSONDecoder().decode(State.self, from: data)
    }

    public func remove(forKey key: String) async {
        let prefixedKey = keyPrefix + key
        defaults.removeObject(forKey: prefixedKey)
    }

    public func exists(forKey key: String) async -> Bool {
        let prefixedKey = keyPrefix + key
        return defaults.object(forKey: prefixedKey) != nil
    }
}

// MARK: - In-Memory Implementation (for testing)

/// An in-memory StatePersistence implementation for testing.
///
/// InMemoryStatePersistence stores states in memory only, useful for
/// unit tests where persistence across app launches is not needed.
public actor InMemoryStatePersistence: StatePersistence {
    private var storage: [String: Data] = [:]

    public init() {}

    public func save<State: Codable & Sendable>(_ state: State, forKey key: String) async throws {
        let data = try JSONEncoder().encode(state)
        storage[key] = data
    }

    public func load<State: Codable & Sendable>(forKey key: String) async throws -> State? {
        guard let data = storage[key] else {
            return nil
        }
        return try JSONDecoder().decode(State.self, from: data)
    }

    public func remove(forKey key: String) async {
        storage.removeValue(forKey: key)
    }

    public func exists(forKey key: String) async -> Bool {
        storage[key] != nil
    }

    /// Clears all stored states (useful for test cleanup).
    public func clear() {
        storage.removeAll()
    }
}

// MARK: - No-Op Implementation

/// A no-op StatePersistence that does nothing.
///
/// Useful when persistence is not needed or should be disabled.
public struct NoOpStatePersistence: StatePersistence {
    public init() {}

    public func save<State: Codable & Sendable>(_ state: State, forKey key: String) async throws {
        // No-op
    }

    public func load<State: Codable & Sendable>(forKey key: String) async throws -> State? {
        nil
    }

    public func remove(forKey key: String) async {
        // No-op
    }

    public func exists(forKey key: String) async -> Bool {
        false
    }
}
