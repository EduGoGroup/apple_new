// MARK: - AccessibilityGrouping.swift
// EduAccessibility - VoiceOver Infrastructure
//
// Helpers para agrupar elementos de accesibilidad relacionados.
// Proporciona APIs para combinar labels y crear grupos lógicos.

import SwiftUI

// MARK: - Grouping Mode

/// Modos de agrupamiento para elementos de accesibilidad.
public enum AccessibilityGroupingMode: Sendable {
    /// Combina todos los children en un solo elemento accesible.
    /// El label resultante es la concatenación de los labels de los children.
    case combine

    /// Mantiene los children como elementos separados pero navegables dentro del grupo.
    case contain

    /// Ignora los children para accesibilidad (solo el contenedor es accesible).
    case ignore
}

// MARK: - Grouping Configuration

/// Configuración para agrupamiento de accesibilidad.
public struct AccessibilityGroupingConfiguration: Sendable {
    /// Modo de agrupamiento.
    public let mode: AccessibilityGroupingMode

    /// Separador entre labels combinados.
    public let separator: String

    /// Label personalizado para el grupo (override del label combinado).
    public let customLabel: String?

    /// Hint para el grupo.
    public let hint: String?

    /// Traits adicionales para el grupo.
    public let traits: AccessibilityTraits

    public init(
        mode: AccessibilityGroupingMode = .combine,
        separator: String = ", ",
        customLabel: String? = nil,
        hint: String? = nil,
        traits: AccessibilityTraits = []
    ) {
        self.mode = mode
        self.separator = separator
        self.customLabel = customLabel
        self.hint = hint
        self.traits = traits
    }

    /// Label efectivo (customLabel si existe, de lo contrario nil).
    public var label: String? {
        customLabel
    }

    // MARK: - Presets

    /// Configuración para cards: agrupa header + content.
    public static let card = AccessibilityGroupingConfiguration(
        mode: .combine,
        separator: ". ",
        traits: .summaryElement
    )

    /// Configuración para rows: agrupa leading + title + subtitle + trailing.
    public static let row = AccessibilityGroupingConfiguration(
        mode: .combine,
        separator: ", "
    )

    /// Configuración para empty states: agrupa icon + title + description.
    public static let emptyState = AccessibilityGroupingConfiguration(
        mode: .combine,
        separator: ". ",
        traits: .staticText
    )

    /// Configuración para modals: mantiene children separados.
    public static let modal = AccessibilityGroupingConfiguration(
        mode: .contain
    )

    /// Configuración para listas: mantiene items navegables.
    public static let list = AccessibilityGroupingConfiguration(
        mode: .contain
    )
}

// MARK: - Accessibility Grouped Modifier

/// ViewModifier para agrupar elementos de accesibilidad.
private struct AccessibilityGroupedModifier: ViewModifier {
    let configuration: AccessibilityGroupingConfiguration
    let labels: [String]

    func body(content: Content) -> some View {
        let childrenMode: AccessibilityChildBehavior = {
            switch configuration.mode {
            case .combine:
                return .combine
            case .contain:
                return .contain
            case .ignore:
                return .ignore
            }
        }()

        content
            .accessibilityElement(children: childrenMode)
            .modifier(ConditionalLabelModifier(
                label: effectiveLabel,
                hint: configuration.hint,
                traits: configuration.traits
            ))
    }

    private var effectiveLabel: String? {
        if let customLabel = configuration.customLabel {
            return customLabel
        }

        let nonEmptyLabels = labels.filter { !$0.isEmpty }
        guard !nonEmptyLabels.isEmpty else { return nil }

        return nonEmptyLabels.joined(separator: configuration.separator)
    }
}

/// Modifier condicional para aplicar label, hint y traits.
private struct ConditionalLabelModifier: ViewModifier {
    let label: String?
    let hint: String?
    let traits: AccessibilityTraits

    func body(content: Content) -> some View {
        content
            .modifier(OptionalAccessibilityLabel(label: label))
            .modifier(OptionalAccessibilityHint(hint: hint))
            .modifier(OptionalAccessibilityTraits(traits: traits))
    }
}

private struct OptionalAccessibilityLabel: ViewModifier {
    let label: String?

    func body(content: Content) -> some View {
        if let label = label {
            content.accessibilityLabel(label)
        } else {
            content
        }
    }
}

private struct OptionalAccessibilityHint: ViewModifier {
    let hint: String?

    func body(content: Content) -> some View {
        if let hint = hint {
            content.accessibilityHint(hint)
        } else {
            content
        }
    }
}

private struct OptionalAccessibilityTraits: ViewModifier {
    let traits: AccessibilityTraits

    func body(content: Content) -> some View {
        if !traits.isEmpty {
            content.accessibilityAddTraits(traits.swiftUITraits)
        } else {
            content
        }
    }
}

// MARK: - View Extensions

public extension View {
    /// Agrupa elementos de accesibilidad con la configuración especificada.
    ///
    /// - Parameters:
    ///   - configuration: Configuración de agrupamiento.
    ///   - labels: Labels de los elementos a combinar.
    ///
    /// ## Ejemplo
    /// ```swift
    /// HStack {
    ///     Image(systemName: "star")
    ///     Text("Title")
    ///     Text("Subtitle")
    /// }
    /// .accessibilityGrouped(
    ///     configuration: .row,
    ///     labels: ["Star icon", "Title", "Subtitle"]
    /// )
    /// ```
    func accessibilityGrouped(
        configuration: AccessibilityGroupingConfiguration = .init(),
        labels: [String] = []
    ) -> some View {
        self.modifier(AccessibilityGroupedModifier(
            configuration: configuration,
            labels: labels
        ))
    }

    /// Agrupa elementos combinando sus labels con el separador especificado.
    ///
    /// - Parameters:
    ///   - labels: Labels a combinar.
    ///   - separator: Separador entre labels (default: ", ").
    ///
    /// ## Ejemplo
    /// ```swift
    /// VStack {
    ///     Text("John Doe")
    ///     Text("Software Engineer")
    /// }
    /// .accessibilityGrouped(combining: ["John Doe", "Software Engineer"])
    /// ```
    func accessibilityGrouped(
        combining labels: [String],
        separator: String = ", "
    ) -> some View {
        self.accessibilityGrouped(
            configuration: AccessibilityGroupingConfiguration(
                mode: .combine,
                separator: separator
            ),
            labels: labels
        )
    }

    /// Agrupa elementos con un label personalizado.
    ///
    /// - Parameters:
    ///   - label: Label del grupo.
    ///   - hint: Hint opcional del grupo.
    ///   - traits: Traits del grupo.
    ///
    /// ## Ejemplo
    /// ```swift
    /// VStack {
    ///     Image(systemName: "tray")
    ///     Text("No items")
    ///     Text("Add items to get started")
    /// }
    /// .accessibilityGrouped(
    ///     label: "Empty state: No items. Add items to get started",
    ///     traits: .staticText
    /// )
    /// ```
    func accessibilityGrouped(
        label: String,
        hint: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        self.accessibilityGrouped(
            configuration: AccessibilityGroupingConfiguration(
                mode: .combine,
                customLabel: label,
                hint: hint,
                traits: traits
            )
        )
    }

    /// Agrupa elementos para una card (header + content).
    ///
    /// - Parameters:
    ///   - headerLabel: Label del header.
    ///   - contentLabel: Label del contenido (opcional).
    ///
    /// ## Ejemplo
    /// ```swift
    /// VStack {
    ///     Text("Settings")
    ///     // content
    /// }
    /// .cardGrouped(headerLabel: "Settings", contentLabel: "App preferences")
    /// ```
    func cardGrouped(
        headerLabel: String,
        contentLabel: String? = nil
    ) -> some View {
        var labels = [headerLabel]
        if let content = contentLabel {
            labels.append(content)
        }

        return self.accessibilityGrouped(
            configuration: .card,
            labels: labels
        )
    }

    /// Agrupa elementos para una row (leading + title + subtitle + trailing).
    ///
    /// - Parameters:
    ///   - title: Título de la row.
    ///   - subtitle: Subtítulo opcional.
    ///   - leadingLabel: Label del contenido leading (icon, avatar, etc).
    ///   - trailingLabel: Label del contenido trailing (badge, chevron, etc).
    ///
    /// ## Ejemplo
    /// ```swift
    /// HStack {
    ///     Image(systemName: "person")
    ///     VStack {
    ///         Text("John Doe")
    ///         Text("Admin")
    ///     }
    ///     Image(systemName: "chevron.right")
    /// }
    /// .rowGrouped(
    ///     title: "John Doe",
    ///     subtitle: "Admin",
    ///     leadingLabel: "Person icon",
    ///     trailingLabel: "Navigate"
    /// )
    /// ```
    func rowGrouped(
        title: String,
        subtitle: String? = nil,
        leadingLabel: String? = nil,
        trailingLabel: String? = nil
    ) -> some View {
        var labels: [String] = []

        if let leading = leadingLabel {
            labels.append(leading)
        }
        labels.append(title)
        if let sub = subtitle {
            labels.append(sub)
        }
        if let trailing = trailingLabel {
            labels.append(trailing)
        }

        return self.accessibilityGrouped(
            configuration: .row,
            labels: labels
        )
    }

    /// Agrupa elementos para un empty state (icon + title + description).
    ///
    /// - Parameters:
    ///   - title: Título del empty state.
    ///   - description: Descripción del empty state.
    ///
    /// ## Ejemplo
    /// ```swift
    /// VStack {
    ///     Image(systemName: "tray")
    ///     Text("No Results")
    ///     Text("Try a different search")
    /// }
    /// .emptyStateGrouped(title: "No Results", description: "Try a different search")
    /// ```
    func emptyStateGrouped(
        title: String,
        description: String
    ) -> some View {
        self.accessibilityGrouped(
            configuration: .emptyState,
            labels: ["Empty state", title, description]
        )
    }

    /// Mantiene los children como elementos separados navegables.
    ///
    /// Útil para modals, sheets y otros contenedores donde los children
    /// deben ser navegables individualmente.
    ///
    /// ## Ejemplo
    /// ```swift
    /// VStack {
    ///     TextField("Email", text: $email)
    ///     SecureField("Password", text: $password)
    ///     Button("Submit") { }
    /// }
    /// .accessibilityContained()
    /// ```
    func accessibilityContained() -> some View {
        self.accessibilityElement(children: .contain)
    }
}

// MARK: - Label Builder

/// Builder para construir labels de accesibilidad combinados.
///
/// ## Ejemplo
/// ```swift
/// let label = AccessibilityLabelBuilder()
///     .add("John Doe")
///     .addIf(isAdmin, "Administrator")
///     .addOptional(department)
///     .build()
/// ```
public struct AccessibilityLabelCombiner: Sendable {
    private var components: [String] = []
    private let separator: String

    public init(separator: String = ", ") {
        self.separator = separator
    }

    /// Agrega un componente al label.
    public func add(_ text: String) -> AccessibilityLabelCombiner {
        var copy = self
        copy.components.append(text)
        return copy
    }

    /// Agrega un componente condicionalmente.
    public func addIf(_ condition: Bool, _ text: String) -> AccessibilityLabelCombiner {
        condition ? add(text) : self
    }

    /// Agrega un componente opcional (si no es nil).
    public func addOptional(_ text: String?) -> AccessibilityLabelCombiner {
        text.map { add($0) } ?? self
    }

    /// Construye el label final.
    public func build() -> String {
        components.filter { !$0.isEmpty }.joined(separator: separator)
    }
}
