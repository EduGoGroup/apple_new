// SyncEngineTests.swift
// EduDomainTests

import Testing
import Foundation
@testable import EduDomain
import EduCore
import EduInfrastructure

// MARK: - Mock NetworkClient

final class OfflineMockNetworkClient: NetworkClientProtocol, @unchecked Sendable {
    var requestDataResults: [Result<(Data, HTTPURLResponse), Error>] = []
    private var callIndex = 0

    func request<T: Decodable & Sendable>(_ request: HTTPRequest) async throws -> T {
        let (data, _) = try await requestData(request)
        return try JSONDecoder().decode(T.self, from: data)
    }

    func requestData(_ request: HTTPRequest) async throws -> (Data, HTTPURLResponse) {
        guard callIndex < requestDataResults.count else {
            throw NetworkError.noData
        }
        let result = requestDataResults[callIndex]
        callIndex += 1
        return try result.get()
    }

    func upload<T: Decodable & Sendable>(data: Data, request: HTTPRequest) async throws -> T {
        throw NetworkError.noData
    }

    func upload<T: Decodable & Sendable>(fileURL: URL, request: HTTPRequest) async throws -> T {
        throw NetworkError.noData
    }

    func download(_ request: HTTPRequest) async throws -> URL {
        throw NetworkError.noData
    }

    func downloadData(_ request: HTTPRequest) async throws -> Data {
        throw NetworkError.noData
    }
}

// MARK: - Tests

@Suite("SyncEngine Tests")
struct SyncEngineTests {

    private func makeSuccessResponse() -> (Data, HTTPURLResponse) {
        let data = "{}".data(using: .utf8)!
        let response = HTTPURLResponse(
            url: URL(string: "https://test.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        return (data, response)
    }

    @Test("Initial state is idle")
    func initialState() async {
        let queue = MutationQueue()
        await queue.clear()
        let client = OfflineMockNetworkClient()
        let engine = SyncEngine(mutationQueue: queue, networkClient: client)

        let state = await engine.syncState
        #expect(state == .idle)
    }

    @Test("ProcessQueue completes with empty queue")
    func processEmptyQueue() async {
        let queue = MutationQueue()
        await queue.clear()
        let client = OfflineMockNetworkClient()
        let engine = SyncEngine(mutationQueue: queue, networkClient: client)

        await engine.processQueue()

        let state = await engine.syncState
        #expect(state == .completed)
    }

    @Test("ProcessQueue succeeds with one mutation")
    func processOneMutation() async throws {
        let queue = MutationQueue()
        await queue.clear()

        let mutation = PendingMutation(
            id: "m1",
            endpoint: "https://api.test.com/users",
            method: "POST",
            body: .object(["name": .string("Test")])
        )
        try await queue.enqueue(mutation)

        let client = OfflineMockNetworkClient()
        client.requestDataResults = [.success(makeSuccessResponse())]

        let engine = SyncEngine(mutationQueue: queue, networkClient: client)
        await engine.processQueue()

        let state = await engine.syncState
        #expect(state == .completed)

        let pendingCount = await queue.pendingCount
        #expect(pendingCount == 0)
    }

    @Test("ProcessQueue marks failed on permanent error")
    func processWithPermanentError() async throws {
        let queue = MutationQueue()
        await queue.clear()

        let mutation = PendingMutation(
            id: "m1",
            endpoint: "https://api.test.com/users",
            method: "POST",
            body: .null
        )
        try await queue.enqueue(mutation)

        let client = OfflineMockNetworkClient()
        client.requestDataResults = [.failure(NetworkError.unauthorized)]

        let engine = SyncEngine(mutationQueue: queue, networkClient: client)
        await engine.processQueue()

        let state = await engine.syncState
        #expect(state == .completed)
    }

    @Test("ProcessQueue handles 404 by skipping silently")
    func processWithNotFound() async throws {
        let queue = MutationQueue()
        await queue.clear()

        let mutation = PendingMutation(
            id: "m1",
            endpoint: "https://api.test.com/users/999",
            method: "PUT",
            body: .null
        )
        try await queue.enqueue(mutation)

        let client = OfflineMockNetworkClient()
        client.requestDataResults = [.failure(NetworkError.notFound)]

        let engine = SyncEngine(mutationQueue: queue, networkClient: client)
        await engine.processQueue()

        let state = await engine.syncState
        #expect(state == .completed)

        // 404 → skipSilently → markCompleted
        let pendingCount = await queue.pendingCount
        #expect(pendingCount == 0)
    }

    @Test("BuildHTTPRequest maps methods correctly")
    func buildHTTPRequest() {
        let postMutation = PendingMutation(
            endpoint: "https://api.test.com/users",
            method: "POST",
            body: .string("test")
        )
        let postRequest = SyncEngine.buildHTTPRequest(from: postMutation)
        #expect(postRequest.method == .post)

        let putMutation = PendingMutation(
            endpoint: "https://api.test.com/users/1",
            method: "PUT",
            body: .null
        )
        let putRequest = SyncEngine.buildHTTPRequest(from: putMutation)
        #expect(putRequest.method == .put)

        let deleteMutation = PendingMutation(
            endpoint: "https://api.test.com/users/1",
            method: "DELETE",
            body: .null
        )
        let deleteRequest = SyncEngine.buildHTTPRequest(from: deleteMutation)
        #expect(deleteRequest.method == .delete)
    }

    @Test("BackoffDelay calculates exponential values")
    func backoffDelay() {
        #expect(SyncEngine.backoffDelay(retryCount: 1) == 1.0)
        #expect(SyncEngine.backoffDelay(retryCount: 2) == 2.0)
        #expect(SyncEngine.backoffDelay(retryCount: 3) == 4.0)
        #expect(SyncEngine.backoffDelay(retryCount: 4) == 8.0)
    }
}
