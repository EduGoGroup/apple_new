// EduFormField.swift
// UI
//
// Form field wrapper with label and validation - iOS 26+ and macOS 26+

import SwiftUI

/// Form field wrapper with label and validation
///
/// Provides consistent styling for form fields with labels,
/// required indicators, help text, and validation feedback.
@available(iOS 26.0, macOS 26.0, *)
@MainActor
public struct EduFormField<Content: View>: View {
    public let label: String
    public let isRequired: Bool
    public let helpText: String?
    @ViewBuilder public let content: () -> Content
    public let validation: EduFormValidation?

    /// Creates a Form Field
    ///
    /// - Parameters:
    ///   - label: Field label
    ///   - isRequired: Shows * if required
    ///   - helpText: Help text (optional)
    ///   - validation: Field validation (optional)
    ///   - content: Field content (TextField, Picker, etc)
    public init(
        label: String,
        isRequired: Bool = false,
        helpText: String? = nil,
        validation: EduFormValidation? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.label = label
        self.isRequired = isRequired
        self.helpText = helpText
        self.validation = validation
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            // Label
            Text(label + (isRequired ? " *" : ""))
                .font(.caption)
                .foregroundStyle(labelColor)

            // Field content
            content()

            // Help text
            if let help = helpText {
                Text(help)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Validation feedback
            if let validation = validation, !validation.isValid {
                Label {
                    Text(validation.message)
                        .font(.caption)
                } icon: {
                    Image(systemName: "exclamationmark.circle")
                        .font(.caption)
                }
                .foregroundStyle(.red)
            } else if let validation = validation, validation.isValid && validation.showSuccess {
                Label {
                    Text(validation.successMessage ?? "Valid")
                        .font(.caption)
                } icon: {
                    Image(systemName: "checkmark.circle")
                        .font(.caption)
                }
                .foregroundStyle(.green)
            }
        }
    }

    private var labelColor: Color {
        if let validation = validation, !validation.isValid {
            return .red
        }
        return .secondary
    }
}

// MARK: - Form Validation

/// Form field validation
@available(iOS 26.0, macOS 26.0, *)
public struct EduFormValidation: Sendable {
    public let isValid: Bool
    public let message: String
    public let showSuccess: Bool
    public let successMessage: String?

    /// Creates a validation
    public init(
        isValid: Bool,
        message: String = "",
        showSuccess: Bool = false,
        successMessage: String? = nil
    ) {
        self.isValid = isValid
        self.message = message
        self.showSuccess = showSuccess
        self.successMessage = successMessage
    }

    /// Success validation
    public static func success(message: String? = nil) -> EduFormValidation {
        EduFormValidation(
            isValid: true,
            message: "",
            showSuccess: true,
            successMessage: message
        )
    }

    /// Error validation
    public static func error(_ message: String) -> EduFormValidation {
        EduFormValidation(
            isValid: false,
            message: message,
            showSuccess: false
        )
    }

    /// Email validation
    public static func email(_ text: String) -> EduFormValidation {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)

        if text.isEmpty {
            return .error("Email is required")
        } else if !emailPredicate.evaluate(with: text) {
            return .error("Invalid email format")
        } else {
            return .success(message: "Valid email")
        }
    }

    /// Minimum length validation
    public static func minLength(_ text: String, min: Int, fieldName: String = "Field") -> EduFormValidation {
        if text.isEmpty {
            return .error("\(fieldName) is required")
        } else if text.count < min {
            return .error("\(fieldName) must have at least \(min) characters")
        } else {
            return .success()
        }
    }

    /// Required validation
    public static func required(_ text: String, fieldName: String = "Field") -> EduFormValidation {
        if text.isEmpty {
            return .error("\(fieldName) is required")
        } else {
            return .success()
        }
    }
}

// MARK: - Compatibility Aliases

@available(iOS 26.0, macOS 26.0, *)
@available(*, deprecated, renamed: "EduFormField")
public typealias DSFormField = EduFormField

@available(iOS 26.0, macOS 26.0, *)
@available(*, deprecated, renamed: "EduFormValidation")
public typealias DSFormValidation = EduFormValidation
