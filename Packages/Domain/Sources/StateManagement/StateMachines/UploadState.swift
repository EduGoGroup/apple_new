/// Represents the states of an upload process.
///
/// UploadState models the complete lifecycle of a file upload operation,
/// from initial validation through processing to completion or error.
///
/// # State Flow
/// ```
/// validating → creating → uploading(progress) → processing → ready
///      ↓           ↓              ↓                 ↓          ↓
///   error ←──────────────────────────────────────────────────────
///      ↓
/// validating (retry)
/// ```
///
/// # Example
/// ```swift
/// let state: UploadState = .uploading(progress: 0.5)
/// if case .uploading(let progress) = state {
///     print("Upload at \(progress * 100)%")
/// }
/// ```
public enum UploadState: AsyncState {
    /// Initial state: validating file type, size, and permissions.
    case validating

    /// Creating upload session with backend/S3.
    case creating

    /// Actively uploading with progress (0.0 to 1.0).
    case uploading(progress: Double)

    /// Upload complete, server is processing the file.
    case processing

    /// Upload fully complete and ready for use.
    case ready

    /// Upload failed with an error.
    case error(UploadError)
}

// MARK: - Equatable Conformance

extension UploadState: Equatable {
    public static func == (lhs: UploadState, rhs: UploadState) -> Bool {
        switch (lhs, rhs) {
        case (.validating, .validating):
            return true
        case (.creating, .creating):
            return true
        case (.uploading(let lProgress), .uploading(let rProgress)):
            return abs(lProgress - rProgress) < 0.001
        case (.processing, .processing):
            return true
        case (.ready, .ready):
            return true
        case (.error(let lError), .error(let rError)):
            return lError == rError
        default:
            return false
        }
    }
}

// MARK: - Upload Error

/// Errors that can occur during the upload process.
public enum UploadError: Error, Equatable, Sendable {
    /// File validation failed (invalid type, size exceeded, etc.).
    case validationFailed(reason: String)

    /// Failed to create upload session with backend.
    case sessionCreationFailed(reason: String)

    /// Network error during upload.
    case networkError(reason: String)

    /// Upload was cancelled by user or system.
    case cancelled

    /// Server processing failed.
    case processingFailed(reason: String)

    /// Generic error with description.
    case unknown(reason: String)
}

// MARK: - State Introspection

extension UploadState {
    /// Returns the progress value if in uploading state, nil otherwise.
    public var progress: Double? {
        if case .uploading(let progress) = self {
            return progress
        }
        return nil
    }

    /// Returns the error if in error state, nil otherwise.
    public var uploadError: UploadError? {
        if case .error(let error) = self {
            return error
        }
        return nil
    }

    /// Returns true if the state represents a terminal state (ready or error).
    public var isTerminal: Bool {
        switch self {
        case .ready, .error:
            return true
        default:
            return false
        }
    }

    /// Returns true if the state represents an active upload in progress.
    public var isActive: Bool {
        switch self {
        case .validating, .creating, .uploading, .processing:
            return true
        default:
            return false
        }
    }

    /// Returns a human-readable description of the state.
    public var description: String {
        switch self {
        case .validating:
            return "Validating file..."
        case .creating:
            return "Creating upload session..."
        case .uploading(let progress):
            return "Uploading (\(Int(progress * 100))%)"
        case .processing:
            return "Processing file..."
        case .ready:
            return "Upload complete"
        case .error(let error):
            return "Error: \(error)"
        }
    }
}
