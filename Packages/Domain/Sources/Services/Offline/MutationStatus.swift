// MutationStatus.swift
// EduDomain
//
// Estado de una mutación pendiente en la cola offline.

import Foundation

/// Estado de una mutación pendiente en la cola de sincronización offline.
public enum MutationStatus: String, Codable, Sendable {
    /// Esperando a ser procesada.
    case pending
    /// Siendo enviada al servidor.
    case syncing
    /// Fallo al intentar sincronizar (puede reintentar).
    case failed
    /// Conflicto detectado con el servidor.
    case conflicted
}
