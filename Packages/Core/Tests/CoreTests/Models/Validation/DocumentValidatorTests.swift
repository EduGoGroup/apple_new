import Testing
import Foundation
import EduFoundation
@testable import EduModels

@Suite("DocumentValidator Tests")
struct DocumentValidatorTests {

    // MARK: - Title Validation Tests

    @Suite("Title Validation")
    struct TitleValidationTests {

        @Test("Valid title passes validation")
        func validTitlePassesValidation() throws {
            try DocumentValidator.validateTitle("Valid Title")
            try DocumentValidator.validateTitle("A")
            try DocumentValidator.validateTitle("  Valid with spaces  ")
        }

        @Test("Empty title throws validationFailed error")
        func emptyTitleThrowsError() {
            #expect(throws: DomainError.self) {
                try DocumentValidator.validateTitle("")
            }

            do {
                try DocumentValidator.validateTitle("")
                Issue.record("Should have thrown validationFailed error")
            } catch let error as DomainError {
                guard case .validationFailed(let field, let reason) = error else {
                    Issue.record("Expected validationFailed error")
                    return
                }
                #expect(field == "title")
                #expect(reason == "El título no puede estar vacío")
            } catch {
                Issue.record("Unexpected error type: \(error)")
            }
        }

        @Test("Whitespace-only title throws validationFailed error")
        func whitespaceTitleThrowsError() {
            #expect(throws: DomainError.self) {
                try DocumentValidator.validateTitle("   ")
            }

            #expect(throws: DomainError.self) {
                try DocumentValidator.validateTitle("\n\t  ")
            }
        }

        @Test("isValidTitle returns correct boolean results")
        func isValidTitleBooleanResults() {
            #expect(DocumentValidator.isValidTitle("Valid Title"))
            #expect(DocumentValidator.isValidTitle("A"))
            #expect(DocumentValidator.isValidTitle("  Valid  "))

            #expect(!DocumentValidator.isValidTitle(""))
            #expect(!DocumentValidator.isValidTitle("   "))
            #expect(!DocumentValidator.isValidTitle("\n\t"))
        }
    }

    // MARK: - Content Validation Tests

    @Suite("Content Validation")
    struct ContentValidationTests {

        @Test("Valid content passes validation")
        func validContentPassesValidation() throws {
            try DocumentValidator.validateContentForPublish("Valid content")
            try DocumentValidator.validateContentForPublish("A")
            try DocumentValidator.validateContentForPublish("  Content with spaces  ")
        }

        @Test("Empty content throws validationFailed error")
        func emptyContentThrowsError() {
            #expect(throws: DomainError.self) {
                try DocumentValidator.validateContentForPublish("")
            }

            do {
                try DocumentValidator.validateContentForPublish("")
                Issue.record("Should have thrown validationFailed error")
            } catch let error as DomainError {
                guard case .validationFailed(let field, let reason) = error else {
                    Issue.record("Expected validationFailed error")
                    return
                }
                #expect(field == "content")
                #expect(reason == "El contenido no puede estar vacío al publicar")
            } catch {
                Issue.record("Unexpected error type: \(error)")
            }
        }

        @Test("Whitespace-only content throws validationFailed error")
        func whitespaceContentThrowsError() {
            #expect(throws: DomainError.self) {
                try DocumentValidator.validateContentForPublish("   ")
            }

            #expect(throws: DomainError.self) {
                try DocumentValidator.validateContentForPublish("\n\t  ")
            }
        }

        @Test("isValidContentForPublish returns correct boolean results")
        func isValidContentBooleanResults() {
            #expect(DocumentValidator.isValidContentForPublish("Valid content"))
            #expect(DocumentValidator.isValidContentForPublish("A"))
            #expect(DocumentValidator.isValidContentForPublish("  Content  "))

            #expect(!DocumentValidator.isValidContentForPublish(""))
            #expect(!DocumentValidator.isValidContentForPublish("   "))
            #expect(!DocumentValidator.isValidContentForPublish("\n\t"))
        }
    }

    // MARK: - State Transition Validation Tests

    @Suite("State Transition Validation")
    struct StateTransitionValidationTests {

        @Test("Valid transitions pass validation")
        func validTransitionsPassValidation() throws {
            // draft → published
            try DocumentValidator.validateTransition(from: .draft, to: .published)

            // published → archived
            try DocumentValidator.validateTransition(from: .published, to: .archived)

            // published → draft
            try DocumentValidator.validateTransition(from: .published, to: .draft)

            // archived → draft
            try DocumentValidator.validateTransition(from: .archived, to: .draft)
        }

        @Test("Invalid transition from draft to archived throws error")
        func draftToArchivedThrowsError() {
            #expect(throws: DomainError.self) {
                try DocumentValidator.validateTransition(from: .draft, to: .archived)
            }

            do {
                try DocumentValidator.validateTransition(from: .draft, to: .archived)
                Issue.record("Should have thrown invalidOperation error")
            } catch let error as DomainError {
                guard case .invalidOperation(let operation) = error else {
                    Issue.record("Expected invalidOperation error")
                    return
                }
                #expect(operation.contains("draft"))
                #expect(operation.contains("archived"))
            } catch {
                Issue.record("Unexpected error type: \(error)")
            }
        }

        @Test("Invalid transition from archived to published throws error")
        func archivedToPublishedThrowsError() {
            #expect(throws: DomainError.self) {
                try DocumentValidator.validateTransition(from: .archived, to: .published)
            }

            do {
                try DocumentValidator.validateTransition(from: .archived, to: .published)
                Issue.record("Should have thrown invalidOperation error")
            } catch let error as DomainError {
                guard case .invalidOperation(let operation) = error else {
                    Issue.record("Expected invalidOperation error")
                    return
                }
                #expect(operation.contains("archived"))
                #expect(operation.contains("published"))
            } catch {
                Issue.record("Unexpected error type: \(error)")
            }
        }

        @Test("Transition to same state throws error")
        func sameStateTransitionThrowsError() {
            #expect(throws: DomainError.self) {
                try DocumentValidator.validateTransition(from: .draft, to: .draft)
            }

            #expect(throws: DomainError.self) {
                try DocumentValidator.validateTransition(from: .published, to: .published)
            }

            #expect(throws: DomainError.self) {
                try DocumentValidator.validateTransition(from: .archived, to: .archived)
            }
        }

        @Test("canTransition returns correct boolean results")
        func canTransitionBooleanResults() {
            // Valid transitions
            #expect(DocumentValidator.canTransition(from: .draft, to: .published))
            #expect(DocumentValidator.canTransition(from: .published, to: .archived))
            #expect(DocumentValidator.canTransition(from: .published, to: .draft))
            #expect(DocumentValidator.canTransition(from: .archived, to: .draft))

            // Invalid transitions
            #expect(!DocumentValidator.canTransition(from: .draft, to: .archived))
            #expect(!DocumentValidator.canTransition(from: .archived, to: .published))

            // Same state transitions
            #expect(!DocumentValidator.canTransition(from: .draft, to: .draft))
            #expect(!DocumentValidator.canTransition(from: .published, to: .published))
            #expect(!DocumentValidator.canTransition(from: .archived, to: .archived))
        }
    }

    // MARK: - Comprehensive Validation Tests

    @Suite("Comprehensive Validation Scenarios")
    struct ComprehensiveValidationTests {

        @Test("Publishing workflow validation")
        func publishingWorkflowValidation() throws {
            let title = "Document Title"
            let content = "Document content"

            // Validate title and content before publishing
            try DocumentValidator.validateTitle(title)
            try DocumentValidator.validateContentForPublish(content)
            try DocumentValidator.validateTransition(from: .draft, to: .published)
        }

        @Test("Publishing with empty content fails")
        func publishingWithEmptyContentFails() throws {
            let title = "Document Title"
            let emptyContent = "   "

            // Title is valid
            try DocumentValidator.validateTitle(title)

            // But content validation fails
            #expect(throws: DomainError.self) {
                try DocumentValidator.validateContentForPublish(emptyContent)
            }
        }

        @Test("Archiving workflow validation")
        func archivingWorkflowValidation() throws {
            // Can archive from published
            try DocumentValidator.validateTransition(from: .published, to: .archived)

            // Cannot archive from draft
            #expect(throws: DomainError.self) {
                try DocumentValidator.validateTransition(from: .draft, to: .archived)
            }
        }

        @Test("Unarchiving workflow validation")
        func unarchivingWorkflowValidation() throws {
            // Can return to draft from archived
            try DocumentValidator.validateTransition(from: .archived, to: .draft)

            // Cannot publish directly from archived
            #expect(throws: DomainError.self) {
                try DocumentValidator.validateTransition(from: .archived, to: .published)
            }
        }
    }

    // MARK: - Sendable Conformance Tests

    @Test("DocumentValidator is Sendable")
    func validatorIsSendable() {
        Task {
            #expect(DocumentValidator.isValidTitle("Test"))
        }
    }
}
