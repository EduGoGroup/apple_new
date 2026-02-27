// ConflictResolution.swift
// EduDomain
//
// Resultado de la resolución de conflictos offline.

import Foundation

/// Resultado de la resolución de un conflicto entre una mutación local y el servidor.
public enum OfflineConflictResolution: Sendable, Equatable {
    /// La mutación local gana (last-write-wins).
    case applyLocal
    /// Ignorar silenciosamente (entidad eliminada en servidor).
    case skipSilently
    /// Reintentar más tarde.
    case retry
    /// Fallo permanente, no reintentar.
    case fail
}
