import Foundation
import SwiftData
import EduCore
import EduFoundation
import EduCore

/// Local repository for User entities using SwiftData
///
/// This actor implements `UserRepositoryProtocol` and provides thread-safe
/// CRUD operations for User entities persisted in SwiftData.
///
/// ## Thread Safety
///
/// As an actor, all operations are automatically serialized, ensuring
/// thread-safe access to the underlying SwiftData context.
///
/// ## Batch Operations
///
/// This repository integrates `TaskGroupCoordinator` for efficient batch
/// operations with configurable concurrency limits and error aggregation.
///
/// ## Usage
///
/// ```swift
/// let repository = LocalUserRepository()
///
/// // Save a user
/// let user = try User(name: "John", email: "john@example.com")
/// try await repository.save(user)
///
/// // Batch save with partial error handling
/// let result = try await repository.saveUsers(usersToCreate)
/// if result.hasPartialSuccess {
///     print("Some users failed to save")
/// }
///
/// // Fetch a user
/// if let fetched = try await repository.get(id: user.id) {
///     print("Found: \(fetched.name)")
/// }
///
/// // List all users
/// let allUsers = try await repository.list()
///
/// // Delete a user
/// try await repository.delete(id: user.id)
/// ```
public actor LocalUserRepository: UserRepositoryProtocol {
    // MARK: - Constants

    /// Maximum number of concurrent batch operations.
    private static let maxConcurrency = 10

    /// Maximum number of items allowed in a single batch operation.
    private static let maxBatchSize = 100

    /// Default timeout for batch operations (30 seconds).
    private static let defaultBatchTimeout: Duration = .seconds(30)

    // MARK: - Properties

    private let containerProvider: PersistenceContainerProvider
    private var cachedUsers: [User]?

    /// Coordinator for batch operations with Void result type.
    private let voidCoordinator: TaskGroupCoordinator<Void>

    /// Coordinator for batch operations returning User.
    private let userCoordinator: TaskGroupCoordinator<User?>

    /// Handler for timeout and cancellation management.
    private let cancellationHandler: CancellationHandler

    // MARK: - Initialization

    /// Creates a new LocalUserRepository
    ///
    /// - Parameter containerProvider: The persistence container provider (defaults to shared)
    public init(containerProvider: PersistenceContainerProvider = .shared) {
        self.containerProvider = containerProvider
        self.voidCoordinator = TaskGroupCoordinator<Void>()
        self.userCoordinator = TaskGroupCoordinator<User?>()
        self.cancellationHandler = CancellationHandler(
            configuration: .init(
                defaultTimeout: Self.defaultBatchTimeout,
                defaultBatchTimeout: Self.defaultBatchTimeout
            )
        )
    }

    // MARK: - Single-Item Operations

    /// Retrieves a user by ID
    ///
    /// - Parameter id: The user's unique identifier
    /// - Returns: The user if found, nil otherwise
    /// - Throws: `RepositoryError.fetchFailed` if the query fails
    public func get(id: UUID) async throws -> User? {
        if let cachedUsers = cachedUsers {
            return cachedUsers.first { $0.id == id }
        }

        do {
            return try await containerProvider.perform { context in
                let predicate = #Predicate<UserModel> { model in
                    model.id == id
                }
                var descriptor = FetchDescriptor(predicate: predicate)
                descriptor.fetchLimit = 1

                let results = try context.fetch(descriptor)

                guard let model = results.first else {
                    return nil
                }

                return try UserPersistenceMapper.toDomain(model)
            }
        } catch let error as RepositoryError {
            throw error
        } catch let error as DomainError {
            throw RepositoryError.fetchFailed(reason: "Failed to map user: \(error.localizedDescription)")
        } catch {
            throw RepositoryError.fetchFailed(reason: error.localizedDescription)
        }
    }

    /// Saves a user (insert or update)
    ///
    /// If a user with the same ID exists, it will be updated.
    /// Otherwise, a new user will be created.
    ///
    /// - Parameter user: The user to save
    /// - Throws: `RepositoryError.saveFailed` if the save operation fails
    public func save(_ user: User) async throws {
        do {
            try await containerProvider.perform { context in
                // Check if user already exists (upsert)
                let predicate = #Predicate<UserModel> { model in
                    model.id == user.id
                }
                var descriptor = FetchDescriptor(predicate: predicate)
                descriptor.fetchLimit = 1

                let existing = try context.fetch(descriptor).first

                // Convert domain to model (updates existing or creates new)
                let model = UserPersistenceMapper.toModel(user, existing: existing)

                // Insert only if new
                if existing == nil {
                    context.insert(model)
                }

                try context.save()
            }

            if cachedUsers != nil {
                if let index = cachedUsers?.firstIndex(where: { $0.id == user.id }) {
                    cachedUsers?[index] = user
                } else {
                    cachedUsers?.append(user)
                }
            }
        } catch let error as RepositoryError {
            throw error
        } catch {
            throw RepositoryError.saveFailed(reason: error.localizedDescription)
        }
    }

    /// Deletes a user by ID
    ///
    /// - Parameter id: The user's unique identifier
    /// - Throws: `RepositoryError.deleteFailed` if the user doesn't exist or deletion fails
    public func delete(id: UUID) async throws {
        do {
            try await containerProvider.perform { context in
                let predicate = #Predicate<UserModel> { model in
                    model.id == id
                }
                var descriptor = FetchDescriptor(predicate: predicate)
                descriptor.fetchLimit = 1

                guard let model = try context.fetch(descriptor).first else {
                    throw RepositoryError.deleteFailed(reason: "User with id \(id) not found")
                }

                context.delete(model)
                try context.save()
            }

            if cachedUsers != nil {
                cachedUsers?.removeAll { $0.id == id }
            }
        } catch let error as RepositoryError {
            throw error
        } catch {
            throw RepositoryError.deleteFailed(reason: error.localizedDescription)
        }
    }

    /// Lists all users
    ///
    /// - Returns: An array of all users
    /// - Throws: `RepositoryError.fetchFailed` if the query fails
    public func list() async throws -> [User] {
        do {
            let users = try await containerProvider.perform { context in
                let descriptor = FetchDescriptor<UserModel>()
                let models = try context.fetch(descriptor)

                return try models.map { model in
                    try UserPersistenceMapper.toDomain(model)
                }
            }

            cachedUsers = users
            return users
        } catch let error as RepositoryError {
            throw error
        } catch let error as DomainError {
            throw RepositoryError.fetchFailed(reason: "Failed to map users: \(error.localizedDescription)")
        } catch {
            throw RepositoryError.fetchFailed(reason: error.localizedDescription)
        }
    }

    // MARK: - Batch Operations

    /// Saves multiple users concurrently using TaskGroupCoordinator.
    ///
    /// Operations are executed in parallel with a maximum concurrency of 10
    /// to prevent resource exhaustion. Partial errors do not stop the entire
    /// batch operation. Includes configurable timeout support.
    ///
    /// - Parameters:
    ///   - users: Array of users to save.
    ///   - timeout: Optional timeout for the batch operation (default: 30s).
    /// - Returns: Result with successes and failures for each operation.
    /// - Throws: `RepositoryError.saveFailed` if input validation fails,
    ///           `CancellationReason.timeout` if timeout is exceeded.
    ///
    /// ## Rate Limiting
    ///
    /// Uses `maxConcurrency` of 10 concurrent operations to balance
    /// throughput and resource usage.
    ///
    /// ## Timeout Behavior
    ///
    /// If the timeout is exceeded, the operation returns with partial results.
    /// Successfully saved users are included in `successes`, while timed-out
    /// operations appear in `failures` with a timeout error.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let users = [user1, user2, user3]
    /// let result = try await repository.saveUsers(users)
    ///
    /// print("Saved: \(result.successes.count)")
    /// print("Failed: \(result.failures.count)")
    ///
    /// if result.hasPartialSuccess {
    ///     // Handle partial failures
    ///     for (index, error) in result.failures {
    ///         print("User at index \(index) failed: \(error)")
    ///     }
    /// }
    ///
    /// // With custom timeout
    /// let result = try await repository.saveUsers(users, timeout: .seconds(60))
    /// ```
    public func saveUsers(
        _ users: [User],
        timeout: Duration? = nil
    ) async throws -> BatchOperationResult<User> {
        // Input validation
        guard !users.isEmpty else {
            throw RepositoryError.saveFailed(reason: "Cannot save empty user list")
        }

        guard users.count <= Self.maxBatchSize else {
            throw RepositoryError.saveFailed(
                reason: "Batch size \(users.count) exceeds maximum of \(Self.maxBatchSize)"
            )
        }

        // Check cancellation before starting
        try await cancellationHandler.checkCancellation()

        await logBatchStart(operation: "saveUsers", count: users.count)

        // Create operations for each user
        let operations: [@Sendable () async throws -> Void] = users.map { user in
            { [weak self] in
                guard let self else { throw RepositoryError.saveFailed(reason: "Repository deallocated") }
                // Check cancellation before each operation
                if Task.isCancelled {
                    throw CancellationReason.parentTaskCancelled
                }
                try await self.save(user)
            }
        }

        // Execute batch with rate limiting and timeout
        let effectiveTimeout = timeout ?? Self.defaultBatchTimeout
        let batchResult = await withCancellableTaskGroup(
            timeout: effectiveTimeout,
            maxConcurrency: Self.maxConcurrency,
            onCancellation: { [weak self] partialSuccesses in
                // Log partial completion on cancellation
                await self?.logBatchCancellation(
                    operation: "saveUsers",
                    completed: partialSuccesses.count,
                    total: users.count
                )
            },
            operations: operations
        )

        // Convert to BatchOperationResult
        let successes: [(index: Int, value: User)] = batchResult.successes.map { item in
            (item.index, users[item.index])
        }

        let failures: [(index: Int, error: String)] = batchResult.failures.map { item in
            (item.index, item.error.description)
        }

        // Update cache if needed
        if cachedUsers != nil {
            for (_, user) in successes {
                if let existingIndex = cachedUsers?.firstIndex(where: { $0.id == user.id }) {
                    cachedUsers?[existingIndex] = user
                } else {
                    cachedUsers?.append(user)
                }
            }
        }

        let result = BatchOperationResult(successes: successes, failures: failures)
        await logBatchComplete(operation: "saveUsers", result: result)

        return result
    }

    /// Deletes multiple users concurrently using TaskGroupCoordinator.
    ///
    /// Operations are executed in parallel with rate limiting and timeout.
    /// Partial errors do not stop the entire batch operation.
    ///
    /// - Parameters:
    ///   - ids: Array of UUIDs of users to delete.
    ///   - timeout: Optional timeout for the batch operation (default: 30s).
    /// - Returns: Result with successfully deleted IDs and failures.
    /// - Throws: `RepositoryError.deleteFailed` if input validation fails.
    public func deleteUsers(
        ids: [UUID],
        timeout: Duration? = nil
    ) async throws -> BatchOperationResult<UUID> {
        // Input validation
        guard !ids.isEmpty else {
            throw RepositoryError.deleteFailed(reason: "Cannot delete empty ID list")
        }

        guard ids.count <= Self.maxBatchSize else {
            throw RepositoryError.deleteFailed(
                reason: "Batch size \(ids.count) exceeds maximum of \(Self.maxBatchSize)"
            )
        }

        // Check cancellation before starting
        try await cancellationHandler.checkCancellation()

        await logBatchStart(operation: "deleteUsers", count: ids.count)

        // Create operations for each ID
        let operations: [@Sendable () async throws -> Void] = ids.map { id in
            { [weak self] in
                guard let self else { throw RepositoryError.deleteFailed(reason: "Repository deallocated") }
                // Check cancellation before each operation
                if Task.isCancelled {
                    throw CancellationReason.parentTaskCancelled
                }
                try await self.delete(id: id)
            }
        }

        // Execute batch with rate limiting and timeout
        let effectiveTimeout = timeout ?? Self.defaultBatchTimeout
        let batchResult = await withCancellableTaskGroup(
            timeout: effectiveTimeout,
            maxConcurrency: Self.maxConcurrency,
            onCancellation: { [weak self] partialSuccesses in
                await self?.logBatchCancellation(
                    operation: "deleteUsers",
                    completed: partialSuccesses.count,
                    total: ids.count
                )
            },
            operations: operations
        )

        // Convert to BatchOperationResult
        let successes: [(index: Int, value: UUID)] = batchResult.successes.map { item in
            (item.index, ids[item.index])
        }

        let failures: [(index: Int, error: String)] = batchResult.failures.map { item in
            (item.index, item.error.description)
        }

        // Update cache if needed
        if cachedUsers != nil {
            let deletedIDs = Set(successes.map { $0.value })
            cachedUsers?.removeAll { deletedIDs.contains($0.id) }
        }

        let result = BatchOperationResult(successes: successes, failures: failures)
        await logBatchComplete(operation: "deleteUsers", result: result)

        return result
    }

    /// Gets multiple users concurrently using TaskGroupCoordinator.
    ///
    /// Operations are executed in parallel with rate limiting and timeout.
    /// Users not found are reported as failures.
    ///
    /// - Parameters:
    ///   - ids: Array of UUIDs of users to fetch.
    ///   - timeout: Optional timeout for the batch operation (default: 30s).
    /// - Returns: Result with found users and failures.
    /// - Throws: `RepositoryError.fetchFailed` if input validation fails.
    public func getUsers(
        ids: [UUID],
        timeout: Duration? = nil
    ) async throws -> BatchOperationResult<User> {
        // Input validation
        guard !ids.isEmpty else {
            throw RepositoryError.fetchFailed(reason: "Cannot fetch empty ID list")
        }

        guard ids.count <= Self.maxBatchSize else {
            throw RepositoryError.fetchFailed(
                reason: "Batch size \(ids.count) exceeds maximum of \(Self.maxBatchSize)"
            )
        }

        // Check cancellation before starting
        try await cancellationHandler.checkCancellation()

        await logBatchStart(operation: "getUsers", count: ids.count)

        // Create operations for each ID
        let operations: [@Sendable () async throws -> User?] = ids.map { id in
            { [weak self] in
                guard let self else { throw RepositoryError.fetchFailed(reason: "Repository deallocated") }
                // Check cancellation before each operation
                if Task.isCancelled {
                    throw CancellationReason.parentTaskCancelled
                }
                return try await self.get(id: id)
            }
        }

        // Execute batch with rate limiting and timeout
        let effectiveTimeout = timeout ?? Self.defaultBatchTimeout
        let batchResult = await withCancellableTaskGroup(
            timeout: effectiveTimeout,
            maxConcurrency: Self.maxConcurrency,
            onCancellation: { [weak self] partialSuccesses in
                await self?.logBatchCancellation(
                    operation: "getUsers",
                    completed: partialSuccesses.count,
                    total: ids.count
                )
            },
            operations: operations
        )

        // Convert to BatchOperationResult, treating nil as "not found"
        var successes: [(index: Int, value: User)] = []
        var failures: [(index: Int, error: String)] = batchResult.failures.map { item in
            (item.index, item.error.description)
        }

        for item in batchResult.successes {
            if let user = item.value {
                successes.append((item.index, user))
            } else {
                failures.append((item.index, "User not found with id: \(ids[item.index])"))
            }
        }

        let result = BatchOperationResult(successes: successes, failures: failures)
        await logBatchComplete(operation: "getUsers", result: result)

        return result
    }

    // MARK: - Private Logging Helpers

    private func logBatchStart(operation: String, count: Int) async {
        await Logger.shared.info(
            "[LocalUserRepository] Batch \(operation) started - Items: \(count), Max concurrency: \(Self.maxConcurrency)"
        )
    }

    private func logBatchComplete<T>(operation: String, result: BatchOperationResult<T>) async {
        let message = "[LocalUserRepository] Batch \(operation) completed - Total: \(result.totalCount), Successes: \(result.successes.count), Failures: \(result.failures.count), Success rate: \(String(format: "%.1f%%", result.successRate * 100))"

        if result.allSucceeded {
            await Logger.shared.info(message)
        } else if result.allFailed {
            await Logger.shared.error(message)
        } else {
            await Logger.shared.info(message)
        }

        // Log individual failures at debug level
        if !result.failures.isEmpty {
            for (index, error) in result.failures {
                await Logger.shared.debug("[LocalUserRepository] \(operation) failed at index \(index): \(error)")
            }
        }
    }

    private func logBatchCancellation(operation: String, completed: Int, total: Int) async {
        await Logger.shared.info(
            "[LocalUserRepository] Batch \(operation) cancelled/timed out - Completed: \(completed)/\(total)"
        )
    }
}
