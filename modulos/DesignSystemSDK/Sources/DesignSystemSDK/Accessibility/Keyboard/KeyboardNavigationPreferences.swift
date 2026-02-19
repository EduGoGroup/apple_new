import SwiftUI
import Foundation

/// Sistema de preferencias de usuario para keyboard navigation
///
/// Permite a los usuarios personalizar shortcuts, habilitar/deshabilitar features
/// de keyboard navigation, y guardar sus preferencias de forma persistente.
@MainActor
@Observable
public final class KeyboardNavigationPreferences {

    // MARK: - Singleton

    public static let shared = KeyboardNavigationPreferences()

    // MARK: - Properties

    /// Indica si keyboard navigation está globalmente habilitado
    public var isEnabled: Bool {
        didSet {
            if oldValue != isEnabled {
                save()
                notifyObservers()
            }
        }
    }

    /// Indica si tab order optimization está habilitado
    public var isTabOrderOptimizationEnabled: Bool {
        didSet {
            if oldValue != isTabOrderOptimizationEnabled {
                save()
            }
        }
    }

    /// Indica si focus trap está habilitado para modals
    public var isFocusTrapEnabled: Bool {
        didSet {
            if oldValue != isFocusTrapEnabled {
                save()
            }
        }
    }

    /// Indica si escape hatches están habilitados
    public var areEscapeHatchesEnabled: Bool {
        didSet {
            if oldValue != areEscapeHatchesEnabled {
                save()
                EscapeHatchManager.shared.setGloballyEnabled(areEscapeHatchesEnabled)
            }
        }
    }

    /// Indica si se deben mostrar hints de keyboard shortcuts
    public var showKeyboardHints: Bool {
        didSet {
            if oldValue != showKeyboardHints {
                save()
            }
        }
    }

    /// Shortcuts custom definidos por el usuario
    public var customShortcuts: [String: KeyboardShortcutDefinition] = [:] {
        didSet {
            save()
        }
    }

    /// Observers registrados
    private var observers: [UUID: @Sendable () -> Void] = [:]

    // MARK: - User Defaults Keys

    private enum UserDefaultsKeys {
        static let isEnabled = "keyboard_navigation_enabled"
        static let isTabOrderOptimizationEnabled = "tab_order_optimization_enabled"
        static let isFocusTrapEnabled = "focus_trap_enabled"
        static let areEscapeHatchesEnabled = "escape_hatches_enabled"
        static let showKeyboardHints = "show_keyboard_hints"
        static let customShortcuts = "custom_shortcuts"
    }

    // MARK: - Initialization

    private init() {
        // Set defaults if first launch
        if !UserDefaults.standard.bool(forKey: "keyboard_navigation_first_launch_done") {
            UserDefaults.standard.set(true, forKey: UserDefaultsKeys.isEnabled)
            UserDefaults.standard.set(true, forKey: UserDefaultsKeys.isTabOrderOptimizationEnabled)
            UserDefaults.standard.set(true, forKey: UserDefaultsKeys.isFocusTrapEnabled)
            UserDefaults.standard.set(true, forKey: UserDefaultsKeys.areEscapeHatchesEnabled)
            UserDefaults.standard.set(true, forKey: UserDefaultsKeys.showKeyboardHints)
            UserDefaults.standard.set(true, forKey: "keyboard_navigation_first_launch_done")
        }

        // Load saved preferences
        self.isEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.isEnabled)
        self.isTabOrderOptimizationEnabled = UserDefaults.standard.bool(
            forKey: UserDefaultsKeys.isTabOrderOptimizationEnabled
        )
        self.isFocusTrapEnabled = UserDefaults.standard.bool(
            forKey: UserDefaultsKeys.isFocusTrapEnabled
        )
        self.areEscapeHatchesEnabled = UserDefaults.standard.bool(
            forKey: UserDefaultsKeys.areEscapeHatchesEnabled
        )
        self.showKeyboardHints = UserDefaults.standard.bool(
            forKey: UserDefaultsKeys.showKeyboardHints
        )
    }

    // MARK: - Defaults

    private func setDefaults() {
        isEnabled = true
        isTabOrderOptimizationEnabled = true
        isFocusTrapEnabled = true
        areEscapeHatchesEnabled = true
        showKeyboardHints = true
        save()
    }

    /// Restaura todas las preferencias a sus valores por defecto
    public func resetToDefaults() {
        setDefaults()
        customShortcuts.removeAll()
        notifyObservers()
    }

    // MARK: - Persistence

    /// Guarda las preferencias en UserDefaults
    private func save() {
        UserDefaults.standard.set(isEnabled, forKey: UserDefaultsKeys.isEnabled)
        UserDefaults.standard.set(
            isTabOrderOptimizationEnabled,
            forKey: UserDefaultsKeys.isTabOrderOptimizationEnabled
        )
        UserDefaults.standard.set(
            isFocusTrapEnabled,
            forKey: UserDefaultsKeys.isFocusTrapEnabled
        )
        UserDefaults.standard.set(
            areEscapeHatchesEnabled,
            forKey: UserDefaultsKeys.areEscapeHatchesEnabled
        )
        UserDefaults.standard.set(
            showKeyboardHints,
            forKey: UserDefaultsKeys.showKeyboardHints
        )
    }

    // MARK: - Custom Shortcuts

    /// Registra un custom shortcut
    /// - Parameter shortcut: Definición del shortcut
    public func registerCustomShortcut(_ shortcut: KeyboardShortcutDefinition) {
        customShortcuts[shortcut.id] = shortcut

        // Intentar registrar en el registry global
        try? KeyboardShortcutRegistry.shared.register(shortcut)
    }

    /// Remueve un custom shortcut
    /// - Parameter id: ID del shortcut
    public func removeCustomShortcut(id: String) {
        customShortcuts.removeValue(forKey: id)
        KeyboardShortcutRegistry.shared.unregister(id)
    }

    /// Obtiene un custom shortcut por ID
    /// - Parameter id: ID del shortcut
    /// - Returns: El shortcut si existe
    public func customShortcut(for id: String) -> KeyboardShortcutDefinition? {
        customShortcuts[id]
    }

    // MARK: - Observers

    /// Registra un observer para cambios en preferencias
    /// - Parameter observer: Closure que se llama cuando cambian las preferencias
    /// - Returns: Token para desregistrar el observer
    @discardableResult
    public func addObserver(_ observer: @escaping @Sendable () -> Void) -> UUID {
        let id = UUID()
        observers[id] = observer
        return id
    }

    /// Remueve un observer
    /// - Parameter id: Token del observer
    public func removeObserver(id: UUID) {
        observers.removeValue(forKey: id)
    }

    private func notifyObservers() {
        for observer in observers.values {
            observer()
        }
    }

    // MARK: - Platform-Specific Settings

    /// Indica si keyboard navigation está disponible en la plataforma actual
    public var isAvailableOnCurrentPlatform: Bool {
        #if os(macOS) || os(iOS)
        return true
        #else
        return false
        #endif
    }

    /// Configuración recomendada por plataforma
    public static var platformRecommendedSettings: KeyboardNavigationPreferences {
        let prefs = KeyboardNavigationPreferences()

        #if os(macOS)
        // macOS tiene keyboard navigation más completo
        prefs.isEnabled = true
        prefs.isTabOrderOptimizationEnabled = true
        prefs.isFocusTrapEnabled = true
        prefs.areEscapeHatchesEnabled = true
        prefs.showKeyboardHints = true

        #elseif os(iOS)
        // iOS puede tener keyboard con iPad + Magic Keyboard
        prefs.isEnabled = true
        prefs.isTabOrderOptimizationEnabled = true
        prefs.isFocusTrapEnabled = true
        prefs.areEscapeHatchesEnabled = false  // Escape no es común en iOS
        prefs.showKeyboardHints = false  // Menos espacio en pantalla

        #elseif os(visionOS)
        // visionOS con teclado virtual o físico
        prefs.isEnabled = true
        prefs.isTabOrderOptimizationEnabled = true
        prefs.isFocusTrapEnabled = false  // Focus management diferente en visionOS
        prefs.areEscapeHatchesEnabled = false
        prefs.showKeyboardHints = true

        #else
        // Otras plataformas: deshabilitado por defecto
        prefs.isEnabled = false
        #endif

        return prefs
    }
}

// MARK: - Preference Types

/// Representa el nivel de agresividad del tab order optimization
public enum TabOrderOptimizationLevel: String, Sendable, CaseIterable {
    /// Sin optimización (orden natural de SwiftUI)
    case none

    /// Optimización básica (top-to-bottom, left-to-right)
    case basic

    /// Optimización avanzada (con priority-based ordering)
    case advanced

    public var description: String {
        switch self {
        case .none:
            return "None"
        case .basic:
            return "Basic"
        case .advanced:
            return "Advanced"
        }
    }
}

// MARK: - Environment Integration

extension KeyboardNavigationPreferencesKey: @preconcurrency EnvironmentKey {}
public struct KeyboardNavigationPreferencesKey {
    @MainActor
    public static var defaultValue: KeyboardNavigationPreferences {
        .shared
    }
}

extension EnvironmentValues {
    /// Acceso a las preferencias de keyboard navigation desde el environment
    public var keyboardNavigationPreferences: KeyboardNavigationPreferences {
        get { self[KeyboardNavigationPreferencesKey.self] }
        set { self[KeyboardNavigationPreferencesKey.self] = newValue }
    }
}

// MARK: - View Extensions

extension View {
    /// Inyecta las preferencias de keyboard navigation en el environment
    /// - Parameter preferences: Preferencias a inyectar (por defecto usa .shared)
    /// - Returns: View con preferencias en el environment
    public func keyboardNavigationPreferences(
        _ preferences: KeyboardNavigationPreferences = .shared
    ) -> some View {
        environment(\.keyboardNavigationPreferences, preferences)
    }
}

// MARK: - Settings UI Helper

/// Helper para generar UI de settings de keyboard navigation
public struct KeyboardNavigationSettingsView: View {
    @State private var preferences = KeyboardNavigationPreferences.shared

    public init() {}

    public var body: some View {
        Form {
            Section("General") {
                Toggle("Enable Keyboard Navigation", isOn: $preferences.isEnabled)
                    .disabled(!preferences.isAvailableOnCurrentPlatform)

                Toggle("Show Keyboard Hints", isOn: $preferences.showKeyboardHints)
                    .disabled(!preferences.isEnabled)
            }

            Section("Features") {
                Toggle("Tab Order Optimization", isOn: $preferences.isTabOrderOptimizationEnabled)
                    .disabled(!preferences.isEnabled)

                Toggle("Focus Trap (Modals)", isOn: $preferences.isFocusTrapEnabled)
                    .disabled(!preferences.isEnabled)

                Toggle("Escape Hatches", isOn: $preferences.areEscapeHatchesEnabled)
                    .disabled(!preferences.isEnabled)
            }

            Section {
                Button("Reset to Defaults") {
                    preferences.resetToDefaults()
                }
            }
        }
        .formStyle(.grouped)
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 300)
        #endif
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension KeyboardNavigationPreferences {
    /// Genera un reporte del estado actual de preferencias (solo para debugging)
    public func debugReport() -> String {
        var report = "Keyboard Navigation Preferences Report\n"
        report += "======================================\n\n"

        report += "Enabled: \(isEnabled)\n"
        report += "Tab Order Optimization: \(isTabOrderOptimizationEnabled)\n"
        report += "Focus Trap: \(isFocusTrapEnabled)\n"
        report += "Escape Hatches: \(areEscapeHatchesEnabled)\n"
        report += "Show Keyboard Hints: \(showKeyboardHints)\n"
        report += "Custom Shortcuts: \(customShortcuts.count)\n\n"

        if !customShortcuts.isEmpty {
            report += "Custom Shortcuts:\n"
            for (id, shortcut) in customShortcuts {
                report += "- \(id): \(shortcut.displayString) (\(shortcut.description))\n"
            }
        }

        return report
    }
}
#endif
