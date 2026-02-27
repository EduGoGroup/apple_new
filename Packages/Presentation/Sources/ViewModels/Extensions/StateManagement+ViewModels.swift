import Foundation
import EduDomain

// MARK: - State Stream Observation Helper

/// Extension to simplify state stream observation in ViewModels.
///
/// Provides a type-safe way to observe state machine streams
/// and update ViewModel properties on the main actor.
///
/// ## Usage
/// ```swift
/// @MainActor
/// @Observable
/// final class MyViewModel {
///     var uploadState: UploadState = .validating
///
///     private let stateMachine: UploadStateMachine
///     private var observationTask: Task<Void, Never>?
///
///     func startObserving() {
///         observationTask = Task {
///             await observe(stateMachine.stateStream) { [weak self] state in
///                 self?.uploadState = state
///             }
///         }
///     }
/// }
/// ```
@MainActor
public func observe<State: AsyncState>(
    _ stream: StateStream<State>,
    onState: @escaping @MainActor (State) -> Void
) async {
    for await state in stream {
        onState(state)
    }
}

// MARK: - Upload State ViewModel Integration

/// Protocol for ViewModels that integrate with UploadStateMachine.
///
/// Provides a standard interface for upload state management
/// with progress tracking and error handling.
@MainActor
public protocol UploadStateObserver: AnyObject {

    /// The current upload state.
    var uploadState: UploadState { get set }

    /// The current upload progress (0.0 - 1.0).
    var uploadProgress: Double { get set }

    /// Error from the upload process, if any.
    var uploadError: UploadError? { get set }

    /// Called when upload completes successfully.
    func onUploadCompleted()
}

extension UploadStateObserver {

    /// Updates the ViewModel based on the new upload state.
    ///
    /// Call this from your state observation loop to automatically
    /// update all related properties.
    ///
    /// - Parameter state: The new upload state from the state machine.
    public func handleUploadState(_ state: UploadState) {
        uploadState = state

        switch state {
        case .uploading(let progress):
            uploadProgress = progress
            uploadError = nil
        case .ready:
            uploadProgress = 1.0
            uploadError = nil
            onUploadCompleted()
        case .error(let error):
            uploadError = error
        default:
            break
        }
    }

    /// Default implementation does nothing.
    public func onUploadCompleted() {}
}

// MARK: - Computed Properties for Upload State

extension UploadState {

    /// Returns true if currently validating.
    public var isValidating: Bool {
        if case .validating = self { return true }
        return false
    }

    /// Returns true if currently creating session.
    public var isCreating: Bool {
        if case .creating = self { return true }
        return false
    }

    /// Returns true if currently uploading.
    public var isUploading: Bool {
        if case .uploading = self { return true }
        return false
    }

    /// Returns true if currently processing.
    public var isProcessing: Bool {
        if case .processing = self { return true }
        return false
    }

    /// Returns true if upload is ready/complete.
    public var isReady: Bool {
        if case .ready = self { return true }
        return false
    }

    /// Returns true if in error state.
    public var isError: Bool {
        if case .error = self { return true }
        return false
    }

    /// Returns true if upload can be cancelled.
    public var canCancel: Bool {
        switch self {
        case .validating, .creating, .uploading, .processing:
            return true
        case .ready, .error:
            return false
        }
    }

    /// Returns true if upload can be retried.
    public var canRetry: Bool {
        if case .error = self { return true }
        return false
    }
}

// MARK: - Assessment State ViewModel Integration

/// Protocol for ViewModels that integrate with AssessmentStateMachine.
///
/// Provides a standard interface for assessment state management
/// with progress tracking, score handling and error management.
@MainActor
public protocol AssessmentStateObserver: AnyObject {

    /// The current assessment state.
    var assessmentState: AssessmentState { get set }

    /// Number of answered questions.
    var answeredCount: Int { get set }

    /// Total number of questions.
    var totalQuestions: Int { get set }

    /// Final score after completion (0.0 - 1.0).
    var finalScore: Double? { get set }

    /// Error from the assessment, if any.
    var assessmentError: AssessmentError? { get set }

    /// Called when assessment is completed with score.
    func onAssessmentCompleted(score: Double)
}

extension AssessmentStateObserver {

    /// Updates the ViewModel based on the new assessment state.
    ///
    /// - Parameter state: The new assessment state from the state machine.
    public func handleAssessmentState(_ state: AssessmentState) {
        assessmentState = state

        switch state {
        case .inProgress(let answered, let total):
            answeredCount = answered
            totalQuestions = total
            assessmentError = nil
        case .completed(let score):
            finalScore = score
            assessmentError = nil
            onAssessmentCompleted(score: score)
        case .error(let error):
            assessmentError = error
        default:
            break
        }
    }

    /// Default implementation does nothing.
    public func onAssessmentCompleted(score: Double) {}
}

// MARK: - Computed Properties for Assessment State

extension AssessmentState {

    /// Returns true if assessment is idle.
    public var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }

    /// Returns true if assessment is loading.
    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    /// Returns true if assessment is ready.
    public var isReady: Bool {
        if case .ready = self { return true }
        return false
    }

    /// Returns true if assessment is in progress.
    public var isInProgress: Bool {
        if case .inProgress = self { return true }
        return false
    }

    /// Returns true if assessment is submitting.
    public var isSubmitting: Bool {
        if case .submitting = self { return true }
        return false
    }

    /// Returns true if assessment is completed.
    public var isCompleted: Bool {
        if case .completed = self { return true }
        return false
    }

    /// Returns true if assessment has error.
    public var isError: Bool {
        if case .error = self { return true }
        return false
    }

    /// Returns true if assessment can be started.
    public var canStart: Bool {
        if case .ready = self { return true }
        return false
    }

    /// Returns true if assessment can be submitted.
    public var canSubmit: Bool {
        switch self {
        case .inProgress:
            return true
        default:
            return false
        }
    }

    /// Returns true if answers can be recorded.
    public var canAnswer: Bool {
        switch self {
        case .ready, .inProgress:
            return true
        default:
            return false
        }
    }
}

// MARK: - Dashboard State ViewModel Integration

/// Protocol for ViewModels that integrate with DashboardStateMachine.
///
/// Provides a standard interface for dashboard state management
/// with partial loading support and error handling.
@MainActor
public protocol DashboardStateObserver: AnyObject {

    /// The current dashboard state.
    var dashboardState: DashboardState { get set }

    /// Indicates if dashboard is loading.
    var isLoadingDashboard: Bool { get set }

    /// The loaded dashboard data, if available.
    var dashboardData: DashboardData? { get set }

    /// Partial data while loading.
    var partialData: PartialDashboardData? { get set }

    /// Error from loading, if any.
    var dashboardError: DashboardError? { get set }

    /// Called when dashboard data is loaded.
    func onDashboardLoaded(_ data: DashboardData)
}

extension DashboardStateObserver {

    /// Updates the ViewModel based on the new dashboard state.
    ///
    /// - Parameter state: The new dashboard state from the state machine.
    public func handleDashboardState(_ state: DashboardState) {
        dashboardState = state

        switch state {
        case .loading:
            isLoadingDashboard = true
            dashboardError = nil
        case .partiallyLoaded(let data):
            partialData = data
            isLoadingDashboard = true
            dashboardError = nil
        case .aggregating:
            isLoadingDashboard = true
            dashboardError = nil
        case .ready(let data):
            dashboardData = data
            partialData = nil
            isLoadingDashboard = false
            dashboardError = nil
            onDashboardLoaded(data)
        case .error(let error):
            isLoadingDashboard = false
            dashboardError = error
        case .idle:
            isLoadingDashboard = false
        }
    }

    /// Default implementation does nothing.
    public func onDashboardLoaded(_ data: DashboardData) {}
}

// MARK: - ViewModel-Friendly Dashboard State Properties

extension DashboardState {

    /// Returns true if dashboard is idle.
    public var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }

    /// Returns true if dashboard is actively loading.
    public var isActivelyLoading: Bool {
        switch self {
        case .loading, .aggregating:
            return true
        default:
            return false
        }
    }

    /// Returns true if dashboard has partial data.
    public var isPartiallyLoaded: Bool {
        if case .partiallyLoaded = self { return true }
        return false
    }

    /// Returns true if dashboard is aggregating.
    public var isAggregating: Bool {
        if case .aggregating = self { return true }
        return false
    }

    /// Returns true if dashboard is ready.
    public var isReady: Bool {
        if case .ready = self { return true }
        return false
    }

    /// Returns true if dashboard has error.
    public var isError: Bool {
        if case .error = self { return true }
        return false
    }

    /// Returns true if dashboard can be refreshed.
    public var canRefresh: Bool {
        switch self {
        case .ready, .error:
            return true
        default:
            return false
        }
    }

    /// Returns true if dashboard has any displayable data.
    public var hasDisplayableData: Bool {
        switch self {
        case .ready, .partiallyLoaded:
            return true
        default:
            return false
        }
    }
}
