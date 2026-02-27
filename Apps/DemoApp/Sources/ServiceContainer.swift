import EduCore
import EduNetwork
import EduDomain
import EduDynamicUI
import Observation

@MainActor
@Observable
final class ServiceContainer {

    // MARK: - Network

    let plainNetworkClient: NetworkClient
    let authenticatedNetworkClient: NetworkClient

    // MARK: - Auth

    let authService: AuthService

    // MARK: - Sync

    let syncService: SyncService
    let localSyncStore: LocalSyncStore

    // MARK: - Menu

    let menuService: MenuService

    // MARK: - DynamicUI

    let screenLoader: ScreenLoader
    let dataLoader: DataLoader

    // MARK: - Config

    let apiConfiguration: APIConfiguration

    // MARK: - Initialization

    init(environment: AppEnvironment = .detect()) {
        let config = APIConfiguration.forEnvironment(environment)
        self.apiConfiguration = config

        // 1. Plain network client (sin interceptors) — para auth
        let plainClient = NetworkClient()
        self.plainNetworkClient = plainClient

        // 2. AuthService (usa plain client para evitar dependencia circular)
        let authService = AuthService(
            networkClient: plainClient,
            apiConfig: config
        )
        self.authService = authService

        // 3. Authenticated network client (con AuthenticationInterceptor)
        let authInterceptor = AuthenticationInterceptor.standard(
            tokenProvider: authService,
            sessionExpiredHandler: authService
        )
        let authenticatedClient = NetworkClient(interceptors: [authInterceptor])
        self.authenticatedNetworkClient = authenticatedClient

        // 4. LocalSyncStore
        let localSyncStore = LocalSyncStore()
        self.localSyncStore = localSyncStore

        // 5. MenuService
        self.menuService = MenuService()

        // 6. SyncService (usa authenticated client + local store)
        self.syncService = SyncService(
            networkClient: authenticatedClient,
            localStore: localSyncStore,
            apiConfig: config
        )

        // 7. DynamicUI loaders (usan authenticated client)
        self.screenLoader = ScreenLoader(
            networkClient: authenticatedClient,
            baseURL: config.mobileBaseURL
        )
        self.dataLoader = DataLoader(
            networkClient: authenticatedClient,
            adminBaseURL: config.adminBaseURL,
            mobileBaseURL: config.mobileBaseURL
        )
    }
}
