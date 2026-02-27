import Foundation

/// Protocolo base para coordinadores especializados por feature.
///
/// Los FeatureCoordinators gestionan la navegación interna de cada flujo
/// específico (Auth, Materials, Assessment, Dashboard) delegando al
/// AppCoordinator para navegación global.
///
/// # Arquitectura
/// - Cada feature tiene su propio coordinator
/// - Los coordinators delegan al AppCoordinator para navegación real
/// - Proporciona separación de concerns por feature
/// - Facilita testing y mantenimiento
///
/// # Ejemplo de uso:
/// ```swift
/// let authCoordinator = AuthCoordinator(
///     appCoordinator: appCoordinator,
///     mediator: mediator
/// )
/// authCoordinator.start()
/// authCoordinator.showLogin()
/// ```
@MainActor
public protocol FeatureCoordinator: AnyObject {
    /// Referencia al coordinador principal de la aplicación
    var appCoordinator: AppCoordinator { get }

    /// Inicia el flujo de la feature, navegando a la pantalla inicial
    func start()
}
