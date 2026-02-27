import Foundation

// MARK: - ProgressSyncedEvent

/// Evento de dominio emitido cuando se completa una sincronización de progreso.
///
/// Este evento captura el resultado de una sincronización de progreso
/// del estudiante entre almacenamiento local y remoto, permitiendo
/// que los suscriptores reaccionen al estado de sincronización.
///
/// ## Información Capturada
/// - Usuario cuyo progreso fue sincronizado
/// - Cantidad de items sincronizados
/// - Conflictos detectados y resueltos
/// - Metadata de la sincronización
///
/// ## Suscriptores Típicos
/// - `CacheInvalidationSubscriber`: Invalida ProgressReadModel
/// - `AnalyticsSubscriber`: Registra métricas de sincronización
/// - `UINotificationSubscriber`: Muestra estado de sync en UI
///
/// ## Ejemplo de Uso
/// ```swift
/// let event = ProgressSyncedEvent(
///     userId: studentId,
///     syncedItemsCount: output.syncedItems.count,
///     conflictsCount: output.conflicts.count,
///     pendingRetryCount: output.pendingRetry.count,
///     strategy: output.resolutionStrategy,
///     metadata: output.metadata
/// )
///
/// await eventBus.publish(event)
/// ```
public struct ProgressSyncedEvent: DomainEvent {

    // MARK: - DomainEvent Properties

    /// Identificador único del evento
    public let eventId: UUID

    /// Timestamp de cuando ocurrió el evento
    public let occurredAt: Date

    /// Metadata adicional para tracing y debugging
    public let metadata: [String: String]

    // MARK: - Event-Specific Properties

    /// ID del usuario cuyo progreso fue sincronizado
    public let userId: UUID

    /// Cantidad de items sincronizados exitosamente
    public let syncedItemsCount: Int

    /// Cantidad de conflictos detectados
    public let conflictsCount: Int

    /// Cantidad de conflictos resueltos automáticamente
    public let autoResolvedCount: Int

    /// Cantidad de items pendientes de retry
    public let pendingRetryCount: Int

    /// Estrategia de resolución de conflictos usada
    public let resolutionStrategy: ConflictResolutionStrategy

    /// Items empujados al servidor
    public let pushedCount: Int

    /// Items descargados del servidor
    public let pulledCount: Int

    /// Duración de la sincronización en segundos
    public let durationSeconds: Double

    /// Si fue sincronización incremental
    public let wasIncremental: Bool

    /// Si la sincronización fue completamente exitosa
    public let wasFullySuccessful: Bool

    // MARK: - DomainEvent Computed Properties

    /// Tipo de evento para routing
    public var eventType: String {
        "progress.synced"
    }

    // MARK: - Initialization

    /// Crea un nuevo evento de sincronización de progreso.
    ///
    /// - Parameters:
    ///   - eventId: ID único del evento (default: generado)
    ///   - occurredAt: Timestamp del evento (default: ahora)
    ///   - userId: ID del usuario cuyo progreso fue sincronizado
    ///   - syncedItemsCount: Items sincronizados exitosamente
    ///   - conflictsCount: Conflictos detectados
    ///   - autoResolvedCount: Conflictos resueltos automáticamente
    ///   - pendingRetryCount: Items pendientes de retry
    ///   - resolutionStrategy: Estrategia de resolución usada
    ///   - pushedCount: Items enviados al servidor
    ///   - pulledCount: Items descargados del servidor
    ///   - durationSeconds: Duración de la sincronización
    ///   - wasIncremental: Si fue sincronización incremental
    ///   - metadata: Metadata adicional
    public init(
        eventId: UUID = UUID(),
        occurredAt: Date = Date(),
        userId: UUID,
        syncedItemsCount: Int,
        conflictsCount: Int,
        autoResolvedCount: Int = 0,
        pendingRetryCount: Int,
        resolutionStrategy: ConflictResolutionStrategy,
        pushedCount: Int,
        pulledCount: Int,
        durationSeconds: Double,
        wasIncremental: Bool,
        metadata: [String: String] = [:]
    ) {
        self.eventId = eventId
        self.occurredAt = occurredAt
        self.userId = userId
        self.syncedItemsCount = syncedItemsCount
        self.conflictsCount = conflictsCount
        self.autoResolvedCount = autoResolvedCount
        self.pendingRetryCount = pendingRetryCount
        self.resolutionStrategy = resolutionStrategy
        self.pushedCount = pushedCount
        self.pulledCount = pulledCount
        self.durationSeconds = durationSeconds
        self.wasIncremental = wasIncremental
        self.wasFullySuccessful = pendingRetryCount == 0 && conflictsCount == 0

        // Enriquecer metadata con información del evento
        var enrichedMetadata = metadata
        enrichedMetadata["userId"] = userId.uuidString
        enrichedMetadata["syncedItemsCount"] = "\(syncedItemsCount)"
        enrichedMetadata["conflictsCount"] = "\(conflictsCount)"
        enrichedMetadata["autoResolvedCount"] = "\(autoResolvedCount)"
        enrichedMetadata["pendingRetryCount"] = "\(pendingRetryCount)"
        enrichedMetadata["resolutionStrategy"] = resolutionStrategy.rawValue
        enrichedMetadata["pushedCount"] = "\(pushedCount)"
        enrichedMetadata["pulledCount"] = "\(pulledCount)"
        enrichedMetadata["durationSeconds"] = String(format: "%.3f", durationSeconds)
        enrichedMetadata["wasIncremental"] = wasIncremental ? "true" : "false"
        enrichedMetadata["wasFullySuccessful"] = self.wasFullySuccessful ? "true" : "false"
        self.metadata = enrichedMetadata
    }

    /// Crea un evento a partir de SyncProgressOutput.
    ///
    /// - Parameters:
    ///   - userId: ID del usuario
    ///   - output: Output del use case de sincronización
    ///   - additionalMetadata: Metadata adicional
    public init(
        userId: UUID,
        output: SyncProgressOutput,
        additionalMetadata: [String: String] = [:]
    ) {
        self.init(
            userId: userId,
            syncedItemsCount: output.syncedItems.count,
            conflictsCount: output.conflicts.count,
            autoResolvedCount: output.metadata.autoResolvedCount,
            pendingRetryCount: output.pendingRetry.count,
            resolutionStrategy: output.resolutionStrategy,
            pushedCount: output.metadata.pushedCount,
            pulledCount: output.metadata.pulledCount,
            durationSeconds: output.metadata.durationSeconds,
            wasIncremental: output.metadata.wasIncremental,
            metadata: additionalMetadata
        )
    }
}

// MARK: - Equatable

extension ProgressSyncedEvent: Equatable {
    public static func == (lhs: ProgressSyncedEvent, rhs: ProgressSyncedEvent) -> Bool {
        lhs.eventId == rhs.eventId
    }
}

// MARK: - CustomStringConvertible

extension ProgressSyncedEvent: CustomStringConvertible {
    public var description: String {
        let status = wasFullySuccessful ? "success" : "partial"
        return "ProgressSyncedEvent(userId: \(userId), synced: \(syncedItemsCount), conflicts: \(conflictsCount), status: \(status))"
    }
}
