import SwiftUI
import Observation

/// Gestor centralizado del tema de la aplicación.
///
/// ThemeManager es un gestor observable que gestiona el tema activo,
/// las preferencias del usuario y la sincronización con el esquema de color del sistema.
///
/// ## Thread Safety
/// ThemeManager usa @MainActor para garantizar acceso thread-safe desde el main thread.
///
/// ## Observation
/// Marcado con @Observable, permitiendo que las vistas SwiftUI se actualicen
/// automáticamente cuando cambia el tema.
///
/// ## Uso
/// ```swift
/// let manager = ThemeManager.shared
/// manager.setTheme(.dark)
/// manager.setColorScheme(.auto)
/// ```
@Observable
@MainActor
public final class ThemeManager {

    // MARK: - Singleton

    /// Instancia compartida del ThemeManager
    public static let shared: ThemeManager = ThemeManager()

    // MARK: - Properties

    /// Tema actual de la aplicación
    public private(set) var currentTheme: Theme

    /// Esquema de color preferido por el usuario
    public private(set) var colorSchemePreference: ColorSchemePreference

    /// Esquema de color efectivo (resuelto según preferencia y sistema)
    public private(set) var effectiveColorScheme: ColorScheme

    // MARK: - Private Properties

    private let userDefaults: UserDefaults
    private var systemColorScheme: ColorScheme = .light

    // MARK: - Keys

    private enum Keys {
        static let themeId = "com.edugo.theme.selectedThemeId"
        static let colorScheme = "com.edugo.theme.colorScheme"
    }

    // MARK: - Initializer

    /// Inicializa el ThemeManager
    /// - Parameter userDefaults: UserDefaults para persistencia (inyectable para testing)
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        // Cargar preferencias guardadas
        let savedThemeId = userDefaults.string(forKey: Keys.themeId) ?? "default"
        let savedColorSchemeRaw = userDefaults.string(forKey: Keys.colorScheme) ?? "auto"
        let savedColorScheme = ColorSchemePreference(rawValue: savedColorSchemeRaw) ?? .auto

        self.currentTheme = Self.themeForId(savedThemeId)
        self.colorSchemePreference = savedColorScheme
        self.effectiveColorScheme = .light

        updateEffectiveColorScheme()
    }

    // MARK: - Public Methods

    /// Cambia el tema activo
    /// - Parameter theme: Nuevo tema a aplicar
    public func setTheme(_ theme: Theme) {
        currentTheme = theme
        userDefaults.set(theme.id, forKey: Keys.themeId)
    }

    /// Cambia la preferencia de esquema de color
    /// - Parameter preference: Nueva preferencia (.light, .dark, .auto)
    public func setColorScheme(_ preference: ColorSchemePreference) {
        colorSchemePreference = preference
        userDefaults.set(preference.rawValue, forKey: Keys.colorScheme)
        updateEffectiveColorScheme()
    }

    /// Actualiza el esquema de color del sistema
    /// - Parameter systemScheme: Esquema detectado del sistema
    public func updateSystemColorScheme(_ systemScheme: ColorScheme) {
        systemColorScheme = systemScheme
        updateEffectiveColorScheme()
    }

    /// Restaura la configuración a valores por defecto
    public func reset() {
        currentTheme = .default
        colorSchemePreference = .auto
        effectiveColorScheme = systemColorScheme

        userDefaults.removeObject(forKey: Keys.themeId)
        userDefaults.removeObject(forKey: Keys.colorScheme)
    }

    /// Carga un tema personalizado
    /// - Parameter theme: Tema custom a cargar
    public func loadCustomTheme(_ theme: Theme) {
        currentTheme = theme
        userDefaults.set(theme.id, forKey: Keys.themeId)
    }

    // MARK: - Private Methods

    private func updateEffectiveColorScheme() {
        switch colorSchemePreference {
        case .light:
            effectiveColorScheme = .light
        case .dark:
            effectiveColorScheme = .dark
        case .auto:
            effectiveColorScheme = systemColorScheme
        }
    }

    private static func themeForId(_ id: String) -> Theme {
        switch id {
        case "default":
            return .default
        case "dark":
            return .dark
        case "highContrast":
            return .highContrast
        case "grayscale":
            return .grayscale
        default:
            return .default
        }
    }
}

// MARK: - Convenience Accessors

extension ThemeManager {

    /// Indica si está usando dark mode actualmente
    public var isDarkMode: Bool {
        effectiveColorScheme == .dark
    }

    /// Indica si está en modo automático
    public var isAutoMode: Bool {
        colorSchemePreference == .auto
    }

    /// Temas predefinidos disponibles
    public var availableThemes: [Theme] {
        [.default, .dark, .highContrast, .grayscale]
    }
}

// MARK: - ColorSchemePreference

/// Preferencia de esquema de color
public enum ColorSchemePreference: String, Sendable, CaseIterable {

    /// Modo claro forzado
    case light = "light"

    /// Modo oscuro forzado
    case dark = "dark"

    /// Automático según configuración del sistema
    case auto = "auto"

    /// Nombre legible para UI
    public var displayName: String {
        switch self {
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        case .auto:
            return "Auto"
        }
    }
}
