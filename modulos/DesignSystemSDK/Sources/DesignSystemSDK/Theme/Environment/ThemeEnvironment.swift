import SwiftUI

// MARK: - Environment Keys

/// EnvironmentKey para el Theme actual
struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue: Theme = .default
}

/// EnvironmentKey para el ThemeManager
struct ThemeManagerEnvironmentKey: EnvironmentKey {
    static let defaultValue: ThemeManager = MainActor.assumeIsolated { ThemeManager.shared }
}

// MARK: - EnvironmentValues Extension

extension EnvironmentValues {

    /// Theme actual en el environment
    public var theme: Theme {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }

    /// ThemeManager en el environment
    public var themeManager: ThemeManager {
        get { self[ThemeManagerEnvironmentKey.self] }
        set { self[ThemeManagerEnvironmentKey.self] = newValue }
    }
}

// MARK: - View Extensions

extension View {

    /// Inyecta un Theme específico en el environment de esta vista y sus hijas
    ///
    /// - Parameter theme: Theme a inyectar
    /// - Returns: Vista modificada con el theme en su environment
    ///
    /// ## Uso
    /// ```swift
    /// MyView()
    ///     .theme(.dark)
    /// ```
    @MainActor
    public func theme(_ theme: Theme) -> some View {
        environment(\.theme, theme)
    }

    /// Inyecta un ThemeManager específico en el environment de esta vista y sus hijas
    ///
    /// - Parameter manager: ThemeManager a inyectar
    /// - Returns: Vista modificada con el manager en su environment
    ///
    /// ## Uso
    /// ```swift
    /// MyView()
    ///     .themeManager(customManager)
    /// ```
    @MainActor
    public func themeManager(_ manager: ThemeManager) -> some View {
        environment(\.themeManager, manager)
    }

    /// Aplica el theme activo del ThemeManager y sincroniza con el color scheme
    ///
    /// Este modifier observa cambios en ThemeManager y actualiza automáticamente
    /// el theme y el color scheme de la vista.
    ///
    /// ## Uso
    /// ```swift
    /// ContentView()
    ///     .themedApp()
    /// ```
    @MainActor
    public func themedApp() -> some View {
        ThemedAppModifier(content: self)
    }
}

// MARK: - ThemedAppModifier

/// ViewModifier que aplica theming completo a la app
@MainActor
private struct ThemedAppModifier<Content: View>: View {

    let content: Content

    @Environment(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var systemColorScheme

    var body: some View {
        content
            .environment(\.theme, themeManager.currentTheme)
            .preferredColorScheme(resolvedColorScheme)
            .task(id: systemColorScheme) {
                // Actualizar ThemeManager cuando cambia el color scheme del sistema
                themeManager.updateSystemColorScheme(systemColorScheme)
            }
    }

    private var resolvedColorScheme: ColorScheme? {
        switch themeManager.colorSchemePreference {
        case .light:
            return .light
        case .dark:
            return .dark
        case .auto:
            return nil  // Dejar que el sistema decida
        }
    }
}

// MARK: - Themed View Wrapper

/// Vista wrapper que proporciona acceso conveniente al theme actual
///
/// ## Uso
/// ```swift
/// ThemedView { theme in
///     Text("Hello")
///         .foregroundStyle(Color.theme.textPrimary)
///         .padding(theme.spacing.md)
/// }
/// ```
@MainActor
public struct ThemedView<Content: View>: View {

    @Environment(\.theme) private var theme
    private let content: (Theme) -> Content

    public init(@ViewBuilder content: @escaping (Theme) -> Content) {
        self.content = content
    }

    public var body: some View {
        content(theme)
    }
}
