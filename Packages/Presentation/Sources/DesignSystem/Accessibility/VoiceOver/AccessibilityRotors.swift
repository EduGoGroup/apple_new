// MARK: - AccessibilityRotors.swift
// EduAccessibility - VoiceOver Infrastructure
//
// Helpers para crear custom rotors de VoiceOver.
// Proporciona APIs para navegación rápida en listas, formularios y headings.

import SwiftUI

// MARK: - Rotor Entry

/// Representa una entrada en un custom rotor de VoiceOver.
public struct AccessibilityRotorItem: Identifiable, Sendable {
    public let id: String
    public let label: String
    public let systemLabel: String?

    public init(id: String, label: String, systemLabel: String? = nil) {
        self.id = id
        self.label = label
        self.systemLabel = systemLabel
    }

    public init<ID: Hashable>(id: ID, label: String, systemLabel: String? = nil) {
        self.id = String(describing: id)
        self.label = label
        self.systemLabel = systemLabel
    }
}

// MARK: - Rotor Type

/// Tipos predefinidos de rotors para VoiceOver.
public enum AccessibilityRotorType: String, Sendable {
    case listItems = "List Items"
    case formFields = "Form Fields"
    case headings = "Headings"
    case links = "Links"
    case buttons = "Buttons"
    case images = "Images"
    case actions = "Actions"
    case custom = "Custom"

    /// Label localizable del rotor.
    public var label: String {
        rawValue
    }
}

// MARK: - Rotor Configuration

/// Configuración para un custom rotor.
public struct AccessibilityRotorConfiguration: Sendable {
    public let type: AccessibilityRotorType
    public let customLabel: String?
    public let systemRotor: EduAccessibilitySystemRotor?

    public init(
        type: AccessibilityRotorType,
        customLabel: String? = nil,
        systemRotor: EduAccessibilitySystemRotor? = nil
    ) {
        self.type = type
        self.customLabel = customLabel
        self.systemRotor = systemRotor
    }

    /// Label efectivo del rotor.
    public var label: String {
        customLabel ?? type.label
    }

    // MARK: - Presets

    /// Rotor para items de lista.
    public static let listItems = AccessibilityRotorConfiguration(
        type: .listItems,
        systemRotor: nil
    )

    /// Rotor para campos de formulario.
    public static let formFields = AccessibilityRotorConfiguration(
        type: .formFields,
        systemRotor: .textFields
    )

    /// Rotor para headings.
    public static let headings = AccessibilityRotorConfiguration(
        type: .headings,
        systemRotor: .headings
    )

    /// Rotor para links.
    public static let links = AccessibilityRotorConfiguration(
        type: .links,
        systemRotor: .links
    )

    /// Rotor para botones (custom rotor, no hay system rotor para botones en SwiftUI).
    public static let buttons = AccessibilityRotorConfiguration(
        type: .buttons,
        systemRotor: nil
    )

    /// Rotor para imágenes.
    public static let images = AccessibilityRotorConfiguration(
        type: .images,
        systemRotor: .images
    )
}

// MARK: - System Rotor Wrapper

/// Wrapper para system rotors de SwiftUI.
///
/// Nota: Solo incluye los rotors disponibles en SwiftUI.AccessibilitySystemRotor.
/// Algunos rotors como `.buttons` no existen en SwiftUI y se manejan como custom rotors.
public enum EduAccessibilitySystemRotor: Sendable {
    case headings
    case links
    case images
    case textFields
    case boldText
    case italicText
    case landmarks
    case tables
    case lists

    /// Convierte a AccessibilitySystemRotor de SwiftUI.
    @available(iOS 15.0, macOS 12.0, *)
    var swiftUIRotor: SwiftUI.AccessibilitySystemRotor {
        switch self {
        case .headings: return .headings
        case .links: return .links
        case .images: return .images
        case .textFields: return .textFields
        case .boldText: return .boldText
        case .italicText: return .italicText
        case .landmarks: return .landmarks
        case .tables: return .tables
        case .lists: return .lists
        }
    }
}

// MARK: - View Extensions for Rotors

public extension View {
    /// Agrega un custom rotor para items de lista.
    ///
    /// - Parameters:
    ///   - items: Los items del rotor.
    ///   - label: Closure que genera el label para cada item.
    ///
    /// ## Ejemplo
    /// ```swift
    /// List {
    ///     ForEach(users) { user in
    ///         UserRow(user: user)
    ///     }
    /// }
    /// .listItemsRotor(users) { user in
    ///     user.name
    /// }
    /// ```
    @available(iOS 15.0, macOS 12.0, *)
    func listItemsRotor<Item: Identifiable>(
        _ items: [Item],
        label: @escaping (Item) -> String
    ) -> some View {
        self.accessibilityRotor(AccessibilityRotorType.listItems.label) {
            ForEach(items) { item in
                AccessibilityRotorEntry(label(item), id: item.id)
            }
        }
    }

    /// Agrega un custom rotor para items de lista con textRange.
    ///
    /// - Parameters:
    ///   - label: Nombre del rotor.
    ///   - items: Los items del rotor.
    ///   - itemLabel: Closure que genera el label para cada item.
    @available(iOS 15.0, macOS 12.0, *)
    func customRotor<Item: Identifiable>(
        _ label: String,
        items: [Item],
        itemLabel: @escaping (Item) -> String
    ) -> some View {
        self.accessibilityRotor(label) {
            ForEach(items) { item in
                AccessibilityRotorEntry(itemLabel(item), id: item.id)
            }
        }
    }

    /// Agrega un rotor de acciones para el elemento.
    ///
    /// - Parameter actions: Las acciones disponibles con sus labels y closures.
    ///
    /// ## Ejemplo
    /// ```swift
    /// EduRow(title: "Item")
    ///     .actionsRotor([
    ///         ("Delete", { deleteItem() }),
    ///         ("Edit", { editItem() })
    ///     ])
    /// ```
    @available(iOS 15.0, macOS 12.0, *)
    func actionsRotor(_ actions: [(label: String, action: () -> Void)]) -> some View {
        self.accessibilityRotor(AccessibilityRotorType.actions.label) {
            ForEach(Array(actions.enumerated()), id: \.offset) { index, action in
                AccessibilityRotorEntry(action.label, id: index)
            }
        }
    }

    /// Marca esta vista como un heading para el rotor de headings.
    ///
    /// - Parameter level: Nivel del heading (1-6, default: 1).
    ///
    /// ## Ejemplo
    /// ```swift
    /// Text("Section Title")
    ///     .asHeading(level: 1)
    /// ```
    func asHeading(level: Int = 1) -> some View {
        self
            .accessibilityAddTraits(.isHeader)
            .accessibilityHeading(headingLevel(for: level))
    }

    /// Marca esta vista como un link para el rotor de links.
    ///
    /// - Parameter destination: Descripción del destino del link.
    ///
    /// ## Ejemplo
    /// ```swift
    /// Button("Learn More") { }
    ///     .asLink(destination: "Documentation page")
    /// ```
    func asLink(destination: String) -> some View {
        self
            .accessibilityAddTraits(.isLink)
            .accessibilityHint("Opens \(destination)")
    }

    /// Marca esta vista como un campo de formulario para el rotor de form fields.
    ///
    /// - Parameters:
    ///   - name: Nombre del campo.
    ///   - isRequired: Si el campo es requerido.
    ///
    /// ## Ejemplo
    /// ```swift
    /// TextField("Email", text: $email)
    ///     .asFormField(name: "Email", isRequired: true)
    /// ```
    func asFormField(name: String, isRequired: Bool = false) -> some View {
        let label = isRequired ? "\(name), required" : name
        return self
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isSearchField)
    }

    // MARK: - Private Helpers

    private func headingLevel(for level: Int) -> AccessibilityHeadingLevel {
        switch level {
        case 1: return .h1
        case 2: return .h2
        case 3: return .h3
        case 4: return .h4
        case 5: return .h5
        case 6: return .h6
        default: return .unspecified
        }
    }
}

// MARK: - Form Rotor Builder

/// Builder para crear un rotor de campos de formulario.
///
/// ## Ejemplo
/// ```swift
/// Form {
///     TextField("Email", text: $email)
///     SecureField("Password", text: $password)
/// }
/// .formFieldsRotor(
///     FormRotorBuilder()
///         .addField("Email", id: "email")
///         .addField("Password", id: "password")
///         .build()
/// )
/// ```
public struct FormRotorBuilder: Sendable {
    private var fields: [AccessibilityRotorItem] = []

    public init() {}

    /// Agrega un campo al rotor.
    public func addField(_ label: String, id: String) -> FormRotorBuilder {
        var copy = self
        copy.fields.append(AccessibilityRotorItem(id: id, label: label))
        return copy
    }

    /// Agrega un campo requerido al rotor.
    public func addRequiredField(_ label: String, id: String) -> FormRotorBuilder {
        addField("\(label), required", id: id)
    }

    /// Agrega múltiples campos al rotor.
    public func addFields(_ fieldLabels: [(label: String, id: String)]) -> FormRotorBuilder {
        var copy = self
        for field in fieldLabels {
            copy.fields.append(AccessibilityRotorItem(id: field.id, label: field.label))
        }
        return copy
    }

    /// Construye la lista de items del rotor.
    public func build() -> [AccessibilityRotorItem] {
        fields
    }
}

// MARK: - View Extension for Form Rotor

public extension View {
    /// Agrega un rotor de campos de formulario.
    ///
    /// - Parameter fields: Los campos del formulario.
    ///
    /// ## Ejemplo
    /// ```swift
    /// Form {
    ///     TextField("Email", text: $email)
    ///     SecureField("Password", text: $password)
    /// }
    /// .formFieldsRotor([
    ///     AccessibilityRotorItem(id: "email", label: "Email"),
    ///     AccessibilityRotorItem(id: "password", label: "Password")
    /// ])
    /// ```
    @available(iOS 15.0, macOS 12.0, *)
    func formFieldsRotor(_ fields: [AccessibilityRotorItem]) -> some View {
        self.accessibilityRotor(AccessibilityRotorType.formFields.label) {
            ForEach(fields) { field in
                AccessibilityRotorEntry(field.label, id: field.id)
            }
        }
    }
}

// MARK: - Heading Rotor Helper

/// Helper para registrar headings en una jerarquía.
///
/// ## Ejemplo
/// ```swift
/// VStack {
///     Text("Main Title")
///         .registerHeading(level: 1, in: headingRegistry)
///     Text("Section 1")
///         .registerHeading(level: 2, in: headingRegistry)
/// }
/// .headingsRotor(headingRegistry.headings)
/// ```
@MainActor
@Observable
public final class HeadingRegistry {
    public private(set) var headings: [AccessibilityRotorItem] = []

    public init() {}

    /// Registra un heading.
    public func register(id: String, label: String, level: Int) {
        let item = AccessibilityRotorItem(
            id: id,
            label: label,
            systemLabel: "Heading level \(level)"
        )

        // Evitar duplicados
        if !headings.contains(where: { $0.id == id }) {
            headings.append(item)
        }
    }

    /// Limpia todos los headings registrados.
    public func clear() {
        headings.removeAll()
    }
}

public extension View {
    /// Registra esta vista como un heading en el registry.
    @MainActor
    func registerHeading(
        id: String,
        label: String,
        level: Int,
        in registry: HeadingRegistry
    ) -> some View {
        self
            .asHeading(level: level)
            .onAppear {
                registry.register(id: id, label: label, level: level)
            }
    }

    /// Agrega un rotor de headings con los items especificados.
    @available(iOS 15.0, macOS 12.0, *)
    func headingsRotor(_ headings: [AccessibilityRotorItem]) -> some View {
        self.accessibilityRotor(AccessibilityRotorType.headings.label) {
            ForEach(headings) { heading in
                AccessibilityRotorEntry(heading.label, id: heading.id)
            }
        }
    }
}
