// SyncState.swift
// EduDomain
//
// State machine for sync operations.

import Foundation

/// Estado actual del proceso de sincronización del bundle.
///
/// Representa las transiciones posibles:
/// ```
/// idle → syncing → completed
///                 → error(Error)
/// error → syncing (retry)
/// completed → syncing (re-sync)
/// ```
public enum BundleSyncState: Sendable, Equatable {
    /// Sin actividad de sincronización.
    case idle

    /// Sincronización en progreso.
    case syncing

    /// Sincronización completada exitosamente.
    case completed

    /// Sincronización falló con un error.
    case error(SyncError)

    /// Verifica si la transición a un nuevo estado es válida.
    static func isValidTransition(from current: BundleSyncState, to next: BundleSyncState) -> Bool {
        switch (current, next) {
        case (.idle, .syncing),
             (.completed, .syncing),
             (.error, .syncing),
             (.syncing, .completed),
             (.syncing, .error):
            return true
        default:
            return false
        }
    }
}

// MARK: - SyncError

/// Errores específicos del proceso de sincronización.
public enum SyncError: Error, Sendable, Equatable {
    /// Error de red durante la sincronización.
    case networkFailure(String)

    /// Los datos recibidos son inválidos o corruptos.
    case invalidData(String)

    /// Error al persistir datos localmente.
    case storageFailed(String)

    /// Error al decodificar la respuesta del servidor.
    case decodingFailed(String)
}

// MARK: - LocalizedError

extension SyncError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .networkFailure(let detail):
            return "Error de red durante sincronización: \(detail)"
        case .invalidData(let detail):
            return "Datos inválidos: \(detail)"
        case .storageFailed(let detail):
            return "Error de almacenamiento: \(detail)"
        case .decodingFailed(let detail):
            return "Error de decodificación: \(detail)"
        }
    }
}
