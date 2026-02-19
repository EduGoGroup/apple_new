import Foundation
import Testing
@testable import FoundationToolkit

@Suite("RepositoryError Tests")
struct RepositoryErrorTests {

    // MARK: - Conformance Tests

    @Test("RepositoryError conforms to Error protocol")
    func test_repositoryError_conformsToError() {
        let error: Error = RepositoryError.fetchFailed(reason: "Test")
        #expect(error is RepositoryError)
    }

    @Test("RepositoryError conforms to LocalizedError protocol")
    func test_repositoryError_conformsToLocalizedError() {
        let error: LocalizedError = RepositoryError.saveFailed(reason: "Test")
        #expect(error is RepositoryError)
    }

    @Test("RepositoryError conforms to Sendable protocol")
    func test_repositoryError_conformsToSendable() {
        let error: Sendable = RepositoryError.deleteFailed(reason: "Test")
        #expect(error is RepositoryError)
    }

    // MARK: - fetchFailed Tests

    @Test("fetchFailed case creates error with reason")
    func test_fetchFailed_whenCreated_thenStoresReason() {
        let reason = "Server returned 404"
        let error = RepositoryError.fetchFailed(reason: reason)

        if case .fetchFailed(let storedReason) = error {
            #expect(storedReason == reason)
        } else {
            Issue.record("Expected fetchFailed case")
        }
    }

    @Test("fetchFailed provides localized error description")
    func test_fetchFailed_whenAccessed_thenProvidesErrorDescription() {
        let reason = "Network timeout"
        let error = RepositoryError.fetchFailed(reason: reason)

        let description = error.errorDescription
        #expect(description != nil)
        #expect(description?.contains(reason) == true)
        #expect(description?.contains("recuperar datos") == true)
    }

    @Test("fetchFailed provides failure reason")
    func test_fetchFailed_whenAccessed_thenProvidesFailureReason() {
        let error = RepositoryError.fetchFailed(reason: "Test")

        let failureReason = error.failureReason
        #expect(failureReason != nil)
        #expect(failureReason?.contains("lectura") == true)
        #expect(failureReason?.contains("fuente de datos") == true)
    }

    @Test("fetchFailed provides recovery suggestion")
    func test_fetchFailed_whenAccessed_thenProvidesRecoverySuggestion() {
        let error = RepositoryError.fetchFailed(reason: "Test")

        let recoverySuggestion = error.recoverySuggestion
        #expect(recoverySuggestion != nil)
        #expect(recoverySuggestion?.contains("conexión") == true)
    }

    // MARK: - saveFailed Tests

    @Test("saveFailed case creates error with reason")
    func test_saveFailed_whenCreated_thenStoresReason() {
        let reason = "Disk full"
        let error = RepositoryError.saveFailed(reason: reason)

        if case .saveFailed(let storedReason) = error {
            #expect(storedReason == reason)
        } else {
            Issue.record("Expected saveFailed case")
        }
    }

    @Test("saveFailed provides localized error description")
    func test_saveFailed_whenAccessed_thenProvidesErrorDescription() {
        let reason = "Sync conflict"
        let error = RepositoryError.saveFailed(reason: reason)

        let description = error.errorDescription
        #expect(description != nil)
        #expect(description?.contains(reason) == true)
        #expect(description?.contains("guardar datos") == true)
    }

    // MARK: - deleteFailed Tests

    @Test("deleteFailed case creates error with reason")
    func test_deleteFailed_whenCreated_thenStoresReason() {
        let reason = "Referenced by other entities"
        let error = RepositoryError.deleteFailed(reason: reason)

        if case .deleteFailed(let storedReason) = error {
            #expect(storedReason == reason)
        } else {
            Issue.record("Expected deleteFailed case")
        }
    }

    @Test("deleteFailed provides localized error description")
    func test_deleteFailed_whenAccessed_thenProvidesErrorDescription() {
        let reason = "Constraint violation"
        let error = RepositoryError.deleteFailed(reason: reason)

        let description = error.errorDescription
        #expect(description != nil)
        #expect(description?.contains(reason) == true)
        #expect(description?.contains("eliminar datos") == true)
    }

    // MARK: - connectionError Tests

    @Test("connectionError case creates error with reason string")
    func test_connectionError_whenCreatedWithReason_thenStoresIt() {
        let reason = "Connection refused"
        let error = RepositoryError.connectionError(reason: reason)

        if case .connectionError(let storedReason) = error {
            #expect(storedReason == reason)
        } else {
            Issue.record("Expected connectionError case")
        }
    }

    @Test("connectionError provides localized error description")
    func test_connectionError_whenAccessed_thenProvidesErrorDescription() {
        let reason = "DNS resolution failed"
        let error = RepositoryError.connectionError(reason: reason)

        let description = error.errorDescription
        #expect(description != nil)
        #expect(description?.contains("conexión") == true)
        #expect(description?.contains(reason) == true)
    }

    @Test("connectionError is Sendable compliant with String parameter")
    func test_connectionError_whenUsedAcrossActorBoundaries_thenIsSendable() async {
        let error = RepositoryError.connectionError(reason: "Network timeout")

        let sendableError: Sendable = error
        #expect(sendableError is RepositoryError)

        if case .connectionError(let reason) = error {
            #expect(reason == "Network timeout")
        }
    }

    // MARK: - serializationError Tests

    @Test("serializationError case creates error with type")
    func test_serializationError_whenCreated_thenStoresType() {
        let type = "Student"
        let error = RepositoryError.serializationError(type: type)

        if case .serializationError(let storedType) = error {
            #expect(storedType == type)
        } else {
            Issue.record("Expected serializationError case")
        }
    }

    @Test("serializationError provides localized error description")
    func test_serializationError_whenAccessed_thenProvidesErrorDescription() {
        let type = "Course"
        let error = RepositoryError.serializationError(type: type)

        let description = error.errorDescription
        #expect(description != nil)
        #expect(description?.contains(type) == true)
        #expect(description?.contains("serialización") == true)
    }

    // MARK: - dataInconsistency Tests

    @Test("dataInconsistency case creates error with description")
    func test_dataInconsistency_whenCreated_thenStoresDescription() {
        let description = "Duplicate primary keys"
        let error = RepositoryError.dataInconsistency(description: description)

        if case .dataInconsistency(let storedDescription) = error {
            #expect(storedDescription == description)
        } else {
            Issue.record("Expected dataInconsistency case")
        }
    }

    @Test("dataInconsistency provides localized error description")
    func test_dataInconsistency_whenAccessed_thenProvidesErrorDescription() {
        let inconsistency = "Foreign key violation"
        let error = RepositoryError.dataInconsistency(description: inconsistency)

        let description = error.errorDescription
        #expect(description != nil)
        #expect(description?.contains(inconsistency) == true)
        #expect(description?.contains("Inconsistencia") == true)
    }

    // MARK: - Pattern Matching Tests

    @Test("Pattern matching extracts associated values correctly")
    func test_patternMatching_whenMatchingCases_thenExtractsValues() {
        let errors: [RepositoryError] = [
            .fetchFailed(reason: "Not found"),
            .saveFailed(reason: "Conflict"),
            .deleteFailed(reason: "Referenced"),
            .connectionError(reason: "Network error"),
            .serializationError(type: "User"),
            .dataInconsistency(description: "Duplicate")
        ]

        for error in errors {
            switch error {
            case .fetchFailed(let reason):
                #expect(!reason.isEmpty)
            case .saveFailed(let reason):
                #expect(!reason.isEmpty)
            case .deleteFailed(let reason):
                #expect(!reason.isEmpty)
            case .connectionError(let reason):
                #expect(!reason.isEmpty)
            case .serializationError(let type):
                #expect(!type.isEmpty)
            case .dataInconsistency(let description):
                #expect(!description.isEmpty)
            }
        }
    }

    // MARK: - Edge Cases

    @Test("Error with empty strings still provides valid messages")
    func test_errorWithEmptyStrings_whenCreated_thenStillProvidesValidMessages() {
        let error = RepositoryError.fetchFailed(reason: "")

        #expect(error.errorDescription != nil)
        #expect(error.failureReason != nil)
        #expect(error.recoverySuggestion != nil)
    }

    @Test("All error cases provide non-nil localized messages")
    func test_allCases_whenAccessed_thenProvideNonNilLocalizedMessages() {
        let errors: [RepositoryError] = [
            .fetchFailed(reason: "Test"),
            .saveFailed(reason: "Test"),
            .deleteFailed(reason: "Test"),
            .connectionError(reason: "Test connection error"),
            .serializationError(type: "Test"),
            .dataInconsistency(description: "Test")
        ]

        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(error.failureReason != nil)
            #expect(error.recoverySuggestion != nil)
        }
    }
}
