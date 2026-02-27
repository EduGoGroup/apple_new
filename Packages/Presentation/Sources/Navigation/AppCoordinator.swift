import SwiftUI
import EduDomain
import EduCore
import Observation

/// Coordinador principal de la aplicación que gestiona la navegación global.
///
/// AppCoordinator implementa el patrón Coordinator para manejar toda la navegación
/// de la aplicación de forma centralizada. Se integra con EventBus para reaccionar
/// automáticamente a eventos de dominio y actualizar la navegación según el estado.
///
/// # Características
/// - NavigationStack: Usa NavigationPath para type-safe navigation
/// - EventBus integration: Navegación automática basada en eventos de dominio
/// - Modal support: Sheets y fullScreenCovers
/// - Authentication state: Maneja login/logout y cambios de contexto
/// - Observable: Compatible con SwiftUI Observation framework
///
/// # Ejemplo de uso:
/// ```swift
/// @State private var coordinator = AppCoordinator(
///     mediator: mediator,
///     eventBus: eventBus
/// )
///
/// NavigationStack(path: $coordinator.navigationPath) {
///     LoginView()
///         .navigationDestination(for: Screen.self) { screen in
///             ViewFactory.view(for: screen, coordinator: coordinator)
///         }
/// }
/// ```
@MainActor
@Observable
public final class AppCoordinator {

    // MARK: - Published State

    /// Path de navegación para NavigationStack
    public var navigationPath: NavigationPath = NavigationPath()

    /// Indica si el usuario está autenticado
    public var isAuthenticated: Bool = false

    /// ID del usuario actual (si está autenticado)
    public var currentUserId: UUID?

    /// Pantalla actual mostrada
    public var currentScreen: Screen = .login

    // MARK: - Modal Presentation

    /// Pantalla presentada como sheet (modal)
    public var presentedSheet: Screen?

    /// Pantalla presentada como full screen cover
    public var presentedFullScreenCover: Screen?

    // MARK: - Dependencies

    private let mediator: Mediator
    private let eventBus: EventBus
    private var subscriptionIds: [UUID] = []

    // MARK: - Initialization

    /// Crea una nueva instancia de AppCoordinator.
    ///
    /// - Parameters:
    ///   - mediator: Mediator para ejecutar comandos
    ///   - eventBus: EventBus para suscribirse a eventos de navegación
    public init(mediator: Mediator, eventBus: EventBus) {
        self.mediator = mediator
        self.eventBus = eventBus
    }

    /// Configura las suscripciones a eventos de navegación.
    ///
    /// Este método debe ser llamado después de crear la instancia
    /// para habilitar la navegación automática basada en eventos.
    public func setup() async {
        await subscribeToNavigationEvents()
    }

    // MARK: - Navigation Actions

    /// Navega a una pantalla usando push navigation.
    ///
    /// - Parameter screen: Pantalla de destino
    public func navigate(to screen: Screen) {
        navigationPath.append(screen)
        currentScreen = screen
    }

    /// Presenta una pantalla como sheet modal.
    ///
    /// - Parameter screen: Pantalla a presentar
    public func presentSheet(_ screen: Screen) {
        presentedSheet = screen
    }

    /// Presenta una pantalla como full screen cover.
    ///
    /// - Parameter screen: Pantalla a presentar
    public func presentFullScreenCover(_ screen: Screen) {
        presentedFullScreenCover = screen
    }

    /// Cierra el modal presentado (sheet o fullScreenCover).
    public func dismissModal() {
        presentedSheet = nil
        presentedFullScreenCover = nil
    }

    /// Vuelve a la pantalla anterior en el navigation stack.
    public func goBack() {
        guard navigationPath.count > 0 else { return }
        navigationPath.removeLast()
    }

    /// Vuelve a la raíz del navigation stack.
    ///
    /// La pantalla raíz depende del estado de autenticación:
    /// - Autenticado: Dashboard
    /// - No autenticado: Login
    public func popToRoot() {
        navigationPath.removeLast(navigationPath.count)
        currentScreen = isAuthenticated ? .dashboard : .login
    }

    /// Resetea toda la navegación (usado en logout).
    ///
    /// Limpia el navigation path, cierra modales, y resetea el estado
    /// de autenticación a su valor inicial.
    public func resetNavigation() {
        navigationPath = NavigationPath()
        presentedSheet = nil
        presentedFullScreenCover = nil
        isAuthenticated = false
        currentUserId = nil
        currentScreen = .login
    }

    // MARK: - Event Subscriptions

    /// Suscribe el coordinador a eventos de dominio para navegación automática.
    ///
    /// Los eventos soportados incluyen:
    /// - LoginSuccessEvent: Navega al dashboard
    /// - ContextSwitchedEvent: Refresca el dashboard
    /// - MaterialUploadedEvent: Navega a la lista de materiales
    /// - MaterialAssignedEvent: Cierra modal de asignación
    /// - AssessmentSubmittedEvent: Navega a resultados
    private func subscribeToNavigationEvents() async {
        // Login Success → Navigate to Dashboard
        let loginSubscription = await eventBus.subscribe(to: LoginSuccessEvent.self) { [weak self] event in
            await MainActor.run {
                self?.isAuthenticated = true
                self?.currentUserId = event.userId
                self?.popToRoot()
                self?.navigate(to: .dashboard)
            }
        }
        subscriptionIds.append(loginSubscription)

        // Context Switch → Pop to Root (refresh dashboard)
        let contextSwitchSubscription = await eventBus.subscribe(to: ContextSwitchedEvent.self) { [weak self] _ in
            await MainActor.run {
                self?.popToRoot()
            }
        }
        subscriptionIds.append(contextSwitchSubscription)

        // Material Upload Success → Navigate to Material List
        let materialUploadSubscription = await eventBus.subscribe(to: MaterialUploadedEvent.self) { [weak self] _ in
            await MainActor.run {
                self?.dismissModal()
                self?.navigate(to: .materialList)
            }
        }
        subscriptionIds.append(materialUploadSubscription)

        // Material Assignment Success → Dismiss Modal
        let assignmentSubscription = await eventBus.subscribe(to: MaterialAssignedEvent.self) { [weak self] _ in
            await MainActor.run {
                self?.dismissModal()
            }
        }
        subscriptionIds.append(assignmentSubscription)

        // Assessment Submit → Navigate to Results
        let assessmentSubmitSubscription = await eventBus.subscribe(to: AssessmentSubmittedEvent.self) { [weak self] event in
            await MainActor.run {
                self?.navigate(to: .assessmentResults(assessmentId: event.assessmentId))
            }
        }
        subscriptionIds.append(assessmentSubmitSubscription)
    }

    // MARK: - Cleanup

    /// Cancela todas las suscripciones a eventos.
    ///
    /// Este método debe ser llamado cuando ya no se necesite el coordinador,
    /// típicamente en el ciclo de vida de la aplicación o cuando se cambie
    /// de contexto principal.
    public func cleanup() async {
        for id in subscriptionIds {
            await eventBus.unsubscribe(id)
        }
        subscriptionIds.removeAll()
    }
}

// MARK: - Computed Properties

extension AppCoordinator {
    /// Indica si es posible navegar hacia atrás.
    public var canGoBack: Bool {
        navigationPath.count > 0
    }

    /// Indica si hay un modal presentado.
    public var isModalPresented: Bool {
        presentedSheet != nil || presentedFullScreenCover != nil
    }
}
