import Foundation
import EduFoundation

/// Validator for Document entities ensuring business rules compliance.
///
/// `DocumentValidator` provides validation methods for Document-related operations,
/// ensuring that titles, content, and state transitions comply with business rules.
///
/// ## Overview
///
/// This validator enforces the following rules:
/// - Titles must not be empty (after trimming whitespace)
/// - Content must not be empty when publishing a document
/// - State transitions must follow the valid transition paths defined in `DocumentState`
///
/// ## Usage
///
/// ```swift
/// let validator = DocumentValidator()
///
/// // Validate title
/// try validator.validateTitle("  ") // Throws validationFailed
///
/// // Validate content for publish
/// try validator.validateContentForPublish("") // Throws validationFailed
///
/// // Validate state transition
/// try validator.validateTransition(from: .draft, to: .archived) // Throws invalidOperation
/// ```
///
/// ## Error Handling
///
/// All validation methods throw `DomainError` when validation fails:
/// - `DomainError.validationFailed(field:reason:)` for field validation errors
/// - `DomainError.invalidOperation(operation:)` for invalid state transitions
///
/// ## Thread Safety
///
/// This struct is `Sendable` and can be safely used across concurrency contexts.
public struct DocumentValidator: Sendable {

    /// Creates a new document validator instance.
    public init() {}

    // MARK: - Title Validation

    /// Validates that a document title is not empty.
    ///
    /// - Parameter title: The title to validate.
    /// - Throws: `DomainError.validationFailed` if the title is empty after trimming whitespace.
    ///
    /// - Note: The title is trimmed of leading and trailing whitespace before validation.
    public static func validateTitle(_ title: String) throws {
        guard isValidTitle(title) else {
            throw DomainError.validationFailed(
                field: "title",
                reason: "El título no puede estar vacío"
            )
        }
    }

    /// Checks if a title is valid without throwing an error.
    ///
    /// - Parameter title: The title to check.
    /// - Returns: `true` if the title is valid (not empty after trimming), `false` otherwise.
    public static func isValidTitle(_ title: String) -> Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Content Validation

    /// Validates that document content is not empty when publishing.
    ///
    /// - Parameter content: The content to validate.
    /// - Throws: `DomainError.validationFailed` if the content is empty after trimming whitespace.
    ///
    /// - Note: This validation should be performed before transitioning a document to the published state.
    /// - Note: The content is trimmed of leading and trailing whitespace before validation.
    public static func validateContentForPublish(_ content: String) throws {
        guard isValidContentForPublish(content) else {
            throw DomainError.validationFailed(
                field: "content",
                reason: "El contenido no puede estar vacío al publicar"
            )
        }
    }

    /// Checks if content is valid for publishing without throwing an error.
    ///
    /// - Parameter content: The content to check.
    /// - Returns: `true` if the content is valid (not empty after trimming), `false` otherwise.
    public static func isValidContentForPublish(_ content: String) -> Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - State Transition Validation

    /// Validates that a state transition is allowed.
    ///
    /// - Parameters:
    ///   - from: The current document state.
    ///   - to: The target document state.
    /// - Throws: `DomainError.invalidOperation` if the transition is not allowed.
    ///
    /// - Note: Valid transitions are defined in `DocumentState.validTransitions`.
    ///
    /// Valid transitions:
    /// - `draft` → `published`
    /// - `published` → `archived` or `draft`
    /// - `archived` → `draft`
    public static func validateTransition(from: DocumentState, to: DocumentState) throws {
        guard canTransition(from: from, to: to) else {
            throw DomainError.invalidOperation(
                operation: "Transición inválida de \(from.rawValue) a \(to.rawValue)"
            )
        }
    }

    /// Checks if a state transition is allowed without throwing an error.
    ///
    /// - Parameters:
    ///   - from: The current document state.
    ///   - to: The target document state.
    /// - Returns: `true` if the transition is allowed, `false` otherwise.
    public static func canTransition(from: DocumentState, to: DocumentState) -> Bool {
        from.canTransition(to: to)
    }
}
