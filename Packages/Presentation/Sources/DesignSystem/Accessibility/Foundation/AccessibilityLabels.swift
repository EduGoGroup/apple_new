import SwiftUI

/// Protocol para tipos que pueden proporcionar labels de accesibilidad.
///
/// Implementa este protocol en tus modelos o enums para generar automáticamente
/// labels descriptivos y context-aware para VoiceOver y otros screen readers.
///
/// ## Ejemplo
/// ```swift
/// enum ButtonStyle: AccessibilityLabelProvider {
///     case primary, secondary, destructive
///
///     var accessibilityLabel: String {
///         switch self {
///         case .primary: return "Primary action button"
///         case .secondary: return "Secondary action button"
///         case .destructive: return "Destructive action button"
///         }
///     }
/// }
/// ```
public protocol AccessibilityLabelProvider: Sendable {
    /// Label de accesibilidad para este tipo
    var accessibilityLabel: String { get }
}

// MARK: - Label Generator

/// Generador de labels de accesibilidad con soporte para localización y contexto dinámico.
///
/// Proporciona métodos para crear labels descriptivos, concisos y localizados que mejoran
/// la experiencia de usuarios de screen readers.
public struct AccessibilityLabel: Sendable {
    private let text: String

    private init(_ text: String) {
        self.text = text
    }

    /// Texto del label
    public var value: String {
        text
    }

    // MARK: - Static Constructors

    /// Crea un label simple de texto
    public static func text(_ text: String) -> AccessibilityLabel {
        AccessibilityLabel(text)
    }

    /// Crea un label localizado usando una key de localización
    ///
    /// - Parameters:
    ///   - key: Key de localización
    ///   - comment: Comentario para el traductor
    public static func localized(_ key: String, comment: String = "") -> AccessibilityLabel {
        AccessibilityLabel(NSLocalizedString(key, comment: comment))
    }

    /// Crea un label con formato interpolado
    ///
    /// Ejemplo:
    /// ```swift
    /// .format("Delete button for %@", itemName)
    /// ```
    public static func format(_ format: String, _ arguments: any CVarArg...) -> AccessibilityLabel {
        let formatted = String(format: format, arguments: arguments)
        return AccessibilityLabel(formatted)
    }

    /// Crea un label context-aware que incluye información del contexto
    ///
    /// Ejemplo:
    /// ```swift
    /// .contextual(action: "Delete", target: "Photo", context: "from album")
    /// // Resultado: "Delete Photo from album"
    /// ```
    public static func contextual(
        action: String,
        target: String? = nil,
        context: String? = nil
    ) -> AccessibilityLabel {
        var components: [String] = [action]

        if let target = target {
            components.append(target)
        }

        if let context = context {
            components.append(context)
        }

        return AccessibilityLabel(components.joined(separator: " "))
    }

    /// Crea un label para un botón de acción
    ///
    /// Ejemplo:
    /// ```swift
    /// .button(action: "Save", target: "document")
    /// // Resultado: "Save document button"
    /// ```
    public static func button(action: String, target: String? = nil) -> AccessibilityLabel {
        if let target = target {
            return AccessibilityLabel("\(action) \(target) button")
        } else {
            return AccessibilityLabel("\(action) button")
        }
    }

    /// Crea un label para un link
    ///
    /// Ejemplo:
    /// ```swift
    /// .link(destination: "Settings page")
    /// // Resultado: "Link to Settings page"
    /// ```
    public static func link(destination: String) -> AccessibilityLabel {
        AccessibilityLabel("Link to \(destination)")
    }

    /// Crea un label para un header o título
    public static func header(_ title: String) -> AccessibilityLabel {
        AccessibilityLabel("\(title) heading")
    }

    /// Crea un label para un campo de entrada
    ///
    /// Ejemplo:
    /// ```swift
    /// .textField(name: "Email", hint: "Enter your email address")
    /// // Resultado: "Email text field, Enter your email address"
    /// ```
    public static func textField(name: String, hint: String? = nil) -> AccessibilityLabel {
        var label = "\(name) text field"
        if let hint = hint {
            label += ", \(hint)"
        }
        return AccessibilityLabel(label)
    }

    /// Crea un label para un toggle/switch
    ///
    /// Ejemplo:
    /// ```swift
    /// .toggle(name: "Notifications", state: true)
    /// // Resultado: "Notifications, on"
    /// ```
    public static func toggle(name: String, state: Bool) -> AccessibilityLabel {
        AccessibilityLabel("\(name), \(state ? "on" : "off")")
    }

    /// Crea un label para un slider o control ajustable
    ///
    /// Ejemplo:
    /// ```swift
    /// .adjustable(name: "Volume", value: "50%")
    /// // Resultado: "Volume slider, 50%"
    /// ```
    public static func adjustable(name: String, value: String) -> AccessibilityLabel {
        AccessibilityLabel("\(name) slider, \(value)")
    }

    /// Crea un label para un progress indicator
    ///
    /// Ejemplo:
    /// ```swift
    /// .progress(value: 75)
    /// // Resultado: "Progress, 75 percent"
    /// ```
    public static func progress(value: Int) -> AccessibilityLabel {
        AccessibilityLabel("Progress, \(value) percent")
    }

    /// Crea un label para un estado de loading
    public static func loading(_ context: String? = nil) -> AccessibilityLabel {
        if let context = context {
            return AccessibilityLabel("Loading \(context)")
        } else {
            return AccessibilityLabel("Loading")
        }
    }

    /// Crea un label para un estado de error
    public static func error(_ message: String) -> AccessibilityLabel {
        AccessibilityLabel("Error: \(message)")
    }

    /// Crea un label para un estado vacío
    public static func empty(_ context: String = "content") -> AccessibilityLabel {
        AccessibilityLabel("No \(context) available")
    }
}

// MARK: - Label Builder

/// Builder pattern para crear labels complejos de forma fluida
public struct AccessibilityLabelBuilder: Sendable {
    private var components: [String] = []

    public init() {}

    /// Añade un componente al label
    public func add(_ text: String) -> AccessibilityLabelBuilder {
        var copy = self
        copy.components.append(text)
        return copy
    }

    /// Añade un componente condicional
    public func addIf(_ condition: Bool, _ text: String) -> AccessibilityLabelBuilder {
        guard condition else { return self }
        return add(text)
    }

    /// Añade un componente opcional
    public func addOptional(_ text: String?) -> AccessibilityLabelBuilder {
        guard let text = text else { return self }
        return add(text)
    }

    /// Construye el label final
    public func build(separator: String = " ") -> AccessibilityLabel {
        AccessibilityLabel.text(components.joined(separator: separator))
    }
}

// MARK: - Predefined Labels (Common Use Cases)

extension AccessibilityLabel {
    /// Labels predefinidos comunes para reutilizar en toda la app
    public struct Common {
        // MARK: - Actions

        public static let save = AccessibilityLabel.button(action: "Save")
        public static let cancel = AccessibilityLabel.button(action: "Cancel")
        public static let delete = AccessibilityLabel.button(action: "Delete")
        public static let edit = AccessibilityLabel.button(action: "Edit")
        public static let add = AccessibilityLabel.button(action: "Add")
        public static let remove = AccessibilityLabel.button(action: "Remove")
        public static let close = AccessibilityLabel.button(action: "Close")
        public static let back = AccessibilityLabel.button(action: "Go back")
        public static let next = AccessibilityLabel.button(action: "Next")
        public static let submit = AccessibilityLabel.button(action: "Submit")
        public static let refresh = AccessibilityLabel.button(action: "Refresh")
        public static let search = AccessibilityLabel.button(action: "Search")

        // MARK: - States

        public static let loading = AccessibilityLabel.loading()
        public static let loadingContent = AccessibilityLabel.loading("content")
        public static let emptyState = AccessibilityLabel.empty()

        // MARK: - Navigation

        public static let menu = AccessibilityLabel.button(action: "Open menu")
        public static let settings = AccessibilityLabel.link(destination: "Settings")
        public static let profile = AccessibilityLabel.link(destination: "Profile")

        // MARK: - Common UI Elements

        public static let passwordField = AccessibilityLabel.textField(name: "Password")
        public static let emailField = AccessibilityLabel.textField(name: "Email")
        public static let searchField = AccessibilityLabel.textField(name: "Search")

        public static let showPassword = AccessibilityLabel.button(action: "Show password")
        public static let hidePassword = AccessibilityLabel.button(action: "Hide password")
        public static let clearSearch = AccessibilityLabel.button(action: "Clear search")
    }
}

// MARK: - Validation Rules

extension AccessibilityLabel {
    /// Valida que el label cumpla con las mejores prácticas de accesibilidad
    public var isValid: Bool {
        // Label no debe estar vacío
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }

        // Label no debe ser excesivamente largo (> 100 caracteres es sospechoso)
        guard text.count <= 100 else {
            return false
        }

        // Label no debe contener solo números o símbolos
        let alphanumericCharacterSet = CharacterSet.alphanumerics
        guard text.unicodeScalars.contains(where: { alphanumericCharacterSet.contains($0) }) else {
            return false
        }

        return true
    }

    /// Longitud recomendada para labels de accesibilidad (15-50 caracteres)
    public var hasRecommendedLength: Bool {
        (15...50).contains(text.count)
    }
}

// MARK: - String Extension

extension String {
    /// Convierte un String en AccessibilityLabel
    public var asAccessibilityLabel: AccessibilityLabel {
        AccessibilityLabel.text(self)
    }
}
