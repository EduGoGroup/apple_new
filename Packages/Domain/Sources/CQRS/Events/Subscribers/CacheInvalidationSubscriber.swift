import Foundation
import OSLog

/// Subscriber que invalida caches cuando ocurren eventos de dominio relevantes.
///
/// CacheInvalidationSubscriber escucha eventos que afectan datos cacheados
/// y coordina la invalidación de los caches correspondientes para mantener
/// la consistencia de datos.
///
/// # Eventos manejados
/// - `MaterialUploadedEvent`: Invalida cache de ListMaterialsQuery
/// - `AssessmentSubmittedEvent`: Invalida caches de Dashboard y Assessment
/// - `LoginSuccessEvent`: Invalida cache de UserContext
///
/// # Arquitectura
/// Este subscriber se registra para múltiples tipos de eventos usando
/// closures, ya que cada evento requiere diferente lógica de invalidación.
/// Se prefiere un solo subscriber coordinador sobre múltiples subscribers
/// específicos para simplificar la configuración.
///
/// # Ejemplo de uso:
/// ```swift
/// let subscriber = CacheInvalidationSubscriber(
///     materialListHandler: materialListQueryHandler,
///     dashboardHandler: dashboardQueryHandler,
///     userContextHandler: userContextQueryHandler
/// )
///
/// await subscriber.registerWithEventBus(eventBus)
/// ```
public actor CacheInvalidationSubscriber {

    // MARK: - Dependencies

    /// Handler de ListMaterialsQuery para invalidar cache de materiales
    private weak var materialListHandler: ListMaterialsQueryHandler?

    /// Handler de GetStudentDashboardQuery para invalidar cache de dashboard
    private weak var dashboardHandler: GetStudentDashboardQueryHandler?

    /// Handler de GetUserContextQuery para invalidar cache de contexto
    private weak var userContextHandler: GetUserContextQueryHandler?

    /// Logger para debugging
    private let logger: Logger

    /// Indica si el logging está habilitado
    private let loggingEnabled: Bool

    /// IDs de suscripciones activas para poder cancelarlas
    private var subscriptionIds: [UUID] = []

    // MARK: - Initialization

    /// Crea un nuevo subscriber de invalidación de cache.
    ///
    /// - Parameters:
    ///   - materialListHandler: Handler para cache de lista de materiales
    ///   - dashboardHandler: Handler para cache de dashboard
    ///   - userContextHandler: Handler para cache de contexto de usuario
    ///   - loggingEnabled: Habilita logging de operaciones
    public init(
        materialListHandler: ListMaterialsQueryHandler? = nil,
        dashboardHandler: GetStudentDashboardQueryHandler? = nil,
        userContextHandler: GetUserContextQueryHandler? = nil,
        loggingEnabled: Bool = true
    ) {
        self.materialListHandler = materialListHandler
        self.dashboardHandler = dashboardHandler
        self.userContextHandler = userContextHandler
        self.loggingEnabled = loggingEnabled
        self.logger = Logger(subsystem: "com.edugo.cqrs", category: "CacheInvalidation")
    }

    // MARK: - Registration

    /// Registra este subscriber con un EventBus para todos los eventos relevantes.
    ///
    /// - Parameter eventBus: El EventBus donde registrarse
    public func registerWithEventBus(_ eventBus: EventBus) async {
        // Limpiar suscripciones anteriores
        await unregisterFromEventBus(eventBus)

        // Registrar para MaterialUploadedEvent
        let materialSubId = await eventBus.subscribe(
            to: MaterialUploadedEvent.self
        ) { [weak self] event in
            await self?.handleMaterialUploaded(event)
        }
        subscriptionIds.append(materialSubId)

        // Registrar para AssessmentSubmittedEvent
        let assessmentSubId = await eventBus.subscribe(
            to: AssessmentSubmittedEvent.self
        ) { [weak self] event in
            await self?.handleAssessmentSubmitted(event)
        }
        subscriptionIds.append(assessmentSubId)

        // Registrar para LoginSuccessEvent
        let loginSubId = await eventBus.subscribe(
            to: LoginSuccessEvent.self
        ) { [weak self] event in
            await self?.handleLoginSuccess(event)
        }
        subscriptionIds.append(loginSubId)

        if loggingEnabled {
            logger.info("CacheInvalidationSubscriber registered for 3 event types")
        }
    }

    /// Cancela todas las suscripciones de este subscriber.
    ///
    /// - Parameter eventBus: El EventBus de donde cancelar suscripciones
    public func unregisterFromEventBus(_ eventBus: EventBus) async {
        for subscriptionId in subscriptionIds {
            await eventBus.unsubscribe(subscriptionId)
        }
        subscriptionIds.removeAll()

        if loggingEnabled {
            logger.info("CacheInvalidationSubscriber unregistered")
        }
    }

    // MARK: - Event Handlers

    /// Maneja el evento de material subido.
    private func handleMaterialUploaded(_ event: MaterialUploadedEvent) async {
        if loggingEnabled {
            logger.debug("Invalidating material cache for: \(event.materialId)")
        }

        // Invalidar cache de ListMaterialsQuery para este material
        await materialListHandler?.invalidateCache(for: event.materialId)

        if loggingEnabled {
            logger.info("Cache invalidated for MaterialUploadedEvent: \(event.eventId)")
        }
    }

    /// Maneja el evento de evaluación enviada.
    private func handleAssessmentSubmitted(_ event: AssessmentSubmittedEvent) async {
        if loggingEnabled {
            logger.debug("Invalidating caches for assessment: \(event.assessmentId), user: \(event.userId)")
        }

        // Invalidar cache de Dashboard para este usuario
        await dashboardHandler?.invalidateCache(for: event.userId)

        if loggingEnabled {
            logger.info("Cache invalidated for AssessmentSubmittedEvent: \(event.eventId)")
        }
    }

    /// Maneja el evento de login exitoso.
    private func handleLoginSuccess(_ event: LoginSuccessEvent) async {
        if loggingEnabled {
            logger.debug("Invalidating user context cache for: \(event.userId)")
        }

        // Invalidar cache de UserContext
        await userContextHandler?.invalidateCache()

        if loggingEnabled {
            logger.info("Cache invalidated for LoginSuccessEvent: \(event.eventId)")
        }
    }

    // MARK: - Configuration

    /// Configura el handler de materiales.
    public func setMaterialListHandler(_ handler: ListMaterialsQueryHandler) {
        self.materialListHandler = handler
    }

    /// Configura el handler de dashboard.
    public func setDashboardHandler(_ handler: GetStudentDashboardQueryHandler) {
        self.dashboardHandler = handler
    }

    /// Configura el handler de contexto de usuario.
    public func setUserContextHandler(_ handler: GetUserContextQueryHandler) {
        self.userContextHandler = handler
    }
}

// MARK: - Specialized Subscribers

/// Subscriber específico para MaterialUploadedEvent que invalida cache de materiales.
///
/// Versión simplificada del CacheInvalidationSubscriber que solo maneja
/// un tipo de evento. Útil cuando solo se necesita invalidar un cache específico.
public actor MaterialCacheInvalidationSubscriber: EventSubscriber {
    public typealias EventType = MaterialUploadedEvent

    private weak var materialListHandler: ListMaterialsQueryHandler?
    private let logger: Logger

    public init(materialListHandler: ListMaterialsQueryHandler) {
        self.materialListHandler = materialListHandler
        self.logger = Logger(subsystem: "com.edugo.cqrs", category: "MaterialCacheInvalidation")
    }

    public func handle(_ event: MaterialUploadedEvent) async {
        logger.debug("Invalidating material cache for: \(event.materialId)")
        await materialListHandler?.invalidateCache(for: event.materialId)
    }
}

/// Subscriber específico para AssessmentSubmittedEvent que invalida cache de dashboard.
public actor DashboardCacheInvalidationSubscriber: EventSubscriber {
    public typealias EventType = AssessmentSubmittedEvent

    private weak var dashboardHandler: GetStudentDashboardQueryHandler?
    private let logger: Logger

    public init(dashboardHandler: GetStudentDashboardQueryHandler) {
        self.dashboardHandler = dashboardHandler
        self.logger = Logger(subsystem: "com.edugo.cqrs", category: "DashboardCacheInvalidation")
    }

    public func handle(_ event: AssessmentSubmittedEvent) async {
        logger.debug("Invalidating dashboard cache for user: \(event.userId)")
        await dashboardHandler?.invalidateCache(for: event.userId)
    }
}

/// Subscriber específico para LoginSuccessEvent que invalida cache de contexto.
public actor UserContextCacheInvalidationSubscriber: EventSubscriber {
    public typealias EventType = LoginSuccessEvent

    private weak var userContextHandler: GetUserContextQueryHandler?
    private let logger: Logger

    public init(userContextHandler: GetUserContextQueryHandler) {
        self.userContextHandler = userContextHandler
        self.logger = Logger(subsystem: "com.edugo.cqrs", category: "UserContextCacheInvalidation")
    }

    public func handle(_ event: LoginSuccessEvent) async {
        logger.debug("Invalidating user context cache for: \(event.userId)")
        await userContextHandler?.invalidateCache()
    }
}
