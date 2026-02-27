import SwiftUI

/// Identificadores únicos y semánticos para elementos UI, diseñados para testing automatizado.
///
/// Los accessibility identifiers son fundamentales para:
/// - UI Testing (XCUITest en iOS/macOS)
/// - Testing de automatización cross-platform (Appium)
/// - Debugging de accesibilidad
/// - Análisis de usage analytics
///
/// ## Naming Convention
/// Los identifiers siguen el formato: `<module>_<screen>_<component>_<action>`
///
/// Ejemplos:
/// - `auth_login_button_submit`
/// - `profile_settings_toggle_notifications`
/// - `feed_post_button_like`
///
/// ## Ejemplo de uso
/// ```swift
/// Button("Login") { }
///     .accessibleIdentifier(.button(module: "auth", screen: "login", action: "submit"))
/// ```
public struct AccessibilityIdentifier: Sendable, Equatable, Hashable {
    /// Identificador único
    public let id: String

    private init(_ id: String) {
        self.id = id
    }

    // MARK: - Static Constructors

    /// Crea un identifier custom
    public static func custom(_ id: String) -> AccessibilityIdentifier {
        AccessibilityIdentifier(id)
    }

    /// Crea un identifier para un botón
    ///
    /// - Parameters:
    ///   - module: Módulo o feature (ej: "auth", "profile")
    ///   - screen: Pantalla donde está el botón (ej: "login", "settings")
    ///   - action: Acción que realiza (ej: "submit", "cancel")
    ///   - context: Contexto alternativo (usa action si no se provee)
    public static func button(
        module: String,
        screen: String,
        action: String? = nil,
        context: String? = nil
    ) -> AccessibilityIdentifier {
        let suffix = action ?? context ?? "default"
        return AccessibilityIdentifier("\(module)_\(screen)_button_\(suffix)")
    }

    /// Crea un identifier para un campo de texto
    public static func textField(
        module: String,
        screen: String,
        field: String? = nil,
        context: String? = nil
    ) -> AccessibilityIdentifier {
        let suffix = field ?? context ?? "default"
        return AccessibilityIdentifier("\(module)_\(screen)_textfield_\(suffix)")
    }

    /// Crea un identifier para un campo seguro (contraseña)
    public static func secureField(
        module: String,
        screen: String,
        context: String
    ) -> AccessibilityIdentifier {
        AccessibilityIdentifier("\(module)_\(screen)_securefield_\(context)")
    }

    /// Crea un identifier para un campo de búsqueda
    public static func searchField(
        module: String,
        screen: String,
        context: String
    ) -> AccessibilityIdentifier {
        AccessibilityIdentifier("\(module)_\(screen)_searchfield_\(context)")
    }

    /// Crea un identifier para un toggle/switch
    public static func toggle(
        module: String,
        screen: String,
        setting: String
    ) -> AccessibilityIdentifier {
        AccessibilityIdentifier("\(module)_\(screen)_toggle_\(setting)")
    }

    /// Crea un identifier para un link
    public static func link(
        module: String,
        screen: String,
        destination: String
    ) -> AccessibilityIdentifier {
        AccessibilityIdentifier("\(module)_\(screen)_link_\(destination)")
    }

    /// Crea un identifier para una celda de lista/tabla
    public static func cell(
        module: String,
        screen: String,
        index: Int? = nil
    ) -> AccessibilityIdentifier {
        if let index = index {
            return AccessibilityIdentifier("\(module)_\(screen)_cell_\(index)")
        } else {
            return AccessibilityIdentifier("\(module)_\(screen)_cell")
        }
    }

    /// Crea un identifier para un header/título
    public static func header(
        module: String,
        screen: String,
        section: String? = nil
    ) -> AccessibilityIdentifier {
        if let section = section {
            return AccessibilityIdentifier("\(module)_\(screen)_header_\(section)")
        } else {
            return AccessibilityIdentifier("\(module)_\(screen)_header")
        }
    }

    /// Crea un identifier para un tab
    public static func tab(
        module: String,
        name: String
    ) -> AccessibilityIdentifier {
        AccessibilityIdentifier("\(module)_tab_\(name)")
    }

    /// Crea un identifier para una imagen
    public static func image(
        module: String,
        screen: String,
        name: String
    ) -> AccessibilityIdentifier {
        AccessibilityIdentifier("\(module)_\(screen)_image_\(name)")
    }

    /// Crea un identifier para un modal/sheet
    public static func modal(
        module: String,
        name: String
    ) -> AccessibilityIdentifier {
        AccessibilityIdentifier("\(module)_modal_\(name)")
    }

    /// Crea un identifier para un alert/dialog
    public static func alert(
        module: String,
        type: String
    ) -> AccessibilityIdentifier {
        AccessibilityIdentifier("\(module)_alert_\(type)")
    }

    /// Crea un identifier para un progress indicator
    public static func progress(
        module: String,
        screen: String,
        context: String
    ) -> AccessibilityIdentifier {
        AccessibilityIdentifier("\(module)_\(screen)_progress_\(context)")
    }

    /// Crea un identifier para un loading indicator
    public static func loading(
        module: String,
        screen: String
    ) -> AccessibilityIdentifier {
        AccessibilityIdentifier("\(module)_\(screen)_loading")
    }

    /// Crea un identifier para un empty state
    public static func emptyState(
        module: String,
        screen: String
    ) -> AccessibilityIdentifier {
        AccessibilityIdentifier("\(module)_\(screen)_emptystate")
    }

    /// Crea un identifier para un error state
    public static func errorState(
        module: String,
        screen: String
    ) -> AccessibilityIdentifier {
        AccessibilityIdentifier("\(module)_\(screen)_errorstate")
    }
}

// MARK: - Identifier Builder

/// Builder pattern para crear identifiers complejos de forma fluida
public struct AccessibilityIdentifierBuilder: Sendable {
    private var components: [String] = []

    public init() {}

    /// Añade el módulo
    public func module(_ name: String) -> AccessibilityIdentifierBuilder {
        var copy = self
        copy.components.append(name.lowercased())
        return copy
    }

    /// Añade la pantalla
    public func screen(_ name: String) -> AccessibilityIdentifierBuilder {
        var copy = self
        copy.components.append(name.lowercased())
        return copy
    }

    /// Añade el tipo de componente
    public func component(_ type: String) -> AccessibilityIdentifierBuilder {
        var copy = self
        copy.components.append(type.lowercased())
        return copy
    }

    /// Añade un descriptor adicional
    public func descriptor(_ text: String) -> AccessibilityIdentifierBuilder {
        var copy = self
        copy.components.append(text.lowercased())
        return copy
    }

    /// Añade un índice numérico
    public func index(_ index: Int) -> AccessibilityIdentifierBuilder {
        var copy = self
        copy.components.append(String(index))
        return copy
    }

    /// Construye el identifier final
    public func build() -> AccessibilityIdentifier {
        let sanitized = components.map { $0.replacingOccurrences(of: " ", with: "_") }
        return AccessibilityIdentifier.custom(sanitized.joined(separator: "_"))
    }
}

// MARK: - Identifier Registry

/// Registro centralizado de identifiers para detectar duplicados y mantener consistencia
@MainActor
@Observable
public final class AccessibilityIdentifierRegistry: Sendable {
    public static let shared = AccessibilityIdentifierRegistry()

    private var registeredIdentifiers: Set<String> = []

    private init() {}

    /// Registra un identifier y detecta duplicados
    ///
    /// - Returns: `true` si el identifier es nuevo, `false` si ya existe (duplicado)
    public func register(_ identifier: AccessibilityIdentifier) -> Bool {
        let (inserted, _) = registeredIdentifiers.insert(identifier.id)

        #if DEBUG
        if !inserted {
            print("⚠️ [Accessibility] Duplicate identifier detected: \(identifier.id)")
        }
        #endif

        return inserted
    }

    /// Verifica si un identifier ya está registrado
    public func isRegistered(_ identifier: AccessibilityIdentifier) -> Bool {
        registeredIdentifiers.contains(identifier.id)
    }

    /// Limpia todos los identifiers registrados (útil para testing)
    public func reset() {
        registeredIdentifiers.removeAll()
    }

    /// Retorna todos los identifiers registrados (debugging)
    public var allIdentifiers: [String] {
        Array(registeredIdentifiers).sorted()
    }
}

// MARK: - Predefined Identifiers (Common Screens)

extension AccessibilityIdentifier {
    /// Identifiers predefinidos para pantallas y componentes comunes
    public struct Common {
        // MARK: - Auth Module

        public static let authLoginButtonSubmit = AccessibilityIdentifier.button(
            module: "auth",
            screen: "login",
            action: "submit"
        )

        public static let authLoginTextFieldEmail = AccessibilityIdentifier.textField(
            module: "auth",
            screen: "login",
            field: "email"
        )

        public static let authLoginTextFieldPassword = AccessibilityIdentifier.textField(
            module: "auth",
            screen: "login",
            field: "password"
        )

        public static let authLoginLinkForgotPassword = AccessibilityIdentifier.link(
            module: "auth",
            screen: "login",
            destination: "forgotpassword"
        )

        public static let authLoginLinkSignup = AccessibilityIdentifier.link(
            module: "auth",
            screen: "login",
            destination: "signup"
        )

        // MARK: - Profile Module

        public static let profileSettingsButtonSave = AccessibilityIdentifier.button(
            module: "profile",
            screen: "settings",
            action: "save"
        )

        public static let profileSettingsButtonCancel = AccessibilityIdentifier.button(
            module: "profile",
            screen: "settings",
            action: "cancel"
        )

        public static let profileSettingsToggleNotifications = AccessibilityIdentifier.toggle(
            module: "profile",
            screen: "settings",
            setting: "notifications"
        )

        // MARK: - Navigation

        public static let navTabHome = AccessibilityIdentifier.tab(module: "nav", name: "home")
        public static let navTabSearch = AccessibilityIdentifier.tab(module: "nav", name: "search")
        public static let navTabProfile = AccessibilityIdentifier.tab(module: "nav", name: "profile")
        public static let navTabSettings = AccessibilityIdentifier.tab(module: "nav", name: "settings")

        // MARK: - Common Actions

        public static let commonButtonClose = AccessibilityIdentifier.custom("common_button_close")
        public static let commonButtonBack = AccessibilityIdentifier.custom("common_button_back")
        public static let commonButtonMenu = AccessibilityIdentifier.custom("common_button_menu")
        public static let commonButtonRefresh = AccessibilityIdentifier.custom("common_button_refresh")
    }
}

// MARK: - Validation

extension AccessibilityIdentifier {
    /// Valida que el identifier cumpla con las naming conventions
    public var isValid: Bool {
        // No debe estar vacío
        guard !id.isEmpty else { return false }

        // Debe contener solo caracteres válidos (letras, números, guiones bajos)
        let validCharacterSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789_")
        guard id.unicodeScalars.allSatisfy({ validCharacterSet.contains($0) }) else {
            return false
        }

        // Debe tener al menos 2 componentes separados por _
        let components = id.split(separator: "_")
        guard components.count >= 2 else { return false }

        // Longitud razonable (no más de 100 caracteres)
        guard id.count <= 100 else { return false }

        return true
    }

    /// Componentes del identifier (separados por _)
    public var components: [String] {
        id.split(separator: "_").map(String.init)
    }

    /// Módulo extraído del identifier (primer componente)
    public var module: String? {
        components.first
    }

    /// Tipo de componente extraído (ej: "button", "textfield")
    public var componentType: String? {
        components.dropFirst().first { ["button", "textfield", "toggle", "link", "cell", "tab"].contains($0) }
    }
}

// MARK: - String Extension

extension String {
    /// Convierte un String en AccessibilityIdentifier
    public var asAccessibilityIdentifier: AccessibilityIdentifier {
        AccessibilityIdentifier.custom(self)
    }
}
