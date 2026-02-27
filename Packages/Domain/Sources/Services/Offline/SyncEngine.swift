// SyncEngine.swift
// EduDomain
//
// Motor de sincronización que procesa la cola de mutaciones offline.

import Foundation
import EduCore
import EduInfrastructure

/// Actor que procesa la cola de mutaciones pendientes enviándolas al servidor.
///
/// Maneja reintentos con backoff exponencial y resolución de conflictos.
///
/// ## Ejemplo de uso
/// ```swift
/// let engine = SyncEngine(mutationQueue: queue, networkClient: client)
/// await engine.processQueue()
/// ```
public actor SyncEngine {

    /// Estado del motor de sincronización.
    public enum State: Sendable, Equatable {
        case idle
        case syncing(progress: Double)
        case completed
        case error(String)
    }

    // MARK: - Properties

    private let mutationQueue: MutationQueue
    private let networkClient: any NetworkClientProtocol

    /// Estado actual del engine.
    public private(set) var syncState: State = .idle

    // MARK: - Stream

    private var continuation: AsyncStream<State>.Continuation?
    private var _syncStateStream: AsyncStream<State>?

    /// Stream para observar cambios de estado del engine.
    public var syncStateStream: AsyncStream<State> {
        if _syncStateStream == nil {
            let (stream, continuation) = AsyncStream<State>.makeStream(
                bufferingPolicy: .unbounded
            )
            self._syncStateStream = stream
            self.continuation = continuation
        }
        return _syncStateStream!
    }

    // MARK: - Initialization

    public init(
        mutationQueue: MutationQueue,
        networkClient: any NetworkClientProtocol
    ) {
        self.mutationQueue = mutationQueue
        self.networkClient = networkClient
    }

    // MARK: - Processing

    /// Procesa todas las mutaciones pendientes en la cola.
    ///
    /// Para cada mutación:
    /// 1. Marca como syncing
    /// 2. Envía al servidor
    /// 3. En éxito → marca completed
    /// 4. En error → usa ConflictResolver para decidir
    public func processQueue() async {
        let pending = await mutationQueue.allPending()
        guard !pending.isEmpty else {
            transition(to: .completed)
            return
        }

        transition(to: .syncing(progress: 0))

        let total = Double(pending.count)
        var processed = 0.0

        for mutation in pending {
            guard !Task.isCancelled else {
                transition(to: .idle)
                return
            }

            await mutationQueue.markSyncing(id: mutation.id)

            let success = await processMutation(mutation)
            processed += 1

            if success {
                await mutationQueue.markCompleted(id: mutation.id)
            }

            transition(to: .syncing(progress: processed / total))
        }

        transition(to: .completed)
    }

    // MARK: - Private

    private func processMutation(_ mutation: PendingMutation) async -> Bool {
        do {
            let request = Self.buildHTTPRequest(from: mutation)
            let _ = try await networkClient.requestData(request)
            return true
        } catch let error as NetworkError {
            return await handleError(error, for: mutation)
        } catch {
            await mutationQueue.markFailed(id: mutation.id)
            return false
        }
    }

    private func handleError(_ error: NetworkError, for mutation: PendingMutation) async -> Bool {
        let resolution = OfflineConflictResolver.resolve(mutation: mutation, serverError: error)

        switch resolution {
        case .applyLocal:
            // Reintentar inmediatamente
            do {
                let request = Self.buildHTTPRequest(from: mutation)
                let _ = try await networkClient.requestData(request)
                return true
            } catch {
                await mutationQueue.markFailed(id: mutation.id)
                return false
            }

        case .skipSilently:
            return true

        case .retry:
            let canRetry = await mutationQueue.incrementRetry(id: mutation.id)
            if canRetry {
                let retryCount = mutation.retryCount + 1
                let delay = Self.backoffDelay(retryCount: retryCount)
                try? await Task.sleep(for: .seconds(delay))

                // Reintentar
                do {
                    let request = Self.buildHTTPRequest(from: mutation)
                    let _ = try await networkClient.requestData(request)
                    return true
                } catch {
                    return false
                }
            }
            return false

        case .fail:
            await mutationQueue.markFailed(id: mutation.id)
            return false
        }
    }

    /// Construye un HTTPRequest a partir de una PendingMutation.
    static func buildHTTPRequest(from mutation: PendingMutation) -> HTTPRequest {
        let base: HTTPRequest = switch mutation.method.uppercased() {
        case "POST":
            HTTPRequest.post(mutation.endpoint)
        case "PUT":
            HTTPRequest.put(mutation.endpoint)
        case "DELETE":
            HTTPRequest.delete(mutation.endpoint)
        case "PATCH":
            HTTPRequest.patch(mutation.endpoint)
        default:
            HTTPRequest.post(mutation.endpoint)
        }

        guard let bodyData = try? JSONEncoder().encode(mutation.body) else {
            return base
        }

        return base.jsonBody(bodyData)
    }

    /// Calcula el delay de backoff exponencial: 1s, 2s, 4s...
    static func backoffDelay(retryCount: Int) -> Double {
        pow(2.0, Double(retryCount - 1))
    }

    private func transition(to newState: State) {
        syncState = newState
        continuation?.yield(newState)
    }
}
