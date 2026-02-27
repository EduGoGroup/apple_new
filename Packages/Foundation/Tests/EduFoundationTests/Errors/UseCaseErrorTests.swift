import Foundation
import Testing
@testable import EduFoundation

/// Suite de tests para verificar el comportamiento del enum `UseCaseError`.
///
/// Valida:
/// - Conformance a `Error`, `LocalizedError` y `Sendable`
/// - Mensajes de localización en español
/// - Wrapping de `DomainError` y `RepositoryError`
/// - Unwrapping mediante propiedades computadas
/// - Propagación de mensajes de errores wrapped
/// - Pattern matching para extracción de errores subyacentes
@Suite("UseCaseError Tests")
struct UseCaseErrorTests {

    // MARK: - Conformance Tests

    @Test("UseCaseError conforms to Error protocol")
    func test_useCaseError_conformsToError() {
        let error: Error = UseCaseError.executionFailed(reason: "Test")
        #expect(error is UseCaseError)
    }

    @Test("UseCaseError conforms to LocalizedError protocol")
    func test_useCaseError_conformsToLocalizedError() {
        let error: LocalizedError = UseCaseError.timeout
        #expect(error is UseCaseError)
    }

    @Test("UseCaseError conforms to Sendable protocol")
    func test_useCaseError_conformsToSendable() {
        let error: Sendable = UseCaseError.preconditionFailed(description: "Test")
        #expect(error is UseCaseError)
    }

    // MARK: - preconditionFailed Tests

    @Test("preconditionFailed case creates error with description")
    func test_preconditionFailed_whenCreated_thenStoresDescription() {
        let description = "Student must be active"
        let error = UseCaseError.preconditionFailed(description: description)

        if case .preconditionFailed(let storedDescription) = error {
            #expect(storedDescription == description)
        } else {
            Issue.record("Expected preconditionFailed case")
        }
    }

    @Test("preconditionFailed provides localized error description")
    func test_preconditionFailed_whenAccessed_thenProvidesErrorDescription() {
        let description = "User must be authenticated"
        let error = UseCaseError.preconditionFailed(description: description)

        let errorDescription = error.errorDescription
        #expect(errorDescription != nil)
        #expect(errorDescription?.contains(description) == true)
        #expect(errorDescription?.contains("Precondición no cumplida") == true)
    }

    @Test("preconditionFailed provides failure reason")
    func test_preconditionFailed_whenAccessed_thenProvidesFailureReason() {
        let error = UseCaseError.preconditionFailed(description: "Test")

        let failureReason = error.failureReason
        #expect(failureReason != nil)
        #expect(failureReason?.contains("precondiciones") == true)
    }

    @Test("preconditionFailed provides recovery suggestion")
    func test_preconditionFailed_whenAccessed_thenProvidesRecoverySuggestion() {
        let error = UseCaseError.preconditionFailed(description: "Test")

        let recoverySuggestion = error.recoverySuggestion
        #expect(recoverySuggestion != nil)
        #expect(recoverySuggestion?.contains("precondiciones") == true)
    }

    // MARK: - unauthorized Tests

    @Test("unauthorized case creates error with action")
    func test_unauthorized_whenCreated_thenStoresAction() {
        let action = "Delete student records"
        let error = UseCaseError.unauthorized(action: action)

        if case .unauthorized(let storedAction) = error {
            #expect(storedAction == action)
        } else {
            Issue.record("Expected unauthorized case")
        }
    }

    @Test("unauthorized provides localized error description")
    func test_unauthorized_whenAccessed_thenProvidesErrorDescription() {
        let action = "Modify grades"
        let error = UseCaseError.unauthorized(action: action)

        let description = error.errorDescription
        #expect(description != nil)
        #expect(description?.contains(action) == true)
        #expect(description?.contains("No autorizado") == true)
    }

    @Test("unauthorized provides failure reason")
    func test_unauthorized_whenAccessed_thenProvidesFailureReason() {
        let error = UseCaseError.unauthorized(action: "Test")

        let failureReason = error.failureReason
        #expect(failureReason != nil)
        #expect(failureReason?.contains("permisos") == true)
    }

    @Test("unauthorized provides recovery suggestion")
    func test_unauthorized_whenAccessed_thenProvidesRecoverySuggestion() {
        let error = UseCaseError.unauthorized(action: "Test")

        let recoverySuggestion = error.recoverySuggestion
        #expect(recoverySuggestion != nil)
        #expect(recoverySuggestion?.contains("administrador") == true)
    }

    // MARK: - domainError Wrapping Tests

    @Test("domainError case wraps DomainError")
    func test_domainError_whenCreated_thenWrapsDomainError() {
        let domainError = DomainError.validationFailed(field: "email", reason: "Invalid format")
        let useCaseError = UseCaseError.domainError(domainError)

        if case .domainError(let wrappedError) = useCaseError {
            #expect(wrappedError == domainError)
        } else {
            Issue.record("Expected domainError case")
        }
    }

    @Test("domainError propagates error description from wrapped error")
    func test_domainError_whenAccessed_thenPropagatesErrorDescription() {
        let domainError = DomainError.businessRuleViolated(rule: "Maximum 6 courses")
        let useCaseError = UseCaseError.domainError(domainError)

        let description = useCaseError.errorDescription
        #expect(description != nil)
        #expect(description?.contains("Error de dominio") == true)
        #expect(description?.contains("Maximum 6 courses") == true)
    }

    @Test("domainError propagates failure reason from wrapped error")
    func test_domainError_whenAccessed_thenPropagatesFailureReason() {
        let domainError = DomainError.invalidOperation(operation: "Delete submitted exam")
        let useCaseError = UseCaseError.domainError(domainError)

        let failureReason = useCaseError.failureReason
        #expect(failureReason != nil)
        #expect(failureReason == domainError.failureReason)
    }

    @Test("domainError propagates recovery suggestion from wrapped error")
    func test_domainError_whenAccessed_thenPropagatesRecoverySuggestion() {
        let domainError = DomainError.entityNotFound(type: "Student", id: "S123")
        let useCaseError = UseCaseError.domainError(domainError)

        let recoverySuggestion = useCaseError.recoverySuggestion
        #expect(recoverySuggestion != nil)
        #expect(recoverySuggestion == domainError.recoverySuggestion)
    }

    @Test("underlyingDomainError returns wrapped DomainError")
    func test_underlyingDomainError_whenDomainErrorWrapped_thenReturnsIt() {
        let domainError = DomainError.validationFailed(field: "age", reason: "Must be >= 18")
        let useCaseError = UseCaseError.domainError(domainError)

        let unwrapped = useCaseError.underlyingDomainError
        #expect(unwrapped != nil)
        #expect(unwrapped == domainError)
    }

    @Test("underlyingDomainError returns nil when not wrapping DomainError")
    func test_underlyingDomainError_whenNoDomainError_thenReturnsNil() {
        let useCaseError = UseCaseError.timeout

        let unwrapped = useCaseError.underlyingDomainError
        #expect(unwrapped == nil)
    }

    // MARK: - repositoryError Wrapping Tests

    @Test("repositoryError case wraps RepositoryError")
    func test_repositoryError_whenCreated_thenWrapsRepositoryError() {
        let repoError = RepositoryError.fetchFailed(reason: "Network timeout")
        let useCaseError = UseCaseError.repositoryError(repoError)

        if case .repositoryError(let wrappedError) = useCaseError {
            #expect(wrappedError == repoError)
        } else {
            Issue.record("Expected repositoryError case")
        }
    }

    @Test("repositoryError propagates error description from wrapped error")
    func test_repositoryError_whenAccessed_thenPropagatesErrorDescription() {
        let repoError = RepositoryError.connectionError(reason: "Network unavailable")
        let useCaseError = UseCaseError.repositoryError(repoError)

        let description = useCaseError.errorDescription
        #expect(description != nil)
        #expect(description?.contains("Error de repositorio") == true)
        #expect(description?.contains("conexión") == true)
    }

    @Test("repositoryError propagates failure reason from wrapped error")
    func test_repositoryError_whenAccessed_thenPropagatesFailureReason() {
        let repoError = RepositoryError.saveFailed(reason: "Disk full")
        let useCaseError = UseCaseError.repositoryError(repoError)

        let failureReason = useCaseError.failureReason
        #expect(failureReason != nil)
        #expect(failureReason == repoError.failureReason)
    }

    @Test("repositoryError propagates recovery suggestion from wrapped error")
    func test_repositoryError_whenAccessed_thenPropagatesRecoverySuggestion() {
        let repoError = RepositoryError.serializationError(type: "Course")
        let useCaseError = UseCaseError.repositoryError(repoError)

        let recoverySuggestion = useCaseError.recoverySuggestion
        #expect(recoverySuggestion != nil)
        #expect(recoverySuggestion == repoError.recoverySuggestion)
    }

    @Test("underlyingRepositoryError returns wrapped RepositoryError")
    func test_underlyingRepositoryError_whenRepositoryErrorWrapped_thenReturnsIt() {
        let repoError = RepositoryError.dataInconsistency(description: "Duplicate keys")
        let useCaseError = UseCaseError.repositoryError(repoError)

        let unwrapped = useCaseError.underlyingRepositoryError
        #expect(unwrapped != nil)
        #expect(unwrapped == repoError)
    }

    @Test("underlyingRepositoryError returns nil when not wrapping RepositoryError")
    func test_underlyingRepositoryError_whenNoRepositoryError_thenReturnsNil() {
        let useCaseError = UseCaseError.executionFailed(reason: "Unknown")

        let unwrapped = useCaseError.underlyingRepositoryError
        #expect(unwrapped == nil)
    }

    // MARK: - executionFailed Tests

    @Test("executionFailed case creates error with reason")
    func test_executionFailed_whenCreated_thenStoresReason() {
        let reason = "Internal processing error"
        let error = UseCaseError.executionFailed(reason: reason)

        if case .executionFailed(let storedReason) = error {
            #expect(storedReason == reason)
        } else {
            Issue.record("Expected executionFailed case")
        }
    }

    @Test("executionFailed provides localized error description")
    func test_executionFailed_whenAccessed_thenProvidesErrorDescription() {
        let reason = "Pipeline failed"
        let error = UseCaseError.executionFailed(reason: reason)

        let description = error.errorDescription
        #expect(description != nil)
        #expect(description?.contains(reason) == true)
        #expect(description?.contains("Ejecución fallida") == true)
    }

    @Test("executionFailed provides failure reason")
    func test_executionFailed_whenAccessed_thenProvidesFailureReason() {
        let error = UseCaseError.executionFailed(reason: "Test")

        let failureReason = error.failureReason
        #expect(failureReason != nil)
        #expect(failureReason?.contains("caso de uso") == true)
    }

    @Test("executionFailed provides recovery suggestion")
    func test_executionFailed_whenAccessed_thenProvidesRecoverySuggestion() {
        let error = UseCaseError.executionFailed(reason: "Test")

        let recoverySuggestion = error.recoverySuggestion
        #expect(recoverySuggestion != nil)
        #expect(recoverySuggestion?.contains("Vuelva a intentar") == true)
    }

    // MARK: - timeout Tests

    @Test("timeout case has no associated values")
    func test_timeout_whenCreated_thenHasNoAssociatedValues() {
        let error = UseCaseError.timeout

        if case .timeout = error {
            // Success: pattern matched correctly
            #expect(true)
        } else {
            Issue.record("Expected timeout case")
        }
    }

    @Test("timeout provides localized error description")
    func test_timeout_whenAccessed_thenProvidesErrorDescription() {
        let error = UseCaseError.timeout

        let description = error.errorDescription
        #expect(description != nil)
        #expect(description?.contains("tiempo límite") == true)
    }

    @Test("timeout provides failure reason")
    func test_timeout_whenAccessed_thenProvidesFailureReason() {
        let error = UseCaseError.timeout

        let failureReason = error.failureReason
        #expect(failureReason != nil)
        #expect(failureReason?.contains("tiempo") == true)
    }

    @Test("timeout provides recovery suggestion")
    func test_timeout_whenAccessed_thenProvidesRecoverySuggestion() {
        let error = UseCaseError.timeout

        let recoverySuggestion = error.recoverySuggestion
        #expect(recoverySuggestion != nil)
        #expect(recoverySuggestion?.contains("conexión") == true)
    }

    // MARK: - Pattern Matching Tests

    @Test("Pattern matching extracts associated values correctly")
    func test_patternMatching_whenMatchingCases_thenExtractsValues() {
        let domainError = DomainError.validationFailed(field: "test", reason: "test")
        let repoError = RepositoryError.fetchFailed(reason: "test")

        let errors: [UseCaseError] = [
            .preconditionFailed(description: "Test precondition"),
            .unauthorized(action: "Test action"),
            .domainError(domainError),
            .repositoryError(repoError),
            .executionFailed(reason: "Test reason"),
            .timeout
        ]

        for error in errors {
            switch error {
            case .preconditionFailed(let description):
                #expect(!description.isEmpty)
            case .unauthorized(let action):
                #expect(!action.isEmpty)
            case .domainError(let wrappedError):
                #expect(wrappedError == domainError)
            case .repositoryError(let wrappedError):
                #expect(wrappedError == repoError)
            case .executionFailed(let reason):
                #expect(!reason.isEmpty)
            case .timeout:
                #expect(true)
            }
        }
    }

    @Test("Pattern matching can extract specific DomainError cases")
    func test_patternMatching_whenDomainErrorWrapped_thenCanExtractSpecificCase() {
        let validationError = DomainError.validationFailed(field: "email", reason: "Invalid")
        let useCaseError = UseCaseError.domainError(validationError)

        if case .domainError(let domainError) = useCaseError {
            if case .validationFailed(let field, let reason) = domainError {
                #expect(field == "email")
                #expect(reason == "Invalid")
            } else {
                Issue.record("Expected validationFailed case")
            }
        } else {
            Issue.record("Expected domainError case")
        }
    }

    @Test("Pattern matching can extract specific RepositoryError cases")
    func test_patternMatching_whenRepositoryErrorWrapped_thenCanExtractSpecificCase() {
        let connectionError = RepositoryError.connectionError(reason: "Network timeout")
        let useCaseError = UseCaseError.repositoryError(connectionError)

        if case .repositoryError(let repoError) = useCaseError {
            if case .connectionError(let reason) = repoError {
                #expect(reason == "Network timeout")
            } else {
                Issue.record("Expected connectionError case")
            }
        } else {
            Issue.record("Expected repositoryError case")
        }
    }

    // MARK: - Unwrapping Tests

    @Test("Both unwrapping properties return nil for non-wrapped errors")
    func test_unwrappingProperties_whenNoWrappedError_thenReturnNil() {
        let errors: [UseCaseError] = [
            .preconditionFailed(description: "Test"),
            .unauthorized(action: "Test"),
            .executionFailed(reason: "Test"),
            .timeout
        ]

        for error in errors {
            #expect(error.underlyingDomainError == nil)
            #expect(error.underlyingRepositoryError == nil)
        }
    }

    @Test("underlyingDomainError returns nil when wrapping RepositoryError")
    func test_underlyingDomainError_whenRepositoryErrorWrapped_thenReturnsNil() {
        let repoError = RepositoryError.fetchFailed(reason: "Test")
        let useCaseError = UseCaseError.repositoryError(repoError)

        #expect(useCaseError.underlyingDomainError == nil)
    }

    @Test("underlyingRepositoryError returns nil when wrapping DomainError")
    func test_underlyingRepositoryError_whenDomainErrorWrapped_thenReturnsNil() {
        let domainError = DomainError.validationFailed(field: "test", reason: "test")
        let useCaseError = UseCaseError.domainError(domainError)

        #expect(useCaseError.underlyingRepositoryError == nil)
    }

    // MARK: - Edge Cases

    @Test("Error with empty strings still provides valid messages")
    func test_errorWithEmptyStrings_whenCreated_thenStillProvidesValidMessages() {
        let error = UseCaseError.preconditionFailed(description: "")

        #expect(error.errorDescription != nil)
        #expect(error.failureReason != nil)
        #expect(error.recoverySuggestion != nil)
    }

    @Test("Wrapping all DomainError cases")
    func test_wrapping_whenAllDomainErrorCases_thenPropagatesCorrectly() {
        let domainErrors: [DomainError] = [
            .validationFailed(field: "name", reason: "Empty"),
            .businessRuleViolated(rule: "Age limit"),
            .invalidOperation(operation: "Delete"),
            .entityNotFound(type: "User", id: "U1")
        ]

        for domainError in domainErrors {
            let useCaseError = UseCaseError.domainError(domainError)
            #expect(useCaseError.errorDescription != nil)
            #expect(useCaseError.underlyingDomainError == domainError)
        }
    }

    @Test("Wrapping all RepositoryError cases")
    func test_wrapping_whenAllRepositoryErrorCases_thenPropagatesCorrectly() {
        let repoErrors: [RepositoryError] = [
            .fetchFailed(reason: "Not found"),
            .saveFailed(reason: "Conflict"),
            .deleteFailed(reason: "Referenced"),
            .connectionError(reason: "Network unavailable"),
            .serializationError(type: "User"),
            .dataInconsistency(description: "Duplicate")
        ]

        for repoError in repoErrors {
            let useCaseError = UseCaseError.repositoryError(repoError)
            #expect(useCaseError.errorDescription != nil)
            #expect(useCaseError.underlyingRepositoryError == repoError)
        }
    }

    @Test("All error cases provide non-nil localized messages")
    func test_allCases_whenAccessed_thenProvideNonNilLocalizedMessages() {
        let domainError = DomainError.validationFailed(field: "test", reason: "test")
        let repoError = RepositoryError.fetchFailed(reason: "test")

        let errors: [UseCaseError] = [
            .preconditionFailed(description: "Test"),
            .unauthorized(action: "Test"),
            .domainError(domainError),
            .repositoryError(repoError),
            .executionFailed(reason: "Test"),
            .timeout
        ]

        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(error.failureReason != nil)
            #expect(error.recoverySuggestion != nil)
        }
    }

    @Test("Nested error chain maintains all information")
    func test_nestedErrorChain_whenMultipleLayers_thenMaintainsInformation() {
        // Create a chain: DomainError -> UseCaseError
        let domainError = DomainError.entityNotFound(type: "Student", id: "S999")
        let useCaseError = UseCaseError.domainError(domainError)

        // Verify unwrapping works
        guard let unwrappedDomain = useCaseError.underlyingDomainError else {
            Issue.record("Failed to unwrap domain error")
            return
        }

        // Verify original information is preserved
        if case .entityNotFound(let type, let id) = unwrappedDomain {
            #expect(type == "Student")
            #expect(id == "S999")
        } else {
            Issue.record("Failed to extract entity not found details")
        }

        // Verify descriptions are propagated
        #expect(useCaseError.errorDescription?.contains("Student") == true)
        #expect(useCaseError.errorDescription?.contains("S999") == true)
    }
}
