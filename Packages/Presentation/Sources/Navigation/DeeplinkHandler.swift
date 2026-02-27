import Foundation
import SwiftUI
import OSLog

/// Handler principal para procesamiento de deeplinks en la aplicación.
///
/// DeeplinkHandler gestiona deeplinks de múltiples fuentes:
/// - URL Schemes (`edugo://`)
/// - Universal Links (`https://edugo.app/`)
/// - Push Notifications (payload con deeplink)
///
/// # Características
/// - Parsing automático de URLs
/// - Validación de autenticación para rutas protegidas
/// - Post-login navigation a deeplinks almacenados
/// - Logging estructurado con OSLog
/// - Observable para integración SwiftUI
///
/// # Ejemplo de uso:
/// ```swift
/// @StateObject var deeplinkHandler = DeeplinkHandler(appCoordinator: coordinator)
///
/// // En App
/// .onOpenURL { url in
///     _ = deeplinkHandler.handle(url)
/// }
/// ```
@MainActor
@Observable
public final class DeeplinkHandler {

    // MARK: - Properties

    private let appCoordinator: AppCoordinator
    private let logger: Logger

    /// Último deeplink procesado (útil para debugging y post-login navigation)
    public private(set) var lastDeeplink: Deeplink?

    // MARK: - Initialization

    /// Crea una nueva instancia de DeeplinkHandler.
    ///
    /// - Parameters:
    ///   - appCoordinator: Coordinador principal para navegación
    ///   - subsystem: Subsystem para logging (default: com.edugo.navigation)
    ///   - category: Categoría para logging (default: DeeplinkHandler)
    public init(
        appCoordinator: AppCoordinator,
        subsystem: String = "com.edugo.navigation",
        category: String = "DeeplinkHandler"
    ) {
        self.appCoordinator = appCoordinator
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    // MARK: - URL Handling

    /// Procesa una URL y navega al destino correspondiente.
    ///
    /// Parsea la URL usando DeeplinkParser y navega a la pantalla
    /// correspondiente si es válida.
    ///
    /// - Parameter url: URL a procesar
    /// - Returns: `true` si la URL fue procesada exitosamente, `false` si no
    ///
    /// # Ejemplo:
    /// ```swift
    /// let url = URL(string: "edugo://dashboard")!
    /// let handled = deeplinkHandler.handle(url)
    /// // handled == true, navega a dashboard
    /// ```
    @discardableResult
    public func handle(_ url: URL) -> Bool {
        logger.info("Handling deeplink: \(url.absoluteString, privacy: .public)")

        guard let deeplink = DeeplinkParser.parse(url) else {
            logger.error("Failed to parse deeplink: \(url.absoluteString, privacy: .public)")
            return false
        }

        lastDeeplink = deeplink
        navigate(to: deeplink)
        return true
    }

    // MARK: - Push Notification Handling

    /// Procesa un deeplink desde una notificación push.
    ///
    /// Extrae el deeplink del payload de la notificación y lo procesa.
    ///
    /// - Parameter userInfo: Payload de la notificación push
    /// - Returns: `true` si se procesó exitosamente, `false` si no
    ///
    /// # Formato esperado del payload:
    /// ```json
    /// {
    ///   "deeplink": "edugo://materials/abc-123"
    /// }
    /// ```
    @discardableResult
    public func handlePushNotification(userInfo: [AnyHashable: Any]) -> Bool {
        logger.info("Handling push notification")

        // Extract deeplink from notification payload
        guard let deeplinkString = userInfo["deeplink"] as? String,
              let url = URL(string: deeplinkString) else {
            logger.error("No valid deeplink in push notification")
            return false
        }

        return handle(url)
    }

    // MARK: - Universal Links

    /// Procesa un universal link desde NSUserActivity.
    ///
    /// Extrae la URL del user activity y la procesa como deeplink.
    ///
    /// - Parameter userActivity: NSUserActivity con tipo browsing web
    /// - Returns: `true` si se procesó exitosamente, `false` si no
    @discardableResult
    public func handleUniversalLink(_ userActivity: NSUserActivity) -> Bool {
        logger.info("Handling universal link")

        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else {
            logger.error("Invalid user activity for universal link")
            return false
        }

        return handle(url)
    }

    // MARK: - Private Navigation

    /// Navega al deeplink especificado.
    ///
    /// Valida autenticación para rutas protegidas y navega a la pantalla.
    /// Si el usuario no está autenticado para una ruta protegida, guarda
    /// el deeplink y navega a login.
    private func navigate(to deeplink: Deeplink) {
        let screen = deeplink.toScreen()

        // Check authentication for protected routes
        let requiresAuth = !isPublicRoute(screen)

        if requiresAuth && !appCoordinator.isAuthenticated {
            logger.warning("Attempted to navigate to protected route without authentication")
            // Store deeplink for later navigation after login
            lastDeeplink = deeplink
            appCoordinator.navigate(to: .login)
            return
        }

        // Navigate to screen
        appCoordinator.popToRoot()
        appCoordinator.navigate(to: screen)

        logger.info("Navigated to: \(screen.id, privacy: .public)")
    }

    /// Determina si una pantalla es pública (no requiere autenticación).
    ///
    /// - Parameter screen: Pantalla a validar
    /// - Returns: `true` si la pantalla es pública, `false` si requiere auth
    private func isPublicRoute(_ screen: Screen) -> Bool {
        switch screen {
        case .login:
            return true
        default:
            return false
        }
    }

    // MARK: - Post-Login Navigation

    /// Navega al deeplink almacenado después de login exitoso.
    ///
    /// Debe ser llamado después de que el usuario se autentique
    /// para navegar al destino original que intentó acceder.
    ///
    /// # Ejemplo de uso:
    /// ```swift
    /// // Después de login exitoso
    /// deeplinkHandler.handlePostLoginNavigation()
    /// ```
    public func handlePostLoginNavigation() {
        guard let deeplink = lastDeeplink else { return }

        logger.info("Navigating to stored deeplink after login")
        navigate(to: deeplink)
        lastDeeplink = nil
    }
}
