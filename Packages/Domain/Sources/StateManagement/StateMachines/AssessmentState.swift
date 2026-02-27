import Foundation

/// Represents the states of an assessment (evaluation) process.
///
/// AssessmentState models the complete lifecycle of taking an assessment,
/// from initial loading through completion with a score.
///
/// # State Flow
/// ```
/// idle → loading → ready → inProgress(answeredCount) → submitting → completed(score)
///   ↓       ↓        ↓              ↓                      ↓             ↓
/// error ←─────────────────────────────────────────────────────────────────
///   ↓
/// idle (reset for new assessment)
/// ```
///
/// # Example
/// ```swift
/// let state: AssessmentState = .inProgress(answeredCount: 5, totalQuestions: 10)
/// if case .inProgress(let answered, let total) = state {
///     print("Answered \(answered) of \(total) questions")
/// }
/// ```
public enum AssessmentState: AsyncState {
    /// Initial state: no assessment loaded.
    case idle

    /// Loading assessment data from server.
    case loading

    /// Assessment loaded and ready to start.
    case ready

    /// Assessment in progress with current answer count.
    case inProgress(answeredCount: Int, totalQuestions: Int)

    /// Submitting answers to server.
    case submitting

    /// Assessment completed successfully with score.
    case completed(score: Double)

    /// Assessment failed with an error.
    case error(AssessmentError)
}

// MARK: - Equatable Conformance

extension AssessmentState: Equatable {
    public static func == (lhs: AssessmentState, rhs: AssessmentState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.loading, .loading):
            return true
        case (.ready, .ready):
            return true
        case (.inProgress(let lAnswered, let lTotal), .inProgress(let rAnswered, let rTotal)):
            return lAnswered == rAnswered && lTotal == rTotal
        case (.submitting, .submitting):
            return true
        case (.completed(let lScore), .completed(let rScore)):
            return abs(lScore - rScore) < 0.001
        case (.error(let lError), .error(let rError)):
            return lError == rError
        default:
            return false
        }
    }
}

// MARK: - Assessment Error

/// Errors that can occur during the assessment process.
public enum AssessmentError: Error, Equatable, Sendable {
    /// Failed to load assessment from server.
    case loadingFailed(reason: String)

    /// Network error during assessment.
    case networkError(reason: String)

    /// Assessment was cancelled by user.
    case cancelled

    /// Assessment timed out (exceeded time limit).
    case timeout

    /// Failed to submit answers.
    case submissionFailed(reason: String)

    /// Assessment session expired.
    case sessionExpired

    /// Generic error with description.
    case unknown(reason: String)
}

// MARK: - State Introspection

extension AssessmentState {
    /// Returns the answered count if in progress, nil otherwise.
    public var answeredCount: Int? {
        if case .inProgress(let count, _) = self {
            return count
        }
        return nil
    }

    /// Returns the total questions if in progress, nil otherwise.
    public var totalQuestions: Int? {
        if case .inProgress(_, let total) = self {
            return total
        }
        return nil
    }

    /// Returns the progress percentage (0.0 to 1.0) if in progress, nil otherwise.
    public var progress: Double? {
        if case .inProgress(let answered, let total) = self, total > 0 {
            return Double(answered) / Double(total)
        }
        return nil
    }

    /// Returns the score if completed, nil otherwise.
    public var score: Double? {
        if case .completed(let score) = self {
            return score
        }
        return nil
    }

    /// Returns the error if in error state, nil otherwise.
    public var assessmentError: AssessmentError? {
        if case .error(let error) = self {
            return error
        }
        return nil
    }

    /// Returns true if the state represents a terminal state (completed or error).
    public var isTerminal: Bool {
        switch self {
        case .completed, .error:
            return true
        default:
            return false
        }
    }

    /// Returns true if the state represents an active assessment.
    public var isActive: Bool {
        switch self {
        case .loading, .ready, .inProgress, .submitting:
            return true
        default:
            return false
        }
    }

    /// Returns true if answers can be recorded (ready or inProgress).
    public var canAnswerQuestions: Bool {
        switch self {
        case .ready, .inProgress:
            return true
        default:
            return false
        }
    }

    /// Returns a human-readable description of the state.
    public var description: String {
        switch self {
        case .idle:
            return "No assessment loaded"
        case .loading:
            return "Loading assessment..."
        case .ready:
            return "Assessment ready to start"
        case .inProgress(let answered, let total):
            return "Question \(answered) of \(total)"
        case .submitting:
            return "Submitting answers..."
        case .completed(let score):
            return "Completed with score: \(Int(score * 100))%"
        case .error(let error):
            return "Error: \(error)"
        }
    }
}

// MARK: - Codable Conformance for Persistence

extension AssessmentState: Codable {
    private enum CodingKeys: String, CodingKey {
        case type
        case answeredCount
        case totalQuestions
        case score
        case errorType
        case errorReason
    }

    private enum StateType: String, Codable {
        case idle, loading, ready, inProgress, submitting, completed, error
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(StateType.self, forKey: .type)

        switch type {
        case .idle:
            self = .idle
        case .loading:
            self = .loading
        case .ready:
            self = .ready
        case .inProgress:
            let answered = try container.decode(Int.self, forKey: .answeredCount)
            let total = try container.decode(Int.self, forKey: .totalQuestions)
            self = .inProgress(answeredCount: answered, totalQuestions: total)
        case .submitting:
            self = .submitting
        case .completed:
            let score = try container.decode(Double.self, forKey: .score)
            self = .completed(score: score)
        case .error:
            let errorType = try container.decode(String.self, forKey: .errorType)
            let errorReason = try container.decodeIfPresent(String.self, forKey: .errorReason)
            self = .error(AssessmentError.decode(type: errorType, reason: errorReason))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .idle:
            try container.encode(StateType.idle, forKey: .type)
        case .loading:
            try container.encode(StateType.loading, forKey: .type)
        case .ready:
            try container.encode(StateType.ready, forKey: .type)
        case .inProgress(let answered, let total):
            try container.encode(StateType.inProgress, forKey: .type)
            try container.encode(answered, forKey: .answeredCount)
            try container.encode(total, forKey: .totalQuestions)
        case .submitting:
            try container.encode(StateType.submitting, forKey: .type)
        case .completed(let score):
            try container.encode(StateType.completed, forKey: .type)
            try container.encode(score, forKey: .score)
        case .error(let error):
            try container.encode(StateType.error, forKey: .type)
            let (errorType, errorReason) = error.encoded
            try container.encode(errorType, forKey: .errorType)
            try container.encodeIfPresent(errorReason, forKey: .errorReason)
        }
    }
}

// MARK: - AssessmentError Codable Helpers

extension AssessmentError {
    var encoded: (type: String, reason: String?) {
        switch self {
        case .loadingFailed(let reason):
            return ("loadingFailed", reason)
        case .networkError(let reason):
            return ("networkError", reason)
        case .cancelled:
            return ("cancelled", nil)
        case .timeout:
            return ("timeout", nil)
        case .submissionFailed(let reason):
            return ("submissionFailed", reason)
        case .sessionExpired:
            return ("sessionExpired", nil)
        case .unknown(let reason):
            return ("unknown", reason)
        }
    }

    static func decode(type: String, reason: String?) -> AssessmentError {
        switch type {
        case "loadingFailed":
            return .loadingFailed(reason: reason ?? "Unknown error")
        case "networkError":
            return .networkError(reason: reason ?? "Unknown error")
        case "cancelled":
            return .cancelled
        case "timeout":
            return .timeout
        case "submissionFailed":
            return .submissionFailed(reason: reason ?? "Unknown error")
        case "sessionExpired":
            return .sessionExpired
        default:
            return .unknown(reason: reason ?? "Unknown error")
        }
    }
}
