import Foundation

/// A state machine actor that manages parallel loading of dashboard resources.
///
/// DashboardStateMachine coordinates loading user, units, and materials data
/// in parallel, emitting progress states and handling partial data scenarios.
///
/// # Features
/// - Parallel loading of multiple resources
/// - Partial data display while loading continues
/// - Configurable timeout per resource
/// - Retry logic with exponential backoff
/// - Cache support for stale-while-revalidate pattern
///
/// # Thread Safety
/// All operations are actor-isolated, ensuring thread-safe state management.
///
/// # Example
/// ```swift
/// let machine = DashboardStateMachine(
///     configuration: .init(timeout: 10, allowPartialData: true)
/// )
///
/// // Subscribe to states
/// Task {
///     for await state in await machine.stateStream {
///         updateUI(with: state)
///     }
/// }
///
/// // Load dashboard
/// await machine.loadDashboard(
///     userId: "user_123",
///     userFetcher: fetchUser,
///     unitsFetcher: fetchUnits,
///     materialsFetcher: fetchMaterials
/// )
/// ```
public actor DashboardStateMachine {
    /// The current state of the dashboard loading process.
    public private(set) var currentState: DashboardState = .idle

    /// Configuration for the state machine.
    public let configuration: Configuration

    /// Indicates whether the machine has been terminated.
    private var isTerminated: Bool = false

    /// The underlying continuation for emitting values to the stream.
    private var continuation: AsyncStream<DashboardState>.Continuation?

    /// The stream that subscribers can iterate over.
    private var _stream: AsyncStream<DashboardState>?

    /// Cached data for stale-while-revalidate pattern.
    private var cachedData: DashboardData?

    /// Current loading task (for cancellation).
    private var loadingTask: Task<Void, Never>?

    /// Creates a new DashboardStateMachine.
    ///
    /// - Parameter configuration: Configuration options.
    public init(configuration: Configuration = .default) {
        self.configuration = configuration
    }

    // MARK: - Configuration

    /// Configuration options for the dashboard state machine.
    public struct Configuration: Sendable {
        /// Timeout in seconds for each resource fetch.
        public let timeout: TimeInterval

        /// Whether to allow displaying partial data while loading.
        public let allowPartialData: Bool

        /// Maximum number of retry attempts.
        public let maxRetries: Int

        /// Base delay for exponential backoff (in seconds).
        public let retryBaseDelay: TimeInterval

        /// Default configuration.
        public static let `default` = Configuration(
            timeout: 10,
            allowPartialData: true,
            maxRetries: 3,
            retryBaseDelay: 1.0
        )

        /// Creates a configuration.
        public init(
            timeout: TimeInterval = 10,
            allowPartialData: Bool = true,
            maxRetries: Int = 3,
            retryBaseDelay: TimeInterval = 1.0
        ) {
            self.timeout = timeout
            self.allowPartialData = allowPartialData
            self.maxRetries = maxRetries
            self.retryBaseDelay = retryBaseDelay
        }
    }

    // MARK: - State Stream

    /// The stream of state updates for subscribers.
    public var stateStream: StateStream<DashboardState> {
        if _stream == nil {
            let (stream, cont) = AsyncStream<DashboardState>.makeStream(
                bufferingPolicy: .unbounded
            )
            self._stream = stream
            self.continuation = cont
        }
        return StateStream(sequence: _stream!)
    }

    // MARK: - Loading

    /// Fetcher type for loading a resource.
    public typealias Fetcher<T> = @Sendable () async throws -> T

    /// Loads the dashboard by fetching all resources in parallel.
    ///
    /// - Parameters:
    ///   - userId: The user ID to load dashboard for.
    ///   - userFetcher: Closure to fetch user data.
    ///   - unitsFetcher: Closure to fetch units data.
    ///   - materialsFetcher: Closure to fetch materials data.
    ///   - cachedData: Optional cached data to show immediately.
    public func loadDashboard(
        userId: String,
        userFetcher: @escaping Fetcher<UserData>,
        unitsFetcher: @escaping Fetcher<[UnitData]>,
        materialsFetcher: @escaping Fetcher<[MaterialData]>,
        cachedData: DashboardData? = nil
    ) async {
        // Cancel any existing loading task
        loadingTask?.cancel()

        // If we have cached data, emit it immediately
        if let cached = cachedData {
            self.cachedData = cached
            await transitionTo(.ready(data: cached))
        }

        // Start loading
        await transitionTo(.loading(progress: LoadingProgress()))

        // Create loading task
        loadingTask = Task { [weak self] in
            guard let self = self else { return }

            await self.performParallelLoad(
                userFetcher: userFetcher,
                unitsFetcher: unitsFetcher,
                materialsFetcher: materialsFetcher
            )
        }

        await loadingTask?.value
    }

    /// Performs the parallel loading of all resources.
    private func performParallelLoad(
        userFetcher: @escaping Fetcher<UserData>,
        unitsFetcher: @escaping Fetcher<[UnitData]>,
        materialsFetcher: @escaping Fetcher<[MaterialData]>
    ) async {
        var partialData = PartialDashboardData()
        var errors: [String] = []

        // Load all resources in parallel
        await withTaskGroup(of: ResourceResult.self) { group in
            group.addTask { [configuration] in
                await self.fetchWithRetry(
                    resource: .user,
                    timeout: configuration.timeout,
                    maxRetries: configuration.maxRetries,
                    baseDelay: configuration.retryBaseDelay,
                    fetcher: userFetcher
                )
            }

            group.addTask { [configuration] in
                await self.fetchWithRetry(
                    resource: .units,
                    timeout: configuration.timeout,
                    maxRetries: configuration.maxRetries,
                    baseDelay: configuration.retryBaseDelay,
                    fetcher: unitsFetcher
                )
            }

            group.addTask { [configuration] in
                await self.fetchWithRetry(
                    resource: .materials,
                    timeout: configuration.timeout,
                    maxRetries: configuration.maxRetries,
                    baseDelay: configuration.retryBaseDelay,
                    fetcher: materialsFetcher
                )
            }

            for await result in group {
                guard !Task.isCancelled else { return }

                switch result {
                case .user(let userData):
                    partialData.user = userData
                    await updateLoadingProgress(partialData: partialData)

                case .units(let unitsData):
                    partialData.units = unitsData
                    await updateLoadingProgress(partialData: partialData)

                case .materials(let materialsData):
                    partialData.materials = materialsData
                    await updateLoadingProgress(partialData: partialData)

                case .error(let resource, let reason):
                    errors.append("\(resource): \(reason)")
                }
            }
        }

        // Handle completion
        await handleLoadingComplete(partialData: partialData, errors: errors)
    }

    /// Updates loading progress and optionally emits partial data.
    private func updateLoadingProgress(partialData: PartialDashboardData) async {
        let progress = partialData.loadingProgress

        if progress.isComplete {
            await transitionTo(.aggregating)
        } else if configuration.allowPartialData && partialData.hasAnyData {
            await transitionTo(.partiallyLoaded(data: partialData))
        } else {
            await transitionTo(.loading(progress: progress))
        }
    }

    /// Handles the completion of all loading tasks.
    private func handleLoadingComplete(
        partialData: PartialDashboardData,
        errors: [String]
    ) async {
        guard !Task.isCancelled else {
            await transitionTo(.error(.cancelled))
            return
        }

        // Check if we have complete data
        if let dashboardData = DashboardData(from: partialData) {
            await transitionTo(.ready(data: dashboardData))
            return
        }

        // Handle errors
        if !errors.isEmpty {
            if errors.count == 1 {
                await transitionTo(.error(.unknown(reason: errors[0])))
            } else {
                await transitionTo(.error(.multipleFailures(errors: errors)))
            }
            return
        }

        // Partial data available
        if configuration.allowPartialData && partialData.hasAnyData {
            await transitionTo(.partiallyLoaded(data: partialData))
        } else {
            await transitionTo(.error(.unknown(reason: "Failed to load dashboard data")))
        }
    }

    /// Fetches a resource with retry logic and timeout.
    private func fetchWithRetry<T: Sendable>(
        resource: ResourceType,
        timeout: TimeInterval,
        maxRetries: Int,
        baseDelay: TimeInterval,
        fetcher: @escaping @Sendable () async throws -> T
    ) async -> ResourceResult {
        var lastError: Error?

        for attempt in 0..<maxRetries {
            guard !Task.isCancelled else {
                return .error(resource, "Cancelled")
            }

            do {
                let result = try await withTimeout(seconds: timeout) {
                    try await fetcher()
                }

                switch resource {
                case .user:
                    if let userData = result as? UserData {
                        return .user(userData)
                    }
                case .units:
                    if let unitsData = result as? [UnitData] {
                        return .units(unitsData)
                    }
                case .materials:
                    if let materialsData = result as? [MaterialData] {
                        return .materials(materialsData)
                    }
                }

                return .error(resource, "Invalid result type")
            } catch {
                lastError = error

                // Don't retry on cancellation
                if Task.isCancelled {
                    return .error(resource, "Cancelled")
                }

                // Exponential backoff before retry
                if attempt < maxRetries - 1 {
                    let delay = baseDelay * pow(2.0, Double(attempt))
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }

        return .error(resource, lastError?.localizedDescription ?? "Unknown error")
    }

    /// Executes a closure with a timeout.
    private func withTimeout<T: Sendable>(
        seconds: TimeInterval,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw DashboardError.timeout
            }

            guard let result = try await group.next() else {
                throw DashboardError.timeout
            }

            group.cancelAll()
            return result
        }
    }

    // MARK: - State Management

    /// Cancels the current loading operation.
    public func cancel() async {
        loadingTask?.cancel()
        loadingTask = nil
        await transitionTo(.error(.cancelled))
    }

    /// Resets the state machine to idle.
    public func reset() async {
        loadingTask?.cancel()
        loadingTask = nil
        cachedData = nil
        await transitionTo(.idle)
    }

    /// Finishes the state machine.
    public func finish() {
        guard !isTerminated else { return }
        isTerminated = true
        loadingTask?.cancel()
        loadingTask = nil
        continuation?.finish()
        continuation = nil
    }

    // MARK: - Private Helpers

    /// Performs the actual state transition and emits.
    private func transitionTo(_ newState: DashboardState) async {
        currentState = newState
        emit(newState)
    }

    /// Emits a state to the stream.
    private func emit(_ state: DashboardState) {
        guard !isTerminated else { return }
        continuation?.yield(state)
    }
}

// MARK: - Supporting Types

extension DashboardStateMachine {
    /// Types of resources being loaded.
    enum ResourceType: String, Sendable {
        case user
        case units
        case materials
    }

    /// Result of loading a resource.
    enum ResourceResult: Sendable {
        case user(UserData)
        case units([UnitData])
        case materials([MaterialData])
        case error(ResourceType, String)
    }
}

// MARK: - Transition Error

/// Error thrown when an invalid dashboard state transition is attempted.
public struct DashboardTransitionError: Error, Equatable, Sendable {
    /// The source state of the attempted transition.
    public let from: DashboardState

    /// The target state of the attempted transition.
    public let to: DashboardState

    /// Creates a DashboardTransitionError.
    public init(from: DashboardState, to: DashboardState) {
        self.from = from
        self.to = to
    }
}

extension DashboardTransitionError: CustomStringConvertible {
    public var description: String {
        "Invalid dashboard transition from \(from) to \(to)"
    }
}
