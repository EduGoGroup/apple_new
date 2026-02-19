import Foundation
import Testing
@testable import FoundationToolkit

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

    // MARK: - timeout Tests

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

    // MARK: - Edge Cases

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
        let domainError = DomainError.entityNotFound(type: "Student", id: "S999")
        let useCaseError = UseCaseError.domainError(domainError)

        guard let unwrappedDomain = useCaseError.underlyingDomainError else {
            Issue.record("Failed to unwrap domain error")
            return
        }

        if case .entityNotFound(let type, let id) = unwrappedDomain {
            #expect(type == "Student")
            #expect(id == "S999")
        } else {
            Issue.record("Failed to extract entity not found details")
        }

        #expect(useCaseError.errorDescription?.contains("Student") == true)
        #expect(useCaseError.errorDescription?.contains("S999") == true)
    }
}
