// PendingMutation.swift
// EduDomain
//
// Modelo de una mutación pendiente para sincronización offline.

import Foundation
import EduCore

/// Representa una operación de escritura (POST/PUT/DELETE) capturada offline
/// para ser sincronizada cuando la conexión se restaure.
public struct PendingMutation: Codable, Sendable, Identifiable {

    /// Identificador único de la mutación.
    public let id: String

    /// Endpoint del API (e.g. "/api/v1/users/123").
    public let endpoint: String

    /// Método HTTP: POST, PUT o DELETE.
    public let method: String

    /// Body de la petición como JSONValue.
    public let body: JSONValue

    /// Momento en que se creó la mutación.
    public let createdAt: Date

    /// Número de reintentos ejecutados.
    public var retryCount: Int

    /// Máximo de reintentos permitidos.
    public let maxRetries: Int

    /// Estado actual de la mutación.
    public var status: MutationStatus

    /// Timestamp de última actualización de la entidad (para detección de conflictos).
    public let entityUpdatedAt: String?

    public init(
        id: String = UUID().uuidString,
        endpoint: String,
        method: String,
        body: JSONValue,
        createdAt: Date = Date(),
        retryCount: Int = 0,
        maxRetries: Int = 3,
        status: MutationStatus = .pending,
        entityUpdatedAt: String? = nil
    ) {
        self.id = id
        self.endpoint = endpoint
        self.method = method
        self.body = body
        self.createdAt = createdAt
        self.retryCount = retryCount
        self.maxRetries = maxRetries
        self.status = status
        self.entityUpdatedAt = entityUpdatedAt
    }

    // MARK: - CodingKeys

    private enum CodingKeys: String, CodingKey {
        case id
        case endpoint
        case method
        case body
        case createdAt = "created_at"
        case retryCount = "retry_count"
        case maxRetries = "max_retries"
        case status
        case entityUpdatedAt = "entity_updated_at"
    }
}
