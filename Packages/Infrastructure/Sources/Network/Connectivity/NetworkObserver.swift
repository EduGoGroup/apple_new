// NetworkObserver.swift
// EduNetwork
//
// Actor que observa cambios de conectividad via NWPathMonitor.

import Foundation
import Network

/// Actor que monitorea el estado de la conexión de red usando `NWPathMonitor`.
///
/// Expone el estado actual y un `AsyncStream` para observar cambios reactivamente.
///
/// ## Ejemplo de uso
/// ```swift
/// let observer = NetworkObserver()
/// await observer.start()
///
/// for await status in await observer.statusStream {
///     switch status {
///     case .available: print("Online")
///     case .unavailable: print("Offline")
///     case .losing: print("Losing connection")
///     }
/// }
/// ```
public actor NetworkObserver {

    // MARK: - Properties

    private var monitor: NWPathMonitor?
    private let monitorQueue: DispatchQueue

    /// Estado actual de la conexión de red.
    public private(set) var status: NetworkStatus = .unavailable

    /// Indica si la red está disponible.
    public var isOnline: Bool { status == .available }

    // MARK: - Stream

    private var continuation: AsyncStream<NetworkStatus>.Continuation?
    private var _statusStream: AsyncStream<NetworkStatus>?

    /// Stream para observar cambios de estado de conectividad.
    public var statusStream: AsyncStream<NetworkStatus> {
        if _statusStream == nil {
            let (stream, continuation) = AsyncStream<NetworkStatus>.makeStream(
                bufferingPolicy: .unbounded
            )
            self._statusStream = stream
            self.continuation = continuation
        }
        return _statusStream!
    }

    // MARK: - Initialization

    public init() {
        self.monitorQueue = DispatchQueue(label: "com.edugo.network.monitor", qos: .utility)
    }

    // MARK: - Lifecycle

    /// Inicia el monitoreo de conectividad.
    public func start() {
        guard monitor == nil else { return }

        let newMonitor = NWPathMonitor()
        self.monitor = newMonitor

        newMonitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            Task { await self.handlePathUpdate(path) }
        }

        newMonitor.start(queue: monitorQueue)
    }

    /// Detiene el monitoreo de conectividad.
    public func stop() {
        monitor?.cancel()
        monitor = nil
        continuation?.finish()
        continuation = nil
        _statusStream = nil
    }

    // MARK: - Private

    private func handlePathUpdate(_ path: NWPath) {
        let newStatus: NetworkStatus = switch path.status {
        case .satisfied:
            .available
        case .requiresConnection:
            .losing
        case .unsatisfied:
            .unavailable
        @unknown default:
            .unavailable
        }

        guard newStatus != status else { return }
        status = newStatus
        continuation?.yield(newStatus)
    }
}
