import SwiftUI
import EduDomain

/// Coordinador especializado para el flujo del Dashboard principal.
///
/// Gestiona la navegación desde el dashboard hacia otras features
/// (Materials, Assessment, Profile) delegando a los coordinadores
/// especializados o al AppCoordinator según corresponda.
///
/// # Responsabilidades
/// - Mostrar dashboard principal
/// - Navegar a perfil de usuario
/// - Mostrar modal de cambio de contexto
/// - Delegar navegación a Materials y Assessment a sus coordinadores
///
/// # Ejemplo de uso:
/// ```swift
/// let dashboardCoordinator = DashboardCoordinator(
///     appCoordinator: appCoordinator,
///     materialsCoordinator: materialsCoordinator,
///     assessmentCoordinator: assessmentCoordinator
/// )
/// dashboardCoordinator.start() // Navega a dashboard
/// dashboardCoordinator.navigateToMaterials() // Delega a MaterialsCoordinator
/// ```
@MainActor
public final class DashboardCoordinator: FeatureCoordinator {

    // MARK: - Properties

    public let appCoordinator: AppCoordinator
    private let materialsCoordinator: MaterialsCoordinator
    private let assessmentCoordinator: AssessmentCoordinator

    // MARK: - Initialization

    /// Crea una nueva instancia de DashboardCoordinator.
    ///
    /// - Parameters:
    ///   - appCoordinator: Coordinador principal de la aplicación
    ///   - materialsCoordinator: Coordinador del flujo de materiales
    ///   - assessmentCoordinator: Coordinador del flujo de evaluaciones
    public init(
        appCoordinator: AppCoordinator,
        materialsCoordinator: MaterialsCoordinator,
        assessmentCoordinator: AssessmentCoordinator
    ) {
        self.appCoordinator = appCoordinator
        self.materialsCoordinator = materialsCoordinator
        self.assessmentCoordinator = assessmentCoordinator
    }

    // MARK: - FeatureCoordinator

    /// Inicia el flujo del dashboard navegando a la pantalla principal.
    public func start() {
        appCoordinator.navigate(to: .dashboard)
    }

    // MARK: - Dashboard Actions

    /// Navega al perfil del usuario.
    public func showProfile() {
        appCoordinator.navigate(to: .userProfile)
    }

    /// Presenta el modal para cambiar de contexto (rol, grupo, etc.).
    public func showContextSwitch() {
        appCoordinator.presentSheet(.contextSwitch)
    }

    /// Navega al flujo de materiales delegando al MaterialsCoordinator.
    public func navigateToMaterials() {
        materialsCoordinator.showMaterialList()
    }

    /// Navega a una evaluación específica delegando al AssessmentCoordinator.
    ///
    /// - Parameters:
    ///   - assessmentId: ID de la evaluación
    ///   - userId: ID del usuario que realizará la evaluación
    public func navigateToAssessment(assessmentId: UUID, userId: UUID) {
        assessmentCoordinator.showAssessment(assessmentId: assessmentId, userId: userId)
    }
}
