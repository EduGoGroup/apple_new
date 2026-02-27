import SwiftUI
import EduDomain

/// Coordinador especializado para el flujo de evaluaciones/assessments.
///
/// Gestiona la navegación relacionada con realizar evaluaciones y ver
/// resultados delegando al AppCoordinator para navegación global.
///
/// # Responsabilidades
/// - Navegar a una evaluación específica
/// - Mostrar resultados de una evaluación
/// - Volver al dashboard después de completar evaluación
///
/// # Ejemplo de uso:
/// ```swift
/// let assessmentCoordinator = AssessmentCoordinator(
///     appCoordinator: appCoordinator,
///     mediator: mediator
/// )
/// assessmentCoordinator.showAssessment(
///     assessmentId: id,
///     userId: userId
/// )
/// assessmentCoordinator.showResults(assessmentId: id)
/// ```
@MainActor
public final class AssessmentCoordinator: FeatureCoordinator {

    // MARK: - Properties

    public let appCoordinator: AppCoordinator
    private let mediator: Mediator

    // MARK: - Initialization

    /// Crea una nueva instancia de AssessmentCoordinator.
    ///
    /// - Parameters:
    ///   - appCoordinator: Coordinador principal de la aplicación
    ///   - mediator: Mediator para ejecutar comandos
    public init(appCoordinator: AppCoordinator, mediator: Mediator) {
        self.appCoordinator = appCoordinator
        self.mediator = mediator
    }

    // MARK: - FeatureCoordinator

    /// Inicia el flujo de assessment.
    ///
    /// NOTA: Assessment requiere IDs específicos, por lo que no hay
    /// navegación por defecto. Usar showAssessment() en su lugar.
    public func start() {
        // Assessment requires specific IDs, so no default start
    }

    // MARK: - Assessment Flow Actions

    /// Navega a una evaluación específica.
    ///
    /// - Parameters:
    ///   - assessmentId: ID de la evaluación a realizar
    ///   - userId: ID del usuario que realiza la evaluación
    public func showAssessment(assessmentId: UUID, userId: UUID) {
        appCoordinator.navigate(to: .assessment(assessmentId: assessmentId, userId: userId))
    }

    /// Muestra los resultados de una evaluación completada.
    ///
    /// - Parameter assessmentId: ID de la evaluación cuyos resultados mostrar
    public func showResults(assessmentId: UUID) {
        appCoordinator.navigate(to: .assessmentResults(assessmentId: assessmentId))
    }

    /// Vuelve al dashboard después de completar una evaluación.
    public func returnToDashboard() {
        appCoordinator.popToRoot()
    }
}
