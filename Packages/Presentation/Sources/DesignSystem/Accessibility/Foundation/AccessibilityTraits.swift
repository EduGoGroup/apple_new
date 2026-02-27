import SwiftUI

/// Traits semánticos de accesibilidad que describen el rol y comportamiento de elementos UI.
///
/// Estos traits se mapean a las características nativas de accesibilidad de cada plataforma
/// (UIAccessibilityTraits en iOS, NSAccessibility en macOS) y proporcionan una API unificada
/// y type-safe para definir el comportamiento accesible de componentes.
///
/// ## Ejemplo de uso
/// ```swift
/// Button("Guardar") { }
///     .accessibleTraits(.button)
///
/// Text("Título de Sección")
///     .accessibleTraits(.header)
///
/// Toggle("Notificaciones", isOn: $enabled)
///     .accessibleTraits([.button, .selected])
/// ```
public struct AccessibilityTraits: OptionSet, Sendable {
    public let rawValue: UInt64

    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }

    // MARK: - Traits Básicos

    /// Elemento que actúa como un botón
    public static let button = AccessibilityTraits(rawValue: 1 << 0)

    /// Elemento que actúa como un link o enlace
    public static let link = AccessibilityTraits(rawValue: 1 << 1)

    /// Elemento que actúa como un search field
    public static let searchField = AccessibilityTraits(rawValue: 1 << 2)

    /// Elemento que actúa como una imagen
    public static let image = AccessibilityTraits(rawValue: 1 << 3)

    /// Elemento que puede ser seleccionado
    public static let selected = AccessibilityTraits(rawValue: 1 << 4)

    /// Elemento que puede recibir input del teclado
    public static let keyboardKey = AccessibilityTraits(rawValue: 1 << 5)

    /// Elemento que actúa como texto estático
    public static let staticText = AccessibilityTraits(rawValue: 1 << 6)

    /// Elemento que representa un header o encabezado
    public static let header = AccessibilityTraits(rawValue: 1 << 7)

    /// Elemento que puede reproducir sonido
    public static let playsSound = AccessibilityTraits(rawValue: 1 << 8)

    /// Elemento que inicia una actualizació o cambio frecuente
    public static let updatesFrequently = AccessibilityTraits(rawValue: 1 << 9)

    /// Elemento que inicia una llamada o interacción de comunicación
    public static let startsMediaSession = AccessibilityTraits(rawValue: 1 << 10)

    /// Elemento que permite ajustar un valor (slider, stepper)
    public static let adjustable = AccessibilityTraits(rawValue: 1 << 11)

    /// Elemento que permite edición directa
    public static let allowsDirectInteraction = AccessibilityTraits(rawValue: 1 << 12)

    /// Elemento que causa una actualización en pantalla cuando se activa
    public static let causesPageTurn = AccessibilityTraits(rawValue: 1 << 13)

    /// Elemento de tipo tab en una tab bar
    public static let tabBar = AccessibilityTraits(rawValue: 1 << 14)

    /// Elemento de tipo summary que proporciona información resumida
    public static let summaryElement = AccessibilityTraits(rawValue: 1 << 15)

    // MARK: - Traits de Estado

    /// Elemento que NO está habilitado para interacción
    public static let notEnabled = AccessibilityTraits(rawValue: 1 << 20)

    // MARK: - Traits Combinados Comunes

    /// Botón que está seleccionado (ej: toggle button activo)
    public static let selectedButton: AccessibilityTraits = [.button, .selected]

    /// Link que abre contenido externo
    public static let externalLink: AccessibilityTraits = [.link, .causesPageTurn]

    /// Campo de texto de búsqueda
    public static let searchInput: AccessibilityTraits = [.searchField, .allowsDirectInteraction]

    /// Control ajustable que se actualiza frecuentemente (ej: progress slider)
    public static let liveAdjustable: AccessibilityTraits = [.adjustable, .updatesFrequently]
}

// MARK: - Platform Mapping Extensions

#if os(iOS) || os(tvOS)
import UIKit

extension AccessibilityTraits {
    /// Convierte AccessibilityTraits a UIAccessibilityTraits nativos de iOS/tvOS
    public var uiTraits: UIAccessibilityTraits {
        var traits: UIAccessibilityTraits = []

        if contains(.button) { traits.insert(.button) }
        if contains(.link) { traits.insert(.link) }
        if contains(.searchField) { traits.insert(.searchField) }
        if contains(.image) { traits.insert(.image) }
        if contains(.selected) { traits.insert(.selected) }
        if contains(.keyboardKey) { traits.insert(.keyboardKey) }
        if contains(.staticText) { traits.insert(.staticText) }
        if contains(.header) { traits.insert(.header) }
        if contains(.playsSound) { traits.insert(.playsSound) }
        if contains(.updatesFrequently) { traits.insert(.updatesFrequently) }
        if contains(.startsMediaSession) { traits.insert(.startsMediaSession) }
        if contains(.adjustable) { traits.insert(.adjustable) }
        if contains(.allowsDirectInteraction) { traits.insert(.allowsDirectInteraction) }
        if contains(.causesPageTurn) { traits.insert(.causesPageTurn) }
        if contains(.tabBar) { traits.insert(.tabBar) }
        if contains(.summaryElement) { traits.insert(.summaryElement) }
        if contains(.notEnabled) { traits.insert(.notEnabled) }

        return traits
    }

    /// Crea AccessibilityTraits desde UIAccessibilityTraits
    public init(uiTraits: UIAccessibilityTraits) {
        var traits: AccessibilityTraits = []

        if uiTraits.contains(.button) { traits.insert(.button) }
        if uiTraits.contains(.link) { traits.insert(.link) }
        if uiTraits.contains(.searchField) { traits.insert(.searchField) }
        if uiTraits.contains(.image) { traits.insert(.image) }
        if uiTraits.contains(.selected) { traits.insert(.selected) }
        if uiTraits.contains(.keyboardKey) { traits.insert(.keyboardKey) }
        if uiTraits.contains(.staticText) { traits.insert(.staticText) }
        if uiTraits.contains(.header) { traits.insert(.header) }
        if uiTraits.contains(.playsSound) { traits.insert(.playsSound) }
        if uiTraits.contains(.updatesFrequently) { traits.insert(.updatesFrequently) }
        if uiTraits.contains(.startsMediaSession) { traits.insert(.startsMediaSession) }
        if uiTraits.contains(.adjustable) { traits.insert(.adjustable) }
        if uiTraits.contains(.allowsDirectInteraction) { traits.insert(.allowsDirectInteraction) }
        if uiTraits.contains(.causesPageTurn) { traits.insert(.causesPageTurn) }
        if uiTraits.contains(.tabBar) { traits.insert(.tabBar) }
        if uiTraits.contains(.summaryElement) { traits.insert(.summaryElement) }
        if uiTraits.contains(.notEnabled) { traits.insert(.notEnabled) }

        self = traits
    }
}
#endif

#if os(macOS)
extension AccessibilityTraits {
    /// Determina si el elemento es enabled según los traits
    public var isEnabled: Bool {
        !contains(.notEnabled)
    }

    /// Retorna el nombre del rol de macOS como String (sin depender de AppKit)
    public var macOSRoleName: String? {
        if contains(.button) { return "AXButton" }
        if contains(.link) { return "AXLink" }
        if contains(.searchField) { return "AXTextField" }
        if contains(.image) { return "AXImage" }
        if contains(.staticText) { return "AXStaticText" }
        if contains(.header) { return "AXGroup" }
        if contains(.adjustable) { return "AXSlider" }
        if contains(.tabBar) { return "AXTabGroup" }

        return nil
    }
}
#endif

// MARK: - Convenience Helpers

extension AccessibilityTraits {
    /// Determina si el elemento es interactivo (puede recibir acciones del usuario)
    public var isInteractive: Bool {
        contains(.button) ||
        contains(.link) ||
        contains(.adjustable) ||
        contains(.allowsDirectInteraction)
    }

    /// Determina si el elemento debería anunciar cambios automáticamente
    public var shouldAnnounceChanges: Bool {
        contains(.updatesFrequently)
    }

    /// Descripción human-readable de los traits activos (para debugging)
    public var description: String {
        var components: [String] = []

        if contains(.button) { components.append("button") }
        if contains(.link) { components.append("link") }
        if contains(.searchField) { components.append("searchField") }
        if contains(.image) { components.append("image") }
        if contains(.selected) { components.append("selected") }
        if contains(.keyboardKey) { components.append("keyboardKey") }
        if contains(.staticText) { components.append("staticText") }
        if contains(.header) { components.append("header") }
        if contains(.playsSound) { components.append("playsSound") }
        if contains(.updatesFrequently) { components.append("updatesFrequently") }
        if contains(.startsMediaSession) { components.append("startsMediaSession") }
        if contains(.adjustable) { components.append("adjustable") }
        if contains(.allowsDirectInteraction) { components.append("allowsDirectInteraction") }
        if contains(.causesPageTurn) { components.append("causesPageTurn") }
        if contains(.tabBar) { components.append("tabBar") }
        if contains(.summaryElement) { components.append("summaryElement") }
        if contains(.notEnabled) { components.append("notEnabled") }

        return components.isEmpty ? "none" : components.joined(separator: ", ")
    }
}

// MARK: - Custom Traits Builder

/// Builder pattern para crear combinaciones complejas de traits de forma fluida
public struct AccessibilityTraitsBuilder: Sendable {
    private var traits: AccessibilityTraits = []

    public init() {}

    /// Marca el elemento como botón
    public func asButton() -> AccessibilityTraitsBuilder {
        var copy = self
        copy.traits.insert(.button)
        return copy
    }

    /// Marca el elemento como link
    public func asLink() -> AccessibilityTraitsBuilder {
        var copy = self
        copy.traits.insert(.link)
        return copy
    }

    /// Marca el elemento como header
    public func asHeader() -> AccessibilityTraitsBuilder {
        var copy = self
        copy.traits.insert(.header)
        return copy
    }

    /// Marca el elemento como seleccionado
    public func selected(_ isSelected: Bool = true) -> AccessibilityTraitsBuilder {
        var copy = self
        if isSelected {
            copy.traits.insert(.selected)
        } else {
            copy.traits.remove(.selected)
        }
        return copy
    }

    /// Marca el elemento como deshabilitado
    public func disabled(_ isDisabled: Bool = true) -> AccessibilityTraitsBuilder {
        var copy = self
        if isDisabled {
            copy.traits.insert(.notEnabled)
        } else {
            copy.traits.remove(.notEnabled)
        }
        return copy
    }

    /// Marca el elemento como ajustable (slider, stepper)
    public func adjustable() -> AccessibilityTraitsBuilder {
        var copy = self
        copy.traits.insert(.adjustable)
        return copy
    }

    /// Marca el elemento como que se actualiza frecuentemente
    public func updatesFrequently() -> AccessibilityTraitsBuilder {
        var copy = self
        copy.traits.insert(.updatesFrequently)
        return copy
    }

    /// Añade traits custom adicionales
    public func with(_ customTraits: AccessibilityTraits) -> AccessibilityTraitsBuilder {
        var copy = self
        copy.traits.formUnion(customTraits)
        return copy
    }

    /// Construye los traits finales
    public func build() -> AccessibilityTraits {
        traits
    }
}

// MARK: - Convenience Static Methods

extension AccessibilityTraits {
    /// Crea un builder para construir traits de forma fluida
    public static func builder() -> AccessibilityTraitsBuilder {
        AccessibilityTraitsBuilder()
    }
}

// MARK: - SwiftUI Traits Conversion

extension AccessibilityTraits {
    /// Convierte AccessibilityTraits a SwiftUI.AccessibilityTraits
    public var swiftUITraits: SwiftUI.AccessibilityTraits {
        var traits: SwiftUI.AccessibilityTraits = []

        if contains(.button) { _ = traits.insert(.isButton) }
        if contains(.link) { _ = traits.insert(.isLink) }
        if contains(.searchField) { _ = traits.insert(.isSearchField) }
        if contains(.image) { _ = traits.insert(.isImage) }
        if contains(.selected) { _ = traits.insert(.isSelected) }
        if contains(.keyboardKey) { _ = traits.insert(.isKeyboardKey) }
        if contains(.staticText) { _ = traits.insert(.isStaticText) }
        if contains(.header) { _ = traits.insert(.isHeader) }
        if contains(.playsSound) { _ = traits.insert(.playsSound) }
        if contains(.updatesFrequently) { _ = traits.insert(.updatesFrequently) }
        if contains(.startsMediaSession) { _ = traits.insert(.startsMediaSession) }
        // SwiftUI no tiene adjustable directo
        if contains(.allowsDirectInteraction) { _ = traits.insert(.allowsDirectInteraction) }
        if contains(.causesPageTurn) { _ = traits.insert(.causesPageTurn) }
        if contains(.summaryElement) { _ = traits.insert(.isSummaryElement) }
        // notEnabled se maneja con .disabled() modifier en SwiftUI

        return traits
    }
}
