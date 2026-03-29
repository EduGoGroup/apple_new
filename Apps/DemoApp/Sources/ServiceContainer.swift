import EduCore
import EduNetwork
import EduDomain
import EduDynamicUI
import EduPresentation
import Observation
import OSLog

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

    // MARK: - Optimistic UI

    let optimisticUpdateManager: OptimisticUpdateManager

    // MARK: - Navigation

    let breadcrumbTracker: BreadcrumbTracker

    // MARK: - i18n

    let serverStringResolver: ServerStringResolver
    let glossaryProvider: GlossaryProvider
    let localeService: LocaleService

    // MARK: - Feedback

    let toastManager: ToastManager

    // MARK: - CQRS

    let mediator: Mediator

    // MARK: - Assessment (Network Services - Infrastructure)

    let assessmentsNetworkService: AssessmentsNetworkService
    let attemptsNetworkService: AttemptsNetworkService
    let eligibilityNetworkService: EligibilityNetworkService
    let assessmentReviewNetworkService: AssessmentReviewNetworkService

    // MARK: - Assessment (Domain Repositories & Services)

    let assessmentsRepository: AssessmentsRepository
    let attemptsRepository: AttemptsRepository
    let eligibilityService: EligibilityService
    let assessmentCacheService: AssessmentCacheService
    let loadAssessmentUseCase: LoadAssessmentUseCase

    // MARK: - Materials (Network Services - Infrastructure)

    let materialUploadRepository: MaterialUploadRepository
    let materialListRepository: MaterialListRepository

    // MARK: - Materials (Domain - Use Cases)

    let uploadMaterialUseCase: UploadMaterialUseCase
    let listMaterialsUseCase: ListMaterialsUseCase

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
        let cacheLogger = os.Logger(subsystem: "com.edugo.apple", category: "Cache")
        self.screenLoader = ScreenLoader(
            networkClient: authenticatedClient,
            baseURL: config.mobileBaseURL,
            logger: cacheLogger
        )
        self.dataLoader = DataLoader(
            networkClient: authenticatedClient,
            adminBaseURL: config.adminBaseURL,
            mobileBaseURL: config.mobileBaseURL,
            logger: cacheLogger
        )

        // 9. Contract registry + optimistic manager + orchestrator
        let registry = ContractRegistry()
        registry.registerDefaults()
        self.contractRegistry = registry
        let optimisticManager = OptimisticUpdateManager()
        self.optimisticUpdateManager = optimisticManager
        self.eventOrchestrator = EventOrchestrator(
            registry: registry,
            networkClient: authenticatedClient,
            dataLoader: self.dataLoader,
            optimisticManager: optimisticManager
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

        // 11. Navigation
        self.breadcrumbTracker = BreadcrumbTracker()

        // 12. i18n services
        self.serverStringResolver = ServerStringResolver()
        self.glossaryProvider = GlossaryProvider()
        self.localeService = LocaleService()

        // 13. Feedback
        self.toastManager = ToastManager.shared

        // 14. CQRS Mediator
        self.mediator = Mediator()

        // 15. Assessment Network Services (Infrastructure layer)
        let assessmentsNetSvc = AssessmentsNetworkService(
            client: authenticatedClient,
            baseURL: config.mobileBaseURL
        )
        self.assessmentsNetworkService = assessmentsNetSvc

        let attemptsNetSvc = AttemptsNetworkService(
            client: authenticatedClient,
            baseURL: config.mobileBaseURL
        )
        self.attemptsNetworkService = attemptsNetSvc

        let eligibilityNetSvc = EligibilityNetworkService(
            client: authenticatedClient,
            baseURL: config.mobileBaseURL
        )
        self.eligibilityNetworkService = eligibilityNetSvc

        let reviewNetSvc = AssessmentReviewNetworkService(
            client: authenticatedClient,
            baseURL: config.mobileBaseURL
        )
        self.assessmentReviewNetworkService = reviewNetSvc

        // 16. Assessment Repositories & Services (Domain layer, wrapping Infrastructure)
        let assessmentsRepo = AssessmentsRepository(
            networkService: assessmentsNetSvc
        )
        self.assessmentsRepository = assessmentsRepo

        let attemptsRepo = AttemptsRepository(
            networkService: attemptsNetSvc
        )
        self.attemptsRepository = attemptsRepo

        let eligibility = EligibilityService(
            networkService: eligibilityNetSvc
        )
        self.eligibilityService = eligibility

        let cacheService = AssessmentCacheService()
        self.assessmentCacheService = cacheService

        // 17. Assessment Use Cases
        self.loadAssessmentUseCase = LoadAssessmentUseCase(
            assessmentsRepository: assessmentsRepo,
            eligibilityService: eligibility,
            cacheService: cacheService
        )

        // 18. Material Repositories (Infrastructure layer)
        let materialUploadRepo = MaterialUploadRepository(
            client: authenticatedClient,
            baseURL: config.mobileBaseURL
        )
        self.materialUploadRepository = materialUploadRepo

        let materialListRepo = MaterialListRepository(
            client: authenticatedClient,
            baseURL: config.mobileBaseURL
        )
        self.materialListRepository = materialListRepo

        // 19. Material Use Cases (Domain layer)
        self.uploadMaterialUseCase = UploadMaterialUseCase(
            uploadRepository: materialUploadRepo
        )

        self.listMaterialsUseCase = ListMaterialsUseCase(
            repository: materialListRepo
        )
    }

    // MARK: - CQRS Handler Registration

    /// Registra los handlers CQRS de assessment review y materiales en el mediator.
    /// Debe llamarse una vez al iniciar la app (contexto async).
    func setupCQRS() async {
        // Assessment Review Queries
        let reviewNetSvc: any AssessmentReviewNetworkServiceProtocol = assessmentReviewNetworkService
        await mediator.registerOrReplaceQueryHandler(GetAttemptListQueryHandler(networkService: reviewNetSvc))
        await mediator.registerOrReplaceQueryHandler(GetAssessmentStatsQueryHandler(networkService: reviewNetSvc))
        await mediator.registerOrReplaceQueryHandler(GetAttemptDetailQueryHandler(networkService: reviewNetSvc))

        // Assessment Review Commands
        await mediator.registerOrReplaceCommandHandler(ReviewAnswerCommandHandler(networkService: reviewNetSvc))
        await mediator.registerOrReplaceCommandHandler(FinalizeAttemptCommandHandler(networkService: reviewNetSvc))
        await mediator.registerOrReplaceCommandHandler(FinalizeAllCommandHandler(networkService: reviewNetSvc))

        // Material Queries
        let listMaterialsHandler = ListMaterialsQueryHandler(useCase: listMaterialsUseCase)
        await mediator.registerOrReplaceQueryHandler(listMaterialsHandler)

        // Material Commands
        let uploadHandler = UploadMaterialCommandHandler(
            useCase: uploadMaterialUseCase,
            materialListHandler: listMaterialsHandler
        )
        await mediator.registerOrReplaceCommandHandler(uploadHandler)
    }
}
