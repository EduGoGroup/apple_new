import Foundation

/// A collection of cross-field validators for complex form validation.
///
/// Use these validators with `FormState.registerCrossValidator` for
/// validation rules that depend on multiple fields.
///
/// ## Usage
/// ```swift
/// formState.registerCrossValidator { [weak self] in
///     guard let self else { return .valid() }
///     return CrossValidators.passwordMatch(password, passwordConfirmation)
/// }
/// ```
public enum CrossValidators {

    // MARK: - Password Validation

    /// Validates that two password strings match.
    ///
    /// - Parameters:
    ///   - password: The password value.
    ///   - confirmation: The confirmation value.
    /// - Returns: Valid if they match, invalid otherwise.
    public static func passwordMatch(
        _ password: String,
        _ confirmation: String
    ) -> ValidationResult {
        if password != confirmation {
            return .invalid("Las contraseñas no coinciden")
        }
        return .valid()
    }

    // MARK: - Date Validation

    /// Validates that a date range is valid (start before end).
    ///
    /// - Parameters:
    ///   - start: The start date.
    ///   - end: The end date.
    /// - Returns: Valid if the range is valid, invalid otherwise.
    public static func dateRange(
        start: Date?,
        end: Date?
    ) -> ValidationResult {
        guard let start, let end else {
            return .invalid("Ambas fechas son requeridas")
        }

        if start > end {
            return .invalid("La fecha de inicio debe ser anterior a la fecha de fin")
        }

        return .valid()
    }

    /// Validates that a date range is valid, allowing nil values.
    ///
    /// - Parameters:
    ///   - start: The optional start date.
    ///   - end: The optional end date.
    /// - Returns: Valid if both are nil, both are set and valid, invalid otherwise.
    public static func optionalDateRange(
        start: Date?,
        end: Date?
    ) -> ValidationResult {
        // If both are nil, that's valid
        if start == nil && end == nil {
            return .valid()
        }

        // If only one is set, that's invalid
        guard let start, let end else {
            return .invalid("Debe completar ambas fechas o ninguna")
        }

        if start > end {
            return .invalid("La fecha de inicio debe ser anterior a la fecha de fin")
        }

        return .valid()
    }

    /// Validates that a date is not in the past.
    ///
    /// - Parameter date: The date to validate.
    /// - Returns: Valid if the date is today or in the future.
    public static func notInPast(_ date: Date?) -> ValidationResult {
        guard let date else {
            return .invalid("La fecha es requerida")
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dateToCheck = calendar.startOfDay(for: date)

        if dateToCheck < today {
            return .invalid("La fecha no puede ser en el pasado")
        }

        return .valid()
    }

    // MARK: - Collection Validation

    /// Validates that at least one item is selected.
    ///
    /// - Parameter items: The set of selected items.
    /// - Returns: Valid if at least one item is selected.
    public static func atLeastOneSelected<T>(
        _ items: Set<T>
    ) -> ValidationResult {
        if items.isEmpty {
            return .invalid("Debe seleccionar al menos un elemento")
        }
        return .valid()
    }

    /// Validates that at least one item is selected from an array.
    ///
    /// - Parameter items: The array of selected items.
    /// - Returns: Valid if at least one item is selected.
    public static func atLeastOneSelected<T>(
        _ items: [T]
    ) -> ValidationResult {
        if items.isEmpty {
            return .invalid("Debe seleccionar al menos un elemento")
        }
        return .valid()
    }

    /// Validates that exactly a specific number of items are selected.
    ///
    /// - Parameters:
    ///   - items: The collection of selected items.
    ///   - count: The required number of items.
    /// - Returns: Valid if the count matches.
    public static func exactCount<T: Collection>(
        _ items: T,
        count: Int
    ) -> ValidationResult {
        if items.count != count {
            return .invalid("Debe seleccionar exactamente \(count) elementos")
        }
        return .valid()
    }

    /// Validates that the number of selected items is within a range.
    ///
    /// - Parameters:
    ///   - items: The collection of selected items.
    ///   - range: The allowed range of item counts.
    /// - Returns: Valid if the count is within the range.
    public static func countInRange<T: Collection>(
        _ items: T,
        range: ClosedRange<Int>
    ) -> ValidationResult {
        if !range.contains(items.count) {
            return .invalid("Debe seleccionar entre \(range.lowerBound) y \(range.upperBound) elementos")
        }
        return .valid()
    }

    // MARK: - Conditional Validation

    /// Validates that a field is required when a condition is true.
    ///
    /// - Parameters:
    ///   - condition: The condition that triggers the requirement.
    ///   - value: The value to check.
    ///   - fieldName: The field name for the error message.
    /// - Returns: Valid if condition is false or value is non-empty.
    public static func conditionalRequired(
        condition: Bool,
        value: String,
        fieldName: String
    ) -> ValidationResult {
        if condition && value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .invalid("\(fieldName) es requerido")
        }
        return .valid()
    }

    /// Validates that a value is required when another value is present.
    ///
    /// - Parameters:
    ///   - dependsOn: The value that triggers the requirement.
    ///   - value: The value to check.
    ///   - fieldName: The field name for the error message.
    /// - Returns: Valid if dependsOn is empty or value is non-empty.
    public static func requiredWhenPresent(
        dependsOn: String,
        value: String,
        fieldName: String
    ) -> ValidationResult {
        let dependsOnTrimmed = dependsOn.trimmingCharacters(in: .whitespacesAndNewlines)
        let valueTrimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if !dependsOnTrimmed.isEmpty && valueTrimmed.isEmpty {
            return .invalid("\(fieldName) es requerido")
        }
        return .valid()
    }

    // MARK: - Comparison Validation

    /// Validates that two values are equal.
    ///
    /// - Parameters:
    ///   - value1: The first value.
    ///   - value2: The second value.
    ///   - errorMessage: Custom error message.
    /// - Returns: Valid if the values are equal.
    public static func equal<T: Equatable>(
        _ value1: T,
        _ value2: T,
        errorMessage: String
    ) -> ValidationResult {
        if value1 != value2 {
            return .invalid(errorMessage)
        }
        return .valid()
    }

    /// Validates that two values are different.
    ///
    /// - Parameters:
    ///   - value1: The first value.
    ///   - value2: The second value.
    ///   - errorMessage: Custom error message.
    /// - Returns: Valid if the values are different.
    public static func notEqual<T: Equatable>(
        _ value1: T,
        _ value2: T,
        errorMessage: String
    ) -> ValidationResult {
        if value1 == value2 {
            return .invalid(errorMessage)
        }
        return .valid()
    }

    // MARK: - Numeric Comparison

    /// Validates that one value is less than another.
    ///
    /// - Parameters:
    ///   - value: The value to check.
    ///   - max: The maximum allowed value (exclusive).
    ///   - fieldName: The field name for the error message.
    /// - Returns: Valid if value < max.
    public static func lessThan<T: Comparable>(
        _ value: T,
        _ max: T,
        fieldName: String = "Valor"
    ) -> ValidationResult {
        if value >= max {
            return .invalid("\(fieldName) debe ser menor que \(max)")
        }
        return .valid()
    }

    /// Validates that one value is greater than another.
    ///
    /// - Parameters:
    ///   - value: The value to check.
    ///   - min: The minimum allowed value (exclusive).
    ///   - fieldName: The field name for the error message.
    /// - Returns: Valid if value > min.
    public static func greaterThan<T: Comparable>(
        _ value: T,
        _ min: T,
        fieldName: String = "Valor"
    ) -> ValidationResult {
        if value <= min {
            return .invalid("\(fieldName) debe ser mayor que \(min)")
        }
        return .valid()
    }

    // MARK: - Composition

    /// Combines multiple validation results, returning the first failure.
    ///
    /// - Parameter validators: Array of validation closures.
    /// - Returns: Valid if all pass, or the first invalid result.
    public static func all(
        _ validators: [() -> ValidationResult]
    ) -> ValidationResult {
        for validator in validators {
            let result = validator()
            if !result.isValid {
                return result
            }
        }
        return .valid()
    }

    /// Combines multiple validation results, collecting all errors.
    ///
    /// - Parameter validators: Array of validation closures.
    /// - Returns: Valid if all pass, or invalid with combined error messages.
    public static func allCollectingErrors(
        _ validators: [() -> ValidationResult]
    ) -> ValidationResult {
        var errors: [String] = []

        for validator in validators {
            let result = validator()
            if !result.isValid, let message = result.errorMessage {
                errors.append(message)
            }
        }

        if errors.isEmpty {
            return .valid()
        }

        return .invalid(errors.joined(separator: "\n"))
    }
}
