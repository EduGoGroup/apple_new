import Foundation

// MARK: - SyncProgressCommand

/// Command para sincronizar el progreso de un estudiante.
///
/// Este command encapsula los datos necesarios para sincronizar
/// el progreso de aprendizaje entre el almacenamiento local y remoto,
/// con estrategias de resolución de conflictos.
///
/// ## Validaciones
/// - UserId no puede ser nil
/// - ConflictStrategy debe ser válida
///
/// ## Eventos Emitidos
/// - `ProgressSyncedEvent`: Cuando la sincronización se completa
///
/// ## Ejemplo de Uso
/// ```swift
/// let command = SyncProgressCommand(
///     userId: studentId,
///     forceFullSync: false,
///     conflictStrategy: .mostRecent
/// )
///
/// let result = try await mediator.execute(command)
/// if result.isSuccess, let output = result.getValue() {
///     print("Sincronizados: \(output.syncedItems.count)")
///     if !output.conflicts.isEmpty {
///         // Mostrar conflictos para resolución manual
///     }
/// }
/// ```
public struct SyncProgressCommand: Command {

    public typealias Result = SyncProgressOutput

    // MARK: - Properties

    /// ID del usuario cuyo progreso se sincroniza
    public let userId: UUID

    /// Forzar sincronización completa ignorando lastSyncTimestamp
    public let forceFullSync: Bool

    /// Estrategia de resolución de conflictos
    public let conflictStrategy: ConflictResolutionStrategy

    /// Metadata opcional para tracing
    public let metadata: [String: String]?

    // MARK: - Initialization

    /// Crea un nuevo command para sincronizar progreso.
    ///
    /// - Parameters:
    ///   - userId: ID del usuario cuyo progreso se sincroniza
    ///   - forceFullSync: Forzar sync completa (default: false)
    ///   - conflictStrategy: Estrategia de conflictos (default: mostRecent)
    ///   - metadata: Metadata opcional
    public init(
        userId: UUID,
        forceFullSync: Bool = false,
        conflictStrategy: ConflictResolutionStrategy = .mostRecent,
        metadata: [String: String]? = nil
    ) {
        self.userId = userId
        self.forceFullSync = forceFullSync
        self.conflictStrategy = conflictStrategy
        self.metadata = metadata
    }

    // MARK: - Command Protocol

    /// Valida el command antes de la ejecución.
    ///
    /// Las validaciones de negocio se realizan en el handler/use case.
    ///
    /// - Throws: `ValidationError` si alguna validación falla
    public func validate() throws {
        // Validaciones básicas de formato ya se garantizan por tipos
        // Validaciones de negocio se delegan al handler
    }
}

// MARK: - SyncProgressCommandHandler

/// Handler que procesa SyncProgressCommand usando SyncProgressUseCase.
///
/// Coordina el proceso de sincronización de progreso, detecta y resuelve
/// conflictos, emite eventos e invalida caches relacionados.
///
/// ## Responsabilidades
/// 1. Ejecutar SyncProgressUseCase
/// 2. Emitir ProgressSyncedEvent
/// 3. Invalidar cache de ProgressReadModel si hay cambios
/// 4. Envolver resultado en CommandResult
///
/// ## Ejemplo de Uso
/// ```swift
/// let handler = SyncProgressCommandHandler(
///     useCase: syncProgressUseCase,
///     eventBus: eventBus
/// )
/// try await mediator.registerCommandHandler(handler)
/// ```
public actor SyncProgressCommandHandler: CommandHandler {

    public typealias CommandType = SyncProgressCommand

    // MARK: - Dependencies

    private let useCase: any SyncProgressUseCaseProtocol

    /// EventBus para publicar eventos
    private let eventBus: EventBus?

    // MARK: - Initialization

    /// Crea un nuevo handler para SyncProgressCommand.
    ///
    /// - Parameters:
    ///   - useCase: Use case que ejecuta la sincronización
    ///   - eventBus: Bus de eventos para publicar (opcional)
    public init(
        useCase: any SyncProgressUseCaseProtocol,
        eventBus: EventBus? = nil
    ) {
        self.useCase = useCase
        self.eventBus = eventBus
    }

    // MARK: - CommandHandler Protocol

    /// Procesa el command y retorna el resultado.
    ///
    /// - Parameter command: Command con datos de la sincronización
    /// - Returns: CommandResult con SyncProgressOutput y eventos emitidos
    /// - Throws: Error si falla la sincronización
    public func handle(_ command: SyncProgressCommand) async throws -> CommandResult<SyncProgressOutput> {
        // Crear input para el use case
        let input = SyncProgressInput(
            userId: command.userId,
            forceFullSync: command.forceFullSync,
            conflictStrategy: command.conflictStrategy
        )

        // Ejecutar use case
        do {
            let output = try await useCase.execute(input: input)

            // Crear y publicar evento
            let event = ProgressSyncedEvent(
                userId: command.userId,
                output: output,
                additionalMetadata: command.metadata ?? [:]
            )

            // Publicar evento si hay eventBus
            if let eventBus = eventBus {
                await eventBus.publish(event)
            }

            // Preparar eventos emitidos
            var events = ["ProgressSyncedEvent"]
            if !output.syncedItems.isEmpty {
                events.append("ProgressCacheInvalidatedEvent")
            }
            if !output.conflicts.isEmpty {
                events.append("ProgressConflictsDetectedEvent")
            }

            // Determinar estado de éxito
            let isPartialSuccess = !output.pendingRetry.isEmpty || !output.conflicts.isEmpty

            // Crear metadata del resultado
            let resultMetadata: [String: String] = [
                "userId": command.userId.uuidString,
                "syncedItemsCount": "\(output.syncedItems.count)",
                "conflictsCount": "\(output.conflicts.count)",
                "pendingRetryCount": "\(output.pendingRetry.count)",
                "pushedCount": "\(output.metadata.pushedCount)",
                "pulledCount": "\(output.metadata.pulledCount)",
                "durationSeconds": String(format: "%.3f", output.metadata.durationSeconds),
                "wasIncremental": output.metadata.wasIncremental ? "true" : "false",
                "conflictStrategy": command.conflictStrategy.rawValue,
                "isPartialSuccess": isPartialSuccess ? "true" : "false",
                "syncedAt": ISO8601DateFormatter().string(from: output.syncedAt)
            ]

            return .success(
                output,
                events: events,
                metadata: resultMetadata
            )

        } catch let error as SyncProgressError {
            return .failure(
                error,
                metadata: [
                    "userId": command.userId.uuidString,
                    "errorType": String(describing: error),
                    "forceFullSync": command.forceFullSync ? "true" : "false",
                    "conflictStrategy": command.conflictStrategy.rawValue
                ]
            )
        } catch {
            return .failure(
                error,
                metadata: [
                    "userId": command.userId.uuidString,
                    "errorDescription": error.localizedDescription,
                    "forceFullSync": command.forceFullSync ? "true" : "false",
                    "conflictStrategy": command.conflictStrategy.rawValue
                ]
            )
        }
    }
}
