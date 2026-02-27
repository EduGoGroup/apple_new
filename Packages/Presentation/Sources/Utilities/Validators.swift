import Foundation

/// A collection of predefined validators for common validation scenarios.
///
/// Use these validators with `@BindableProperty` for real-time validation:
///
/// ```swift
/// @BindableProperty(validation: Validators.email())
/// var email: String = ""
///
/// @BindableProperty(validation: Validators.password(minLength: 8))
/// var password: String = ""
/// ```
public enum Validators {

    // MARK: - String Validators

    /// Creates an email validator.
    ///
    /// Validates that the string is a properly formatted email address.
    ///
    /// - Returns: A validator closure for email validation.
    public static func email() -> @Sendable (String) -> ValidationResult {
        { value in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmed.isEmpty {
                return .invalid("El email es requerido")
            }

            let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)

            if !emailPredicate.evaluate(with: trimmed) {
                return .invalid("Email inválido")
            }

            return .valid()
        }
    }

    /// Creates a password validator with configurable security requirements.
    ///
    /// Validates that the password meets specified security criteria including length
    /// and optionally character types (uppercase, lowercase, numbers, symbols).
    ///
    /// - Parameters:
    ///   - minLength: Minimum required password length. Default is 8.
    ///   - requireUppercase: Require at least one uppercase letter. Default is false.
    ///   - requireLowercase: Require at least one lowercase letter. Default is false.
    ///   - requireNumbers: Require at least one number. Default is false.
    ///   - requireSymbols: Require at least one symbol. Default is false.
    /// - Returns: A validator closure for password validation.
    ///
    /// ## Examples
    ///
    /// Basic validation (backward compatible):
    /// ```swift
    /// @BindableProperty(validation: Validators.password(minLength: 8))
    /// var password: String = ""
    /// ```
    ///
    /// Strong password for financial transactions:
    /// ```swift
    /// @BindableProperty(validation: Validators.password(
    ///     minLength: 12,
    ///     requireUppercase: true,
    ///     requireNumbers: true,
    ///     requireSymbols: true
    /// ))
    /// var securePassword: String = ""
    /// ```
    ///
    /// Medium security for general login:
    /// ```swift
    /// @BindableProperty(validation: Validators.password(
    ///     minLength: 8,
    ///     requireUppercase: true,
    ///     requireNumbers: true
    /// ))
    /// var loginPassword: String = ""
    /// ```
    public static func password(
        minLength: Int = 8,
        requireUppercase: Bool = false,
        requireLowercase: Bool = false,
        requireNumbers: Bool = false,
        requireSymbols: Bool = false
    ) -> @Sendable (String) -> ValidationResult {
        { value in
            if value.isEmpty {
                return .invalid("La contraseña es requerida")
            }

            if value.count < minLength {
                return .invalid("La contraseña debe tener al menos \(minLength) caracteres")
            }

            if requireUppercase && value.rangeOfCharacter(from: .uppercaseLetters) == nil {
                return .invalid("La contraseña debe contener al menos una mayúscula")
            }

            if requireLowercase && value.rangeOfCharacter(from: .lowercaseLetters) == nil {
                return .invalid("La contraseña debe contener al menos una minúscula")
            }

            if requireNumbers && value.rangeOfCharacter(from: .decimalDigits) == nil {
                return .invalid("La contraseña debe contener al menos un número")
            }

            if requireSymbols {
                let symbolSet = CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")
                if value.rangeOfCharacter(from: symbolSet) == nil {
                    return .invalid("La contraseña debe contener al menos un símbolo (!@#$%^&*...)")
                }
            }

            return .valid()
        }
    }

    /// Creates a non-empty string validator.
    ///
    /// Validates that the string is not empty after trimming whitespace.
    ///
    /// - Parameter fieldName: Name of the field for error messages. Default is "Campo".
    /// - Returns: A validator closure for non-empty validation.
    public static func nonEmpty(fieldName: String = "Campo") -> @Sendable (String) -> ValidationResult {
        { value in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmed.isEmpty {
                return .invalid("\(fieldName) no puede estar vacío")
            }

            return .valid()
        }
    }

    /// Creates a minimum length validator.
    ///
    /// Validates that the string has at least the specified number of characters.
    ///
    /// - Parameters:
    ///   - length: Minimum required length.
    ///   - fieldName: Name of the field for error messages. Default is "Campo".
    /// - Returns: A validator closure for minimum length validation.
    public static func minLength(_ length: Int, fieldName: String = "Campo") -> @Sendable (String) -> ValidationResult {
        { value in
            if value.count < length {
                return .invalid("\(fieldName) debe tener al menos \(length) caracteres")
            }

            return .valid()
        }
    }

    /// Creates a maximum length validator.
    ///
    /// Validates that the string does not exceed the specified number of characters.
    ///
    /// - Parameters:
    ///   - length: Maximum allowed length.
    ///   - fieldName: Name of the field for error messages. Default is "Campo".
    /// - Returns: A validator closure for maximum length validation.
    public static func maxLength(_ length: Int, fieldName: String = "Campo") -> @Sendable (String) -> ValidationResult {
        { value in
            if value.count > length {
                return .invalid("\(fieldName) no puede tener más de \(length) caracteres")
            }

            return .valid()
        }
    }

    /// Creates a regex pattern validator.
    ///
    /// Validates that the string matches the specified regex pattern.
    ///
    /// - Parameters:
    ///   - pattern: The regex pattern to match.
    ///   - errorMessage: Error message when validation fails.
    /// - Returns: A validator closure for regex validation.
    public static func pattern(
        _ pattern: String,
        errorMessage: String
    ) -> @Sendable (String) -> ValidationResult {
        { value in
            let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)

            if !predicate.evaluate(with: value) {
                return .invalid(errorMessage)
            }

            return .valid()
        }
    }

    // MARK: - Numeric Validators

    /// Creates a range validator for comparable values.
    ///
    /// Validates that the value falls within the specified closed range.
    ///
    /// - Parameters:
    ///   - range: The allowed range of values.
    ///   - fieldName: Name of the field for error messages. Default is "Valor".
    /// - Returns: A validator closure for range validation.
    public static func range<T: Comparable & Sendable>(
        _ range: ClosedRange<T>,
        fieldName: String = "Valor"
    ) -> @Sendable (T) -> ValidationResult {
        { value in
            if !range.contains(value) {
                return .invalid("\(fieldName) debe estar entre \(range.lowerBound) y \(range.upperBound)")
            }

            return .valid()
        }
    }

    /// Creates a minimum value validator.
    ///
    /// Validates that the value is at least the specified minimum.
    ///
    /// - Parameters:
    ///   - minimum: The minimum allowed value.
    ///   - fieldName: Name of the field for error messages. Default is "Valor".
    /// - Returns: A validator closure for minimum value validation.
    public static func min<T: Comparable & Sendable>(
        _ minimum: T,
        fieldName: String = "Valor"
    ) -> @Sendable (T) -> ValidationResult {
        { value in
            if value < minimum {
                return .invalid("\(fieldName) debe ser al menos \(minimum)")
            }

            return .valid()
        }
    }

    /// Creates a maximum value validator.
    ///
    /// Validates that the value does not exceed the specified maximum.
    ///
    /// - Parameters:
    ///   - maximum: The maximum allowed value.
    ///   - fieldName: Name of the field for error messages. Default is "Valor".
    /// - Returns: A validator closure for maximum value validation.
    public static func max<T: Comparable & Sendable>(
        _ maximum: T,
        fieldName: String = "Valor"
    ) -> @Sendable (T) -> ValidationResult {
        { value in
            if value > maximum {
                return .invalid("\(fieldName) no puede ser mayor que \(maximum)")
            }

            return .valid()
        }
    }

    // MARK: - Composition

    /// Combines multiple validators into a single validator.
    ///
    /// Runs all validators in order and returns the first failure,
    /// or valid if all pass.
    ///
    /// - Parameter validators: Array of validators to combine.
    /// - Returns: A combined validator closure.
    public static func all<Value: Sendable>(
        _ validators: [@Sendable (Value) -> ValidationResult]
    ) -> @Sendable (Value) -> ValidationResult {
        { value in
            for validator in validators {
                let result = validator(value)
                if !result.isValid {
                    return result
                }
            }

            return .valid()
        }
    }

    /// Creates a conditional validator that only validates when a condition is met.
    ///
    /// - Parameters:
    ///   - condition: Closure that determines if validation should run.
    ///   - validator: The validator to run when condition is true.
    /// - Returns: A conditional validator closure.
    public static func when<Value: Sendable>(
        _ condition: @escaping @Sendable (Value) -> Bool,
        then validator: @escaping @Sendable (Value) -> ValidationResult
    ) -> @Sendable (Value) -> ValidationResult {
        { value in
            if condition(value) {
                return validator(value)
            }

            return .valid()
        }
    }
}
