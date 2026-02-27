// MutationQueue.swift
// EduDomain
//
// Cola de mutaciones offline con persistencia y deduplicación.

import Foundation
import EduCore

/// Error al encolar una mutación.
public enum MutationQueueError: Error, Sendable {
    /// Se alcanzó el máximo de mutaciones pendientes.
    case queueFull(max: Int)
}

/// Actor que gestiona una cola FIFO de mutaciones pendientes
/// para sincronización offline.
///
/// Características:
/// - Deduplicación: mismo endpoint + method reemplaza la anterior
/// - Límite: máximo 50 mutaciones pendientes
/// - Persistencia: guarda/restaura desde UserDefaults
/// - AsyncStream para observar conteo de pendientes
public actor MutationQueue {

    /// Máximo de mutaciones permitidas en la cola.
    public static let maxMutations = 50

    // MARK: - Storage

    private var mutations: [PendingMutation] = []
    private let storageKey = "com.edugo.mutation.queue"

    // MARK: - Stream

    private var countContinuation: AsyncStream<Int>.Continuation?
    private var _pendingCountStream: AsyncStream<Int>?

    /// Número actual de mutaciones pendientes.
    public var pendingCount: Int { mutations.count }

    /// Stream para observar cambios en el conteo de mutaciones pendientes.
    public var pendingCountStream: AsyncStream<Int> {
        if _pendingCountStream == nil {
            let (stream, continuation) = AsyncStream<Int>.makeStream(
                bufferingPolicy: .unbounded
            )
            self._pendingCountStream = stream
            self.countContinuation = continuation
        }
        return _pendingCountStream!
    }

    // MARK: - Initialization

    public init() {
        self.mutations = Self.loadFromStorage(key: "com.edugo.mutation.queue")
    }

    // MARK: - Queue Operations

    /// Encola una nueva mutación. Si ya existe una con el mismo endpoint + method, la reemplaza.
    ///
    /// - Parameter mutation: La mutación a encolar.
    /// - Throws: `MutationQueueError.queueFull` si se alcanzó el máximo.
    public func enqueue(_ mutation: PendingMutation) throws {
        // Dedup: reemplazar si mismo endpoint + method
        if let existingIndex = mutations.firstIndex(where: {
            $0.endpoint == mutation.endpoint && $0.method == mutation.method
        }) {
            mutations[existingIndex] = mutation
        } else {
            guard mutations.count < Self.maxMutations else {
                throw MutationQueueError.queueFull(max: Self.maxMutations)
            }
            mutations.append(mutation)
        }

        persist()
        emitCount()
    }

    /// Obtiene la siguiente mutación pendiente sin removerla.
    ///
    /// - Returns: La primera mutación con status `.pending`, o `nil` si no hay ninguna.
    public func dequeue() -> PendingMutation? {
        mutations.first { $0.status == .pending }
    }

    /// Marca una mutación como en proceso de sincronización.
    public func markSyncing(id: String) {
        updateStatus(id: id, status: .syncing)
    }

    /// Marca una mutación como completada y la remueve de la cola.
    public func markCompleted(id: String) {
        mutations.removeAll { $0.id == id }
        persist()
        emitCount()
    }

    /// Marca una mutación como fallida.
    public func markFailed(id: String) {
        updateStatus(id: id, status: .failed)
    }

    /// Marca una mutación como en conflicto.
    public func markConflicted(id: String) {
        updateStatus(id: id, status: .conflicted)
    }

    /// Incrementa el retry count de una mutación.
    ///
    /// - Returns: `true` si aún no se alcanzó maxRetries, `false` si se excedió.
    @discardableResult
    public func incrementRetry(id: String) -> Bool {
        guard let index = mutations.firstIndex(where: { $0.id == id }) else {
            return false
        }

        mutations[index].retryCount += 1

        if mutations[index].retryCount >= mutations[index].maxRetries {
            mutations[index].status = .failed
            persist()
            emitCount()
            return false
        }

        mutations[index].status = .pending
        persist()
        emitCount()
        return true
    }

    /// Retorna todas las mutaciones con status `.pending`.
    public func allPending() -> [PendingMutation] {
        mutations.filter { $0.status == .pending }
    }

    /// Limpia toda la cola.
    public func clear() {
        mutations.removeAll()
        persist()
        emitCount()
    }

    // MARK: - Private

    private func updateStatus(id: String, status: MutationStatus) {
        guard let index = mutations.firstIndex(where: { $0.id == id }) else { return }
        mutations[index].status = status
        persist()
        emitCount()
    }

    private func emitCount() {
        countContinuation?.yield(mutations.count)
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(mutations) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private static func loadFromStorage(key: String) -> [PendingMutation] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let mutations = try? JSONDecoder().decode([PendingMutation].self, from: data) else {
            return []
        }
        return mutations
    }
}
