import Foundation
import Observation

/// Manages the state and validation of complex forms with multiple fields.
///
/// `FormState` provides:
/// - Registration of individual field validators
/// - Cross-field validation for rules that depend on multiple fields
/// - Automatic validation before submission
/// - Submission handling with loading state
///
/// ## Usage
/// ```swift
/// @MainActor
/// @Observable
/// final class RegistrationViewModel {
///     @BindableProperty(validation: Validators.email())
///     var email: String = ""
///
///     var password: String = ""
///     var passwordConfirmation: String = ""
///
///     let formState = FormState()
///
///     init() {
///         formState.registerCrossValidator { [weak self] in
///             guard let self else { return .valid() }
///             return CrossValidators.passwordMatch(password, passwordConfirmation)
///         }
///     }
/// }
/// ```
@MainActor
@Observable
public final class FormState: Sendable {

    /// Indicates whether all validations pass.
    public var isValid: Bool = false

    /// Indicates whether a submission is in progress.
    public var isSubmitting: Bool = false

    /// Dictionary of validation errors keyed by field name.
    /// The key "form" is reserved for cross-field validation errors.
    public var errors: [String: String] = [:]

    private var fieldValidators: [String: @Sendable () -> ValidationResult] = [:]
    private var crossValidators: [@Sendable () -> ValidationResult] = []

    public init() {}

    // MARK: - Field Registration

    /// Registers a validator for a specific field.
    ///
    /// - Parameters:
    ///   - key: Unique identifier for the field (used as error key).
    ///   - validator: Closure that returns a `ValidationResult`.
    public func registerField(
        _ key: String,
        validator: @escaping @Sendable () -> ValidationResult
    ) {
        fieldValidators[key] = validator
    }

    /// Unregisters a field validator.
    ///
    /// - Parameter key: The field identifier to remove.
    public func unregisterField(_ key: String) {
        fieldValidators.removeValue(forKey: key)
    }

    /// Registers a cross-field validator.
    ///
    /// Cross-field validators run after individual field validators
    /// and are useful for rules that depend on multiple fields.
    ///
    /// - Parameter validator: Closure that returns a `ValidationResult`.
    public func registerCrossValidator(
        _ validator: @escaping @Sendable () -> ValidationResult
    ) {
        crossValidators.append(validator)
    }

    /// Removes all cross-field validators.
    public func clearCrossValidators() {
        crossValidators.removeAll()
    }

    // MARK: - Validation

    /// Validates all registered fields and cross-field rules.
    ///
    /// Updates `errors` dictionary and `isValid` property.
    public func validate() {
        errors.removeAll()

        // Validate individual fields
        for (key, validator) in fieldValidators {
            let result = validator()
            if !result.isValid, let message = result.errorMessage {
                errors[key] = message
            }
        }

        // Validate cross-field rules
        for validator in crossValidators {
            let result = validator()
            if !result.isValid, let message = result.errorMessage {
                // Append to existing form error if present
                if let existing = errors["form"] {
                    errors["form"] = "\(existing)\n\(message)"
                } else {
                    errors["form"] = message
                }
            }
        }

        isValid = errors.isEmpty
    }

    /// Validates a specific field by key.
    ///
    /// - Parameter key: The field identifier to validate.
    /// - Returns: The validation result, or `.valid()` if no validator is registered.
    @discardableResult
    public func validateField(_ key: String) -> ValidationResult {
        guard let validator = fieldValidators[key] else {
            return .valid()
        }

        let result = validator()
        if result.isValid {
            errors.removeValue(forKey: key)
        } else if let message = result.errorMessage {
            errors[key] = message
        }

        updateIsValid()
        return result
    }

    /// Returns the error message for a specific field.
    ///
    /// - Parameter key: The field identifier.
    /// - Returns: The error message, or `nil` if no error.
    public func error(for key: String) -> String? {
        errors[key]
    }

    /// Clears the error for a specific field.
    ///
    /// - Parameter key: The field identifier.
    public func clearError(for key: String) {
        errors.removeValue(forKey: key)
        updateIsValid()
    }

    /// Clears all errors and resets the form state.
    public func reset() {
        errors.removeAll()
        isValid = false
        isSubmitting = false
    }

    // MARK: - Submission

    /// Validates the form and executes the action if valid.
    ///
    /// - Parameter action: Async closure to execute if validation passes.
    /// - Returns: `true` if the action was executed successfully.
    @discardableResult
    public func submit(
        action: @escaping @Sendable () async throws -> Void
    ) async -> Bool {
        validate()

        guard isValid else { return false }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await action()
            return true
        } catch {
            errors["form"] = error.localizedDescription
            isValid = false
            return false
        }
    }

    // MARK: - Private

    private func updateIsValid() {
        isValid = errors.isEmpty
    }
}
