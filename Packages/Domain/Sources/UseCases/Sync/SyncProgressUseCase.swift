import Foundation
import EduFoundation

// MARK: - Input/Output Types

/// Input para sincronizar progreso del estudiante.
public struct SyncProgressInput: Sendable, Equatable {
    /// ID del usuario
    public let userId: UUID
    /// Forzar sincronización completa ignorando lastSyncTimestamp
    public let forceFullSync: Bool
    /// Estrategia de resolución de conflictos (default: .mostRecent)
    public let conflictStrategy: ConflictResolutionStrategy

    public init(
        userId: UUID,
        forceFullSync: Bool = false,
        conflictStrategy: ConflictResolutionStrategy = .mostRecent
    ) {
        self.userId = userId
        self.forceFullSync = forceFullSync
        self.conflictStrategy = conflictStrategy
    }
}

/// Estrategias de resolución de conflictos.
public enum ConflictResolutionStrategy: String, Sendable, Equatable, Codable {
    /// Preferir datos locales
    case localWins = "local_wins"
    /// Preferir datos remotos
    case remoteWins = "remote_wins"
    /// Usar el más reciente por timestamp
    case mostRecent = "most_recent"
    /// Retornar conflictos para decisión manual en UI
    case manual = "manual"
}

/// Item de progreso para sincronización.
public struct ProgressItem: Sendable, Equatable, Codable, Identifiable {
    public let id: UUID
    public let materialId: UUID
    public let userId: UUID
    public let percentage: Int
    public let lastUpdated: Date
    public let isSynced: Bool

    public init(
        id: UUID = UUID(),
        materialId: UUID,
        userId: UUID,
        percentage: Int,
        lastUpdated: Date,
        isSynced: Bool = false
    ) {
        self.id = id
        self.materialId = materialId
        self.userId = userId
        self.percentage = percentage
        self.lastUpdated = lastUpdated
        self.isSynced = isSynced
    }

    /// Crea una copia marcada como sincronizada.
    public func markSynced() -> ProgressItem {
        ProgressItem(
            id: id,
            materialId: materialId,
            userId: userId,
            percentage: percentage,
            lastUpdated: lastUpdated,
            isSynced: true
        )
    }
}

/// Conflicto de sincronización detectado.
public struct ProgressConflict: Sendable, Equatable, Codable, Identifiable {
    public let id: UUID
    public let materialId: UUID
    public let localItem: ProgressItem
    public let remoteItem: ProgressItem
    public let detectedAt: Date

    public init(
        id: UUID = UUID(),
        materialId: UUID,
        localItem: ProgressItem,
        remoteItem: ProgressItem,
        detectedAt: Date = Date()
    ) {
        self.id = id
        self.materialId = materialId
        self.localItem = localItem
        self.remoteItem = remoteItem
        self.detectedAt = detectedAt
    }
}

/// Resultado de la sincronización.
public struct SyncProgressOutput: Sendable, Equatable {
    /// Items sincronizados exitosamente
    public let syncedItems: [ProgressItem]
    /// Conflictos detectados (si strategy = .manual)
    public let conflicts: [ProgressConflict]
    /// Estrategia de resolución usada
    public let resolutionStrategy: ConflictResolutionStrategy
    /// Timestamp de la sincronización
    public let syncedAt: Date
    /// Items que fallaron y están en cola para retry
    public let pendingRetry: [ProgressItem]
    /// Metadata de la sincronización
    public let metadata: SyncMetadata

    public init(
        syncedItems: [ProgressItem],
        conflicts: [ProgressConflict] = [],
        resolutionStrategy: ConflictResolutionStrategy,
        syncedAt: Date = Date(),
        pendingRetry: [ProgressItem] = [],
        metadata: SyncMetadata = SyncMetadata()
    ) {
        self.syncedItems = syncedItems
        self.conflicts = conflicts
        self.resolutionStrategy = resolutionStrategy
        self.syncedAt = syncedAt
        self.pendingRetry = pendingRetry
        self.metadata = metadata
    }
}

/// Metadata de sincronización.
public struct SyncMetadata: Sendable, Equatable, Codable {
    /// Items empujados al servidor
    public let pushedCount: Int
    /// Items descargados del servidor
    public let pulledCount: Int
    /// Conflictos resueltos automáticamente
    public let autoResolvedCount: Int
    /// Duración de la sincronización en segundos
    public let durationSeconds: Double
    /// Si fue sincronización incremental
    public let wasIncremental: Bool

    public init(
        pushedCount: Int = 0,
        pulledCount: Int = 0,
        autoResolvedCount: Int = 0,
        durationSeconds: Double = 0,
        wasIncremental: Bool = true
    ) {
        self.pushedCount = pushedCount
        self.pulledCount = pulledCount
        self.autoResolvedCount = autoResolvedCount
        self.durationSeconds = durationSeconds
        self.wasIncremental = wasIncremental
    }
}

// MARK: - Sync State

/// Estado de sincronización persistido.
public struct SyncState: Sendable, Equatable, Codable {
    /// Último timestamp de sincronización exitosa
    public let lastSyncTimestamp: Date?
    /// IDs de items sincronizados
    public let syncedItemIds: Set<UUID>
    /// Items pendientes de retry
    public let pendingRetryItems: [ProgressItem]

    public init(
        lastSyncTimestamp: Date? = nil,
        syncedItemIds: Set<UUID> = [],
        pendingRetryItems: [ProgressItem] = []
    ) {
        self.lastSyncTimestamp = lastSyncTimestamp
        self.syncedItemIds = syncedItemIds
        self.pendingRetryItems = pendingRetryItems
    }
}

// MARK: - Repository Protocols

/// Protocolo del repositorio local de progreso.
public protocol LocalProgressRepositoryProtocol: Sendable {
    /// Obtiene items de progreso locales no sincronizados o modificados desde la última sync.
    func getUnsyncedItems(userId: UUID, since: Date?) async throws -> [ProgressItem]

    /// Guarda items de progreso localmente.
    func saveItems(_ items: [ProgressItem]) async throws

    /// Marca items como sincronizados.
    func markAsSynced(itemIds: [UUID]) async throws

    /// Obtiene el estado de sincronización.
    func getSyncState(userId: UUID) async -> SyncState

    /// Guarda el estado de sincronización.
    func saveSyncState(_ state: SyncState, userId: UUID) async throws
}

/// Protocolo del repositorio remoto de progreso.
public protocol RemoteProgressRepositoryProtocol: Sendable {
    /// Obtiene items de progreso desde el servidor.
    func fetchItems(userId: UUID, since: Date?) async throws -> [ProgressItem]

    /// Envía batch de items al servidor.
    func pushItems(_ items: [ProgressItem]) async throws -> [ProgressItem]
}

/// Protocolo del servicio de resolución de conflictos.
public protocol ConflictResolverProtocol: Sendable {
    /// Resuelve un conflicto según la estrategia especificada.
    func resolve(
        conflict: ProgressConflict,
        strategy: ConflictResolutionStrategy
    ) -> ConflictResolution
}

/// Resultado de la resolución de un conflicto.
public struct ConflictResolution: Sendable, Equatable {
    /// Item resuelto (nil si requiere decisión manual)
    public let resolvedItem: ProgressItem?
    /// Si el conflicto requiere decisión manual
    public let requiresManualDecision: Bool
    /// Razón de la resolución
    public let reason: String

    public init(
        resolvedItem: ProgressItem?,
        requiresManualDecision: Bool = false,
        reason: String
    ) {
        self.resolvedItem = resolvedItem
        self.requiresManualDecision = requiresManualDecision
        self.reason = reason
    }
}

// MARK: - Default Conflict Resolver

/// Implementación por defecto del resolutor de conflictos.
public struct DefaultConflictResolver: ConflictResolverProtocol {
    public init() {}

    public func resolve(
        conflict: ProgressConflict,
        strategy: ConflictResolutionStrategy
    ) -> ConflictResolution {
        switch strategy {
        case .localWins:
            return ConflictResolution(
                resolvedItem: conflict.localItem,
                reason: "Local wins strategy applied"
            )

        case .remoteWins:
            return ConflictResolution(
                resolvedItem: conflict.remoteItem,
                reason: "Remote wins strategy applied"
            )

        case .mostRecent:
            let localIsNewer = conflict.localItem.lastUpdated > conflict.remoteItem.lastUpdated
            let winner = localIsNewer ? conflict.localItem : conflict.remoteItem
            return ConflictResolution(
                resolvedItem: winner,
                reason: localIsNewer ? "Local is more recent" : "Remote is more recent"
            )

        case .manual:
            return ConflictResolution(
                resolvedItem: nil,
                requiresManualDecision: true,
                reason: "Manual resolution required"
            )
        }
    }
}

// MARK: - Sync Errors

/// Errores de sincronización.
public enum SyncProgressError: Error, Sendable, Equatable {
    case noItemsToSync
    case partialSyncFailure(synced: Int, failed: Int)
    case networkUnavailable
    case serverConflict(materialId: UUID)
    case invalidSyncState
    case batchSizeExceeded(max: Int)
}

extension SyncProgressError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noItemsToSync:
            return "No hay items para sincronizar"
        case .partialSyncFailure(let synced, let failed):
            return "Sincronización parcial: \(synced) exitosos, \(failed) fallidos"
        case .networkUnavailable:
            return "Red no disponible"
        case .serverConflict(let materialId):
            return "Conflicto en servidor para material \(materialId)"
        case .invalidSyncState:
            return "Estado de sincronización inválido"
        case .batchSizeExceeded(let max):
            return "Tamaño de batch excedido (máximo: \(max))"
        }
    }
}

// MARK: - SyncProgressUseCase

/// Actor que sincroniza el progreso del estudiante entre almacenamiento local y backend.
///
/// Implementa:
/// - Sincronización incremental (solo cambios desde última sync)
/// - Detección y resolución de conflictos
/// - Batch sync (max 50 items por request)
/// - Queue de retry para items fallidos
///
/// ## Flujo de Sincronización
/// 1. Fetch local: items no sincronizados o modificados
/// 2. Fetch remote: items desde lastSyncTimestamp
/// 3. Detect conflicts: comparar por (material_id, user_id)
/// 4. Resolve conflicts según estrategia
/// 5. Push cambios locales al servidor
/// 6. Pull cambios remotos al local
/// 7. Update sync metadata
///
/// ## Estrategias de Resolución
/// - `.localWins`: preferir datos locales
/// - `.remoteWins`: preferir datos remotos
/// - `.mostRecent`: usar timestamp más reciente
/// - `.manual`: retornar conflictos para UI
///
/// ## Ejemplo de Uso
/// ```swift
/// let useCase = SyncProgressUseCase(
///     localRepository: localRepo,
///     remoteRepository: remoteRepo,
///     conflictResolver: DefaultConflictResolver()
/// )
///
/// let input = SyncProgressInput(userId: userId)
/// let output = try await useCase.execute(input: input)
///
/// if !output.conflicts.isEmpty {
///     // Mostrar conflictos en UI para resolución manual
/// }
/// print("Sincronizados: \(output.syncedItems.count)")
/// ```
public actor SyncProgressUseCase: UseCase {

    public typealias Input = SyncProgressInput
    public typealias Output = SyncProgressOutput

    // MARK: - Dependencies

    private let localRepository: LocalProgressRepositoryProtocol
    private let remoteRepository: RemoteProgressRepositoryProtocol
    private let conflictResolver: ConflictResolverProtocol

    // MARK: - Configuration

    /// Tamaño máximo de batch para sincronización
    private let maxBatchSize = 50

    // MARK: - Initialization

    /// Crea una nueva instancia del caso de uso.
    ///
    /// - Parameters:
    ///   - localRepository: Repositorio local de progreso
    ///   - remoteRepository: Repositorio remoto de progreso
    ///   - conflictResolver: Resolutor de conflictos (default: DefaultConflictResolver)
    public init(
        localRepository: LocalProgressRepositoryProtocol,
        remoteRepository: RemoteProgressRepositoryProtocol,
        conflictResolver: ConflictResolverProtocol = DefaultConflictResolver()
    ) {
        self.localRepository = localRepository
        self.remoteRepository = remoteRepository
        self.conflictResolver = conflictResolver
    }

    // MARK: - UseCase Implementation

    /// Ejecuta la sincronización de progreso.
    ///
    /// - Parameter input: Input con userId, forceFullSync y conflictStrategy
    /// - Returns: SyncProgressOutput con items sincronizados, conflictos y metadata
    /// - Throws: SyncProgressError si la sincronización falla completamente
    public func execute(input: SyncProgressInput) async throws -> SyncProgressOutput {
        let startTime = Date()

        // PASO 1: Obtener estado de sync y timestamp
        let syncState = await localRepository.getSyncState(userId: input.userId)
        let sinceTimestamp = input.forceFullSync ? nil : syncState.lastSyncTimestamp

        // PASO 2: Fetch local y remote en paralelo
        async let localItemsTask = localRepository.getUnsyncedItems(
            userId: input.userId,
            since: sinceTimestamp
        )
        async let remoteItemsTask = remoteRepository.fetchItems(
            userId: input.userId,
            since: sinceTimestamp
        )

        let localItems: [ProgressItem]
        let remoteItems: [ProgressItem]

        do {
            localItems = try await localItemsTask
            remoteItems = try await remoteItemsTask
        } catch {
            // Si falla remote pero tenemos items locales, guardarlos para retry
            if let localOnly = try? await localItemsTask, !localOnly.isEmpty {
                let newState = SyncState(
                    lastSyncTimestamp: syncState.lastSyncTimestamp,
                    syncedItemIds: syncState.syncedItemIds,
                    pendingRetryItems: localOnly
                )
                try? await localRepository.saveSyncState(newState, userId: input.userId)
            }
            throw error
        }

        // PASO 3: Detectar conflictos
        let (conflicts, nonConflictingLocal, nonConflictingRemote) = detectConflicts(
            localItems: localItems,
            remoteItems: remoteItems
        )

        // PASO 4: Resolver conflictos
        var resolvedItems: [ProgressItem] = []
        var unresolvedConflicts: [ProgressConflict] = []
        var autoResolvedCount = 0

        for conflict in conflicts {
            let resolution = conflictResolver.resolve(
                conflict: conflict,
                strategy: input.conflictStrategy
            )

            if resolution.requiresManualDecision {
                unresolvedConflicts.append(conflict)
            } else if let resolved = resolution.resolvedItem {
                resolvedItems.append(resolved)
                autoResolvedCount += 1
            }
        }

        // PASO 5: Preparar items para push y pull
        let itemsToPush = nonConflictingLocal + resolvedItems.filter { item in
            // Push items que son locales o donde local ganó
            localItems.contains { $0.materialId == item.materialId }
        }

        let itemsToPull = nonConflictingRemote + resolvedItems.filter { item in
            // Pull items que son remotos
            remoteItems.contains { $0.materialId == item.materialId } &&
            !localItems.contains { $0.materialId == item.materialId }
        }

        // PASO 6: Ejecutar push y pull
        var syncedItems: [ProgressItem] = []
        var pendingRetry: [ProgressItem] = []
        var pushedCount = 0
        var pulledCount = 0

        // Push en batches
        if !itemsToPush.isEmpty {
            let (pushed, failed) = await pushInBatches(itemsToPush)
            syncedItems.append(contentsOf: pushed)
            pendingRetry.append(contentsOf: failed)
            pushedCount = pushed.count
        }

        // Pull: guardar items remotos localmente
        if !itemsToPull.isEmpty {
            do {
                try await localRepository.saveItems(itemsToPull)
                syncedItems.append(contentsOf: itemsToPull.map { $0.markSynced() })
                pulledCount = itemsToPull.count
            } catch {
                pendingRetry.append(contentsOf: itemsToPull)
            }
        }

        // PASO 7: Actualizar estado de sync
        let endTime = Date()
        let newSyncState = SyncState(
            lastSyncTimestamp: endTime,
            syncedItemIds: Set(syncedItems.map { $0.id }),
            pendingRetryItems: pendingRetry
        )
        try? await localRepository.saveSyncState(newSyncState, userId: input.userId)

        // Marcar items como sincronizados
        if !syncedItems.isEmpty {
            try? await localRepository.markAsSynced(itemIds: syncedItems.map { $0.id })
        }

        // PASO 8: Construir output
        let metadata = SyncMetadata(
            pushedCount: pushedCount,
            pulledCount: pulledCount,
            autoResolvedCount: autoResolvedCount,
            durationSeconds: endTime.timeIntervalSince(startTime),
            wasIncremental: !input.forceFullSync
        )

        return SyncProgressOutput(
            syncedItems: syncedItems,
            conflicts: unresolvedConflicts,
            resolutionStrategy: input.conflictStrategy,
            syncedAt: endTime,
            pendingRetry: pendingRetry,
            metadata: metadata
        )
    }

    // MARK: - Private Methods

    /// Detecta conflictos entre items locales y remotos.
    private func detectConflicts(
        localItems: [ProgressItem],
        remoteItems: [ProgressItem]
    ) -> (
        conflicts: [ProgressConflict],
        nonConflictingLocal: [ProgressItem],
        nonConflictingRemote: [ProgressItem]
    ) {
        var conflicts: [ProgressConflict] = []
        var nonConflictingLocal: [ProgressItem] = []
        var nonConflictingRemote: [ProgressItem] = []

        let localByMaterial = Dictionary(grouping: localItems) { $0.materialId }
        let remoteByMaterial = Dictionary(grouping: remoteItems) { $0.materialId }

        // Encontrar items que existen en ambos (posibles conflictos)
        for (materialId, localList) in localByMaterial {
            guard let local = localList.first else { continue }

            if let remoteList = remoteByMaterial[materialId],
               let remote = remoteList.first {
                // Existe en ambos - verificar si hay conflicto
                if local.percentage != remote.percentage {
                    // Datos diferentes = conflicto
                    let conflict = ProgressConflict(
                        materialId: materialId,
                        localItem: local,
                        remoteItem: remote
                    )
                    conflicts.append(conflict)
                } else {
                    // Mismos datos - no es conflicto, marcar como synced
                    nonConflictingLocal.append(local.markSynced())
                }
            } else {
                // Solo existe local - push
                nonConflictingLocal.append(local)
            }
        }

        // Items que solo existen en remote - pull
        for (materialId, remoteList) in remoteByMaterial {
            guard let remote = remoteList.first else { continue }

            if localByMaterial[materialId] == nil {
                nonConflictingRemote.append(remote)
            }
        }

        return (conflicts, nonConflictingLocal, nonConflictingRemote)
    }

    /// Ejecuta push en batches de máximo maxBatchSize.
    private func pushInBatches(
        _ items: [ProgressItem]
    ) async -> (pushed: [ProgressItem], failed: [ProgressItem]) {
        var allPushed: [ProgressItem] = []
        var allFailed: [ProgressItem] = []

        // Dividir en batches
        let batches = stride(from: 0, to: items.count, by: maxBatchSize).map {
            Array(items[$0..<min($0 + maxBatchSize, items.count)])
        }

        for batch in batches {
            do {
                let pushed = try await remoteRepository.pushItems(batch)
                allPushed.append(contentsOf: pushed)
            } catch {
                // Batch falló - agregar a retry
                allFailed.append(contentsOf: batch)
            }
        }

        return (allPushed, allFailed)
    }
}
