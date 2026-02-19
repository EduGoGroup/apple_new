import SwiftUI

/// Observer que sincroniza el ThemeManager con cambios en el color scheme del sistema.
///
/// ThemeObserver es un ViewModifier invisible que observa cambios en el
/// @Environment(\.colorScheme) y actualiza el ThemeManager automáticamente.
///
/// ## Uso
/// ```swift
/// ContentView()
///     .modifier(ThemeObserver())
/// ```
///
/// O usando la extensión:
/// ```swift
/// ContentView()
///     .observeThemeChanges()
/// ```
@MainActor
public struct ThemeObserver: ViewModifier {

    @Environment(\.themeManager) private var themeManager
    @Environment(\.colorScheme) private var colorScheme

    public init() {}

    public func body(content: Content) -> some View {
        content
            .task(id: colorScheme) {
                // Actualizar ThemeManager cuando cambia el sistema
                themeManager.updateSystemColorScheme(colorScheme)
            }
    }
}

// MARK: - View Extension

extension View {

    /// Aplica el ThemeObserver a esta vista
    ///
    /// Permite que el ThemeManager se sincronice automáticamente con cambios
    /// en el dark mode del sistema operativo.
    ///
    /// ## Uso
    /// ```swift
    /// ContentView()
    ///     .observeThemeChanges()
    /// ```
    @MainActor
    public func observeThemeChanges() -> some View {
        modifier(ThemeObserver())
    }
}

// MARK: - Theme Change Publisher

/// Helper para observar cambios de theme desde código imperativo
///
/// ## Uso
/// ```swift
/// let observer = ThemeChangeObserver(manager: .shared)
/// observer.onThemeChange = { theme in
///     print("Theme changed to: \(theme.name)")
/// }
/// ```
@MainActor
@Observable
public final class ThemeChangeObserver {

    private let manager: ThemeManager

    /// Closure que se ejecuta cuando cambia el theme
    public var onThemeChange: ((Theme) -> Void)?

    /// Closure que se ejecuta cuando cambia el color scheme
    public var onColorSchemeChange: ((ColorScheme) -> Void)?

    private var lastTheme: Theme
    private var lastColorScheme: ColorScheme

    public init(manager: ThemeManager) {
        self.manager = manager
        self.lastTheme = manager.currentTheme
        self.lastColorScheme = manager.effectiveColorScheme

        // Iniciar observación
        Task {
            await observeChanges()
        }
    }

    private func observeChanges() async {
        // Polling simple para detectar cambios
        // En producción, esto debería usar Combine o async streams
        while !Task.isCancelled {
            if manager.currentTheme != lastTheme {
                lastTheme = manager.currentTheme
                onThemeChange?(lastTheme)
            }

            if manager.effectiveColorScheme != lastColorScheme {
                lastColorScheme = manager.effectiveColorScheme
                onColorSchemeChange?(lastColorScheme)
            }

            try? await Task.sleep(for: .milliseconds(100))
        }
    }
}
