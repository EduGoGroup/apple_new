// ConflictResolverTests.swift
// EduDomainTests

import Testing
import Foundation
@testable import EduDomain
import EduCore
import EduInfrastructure

@Suite("ConflictResolver Tests")
struct ConflictResolverTests {

    private func makeMutation() -> PendingMutation {
        PendingMutation(
            endpoint: "/api/v1/test",
            method: "POST",
            body: .null
        )
    }

    @Test("404 Not Found resolves to skipSilently")
    func notFoundSkips() {
        let resolution = OfflineConflictResolver.resolve(
            mutation: makeMutation(),
            serverError: .notFound
        )
        #expect(resolution == .skipSilently)
    }

    @Test("409 Conflict resolves to applyLocal")
    func conflictAppliesLocal() {
        let resolution = OfflineConflictResolver.resolve(
            mutation: makeMutation(),
            serverError: .serverError(statusCode: 409, message: "Conflict")
        )
        #expect(resolution == .applyLocal)
    }

    @Test("400 Bad Request resolves to fail")
    func badRequestFails() {
        let resolution = OfflineConflictResolver.resolve(
            mutation: makeMutation(),
            serverError: .serverError(statusCode: 400, message: "Bad Request")
        )
        #expect(resolution == .fail)
    }

    @Test("500 Internal Server Error resolves to retry")
    func serverErrorRetries() {
        let resolution = OfflineConflictResolver.resolve(
            mutation: makeMutation(),
            serverError: .serverError(statusCode: 500, message: nil)
        )
        #expect(resolution == .retry)
    }

    @Test("502 Bad Gateway resolves to retry")
    func badGatewayRetries() {
        let resolution = OfflineConflictResolver.resolve(
            mutation: makeMutation(),
            serverError: .serverError(statusCode: 502, message: nil)
        )
        #expect(resolution == .retry)
    }

    @Test("503 Service Unavailable resolves to retry")
    func serviceUnavailableRetries() {
        let resolution = OfflineConflictResolver.resolve(
            mutation: makeMutation(),
            serverError: .serverError(statusCode: 503, message: nil)
        )
        #expect(resolution == .retry)
    }

    @Test("Timeout resolves to retry")
    func timeoutRetries() {
        let resolution = OfflineConflictResolver.resolve(
            mutation: makeMutation(),
            serverError: .timeout
        )
        #expect(resolution == .retry)
    }

    @Test("Network failure resolves to retry")
    func networkFailureRetries() {
        let resolution = OfflineConflictResolver.resolve(
            mutation: makeMutation(),
            serverError: .networkFailure(underlyingError: "Connection lost")
        )
        #expect(resolution == .retry)
    }

    @Test("Unauthorized resolves to fail")
    func unauthorizedFails() {
        let resolution = OfflineConflictResolver.resolve(
            mutation: makeMutation(),
            serverError: .unauthorized
        )
        #expect(resolution == .fail)
    }

    @Test("Forbidden resolves to fail")
    func forbiddenFails() {
        let resolution = OfflineConflictResolver.resolve(
            mutation: makeMutation(),
            serverError: .forbidden
        )
        #expect(resolution == .fail)
    }

    @Test("Decoding error resolves to fail")
    func decodingErrorFails() {
        let resolution = OfflineConflictResolver.resolve(
            mutation: makeMutation(),
            serverError: .decodingError(type: "Test", underlyingError: "bad json")
        )
        #expect(resolution == .fail)
    }
}
