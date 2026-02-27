import Foundation
import Testing
@testable import EduFoundation

/// Suite de tests para verificar el comportamiento del enum `DomainError`.
///
/// Valida:
/// - Conformance a `Error`, `LocalizedError` y `Sendable`
/// - Mensajes de localización en español
/// - Associated values en cada caso
/// - Pattern matching para extracción de valores
@Suite("DomainError Tests")
struct DomainErrorTests {

    // MARK: - Conformance Tests

    @Test("DomainError conforms to Error protocol")
    func test_domainError_conformsToError() {
        let error: Error = DomainError.validationFailed(field: "email", reason: "Formato inválido")
        #expect(error is DomainError)
    }

    @Test("DomainError conforms to LocalizedError protocol")
    func test_domainError_conformsToLocalizedError() {
        let error: LocalizedError = DomainError.businessRuleViolated(rule: "Test rule")
        #expect(error is DomainError)
    }

    @Test("DomainError conforms to Sendable protocol")
    func test_domainError_conformsToSendable() {
        let error: Sendable = DomainError.invalidOperation(operation: "Test operation")
        #expect(error is DomainError)
    }

    // MARK: - validationFailed Tests

    @Test("validationFailed case creates error with field and reason")
    func test_validationFailed_whenCreated_thenStoresFieldAndReason() {
        let error = DomainError.validationFailed(field: "email", reason: "Formato inválido")

        if case .validationFailed(let field, let reason) = error {
            #expect(field == "email")
            #expect(reason == "Formato inválido")
        } else {
            Issue.record("Expected validationFailed case")
        }
    }

    @Test("validationFailed provides localized error description")
    func test_validationFailed_whenAccessed_thenProvidesErrorDescription() {
        let error = DomainError.validationFailed(field: "email", reason: "Formato inválido")

        let description = error.errorDescription
        #expect(description != nil)
        #expect(description?.contains("email") == true)
        #expect(description?.contains("Formato inválido") == true)
        #expect(description?.contains("Error de validación") == true)
    }

    @Test("validationFailed provides failure reason")
    func test_validationFailed_whenAccessed_thenProvidesFailureReason() {
        let error = DomainError.validationFailed(field: "password", reason: "Muy corta")

        let failureReason = error.failureReason
        #expect(failureReason != nil)
        #expect(failureReason?.contains("password") == true)
        #expect(failureReason?.contains("validación") == true)
    }

    @Test("validationFailed provides recovery suggestion")
    func test_validationFailed_whenAccessed_thenProvidesRecoverySuggestion() {
        let error = DomainError.validationFailed(field: "age", reason: "Debe ser mayor a 18")

        let recoverySuggestion = error.recoverySuggestion
        #expect(recoverySuggestion != nil)
        #expect(recoverySuggestion?.contains("Verifique") == true)
    }

    // MARK: - businessRuleViolated Tests

    @Test("businessRuleViolated case creates error with rule description")
    func test_businessRuleViolated_whenCreated_thenStoresRule() {
        let rule = "Un estudiante no puede estar inscrito en más de 6 materias"
        let error = DomainError.businessRuleViolated(rule: rule)

        if case .businessRuleViolated(let storedRule) = error {
            #expect(storedRule == rule)
        } else {
            Issue.record("Expected businessRuleViolated case")
        }
    }

    @Test("businessRuleViolated provides localized error description")
    func test_businessRuleViolated_whenAccessed_thenProvidesErrorDescription() {
        let rule = "Máximo 6 materias simultáneas"
        let error = DomainError.businessRuleViolated(rule: rule)

        let description = error.errorDescription
        #expect(description != nil)
        #expect(description?.contains(rule) == true)
        #expect(description?.contains("Regla de negocio violada") == true)
    }

    @Test("businessRuleViolated provides failure reason")
    func test_businessRuleViolated_whenAccessed_thenProvidesFailureReason() {
        let error = DomainError.businessRuleViolated(rule: "Test rule")

        let failureReason = error.failureReason
        #expect(failureReason != nil)
        #expect(failureReason?.contains("regla") == true)
        #expect(failureReason?.contains("dominio") == true)
    }

    @Test("businessRuleViolated provides recovery suggestion")
    func test_businessRuleViolated_whenAccessed_thenProvidesRecoverySuggestion() {
        let error = DomainError.businessRuleViolated(rule: "Test rule")

        let recoverySuggestion = error.recoverySuggestion
        #expect(recoverySuggestion != nil)
        #expect(recoverySuggestion?.contains("reglas de negocio") == true)
    }

    // MARK: - invalidOperation Tests

    @Test("invalidOperation case creates error with operation description")
    func test_invalidOperation_whenCreated_thenStoresOperation() {
        let operation = "Calificar examen no enviado"
        let error = DomainError.invalidOperation(operation: operation)

        if case .invalidOperation(let storedOperation) = error {
            #expect(storedOperation == operation)
        } else {
            Issue.record("Expected invalidOperation case")
        }
    }

    @Test("invalidOperation provides localized error description")
    func test_invalidOperation_whenAccessed_thenProvidesErrorDescription() {
        let operation = "Editar examen finalizado"
        let error = DomainError.invalidOperation(operation: operation)

        let description = error.errorDescription
        #expect(description != nil)
        #expect(description?.contains(operation) == true)
        #expect(description?.contains("Operación inválida") == true)
    }

    @Test("invalidOperation provides failure reason")
    func test_invalidOperation_whenAccessed_thenProvidesFailureReason() {
        let error = DomainError.invalidOperation(operation: "Test operation")

        let failureReason = error.failureReason
        #expect(failureReason != nil)
        #expect(failureReason?.contains("operación") == true)
        #expect(failureReason?.contains("estado") == true)
    }

    @Test("invalidOperation provides recovery suggestion")
    func test_invalidOperation_whenAccessed_thenProvidesRecoverySuggestion() {
        let error = DomainError.invalidOperation(operation: "Test operation")

        let recoverySuggestion = error.recoverySuggestion
        #expect(recoverySuggestion != nil)
        #expect(recoverySuggestion?.contains("estado correcto") == true)
    }

    // MARK: - entityNotFound Tests

    @Test("entityNotFound case creates error with type and id")
    func test_entityNotFound_whenCreated_thenStoresTypeAndId() {
        let error = DomainError.entityNotFound(type: "Student", id: "12345")

        if case .entityNotFound(let type, let id) = error {
            #expect(type == "Student")
            #expect(id == "12345")
        } else {
            Issue.record("Expected entityNotFound case")
        }
    }

    @Test("entityNotFound provides localized error description")
    func test_entityNotFound_whenAccessed_thenProvidesErrorDescription() {
        let error = DomainError.entityNotFound(type: "Course", id: "CS101")

        let description = error.errorDescription
        #expect(description != nil)
        #expect(description?.contains("Course") == true)
        #expect(description?.contains("CS101") == true)
        #expect(description?.contains("No se encontró") == true)
    }

    @Test("entityNotFound provides failure reason")
    func test_entityNotFound_whenAccessed_thenProvidesFailureReason() {
        let error = DomainError.entityNotFound(type: "Professor", id: "P123")

        let failureReason = error.failureReason
        #expect(failureReason != nil)
        #expect(failureReason?.contains("Professor") == true)
        #expect(failureReason?.contains("no existe") == true)
    }

    @Test("entityNotFound provides recovery suggestion")
    func test_entityNotFound_whenAccessed_thenProvidesRecoverySuggestion() {
        let error = DomainError.entityNotFound(type: "Assignment", id: "A456")

        let recoverySuggestion = error.recoverySuggestion
        #expect(recoverySuggestion != nil)
        #expect(recoverySuggestion?.contains("identificador") == true)
    }

    // MARK: - Pattern Matching Tests

    @Test("Pattern matching extracts associated values correctly")
    func test_patternMatching_whenMatchingCases_thenExtractsValues() {
        let errors: [DomainError] = [
            .validationFailed(field: "name", reason: "Empty"),
            .businessRuleViolated(rule: "Age limit"),
            .invalidOperation(operation: "Delete"),
            .entityNotFound(type: "User", id: "U1")
        ]

        for error in errors {
            switch error {
            case .validationFailed(let field, let reason):
                #expect(!field.isEmpty)
                #expect(!reason.isEmpty)
            case .businessRuleViolated(let rule):
                #expect(!rule.isEmpty)
            case .invalidOperation(let operation):
                #expect(!operation.isEmpty)
            case .entityNotFound(let type, let id):
                #expect(!type.isEmpty)
                #expect(!id.isEmpty)
            }
        }
    }

    // MARK: - Edge Cases

    @Test("Error with empty strings still provides valid messages")
    func test_errorWithEmptyStrings_whenCreated_thenStillProvidesValidMessages() {
        let error = DomainError.validationFailed(field: "", reason: "")

        #expect(error.errorDescription != nil)
        #expect(error.failureReason != nil)
        #expect(error.recoverySuggestion != nil)
    }

    @Test("Error with special characters in strings")
    func test_errorWithSpecialCharacters_whenCreated_thenHandlesCorrectly() {
        let field = "user@email.com"
        let reason = "Formato: debe contener '@' y '.'"
        let error = DomainError.validationFailed(field: field, reason: reason)

        let description = error.errorDescription
        #expect(description?.contains(field) == true)
        #expect(description?.contains(reason) == true)
    }

    @Test("Error with very long strings")
    func test_errorWithLongStrings_whenCreated_thenHandlesCorrectly() {
        let longField = String(repeating: "a", count: 1000)
        let longReason = String(repeating: "b", count: 1000)
        let error = DomainError.validationFailed(field: longField, reason: longReason)

        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.count ?? 0 > 0)
    }

    @Test("Error with Unicode characters")
    func test_errorWithUnicodeCharacters_whenCreated_thenHandlesCorrectly() {
        let field = "nombre_completo"
        let reason = "Debe contener solo letras: á, é, í, ó, ú, ñ"
        let error = DomainError.validationFailed(field: field, reason: reason)

        let description = error.errorDescription
        #expect(description?.contains("á") == true)
        #expect(description?.contains("ñ") == true)
    }
}
