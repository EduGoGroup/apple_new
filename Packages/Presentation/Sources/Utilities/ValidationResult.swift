import Foundation

/// Represents the result of a validation operation.
///
/// Use this type to communicate validation outcomes from validators
/// to property wrappers and UI components.
///
/// ## Usage
/// ```swift
/// let result = ValidationResult.valid()
/// let error = ValidationResult.invalid("Email is required")
/// ```
public struct ValidationResult: Sendable, Equatable {

    /// Indicates whether the validation passed.
    public let isValid: Bool

    /// Error message when validation fails, nil when valid.
    public let errorMessage: String?

    /// Creates a validation result.
    /// - Parameters:
    ///   - isValid: Whether the validation passed.
    ///   - errorMessage: Optional error message for invalid states.
    public init(isValid: Bool, errorMessage: String?) {
        self.isValid = isValid
        self.errorMessage = errorMessage
    }

    /// Creates a successful validation result.
    /// - Returns: A valid `ValidationResult` with no error message.
    public static func valid() -> ValidationResult {
        ValidationResult(isValid: true, errorMessage: nil)
    }

    /// Creates a failed validation result with an error message.
    /// - Parameter message: The error message describing why validation failed.
    /// - Returns: An invalid `ValidationResult` with the provided error message.
    public static func invalid(_ message: String) -> ValidationResult {
        ValidationResult(isValid: false, errorMessage: message)
    }
}
