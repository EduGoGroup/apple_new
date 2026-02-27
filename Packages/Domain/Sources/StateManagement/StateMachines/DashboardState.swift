import Foundation

/// Represents the states of a student dashboard loading process.
///
/// DashboardState models the lifecycle of loading a dashboard that
/// aggregates data from multiple sources (user, units, materials).
///
/// # State Flow
/// ```
/// idle → loading → partiallyLoaded / ready / error
///          ↓
///    aggregating → ready(DashboardData)
///          ↓
///        error
/// ```
///
/// # Example
/// ```swift
/// let state: DashboardState = .loading(progress: .init(user: true, units: false, materials: false))
/// if state.isPartiallyReady {
///     // Show partial data while loading continues
/// }
/// ```
public enum DashboardState: AsyncState {
    /// Initial state: no dashboard loaded.
    case idle

    /// Loading dashboard data from multiple sources.
    case loading(progress: LoadingProgress)

    /// Some resources loaded, waiting for others.
    case partiallyLoaded(data: PartialDashboardData)

    /// Aggregating all resources into final dashboard.
    case aggregating

    /// Dashboard fully loaded and ready.
    case ready(data: DashboardData)

    /// Loading failed with an error.
    case error(DashboardError)
}

// MARK: - Loading Progress

/// Tracks loading progress for individual resources.
public struct LoadingProgress: Sendable, Equatable, Codable {
    /// Whether user data has been loaded.
    public var userLoaded: Bool

    /// Whether units data has been loaded.
    public var unitsLoaded: Bool

    /// Whether materials data has been loaded.
    public var materialsLoaded: Bool

    /// Creates a new loading progress tracker.
    public init(
        userLoaded: Bool = false,
        unitsLoaded: Bool = false,
        materialsLoaded: Bool = false
    ) {
        self.userLoaded = userLoaded
        self.unitsLoaded = unitsLoaded
        self.materialsLoaded = materialsLoaded
    }

    /// Returns the completion percentage (0.0 to 1.0).
    public var completionPercentage: Double {
        let loaded = [userLoaded, unitsLoaded, materialsLoaded].filter { $0 }.count
        return Double(loaded) / 3.0
    }

    /// Returns true if all resources are loaded.
    public var isComplete: Bool {
        userLoaded && unitsLoaded && materialsLoaded
    }

    /// Returns the number of loaded resources.
    public var loadedCount: Int {
        [userLoaded, unitsLoaded, materialsLoaded].filter { $0 }.count
    }
}

// MARK: - Partial Dashboard Data

/// Contains partially loaded dashboard data.
public struct PartialDashboardData: Sendable, Equatable, Codable {
    /// User data if loaded.
    public var user: UserData?

    /// Units data if loaded.
    public var units: [UnitData]?

    /// Materials data if loaded.
    public var materials: [MaterialData]?

    /// Whether this partial data came from cache.
    public var isFromCache: Bool

    /// Creates partial dashboard data.
    public init(
        user: UserData? = nil,
        units: [UnitData]? = nil,
        materials: [MaterialData]? = nil,
        isFromCache: Bool = false
    ) {
        self.user = user
        self.units = units
        self.materials = materials
        self.isFromCache = isFromCache
    }

    /// Returns the loading progress for this partial data.
    public var loadingProgress: LoadingProgress {
        LoadingProgress(
            userLoaded: user != nil,
            unitsLoaded: units != nil,
            materialsLoaded: materials != nil
        )
    }

    /// Returns true if at least one resource is loaded.
    public var hasAnyData: Bool {
        user != nil || units != nil || materials != nil
    }
}

// MARK: - Dashboard Data

/// Complete dashboard data aggregating all resources.
public struct DashboardData: Sendable, Equatable, Codable {
    /// User information.
    public let user: UserData

    /// Available learning units.
    public let units: [UnitData]

    /// Available learning materials.
    public let materials: [MaterialData]

    /// Timestamp when data was loaded.
    public let loadedAt: Date

    /// Whether this data came from cache (may be stale).
    public let isFromCache: Bool

    /// Creates complete dashboard data.
    public init(
        user: UserData,
        units: [UnitData],
        materials: [MaterialData],
        loadedAt: Date = Date(),
        isFromCache: Bool = false
    ) {
        self.user = user
        self.units = units
        self.materials = materials
        self.loadedAt = loadedAt
        self.isFromCache = isFromCache
    }

    /// Creates dashboard data from partial data (requires all fields present).
    public init?(from partial: PartialDashboardData) {
        guard let user = partial.user,
              let units = partial.units,
              let materials = partial.materials else {
            return nil
        }
        self.user = user
        self.units = units
        self.materials = materials
        self.loadedAt = Date()
        self.isFromCache = partial.isFromCache
    }
}

// MARK: - Domain Models

/// User data for the dashboard.
public struct UserData: Sendable, Equatable, Codable {
    /// User identifier.
    public let id: String

    /// User's display name.
    public let name: String

    /// User's email address.
    public let email: String

    /// User's avatar URL.
    public let avatarURL: String?

    /// Creates user data.
    public init(id: String, name: String, email: String, avatarURL: String? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.avatarURL = avatarURL
    }
}

/// Learning unit data.
public struct UnitData: Sendable, Equatable, Codable {
    /// Unit identifier.
    public let id: String

    /// Unit title.
    public let title: String

    /// Progress percentage (0.0 to 1.0).
    public let progress: Double

    /// Whether the unit is locked.
    public let isLocked: Bool

    /// Creates unit data.
    public init(id: String, title: String, progress: Double, isLocked: Bool = false) {
        self.id = id
        self.title = title
        self.progress = max(0, min(1, progress))
        self.isLocked = isLocked
    }
}

/// Learning material data.
public struct MaterialData: Sendable, Equatable, Codable {
    /// Material identifier.
    public let id: String

    /// Material title.
    public let title: String

    /// Material type (video, document, etc.).
    public let type: MaterialType

    /// Duration in seconds (for video/audio).
    public let duration: TimeInterval?

    /// Creates material data.
    public init(id: String, title: String, type: MaterialType, duration: TimeInterval? = nil) {
        self.id = id
        self.title = title
        self.type = type
        self.duration = duration
    }
}

/// Types of learning materials.
public enum MaterialType: String, Sendable, Equatable, Hashable, Codable {
    case video
    case document
    case audio
    case quiz
    case interactive
    case pdf
    case image
    case other
}

// MARK: - Dashboard Error

/// Errors that can occur during dashboard loading.
public enum DashboardError: Error, Equatable, Sendable {
    /// Failed to load user data.
    case userLoadFailed(reason: String)

    /// Failed to load units data.
    case unitsLoadFailed(reason: String)

    /// Failed to load materials data.
    case materialsLoadFailed(reason: String)

    /// Multiple resources failed to load.
    case multipleFailures(errors: [String])

    /// Network error during loading.
    case networkError(reason: String)

    /// Loading timed out.
    case timeout

    /// Loading was cancelled.
    case cancelled

    /// Unknown error.
    case unknown(reason: String)
}

// MARK: - State Introspection

extension DashboardState {
    /// Returns true if the state represents a terminal state.
    public var isTerminal: Bool {
        switch self {
        case .ready, .error:
            return true
        default:
            return false
        }
    }

    /// Returns true if the state represents an active loading process.
    public var isLoading: Bool {
        switch self {
        case .loading, .aggregating:
            return true
        default:
            return false
        }
    }

    /// Returns true if there is partial data available.
    public var hasPartialData: Bool {
        if case .partiallyLoaded = self {
            return true
        }
        return false
    }

    /// Returns the dashboard data if ready, nil otherwise.
    public var dashboardData: DashboardData? {
        if case .ready(let data) = self {
            return data
        }
        return nil
    }

    /// Returns the partial data if available, nil otherwise.
    public var partialData: PartialDashboardData? {
        if case .partiallyLoaded(let data) = self {
            return data
        }
        return nil
    }

    /// Returns the error if in error state, nil otherwise.
    public var dashboardError: DashboardError? {
        if case .error(let error) = self {
            return error
        }
        return nil
    }

    /// Returns the loading progress if loading, nil otherwise.
    public var loadingProgress: LoadingProgress? {
        switch self {
        case .loading(let progress):
            return progress
        case .partiallyLoaded(let data):
            return data.loadingProgress
        default:
            return nil
        }
    }

    /// Returns a human-readable description of the state.
    public var description: String {
        switch self {
        case .idle:
            return "Dashboard not loaded"
        case .loading(let progress):
            return "Loading dashboard (\(Int(progress.completionPercentage * 100))%)"
        case .partiallyLoaded(let data):
            return "Partially loaded (\(data.loadingProgress.loadedCount)/3 resources)"
        case .aggregating:
            return "Preparing dashboard..."
        case .ready(let data):
            if data.isFromCache {
                return "Dashboard ready (cached)"
            }
            return "Dashboard ready"
        case .error(let error):
            return "Error: \(error)"
        }
    }
}

// MARK: - Equatable Conformance

extension DashboardState: Equatable {
    public static func == (lhs: DashboardState, rhs: DashboardState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.loading(let lProgress), .loading(let rProgress)):
            return lProgress == rProgress
        case (.partiallyLoaded(let lData), .partiallyLoaded(let rData)):
            return lData == rData
        case (.aggregating, .aggregating):
            return true
        case (.ready(let lData), .ready(let rData)):
            return lData == rData
        case (.error(let lError), .error(let rError)):
            return lError == rError
        default:
            return false
        }
    }
}

// MARK: - Codable Conformance

extension DashboardState: Codable {
    private enum CodingKeys: String, CodingKey {
        case type
        case progress
        case partialData
        case data
        case errorType
        case errorReason
        case errorReasons
    }

    private enum StateType: String, Codable {
        case idle, loading, partiallyLoaded, aggregating, ready, error
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(StateType.self, forKey: .type)

        switch type {
        case .idle:
            self = .idle
        case .loading:
            let progress = try container.decode(LoadingProgress.self, forKey: .progress)
            self = .loading(progress: progress)
        case .partiallyLoaded:
            let data = try container.decode(PartialDashboardData.self, forKey: .partialData)
            self = .partiallyLoaded(data: data)
        case .aggregating:
            self = .aggregating
        case .ready:
            let data = try container.decode(DashboardData.self, forKey: .data)
            self = .ready(data: data)
        case .error:
            let errorType = try container.decode(String.self, forKey: .errorType)
            let errorReason = try container.decodeIfPresent(String.self, forKey: .errorReason)
            let errorReasons = try container.decodeIfPresent([String].self, forKey: .errorReasons)
            self = .error(DashboardError.decode(type: errorType, reason: errorReason, reasons: errorReasons))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .idle:
            try container.encode(StateType.idle, forKey: .type)
        case .loading(let progress):
            try container.encode(StateType.loading, forKey: .type)
            try container.encode(progress, forKey: .progress)
        case .partiallyLoaded(let data):
            try container.encode(StateType.partiallyLoaded, forKey: .type)
            try container.encode(data, forKey: .partialData)
        case .aggregating:
            try container.encode(StateType.aggregating, forKey: .type)
        case .ready(let data):
            try container.encode(StateType.ready, forKey: .type)
            try container.encode(data, forKey: .data)
        case .error(let error):
            try container.encode(StateType.error, forKey: .type)
            let (errorType, errorReason, errorReasons) = error.encoded
            try container.encode(errorType, forKey: .errorType)
            try container.encodeIfPresent(errorReason, forKey: .errorReason)
            try container.encodeIfPresent(errorReasons, forKey: .errorReasons)
        }
    }
}

// MARK: - DashboardError Codable Helpers

extension DashboardError {
    var encoded: (type: String, reason: String?, reasons: [String]?) {
        switch self {
        case .userLoadFailed(let reason):
            return ("userLoadFailed", reason, nil)
        case .unitsLoadFailed(let reason):
            return ("unitsLoadFailed", reason, nil)
        case .materialsLoadFailed(let reason):
            return ("materialsLoadFailed", reason, nil)
        case .multipleFailures(let errors):
            return ("multipleFailures", nil, errors)
        case .networkError(let reason):
            return ("networkError", reason, nil)
        case .timeout:
            return ("timeout", nil, nil)
        case .cancelled:
            return ("cancelled", nil, nil)
        case .unknown(let reason):
            return ("unknown", reason, nil)
        }
    }

    static func decode(type: String, reason: String?, reasons: [String]?) -> DashboardError {
        switch type {
        case "userLoadFailed":
            return .userLoadFailed(reason: reason ?? "Unknown error")
        case "unitsLoadFailed":
            return .unitsLoadFailed(reason: reason ?? "Unknown error")
        case "materialsLoadFailed":
            return .materialsLoadFailed(reason: reason ?? "Unknown error")
        case "multipleFailures":
            return .multipleFailures(errors: reasons ?? [])
        case "networkError":
            return .networkError(reason: reason ?? "Unknown error")
        case "timeout":
            return .timeout
        case "cancelled":
            return .cancelled
        default:
            return .unknown(reason: reason ?? "Unknown error")
        }
    }
}
