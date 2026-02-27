import EduCore
import EduNetwork
import EduDomain
import EduDynamicUI
import EduPresentation
import Observation

@MainActor
@Observable
final class ServiceContainer {

    // MARK: - Network

    let plainNetworkClient: NetworkClient
    let authenticatedNetworkClient: NetworkClient
    let networkObserver: NetworkObserver

    // MARK: - Auth

    let authService: AuthService

    // MARK: - Sync

    let syncService: SyncService
    let localSyncStore: LocalSyncStore

    // MARK: - Offline

    let mutationQueue: MutationQueue
    let syncEngine: SyncEngine
    let connectivitySyncManager: ConnectivitySyncManager

    // MARK: - Menu

    let menuService: MenuService

    // MARK: - DynamicUI

    let screenLoader: ScreenLoader
    let dataLoader: DataLoader

    // MARK: - Contracts

    let contractRegistry: ContractRegistry
    let eventOrchestrator: EventOrchestrator

    // MARK: - i18n

    let serverStringResolver: ServerStringResolver
    let glossaryProvider: GlossaryProvider
    let localeService: LocaleService

    // MARK: - Feedback

    let toastManager: ToastManager

    // MARK: - Config

    let apiConfiguration: APIConfiguration

    // MARK: - Initialization

    init(environment: AppEnvironment = .detect()) {
        let config = APIConfiguration.forEnvironment(environment)
        self.apiConfiguration = config

        // 1. Plain network client (sin interceptors) — para auth
        let plainClient = NetworkClient()
        self.plainNetworkClient = plainClient

        // 2. NetworkObserver (sin dependencias)
        self.networkObserver = NetworkObserver()

        // 3. AuthService (usa plain client para evitar dependencia circular)
        let authService = AuthService(
            networkClient: plainClient,
            apiConfig: config
        )
        self.authService = authService

        // 4. Authenticated network client (con AuthenticationInterceptor)
        let authInterceptor = AuthenticationInterceptor.standard(
            tokenProvider: authService,
            sessionExpiredHandler: authService
        )
        let authenticatedClient = NetworkClient(interceptors: [authInterceptor])
        self.authenticatedNetworkClient = authenticatedClient

        // 5. LocalSyncStore
        let localSyncStore = LocalSyncStore()
        self.localSyncStore = localSyncStore

        // 6. MenuService
        self.menuService = MenuService()

        // 7. SyncService (usa authenticated client + local store)
        let syncService = SyncService(
            networkClient: authenticatedClient,
            localStore: localSyncStore,
            apiConfig: config
        )
        self.syncService = syncService

        // 8. DynamicUI loaders (usan authenticated client)
        self.screenLoader = ScreenLoader(
            networkClient: authenticatedClient,
            baseURL: config.mobileBaseURL
        )
        self.dataLoader = DataLoader(
            networkClient: authenticatedClient,
            adminBaseURL: config.adminBaseURL,
            mobileBaseURL: config.mobileBaseURL
        )

        // 9. Contract registry + orchestrator
        let registry = ContractRegistry()
        registry.registerDefaults()
        self.contractRegistry = registry
        self.eventOrchestrator = EventOrchestrator(
            registry: registry,
            networkClient: authenticatedClient,
            dataLoader: self.dataLoader
        )

        // 10. Offline: mutation queue → sync engine → connectivity manager
        let mutationQueue = MutationQueue()
        self.mutationQueue = mutationQueue

        let syncEngine = SyncEngine(
            mutationQueue: mutationQueue,
            networkClient: authenticatedClient
        )
        self.syncEngine = syncEngine

        self.connectivitySyncManager = ConnectivitySyncManager(
            networkObserver: self.networkObserver,
            syncEngine: syncEngine,
            syncService: syncService
        )

        // 11. i18n services
        self.serverStringResolver = ServerStringResolver()
        self.glossaryProvider = GlossaryProvider()
        self.localeService = LocaleService()

        // 12. Feedback
        self.toastManager = ToastManager.shared
    }
}
