import SwiftUI
import os.log

/// Logger para diagnóstico de problemas con el coordinator environment.
private let coordinatorLogger = Logger(
    subsystem: "com.edugo.navigation",
    category: "CoordinatorEnvironment"
)

/// EnvironmentKey para inyectar AppCoordinator en el environment de SwiftUI.
///
/// Permite acceder al coordinador desde cualquier View sin necesidad de
/// pasar explícitamente la referencia a través de la jerarquía.
///
/// ## Importante
/// El coordinador retorna `nil` si no se ha inyectado. Siempre use
/// `requireCoordinator()` en Views que necesitan navegación obligatoria,
/// o maneje el caso `nil` apropiadamente.
///
/// # Ejemplo de uso:
/// ```swift
/// // En la raíz de la app
/// ContentView()
///     .withCoordinator(appCoordinator)
///
/// // En cualquier View hija (acceso opcional)
/// struct MyView: View {
///     @Environment(\.appCoordinator) var coordinator
///
///     var body: some View {
///         Button("Navigate") {
///             coordinator?.navigate(to: .dashboard)
///         }
///     }
/// }
///
/// // Acceso con validación (recomendado para navegación crítica)
/// struct CriticalNavigationView: View {
///     @Environment(\.appCoordinator) var coordinator
///
///     var body: some View {
///         Button("Navigate") {
///             guard let coordinator else {
///                 assertionFailure("AppCoordinator not injected")
///                 return
///             }
///             coordinator.navigate(to: .dashboard)
///         }
///     }
/// }
/// ```
private struct AppCoordinatorKey: EnvironmentKey {
    static let defaultValue: AppCoordinator? = nil
}

extension EnvironmentValues {
    /// AppCoordinator accesible desde el environment.
    ///
    /// Permite acceder al coordinador de navegación desde cualquier View.
    /// Retorna `nil` si no se ha inyectado un coordinador en el environment.
    ///
    /// - Warning: Siempre verifique si es `nil` antes de usar, especialmente
    ///   en Views que pueden ser usadas fuera de la jerarquía principal.
    public var appCoordinator: AppCoordinator? {
        get { self[AppCoordinatorKey.self] }
        set { self[AppCoordinatorKey.self] = newValue }
    }
}

// MARK: - Safe Access Helpers

extension View {
    /// Ejecuta una acción de navegación de forma segura, loggeando si el coordinator no está disponible.
    ///
    /// Use este helper cuando la navegación es opcional y no debe causar
    /// un crash si el coordinator no está inyectado.
    ///
    /// - Parameters:
    ///   - coordinator: El coordinator opcional del environment
    ///   - file: Archivo desde donde se llama (para logging)
    ///   - function: Función desde donde se llama (para logging)
    ///   - action: Acción a ejecutar con el coordinator
    @MainActor
    public static func safeNavigate(
        with coordinator: AppCoordinator?,
        file: String = #file,
        function: String = #function,
        action: (AppCoordinator) -> Void
    ) {
        guard let coordinator else {
            let fileName = (file as NSString).lastPathComponent
            coordinatorLogger.warning(
                "Navigation attempted without coordinator in \(fileName, privacy: .public):\(function, privacy: .public)"
            )
            return
        }
        action(coordinator)
    }
}

extension View {
    /// Inyecta un AppCoordinator en el environment de la View.
    ///
    /// Todas las Views hijas tendrán acceso al coordinador a través
    /// del environment.
    ///
    /// - Parameter coordinator: Coordinador a inyectar
    /// - Returns: View modificada con el coordinador en el environment
    ///
    /// # Ejemplo:
    /// ```swift
    /// NavigationStack {
    ///     RootView()
    /// }
    /// .withCoordinator(appCoordinator)
    /// ```
    public func withCoordinator(_ coordinator: AppCoordinator) -> some View {
        environment(\.appCoordinator, coordinator)
    }
}
