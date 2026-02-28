// SyncService.swift
// EduDomain
//
// Actor that coordinates full and delta sync with the backend.

import Foundation
import EduCore
import EduInfrastructure

/// Actor que coordina la sincronización de datos con el backend.
///
/// Responsable de:
/// - Full sync: descarga completa del bundle (`GET /api/v1/sync/bundle`)
/// - Delta sync: sincronización incremental (`POST /api/v1/sync/delta`)
/// - Exposición del estado de sync via `AsyncStream<BundleSyncState>`
///
/// ## Flujo de arranque
/// ```
/// 1. restoreFromLocal() → cargar bundle persistido
/// 2. Si existe → pre-popular cache (ScreenLoader, Menu, Permissions)
/// 3. En background → deltaSync con hashes del bundle local
/// 4. Si cambiaron buckets → actualizar bundle + re-notificar UI
/// ```
///
/// ## Ejemplo de uso
/// ```swift
/// let syncService = SyncService(
///     networkClient: authenticatedClient,
///     localStore: localSyncStore,
///     apiConfig: .forEnvironment(.staging)
/// )
///
/// // Observar estado
/// for await state in await syncService.stateStream {
///     switch state {
///     case .syncing: showSpinner()
///     case .completed: hideSpinner()
///     case .error(let err): showError(err)
///     case .idle: break
///     }
/// }
/// ```
public actor SyncService {

    // MARK: - Properties

    private let networkClient: any NetworkClientProtocol
    private let localStore: LocalSyncStore
    private let apiConfig: APIConfiguration

    /// Bundle activo en memoria.
    public private(set) var currentBundle: UserDataBundle?

    /// Estado actual de la sincronización.
    public private(set) var syncState: BundleSyncState = .idle

    // MARK: - State Stream

    private var continuation: AsyncStream<BundleSyncState>.Continuation?
    private var _stateStream: AsyncStream<BundleSyncState>?

    /// Stream para observar cambios de estado de sincronización.
    public var stateStream: AsyncStream<BundleSyncState> {
        if _stateStream == nil {
            let (stream, continuation) = AsyncStream<BundleSyncState>.makeStream(
                bufferingPolicy: .unbounded
            )
            self._stateStream = stream
            self.continuation = continuation
        }
        return _stateStream!
    }

    // MARK: - Initialization

    /// Crea un SyncService.
    ///
    /// - Parameters:
    ///   - networkClient: Cliente de red autenticado (con interceptor de auth).
    ///   - localStore: Store local para persistencia del bundle.
    ///   - apiConfig: Configuración de API con URLs base.
    public init(
        networkClient: any NetworkClientProtocol,
        localStore: LocalSyncStore,
        apiConfig: APIConfiguration
    ) {
        self.networkClient = networkClient
        self.localStore = localStore
        self.apiConfig = apiConfig
    }

    // MARK: - Full Sync

    /// Ejecuta una sincronización completa descargando el bundle desde el backend.
    ///
    /// - Returns: El `UserDataBundle` sincronizado.
    /// - Throws: `SyncError` si la operación falla.
    @discardableResult
    public func fullSync() async throws -> UserDataBundle {
        transition(to: .syncing)

        do {
            let url = "\(apiConfig.iamBaseURL)/api/v1/sync/bundle"
            let response: SyncBundleResponseDTO = try await networkClient.get(url)

            let bundle = UserDataBundle(
                menu: response.menu,
                permissions: response.permissions,
                screens: response.screens,
                availableContexts: response.availableContexts,
                hashes: response.hashes,
                glossary: response.glossary ?? [:],
                strings: response.strings ?? [:],
                syncedAt: Date()
            )

            try await localStore.save(bundle: bundle)
            currentBundle = bundle
            transition(to: .completed)

            return bundle
        } catch let error as SyncError {
            transition(to: .error(error))
            throw error
        } catch {
            let syncError = SyncError.networkFailure(error.localizedDescription)
            transition(to: .error(syncError))
            throw syncError
        }
    }

    // MARK: - Selective Bucket Sync

    /// Ejecuta una sincronizacion parcial solicitando solo los buckets indicados.
    ///
    /// Construye `GET /api/v1/sync/bundle?buckets=menu,permissions,...`
    /// El bundle parcial se mergea con el bundle local existente,
    /// preservando los buckets no solicitados.
    ///
    /// - Parameter buckets: Buckets a solicitar al backend.
    /// - Returns: El `UserDataBundle` resultante (merge de parcial + local).
    /// - Throws: `SyncError` si la operacion falla.
    @discardableResult
    public func syncBuckets(_ buckets: [SyncBucket]) async throws -> UserDataBundle {
        transition(to: .syncing)

        do {
            let url = "\(apiConfig.iamBaseURL)/api/v1/sync/bundle"
            var httpRequest = HTTPRequest.get(url)

            if !buckets.isEmpty {
                let bucketNames = buckets.map(\.rawValue).joined(separator: ",")
                httpRequest = httpRequest.queryParam("buckets", bucketNames)
            }

            let response: SyncBundleResponseDTO = try await networkClient.request(httpRequest)

            let partialBundle = UserDataBundle(
                menu: response.menu,
                permissions: response.permissions,
                screens: response.screens,
                availableContexts: response.availableContexts,
                hashes: response.hashes,
                glossary: response.glossary ?? [:],
                strings: response.strings ?? [:],
                syncedAt: Date()
            )

            let bucketNames = Set(buckets.map(\.rawValue))
            let merged = await localStore.mergePartial(
                incoming: partialBundle,
                receivedBuckets: bucketNames
            )

            try await localStore.save(bundle: merged)
            currentBundle = merged
            transition(to: .completed)

            return merged
        } catch let error as SyncError {
            transition(to: .error(error))
            throw error
        } catch {
            let syncError = SyncError.networkFailure(error.localizedDescription)
            transition(to: .error(syncError))
            throw syncError
        }
    }

    // MARK: - Delta Sync

    /// Ejecuta una sincronización incremental enviando hashes actuales al backend.
    ///
    /// Solo descarga los buckets que han cambiado respecto a los hashes locales.
    ///
    /// - Parameter currentHashes: Mapa de bucket names a sus hashes actuales.
    /// - Returns: La respuesta delta con buckets cambiados y sin cambios.
    /// - Throws: `SyncError` si la operación falla.
    @discardableResult
    public func deltaSync(currentHashes: [String: String]) async throws -> DeltaSyncResponseDTO {
        transition(to: .syncing)

        do {
            let url = "\(apiConfig.iamBaseURL)/api/v1/sync/delta"
            let requestBody = DeltaSyncRequestDTO(hashes: currentHashes)
            let response: DeltaSyncResponseDTO = try await networkClient.post(url, body: requestBody)

            // Aplicar buckets cambiados al store local en paralelo.
            // LocalSyncStore es un actor, así que las llamadas ya son thread-safe.
            try await withThrowingTaskGroup(of: Void.self) { group in
                for (bucketName, bucketData) in response.changed {
                    let store = localStore
                    group.addTask {
                        try await store.updateBucket(
                            name: bucketName,
                            data: bucketData.data,
                            hash: bucketData.hash
                        )
                    }
                }
                try await group.waitForAll()
            }

            // Actualizar bundle en memoria desde el store
            if let updatedBundle = await localStore.restore() {
                currentBundle = updatedBundle
            }

            transition(to: .completed)
            return response
        } catch let error as SyncError {
            transition(to: .error(error))
            throw error
        } catch {
            let syncError = SyncError.networkFailure(error.localizedDescription)
            transition(to: .error(syncError))
            throw syncError
        }
    }

    // MARK: - Restore from Local

    /// Restaura el bundle desde almacenamiento local.
    ///
    /// Usado en el arranque para tener datos disponibles inmediatamente
    /// antes de que la sincronización con el backend termine.
    ///
    /// - Returns: El bundle restaurado, o `nil` si no existe.
    public func restoreFromLocal() async -> UserDataBundle? {
        let bundle = await localStore.restore()
        if let bundle {
            currentBundle = bundle
        }
        return bundle
    }

    // MARK: - Background Delta Sync

    /// Flujo completo de arranque: restaurar local + delta sync en background.
    ///
    /// 1. Restaura el bundle local si existe.
    /// 2. Si hay hashes disponibles, ejecuta delta sync.
    /// 3. Si no hay bundle local, ejecuta full sync.
    ///
    /// - Returns: El bundle final (local restaurado o sincronizado).
    /// - Throws: `SyncError` si la sincronización falla.
    @discardableResult
    public func syncOnLaunch() async throws -> UserDataBundle {
        // Paso 1: Intentar restaurar desde local
        if let localBundle = await restoreFromLocal() {
            // Paso 2: Delta sync con hashes del bundle local
            do {
                _ = try await deltaSync(currentHashes: localBundle.hashes)
            } catch {
                // Delta sync falló, pero tenemos datos locales
                // El UI puede continuar con datos locales
            }

            // Retornar el bundle más actualizado
            if let updated = currentBundle {
                return updated
            }
            return localBundle
        }

        // Paso 3: No hay datos locales → full sync obligatorio
        return try await fullSync()
    }

    /// Limpia todo el estado de sincronización (logout).
    public func clear() async {
        currentBundle = nil
        syncState = .idle
        await localStore.clear()
        continuation?.yield(.idle)
    }

    // MARK: - State Management

    private func transition(to newState: BundleSyncState) {
        guard BundleSyncState.isValidTransition(from: syncState, to: newState) else { return }
        syncState = newState
        continuation?.yield(newState)
    }
}
