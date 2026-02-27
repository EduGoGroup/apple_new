// ConnectivitySyncManager.swift
// EduDomain
//
// Coordina la sincronización automática ante cambios de conectividad.

import Foundation
import EduInfrastructure

/// Actor que coordina la sincronización automática basada en cambios de conectividad.
///
/// Responsabilidades:
/// - Observa `NetworkObserver.statusStream`
/// - Cuando cambia de offline → online:
///   1. Procesa la cola de mutaciones via `SyncEngine`
///   2. Ejecuta delta sync via `SyncService`
///   3. Notifica a la UI para recargar
/// - Cuando cambia de online → offline:
///   1. Notifica a la UI para mostrar banner offline
public actor ConnectivitySyncManager {

    // MARK: - Dependencies

    private let networkObserver: NetworkObserver
    private let syncEngine: SyncEngine
    private let syncService: SyncService

    // MARK: - State

    private var observationTask: Task<Void, Never>?

    /// Indica si actualmente hay conexión de red.
    public private(set) var isOnline: Bool = false

    // MARK: - Stream

    private var onlineContinuation: AsyncStream<Bool>.Continuation?
    private var _isOnlineStream: AsyncStream<Bool>?

    /// Stream para observar cambios de conectividad (true = online, false = offline).
    public var isOnlineStream: AsyncStream<Bool> {
        if _isOnlineStream == nil {
            let (stream, continuation) = AsyncStream<Bool>.makeStream(
                bufferingPolicy: .unbounded
            )
            self._isOnlineStream = stream
            self.onlineContinuation = continuation
        }
        return _isOnlineStream!
    }

    // MARK: - Initialization

    public init(
        networkObserver: NetworkObserver,
        syncEngine: SyncEngine,
        syncService: SyncService
    ) {
        self.networkObserver = networkObserver
        self.syncEngine = syncEngine
        self.syncService = syncService
    }

    // MARK: - Observation

    /// Inicia la observación de cambios de conectividad.
    public func startObserving() async {
        await networkObserver.start()
        isOnline = await networkObserver.isOnline
        onlineContinuation?.yield(isOnline)

        observationTask = Task { [weak self] in
            guard let self else { return }
            let stream = await self.networkObserver.statusStream

            for await status in stream {
                guard !Task.isCancelled else { break }
                await self.handleStatusChange(status)
            }
        }
    }

    /// Detiene la observación de conectividad.
    public func stopObserving() {
        observationTask?.cancel()
        observationTask = nil
        onlineContinuation?.finish()
        onlineContinuation = nil
        _isOnlineStream = nil
    }

    // MARK: - Private

    private func handleStatusChange(_ status: NetworkStatus) async {
        let wasOnline = isOnline
        let nowOnline = status == .available

        isOnline = nowOnline
        onlineContinuation?.yield(nowOnline)

        if !wasOnline && nowOnline {
            await handleReconnection()
        }
    }

    private func handleReconnection() async {
        // 1. Procesar cola de mutaciones pendientes
        await syncEngine.processQueue()

        // 2. Delta sync con el backend
        if let bundle = await syncService.currentBundle {
            _ = try? await syncService.deltaSync(currentHashes: bundle.hashes)
        }
    }
}
