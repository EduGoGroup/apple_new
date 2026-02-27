import SwiftUI

/// Sistema de registro y gestión de keyboard shortcuts multiplataforma
@MainActor
@Observable
public final class KeyboardShortcutRegistry {

    // MARK: - Singleton

    public static let shared = KeyboardShortcutRegistry()

    // MARK: - Properties

    /// Shortcuts registrados por ID
    private var shortcuts: [String: KeyboardShortcutDefinition] = [:]

    /// Índice de shortcuts por combinación de teclas (para detección de conflictos)
    private var shortcutsByKeys: [ShortcutKey: Set<String>] = [:]

    /// Shortcuts deshabilitados temporalmente
    private var disabledShortcuts: Set<String> = []

    // MARK: - Initialization

    private init() {
        registerDefaultShortcuts()
    }

    // MARK: - Registration

    /// Registra un nuevo keyboard shortcut
    /// - Parameter shortcut: Definición del shortcut a registrar
    /// - Throws: KeyboardShortcutError si hay conflictos o errores
    public func register(_ shortcut: KeyboardShortcutDefinition) throws {
        // Verificar si ya existe un shortcut con este ID
        if shortcuts[shortcut.id] != nil {
            throw KeyboardShortcutError.duplicateID(shortcut.id)
        }

        // Verificar conflictos en la plataforma actual
        if let conflict = findConflict(for: shortcut) {
            throw KeyboardShortcutError.conflict(shortcut.id, conflict)
        }

        // Registrar el shortcut
        shortcuts[shortcut.id] = shortcut

        // Indexar por combinación de teclas
        let key = ShortcutKey(key: shortcut.key, modifiers: shortcut.modifiers)
        shortcutsByKeys[key, default: []].insert(shortcut.id)
    }

    /// Desregistra un shortcut existente
    /// - Parameter id: ID del shortcut a desregistrar
    public func unregister(_ id: String) {
        guard let shortcut = shortcuts.removeValue(forKey: id) else {
            return
        }

        // Remover del índice
        let key = ShortcutKey(key: shortcut.key, modifiers: shortcut.modifiers)
        shortcutsByKeys[key]?.remove(id)
        if shortcutsByKeys[key]?.isEmpty == true {
            shortcutsByKeys.removeValue(forKey: key)
        }
    }

    // MARK: - Query

    /// Obtiene un shortcut por su ID
    public func shortcut(for id: String) -> KeyboardShortcutDefinition? {
        shortcuts[id]
    }

    /// Obtiene todos los shortcuts registrados
    public var allShortcuts: [KeyboardShortcutDefinition] {
        Array(shortcuts.values).sorted { $0.id < $1.id }
    }

    /// Obtiene shortcuts por categoría
    public func shortcuts(in category: ShortcutCategory) -> [KeyboardShortcutDefinition] {
        shortcuts.values.filter { $0.category == category }.sorted { $0.id < $1.id }
    }

    /// Obtiene shortcuts disponibles en la plataforma actual
    public var platformShortcuts: [KeyboardShortcutDefinition] {
        shortcuts.values.filter { $0.isAvailableOnCurrentPlatform }.sorted { $0.id < $1.id }
    }

    // MARK: - Enable/Disable

    /// Deshabilita temporalmente un shortcut
    public func disable(_ id: String) {
        disabledShortcuts.insert(id)
    }

    /// Habilita un shortcut previamente deshabilitado
    public func enable(_ id: String) {
        disabledShortcuts.remove(id)
    }

    /// Verifica si un shortcut está habilitado
    public func isEnabled(_ id: String) -> Bool {
        !disabledShortcuts.contains(id)
    }

    // MARK: - Conflict Detection

    private func findConflict(for shortcut: KeyboardShortcutDefinition) -> String? {
        let key = ShortcutKey(key: shortcut.key, modifiers: shortcut.modifiers)

        guard let existingIDs = shortcutsByKeys[key] else {
            return nil
        }

        // Buscar conflictos en la misma plataforma
        for existingID in existingIDs {
            guard let existing = shortcuts[existingID] else { continue }

            // Si ambos están disponibles en alguna plataforma común, hay conflicto
            if !shortcut.platforms.isDisjoint(with: existing.platforms) {
                return existingID
            }
        }

        return nil
    }

    // MARK: - Default Shortcuts

    private func registerDefaultShortcuts() {
        let defaults: [KeyboardShortcutDefinition] = [
            // Navigation
            .init(
                id: "nav.back",
                key: KeyEquivalent("["),
                modifiers: [.command],
                platforms: [.macOS],
                category: .navigation,
                description: "Navigate back"
            ),
            .init(
                id: "nav.forward",
                key: KeyEquivalent("]"),
                modifiers: [.command],
                platforms: [.macOS],
                category: .navigation,
                description: "Navigate forward"
            ),

            // Editing
            .init(
                id: "edit.submit",
                key: .return,
                modifiers: [],
                platforms: [.macOS, .iOS, .visionOS],
                category: .editing,
                description: "Submit form"
            ),
            .init(
                id: "edit.cancel",
                key: .escape,
                modifiers: [],
                platforms: [.macOS, .iOS, .visionOS],
                category: .editing,
                description: "Cancel editing"
            ),

            // General
            .init(
                id: "general.help",
                key: KeyEquivalent("/"),
                modifiers: [.command, .shift],
                platforms: [.macOS, .iOS],
                category: .general,
                description: "Show keyboard shortcuts"
            ),
            .init(
                id: "general.close",
                key: KeyEquivalent("w"),
                modifiers: [.command],
                platforms: [.macOS],
                category: .general,
                description: "Close window"
            )
        ]

        for shortcut in defaults {
            try? register(shortcut)
        }
    }
}

// MARK: - Keyboard Shortcut Definition

/// Definición de un keyboard shortcut
public struct KeyboardShortcutDefinition: Sendable, Identifiable {
    public let id: String
    public let key: KeyEquivalent
    public let modifiers: EventModifiers
    public let platforms: Set<ShortcutPlatform>
    public let category: ShortcutCategory
    public let description: String
    public let isCustomizable: Bool

    public init(
        id: String,
        key: KeyEquivalent,
        modifiers: EventModifiers,
        platforms: Set<ShortcutPlatform>,
        category: ShortcutCategory,
        description: String,
        isCustomizable: Bool = false
    ) {
        self.id = id
        self.key = key
        self.modifiers = modifiers
        self.platforms = platforms
        self.category = category
        self.description = description
        self.isCustomizable = isCustomizable
    }

    /// Verifica si este shortcut está disponible en la plataforma actual
    public var isAvailableOnCurrentPlatform: Bool {
        #if os(macOS)
        return platforms.contains(.macOS)
        #elseif os(iOS)
        return platforms.contains(.iOS)
        #elseif os(visionOS)
        return platforms.contains(.visionOS)
        #elseif os(watchOS)
        return platforms.contains(.watchOS)
        #elseif os(tvOS)
        return platforms.contains(.tvOS)
        #else
        return false
        #endif
    }

    /// Representación en texto del shortcut
    public var displayString: String {
        var parts: [String] = []

        if modifiers.contains(.command) {
            parts.append("⌘")
        }
        if modifiers.contains(.shift) {
            parts.append("⇧")
        }
        if modifiers.contains(.option) {
            parts.append("⌥")
        }
        if modifiers.contains(.control) {
            parts.append("⌃")
        }

        // Añadir la tecla principal
        parts.append(key.displayName)

        return parts.joined()
    }
}

// MARK: - Supporting Types

/// Categorías de shortcuts
public enum ShortcutCategory: String, Sendable, CaseIterable {
    case navigation
    case editing
    case general
    case custom

    public var displayName: String {
        switch self {
        case .navigation: return "Navigation"
        case .editing: return "Editing"
        case .general: return "General"
        case .custom: return "Custom"
        }
    }
}

/// Plataformas soportadas
public enum ShortcutPlatform: String, Sendable, Hashable {
    case macOS
    case iOS
    case visionOS
    case watchOS
    case tvOS
}

/// Clave compuesta para indexar shortcuts
private struct ShortcutKey: Hashable, Sendable {
    let key: KeyEquivalent
    let modifiers: EventModifiers

    func hash(into hasher: inout Hasher) {
        hasher.combine(key.character)
        hasher.combine(modifiers.rawValue)
    }

    static func == (lhs: ShortcutKey, rhs: ShortcutKey) -> Bool {
        lhs.key.character == rhs.key.character && lhs.modifiers.rawValue == rhs.modifiers.rawValue
    }
}

/// Errores de keyboard shortcuts
public enum KeyboardShortcutError: Error, LocalizedError {
    case duplicateID(String)
    case conflict(String, String)

    public var errorDescription: String? {
        switch self {
        case .duplicateID(let id):
            return "Shortcut with ID '\(id)' is already registered"
        case .conflict(let newID, let existingID):
            return "Shortcut '\(newID)' conflicts with existing shortcut '\(existingID)'"
        }
    }
}

// MARK: - KeyEquivalent Extensions

extension KeyEquivalent {
    /// Nombre displayable de la tecla
    public var displayName: String {
        switch self {
        case .return: return "⏎"
        case .escape: return "⎋"
        case .delete: return "⌫"
        case .deleteForward: return "⌦"
        case .tab: return "⇥"
        case .space: return "Space"
        case .upArrow: return "↑"
        case .downArrow: return "↓"
        case .leftArrow: return "←"
        case .rightArrow: return "→"
        case .home: return "↖"
        case .end: return "↘"
        case .pageUp: return "⇞"
        case .pageDown: return "⇟"
        case .clear: return "⌧"
        default:
            return String(self.character).uppercased()
        }
    }
}

// MARK: - Environment Integration

extension KeyboardShortcutRegistryKey: @preconcurrency EnvironmentKey {}
public struct KeyboardShortcutRegistryKey {
    @MainActor
    public static var defaultValue: KeyboardShortcutRegistry {
        .shared
    }
}

extension EnvironmentValues {
    public var keyboardShortcutRegistry: KeyboardShortcutRegistry {
        get { self[KeyboardShortcutRegistryKey.self] }
        set { self[KeyboardShortcutRegistryKey.self] = newValue }
    }
}
