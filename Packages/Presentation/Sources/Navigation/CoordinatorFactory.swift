import SwiftUI
import EduDomain

/// Factory para crear coordinadores de navegación de forma centralizada.
///
/// CoordinatorFactory proporciona un punto único de creación para todos
/// los coordinadores de la aplicación, manejando las dependencias y
/// garantizando la configuración correcta.
///
/// # Ventajas
/// - Centraliza la creación de coordinadores
/// - Maneja las dependencias automáticamente
/// - Facilita testing mediante inyección
/// - Garantiza configuración consistente
///
/// # Ejemplo de uso:
/// ```swift
/// let factory = CoordinatorFactory(
///     appCoordinator: appCoordinator,
///     mediator: mediator
/// )
///
/// let authCoordinator = factory.makeAuthCoordinator()
/// let dashboardCoordinator = factory.makeDashboardCoordinator()
///
/// authCoordinator.start()
/// ```
@MainActor
public final class CoordinatorFactory {

    // MARK: - Properties

    private let appCoordinator: AppCoordinator
    private let mediator: Mediator

    // MARK: - Initialization

    /// Crea una nueva instancia de CoordinatorFactory.
    ///
    /// - Parameters:
    ///   - appCoordinator: Coordinador principal de la aplicación
    ///   - mediator: Mediator para ejecutar comandos y queries
    public init(appCoordinator: AppCoordinator, mediator: Mediator) {
        self.appCoordinator = appCoordinator
        self.mediator = mediator
    }

    // MARK: - Factory Methods

    /// Crea un coordinador para el flujo de autenticación.
    ///
    /// - Returns: Nueva instancia de AuthCoordinator
    public func makeAuthCoordinator() -> AuthCoordinator {
        AuthCoordinator(appCoordinator: appCoordinator, mediator: mediator)
    }

    /// Crea un coordinador para el flujo de materiales educativos.
    ///
    /// - Returns: Nueva instancia de MaterialsCoordinator
    public func makeMaterialsCoordinator() -> MaterialsCoordinator {
        MaterialsCoordinator(appCoordinator: appCoordinator, mediator: mediator)
    }

    /// Crea un coordinador para el flujo de evaluaciones.
    ///
    /// - Returns: Nueva instancia de AssessmentCoordinator
    public func makeAssessmentCoordinator() -> AssessmentCoordinator {
        AssessmentCoordinator(appCoordinator: appCoordinator, mediator: mediator)
    }

    /// Crea un coordinador para el dashboard principal.
    ///
    /// Este método crea automáticamente las dependencias necesarias
    /// (MaterialsCoordinator y AssessmentCoordinator).
    ///
    /// - Returns: Nueva instancia de DashboardCoordinator con sus dependencias
    public func makeDashboardCoordinator() -> DashboardCoordinator {
        let materialsCoordinator = makeMaterialsCoordinator()
        let assessmentCoordinator = makeAssessmentCoordinator()
        return DashboardCoordinator(
            appCoordinator: appCoordinator,
            materialsCoordinator: materialsCoordinator,
            assessmentCoordinator: assessmentCoordinator
        )
    }
}
