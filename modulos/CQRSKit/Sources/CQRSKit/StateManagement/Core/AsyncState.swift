/// Protocol that defines the contract for states that can be emitted via StatePublisher.
///
/// AsyncState requires conformance to Sendable and Equatable to ensure:
/// - Thread-safe emission across actor boundaries (Sendable)
/// - Efficient state comparison for deduplication (Equatable)
///
/// # Conformance Requirements
/// Types conforming to AsyncState must:
/// - Be immutable value types (preferred) or properly synchronized reference types
/// - Implement Equatable for state deduplication
/// - Conform to Sendable for cross-actor usage
///
/// # Example
/// ```swift
/// struct UploadState: AsyncState {
///     let progress: Double
///     let fileName: String
///     let status: UploadStatus
/// }
/// ```
public protocol AsyncState: Sendable, Equatable {}
