import Foundation
import Observation

/// A property wrapper that provides real-time validation and change observation
/// for editable properties in ViewModels.
///
/// `@BindableProperty` is thread-safe through `@MainActor` isolation and supports:
/// - Real-time validation with customizable validators
/// - Change callbacks for side effects
/// - Observable validation state for UI binding
///
/// ## Usage
/// ```swift
/// @MainActor
/// @Observable
/// final class LoginViewModel {
///     @BindableProperty(validation: Validators.email())
///     var email: String = ""
///
///     var isEmailValid: Bool {
///         $email.validationState.isValid
///     }
/// }
/// ```
@MainActor
@propertyWrapper
public struct BindableProperty<Value: Sendable>: Sendable {

    private var value: Value
    private let validation: (@Sendable (Value) -> ValidationResult)?
    private let onChange: (@Sendable (Value) -> Void)?

    /// Observable state containing validation results.
    ///
    /// Access through the projected value (`$property.validationState`)
    /// to bind validation status to UI components.
    @Observable
    @MainActor
    public final class ValidationState: Sendable {

        /// Indicates whether the current value passes validation.
        public var isValid: Bool = true

        /// Error message from the last validation, nil if valid.
        public var errorMessage: String?

        public init() {}
    }

    /// The observable validation state for this property.
    public let validationState: ValidationState

    /// The wrapped value with automatic validation on set.
    public var wrappedValue: Value {
        get { value }
        set {
            value = newValue

            if let validation {
                let result = validation(newValue)
                validationState.isValid = result.isValid
                validationState.errorMessage = result.errorMessage
            }

            onChange?(newValue)
        }
    }

    /// The projected value providing access to the property wrapper itself.
    ///
    /// Use this to access `validationState`:
    /// ```swift
    /// $email.validationState.isValid
    /// $email.validationState.errorMessage
    /// ```
    public var projectedValue: BindableProperty<Value> {
        self
    }

    /// Creates a bindable property with optional validation and change callback.
    ///
    /// - Parameters:
    ///   - wrappedValue: The initial value.
    ///   - validation: Optional validation closure that returns a `ValidationResult`.
    ///   - onChange: Optional callback invoked after each value change.
    public init(
        wrappedValue: Value,
        validation: (@Sendable (Value) -> ValidationResult)? = nil,
        onChange: (@Sendable (Value) -> Void)? = nil
    ) {
        self.value = wrappedValue
        self.validation = validation
        self.onChange = onChange
        self.validationState = ValidationState()
    }

    /// Manually triggers validation on the current value.
    ///
    /// Useful for validating fields that haven't been modified yet,
    /// such as on form submission.
    public mutating func validate() {
        if let validation {
            let result = validation(value)
            validationState.isValid = result.isValid
            validationState.errorMessage = result.errorMessage
        }
    }

    /// Resets the validation state to valid with no error message.
    ///
    /// Use this to clear validation errors, for example when
    /// the user starts editing a field.
    public func resetValidation() {
        validationState.isValid = true
        validationState.errorMessage = nil
    }
}
