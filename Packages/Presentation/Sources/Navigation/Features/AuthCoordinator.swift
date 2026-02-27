import SwiftUI
import EduDomain

/// Coordinador especializado para el flujo de autenticación.
///
/// Gestiona la navegación relacionada con login, logout y autenticación
/// delegando al AppCoordinator para navegación global.
///
/// # Responsabilidades
/// - Mostrar pantalla de login
/// - Manejar navegación post-login (delegada a eventos)
/// - Manejar logout y reset de navegación
///
/// # Ejemplo de uso:
/// ```swift
/// let authCoordinator = AuthCoordinator(
///     appCoordinator: appCoordinator,
///     mediator: mediator
/// )
/// authCoordinator.start() // Navega a login
/// authCoordinator.handleLogout() // Reset navegación
/// ```
@MainActor
public final class AuthCoordinator: FeatureCoordinator {

    // MARK: - Properties

    public let appCoordinator: AppCoordinator
    private let mediator: Mediator

    // MARK: - Initialization

    /// Crea una nueva instancia de AuthCoordinator.
    ///
    /// - Parameters:
    ///   - appCoordinator: Coordinador principal de la aplicación
    ///   - mediator: Mediator para ejecutar comandos
    public init(appCoordinator: AppCoordinator, mediator: Mediator) {
        self.appCoordinator = appCoordinator
        self.mediator = mediator
    }

    // MARK: - FeatureCoordinator

    /// Inicia el flujo de autenticación navegando a la pantalla de login.
    public func start() {
        appCoordinator.navigate(to: .login)
    }

    // MARK: - Auth Flow Actions

    /// Muestra la pantalla de login.
    ///
    /// Útil para navegación explícita desde otras partes de la app.
    public func showLogin() {
        appCoordinator.navigate(to: .login)
    }

    /// Maneja el éxito del login.
    ///
    /// NOTA: La navegación post-login es manejada automáticamente
    /// por el AppCoordinator a través del LoginSuccessEvent.
    /// Este método existe para llamadas explícitas si fuera necesario.
    public func handleLoginSuccess() {
        // Navigation handled by AppCoordinator via LoginSuccessEvent
        // This method exists for explicit calls if needed
    }

    /// Maneja el logout del usuario.
    ///
    /// Resetea toda la navegación y vuelve a la pantalla de login.
    public func handleLogout() {
        appCoordinator.resetNavigation()
    }
}
