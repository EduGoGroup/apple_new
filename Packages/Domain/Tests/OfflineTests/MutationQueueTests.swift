// MutationQueueTests.swift
// EduDomainTests

import Testing
import Foundation
@testable import EduDomain
import EduCore

@Suite("MutationQueue Tests")
struct MutationQueueTests {

    private func makeQueue() -> MutationQueue {
        // Limpiar UserDefaults antes de crear la cola para que no cargue datos residuales
        UserDefaults.standard.removeObject(forKey: "com.edugo.mutation.queue")
        return MutationQueue()
    }

    private func makeMutation(
        id: String = UUID().uuidString,
        endpoint: String = "/api/v1/users",
        method: String = "POST",
        body: JSONValue = .object(["name": .string("Test")])
    ) -> PendingMutation {
        PendingMutation(
            id: id,
            endpoint: endpoint,
            method: method,
            body: body
        )
    }

    @Test("Enqueue adds mutation")
    func enqueue() async throws {
        let queue = makeQueue()
        await queue.clear()

        let mutation = makeMutation()
        try await queue.enqueue(mutation)

        let count = await queue.pendingCount
        #expect(count == 1)
    }

    @Test("Dequeue returns first pending mutation")
    func dequeue() async throws {
        let queue = makeQueue()
        await queue.clear()

        let mutation = makeMutation(id: "first")
        try await queue.enqueue(mutation)

        let dequeued = await queue.dequeue()
        #expect(dequeued?.id == "first")
    }

    @Test("Dequeue returns nil for empty queue")
    func dequeueEmpty() async {
        let queue = makeQueue()
        await queue.clear()

        let dequeued = await queue.dequeue()
        #expect(dequeued == nil)
    }

    @Test("Dedup replaces mutation with same endpoint and method")
    func dedup() async throws {
        let queue = makeQueue()
        await queue.clear()

        let mutation1 = makeMutation(id: "v1", endpoint: "/api/v1/users", method: "POST", body: .string("first"))
        let mutation2 = makeMutation(id: "v2", endpoint: "/api/v1/users", method: "POST", body: .string("second"))

        try await queue.enqueue(mutation1)
        try await queue.enqueue(mutation2)

        let count = await queue.pendingCount
        #expect(count == 1)

        let dequeued = await queue.dequeue()
        #expect(dequeued?.id == "v2")
    }

    @Test("Different endpoints are not deduped")
    func noDedupDifferentEndpoints() async throws {
        let queue = makeQueue()
        await queue.clear()

        let mutation1 = makeMutation(endpoint: "/api/v1/users", method: "POST")
        let mutation2 = makeMutation(endpoint: "/api/v1/courses", method: "POST")

        try await queue.enqueue(mutation1)
        try await queue.enqueue(mutation2)

        let count = await queue.pendingCount
        #expect(count == 2)
    }

    @Test("Queue rejects when full (50 mutations)")
    func queueFull() async throws {
        let queue = makeQueue()
        await queue.clear()

        // Llenar la cola con 50 mutaciones distintas
        for i in 0..<50 {
            let mutation = makeMutation(endpoint: "/api/v1/item/\(i)", method: "POST")
            try await queue.enqueue(mutation)
        }

        let count = await queue.pendingCount
        #expect(count == 50)

        // La 51ra debe fallar
        let extraMutation = makeMutation(endpoint: "/api/v1/item/extra", method: "POST")
        do {
            try await queue.enqueue(extraMutation)
            #expect(Bool(false), "Should have thrown")
        } catch is MutationQueueError {
            // Esperado
        }
    }

    @Test("MarkSyncing changes status")
    func markSyncing() async throws {
        let queue = makeQueue()
        await queue.clear()

        let mutation = makeMutation(id: "test")
        try await queue.enqueue(mutation)

        await queue.markSyncing(id: "test")

        // Después de markSyncing, dequeue no debería devolver esta mutación
        let next = await queue.dequeue()
        #expect(next == nil)
    }

    @Test("MarkCompleted removes mutation")
    func markCompleted() async throws {
        let queue = makeQueue()
        await queue.clear()

        let mutation = makeMutation(id: "test")
        try await queue.enqueue(mutation)

        await queue.markCompleted(id: "test")

        let count = await queue.pendingCount
        #expect(count == 0)
    }

    @Test("MarkFailed changes status to failed")
    func markFailed() async throws {
        let queue = makeQueue()
        await queue.clear()

        let mutation = makeMutation(id: "test")
        try await queue.enqueue(mutation)

        await queue.markFailed(id: "test")

        // No debería aparecer como pending
        let pending = await queue.allPending()
        #expect(pending.isEmpty)
    }

    @Test("IncrementRetry returns true until maxRetries reached")
    func incrementRetry() async throws {
        let queue = makeQueue()
        await queue.clear()

        let mutation = PendingMutation(
            id: "retry-test",
            endpoint: "/api/v1/test",
            method: "POST",
            body: .null,
            maxRetries: 3
        )
        try await queue.enqueue(mutation)

        let first = await queue.incrementRetry(id: "retry-test")
        #expect(first == true)

        let second = await queue.incrementRetry(id: "retry-test")
        #expect(second == true)

        let third = await queue.incrementRetry(id: "retry-test")
        #expect(third == false) // maxRetries(3) reached
    }

    @Test("Clear removes all mutations")
    func clear() async throws {
        let queue = makeQueue()
        await queue.clear()

        try await queue.enqueue(makeMutation(endpoint: "/a", method: "POST"))
        try await queue.enqueue(makeMutation(endpoint: "/b", method: "PUT"))

        await queue.clear()

        let count = await queue.pendingCount
        #expect(count == 0)
    }

    @Test("AllPending returns only pending mutations")
    func allPending() async throws {
        let queue = makeQueue()
        await queue.clear()

        try await queue.enqueue(makeMutation(id: "a", endpoint: "/a", method: "POST"))
        try await queue.enqueue(makeMutation(id: "b", endpoint: "/b", method: "POST"))

        await queue.markSyncing(id: "a")

        let pending = await queue.allPending()
        #expect(pending.count == 1)
        #expect(pending.first?.id == "b")
    }
}
