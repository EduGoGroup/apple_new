// ConflictResolver.swift
// EduDomain
//
// Resuelve conflictos entre mutaciones offline y errores del servidor.

import Foundation
import EduInfrastructure

/// Resuelve conflictos entre mutaciones offline pendientes y errores del servidor.
///
/// Estrategia:
/// - 404 (Not Found) → `.skipSilently` (entidad eliminada en servidor)
/// - 409 (Conflict) → `.applyLocal` (last-write-wins)
/// - 400 (Bad Request) → `.fail` (datos inválidos)
/// - 5xx (Server Error) → `.retry` (error temporal del servidor)
/// - Timeout → `.retry`
/// - Network failure → `.retry`
/// - Otros → `.fail`
public struct OfflineConflictResolver: Sendable {

    /// Resuelve el conflicto entre una mutación pendiente y el error del servidor.
    ///
    /// - Parameters:
    ///   - mutation: La mutación que generó el error.
    ///   - serverError: El error recibido del servidor.
    /// - Returns: La resolución a aplicar.
    public static func resolve(
        mutation: PendingMutation,
        serverError: NetworkError
    ) -> OfflineConflictResolution {
        switch serverError {
        case .notFound:
            return .skipSilently

        case .serverError(let statusCode, _):
            switch statusCode {
            case 409:
                return .applyLocal
            case 400:
                return .fail
            case 500...599:
                return .retry
            default:
                return .fail
            }

        case .timeout, .networkFailure:
            return .retry

        default:
            return .fail
        }
    }
}
