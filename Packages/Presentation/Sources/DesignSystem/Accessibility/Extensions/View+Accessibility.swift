import SwiftUI

// MARK: - View Accessibility Extensions

/// Extensiones de SwiftUI View para aplicar propiedades de accesibilidad de forma fluida.
///
/// Estas extensiones proporcionan una API chainable y type-safe para configurar
/// accesibilidad en componentes UI, envolviendo las APIs nativas de SwiftUI.
///
/// ## Ejemplo de uso
/// ```swift
/// Button("Save") { }
///     .accessibleLabel(.button(action: "Save", target: "document"))
///     .accessibleHint(.saves("your changes"))
///     .accessibleTraits(.button)
///     .accessibleIdentifier(.button(module: "editor", screen: "main", action: "save"))
/// ```
extension View {

    // MARK: - Label

    /// Aplica un accessibility label al view
    ///
    /// El label describe QUÉ es el elemento para screen readers.
    ///
    /// - Parameter label: AccessibilityLabel a aplicar
    /// - Returns: View modificado con el label
    public func accessibleLabel(_ label: AccessibilityLabel) -> some View {
        self.accessibilityLabel(label.value)
    }

    /// Aplica un accessibility label desde un String
    public func accessibleLabel(_ text: String) -> some View {
        self.accessibilityLabel(AccessibilityLabel.text(text).value)
    }

    /// Aplica un accessibility label desde un provider
    public func accessibleLabel<P: AccessibilityLabelProvider>(_ provider: P) -> some View {
        self.accessibilityLabel(provider.accessibilityLabel)
    }

    // MARK: - Hint

    /// Aplica un accessibility hint al view
    ///
    /// El hint describe QUÉ HACE el elemento cuando el usuario interactúa.
    ///
    /// - Parameter hint: AccessibilityHint a aplicar
    /// - Returns: View modificado con el hint
    public func accessibleHint(_ hint: AccessibilityHint) -> some View {
        self.accessibilityHint(hint.value)
    }

    /// Aplica un accessibility hint desde un String
    public func accessibleHint(_ text: String) -> some View {
        self.accessibilityHint(AccessibilityHint.text(text).value)
    }

    /// Aplica un accessibility hint condicional
    ///
    /// El hint solo se muestra si `shouldShow` es true y cumple las reglas de validación.
    public func accessibleHint(
        _ hint: AccessibilityHint?,
        label: AccessibilityLabel? = nil,
        shouldShow: Bool = true
    ) -> some View {
        Group {
            if shouldShow, AccessibilityHint.shouldShow(hint: hint, label: label) {
                self.accessibilityHint(hint?.value ?? "")
            } else {
                self
            }
        }
    }

    // MARK: - Value

    /// Aplica un accessibility value al view
    ///
    /// El value describe el ESTADO o VALOR ACTUAL del elemento (para sliders, progress, etc).
    ///
    /// - Parameter value: Valor actual del elemento
    /// - Returns: View modificado con el value
    public func accessibleValue(_ value: String) -> some View {
        self.accessibilityValue(value)
    }

    /// Aplica un accessibility value desde un número formateado como porcentaje
    public func accessibleValuePercent(_ value: Double) -> some View {
        self.accessibilityValue("\(Int(value * 100)) percent")
    }

    /// Aplica un accessibility value desde un número con unidad custom
    public func accessibleValue(_ value: Double, unit: String) -> some View {
        self.accessibilityValue("\(Int(value)) \(unit)")
    }

    // MARK: - Traits

    /// Aplica accessibility traits al view
    ///
    /// Los traits describen el ROL y COMPORTAMIENTO del elemento.
    ///
    /// - Parameter traits: AccessibilityTraits a aplicar
    /// - Returns: View modificado con los traits
    public func accessibleTraits(_ traits: AccessibilityTraits) -> some View {
        #if os(iOS) || os(tvOS)
        self.accessibilityAddTraits(traits.swiftUITraits)
        #elseif os(macOS)
        self.modifier(MacOSAccessibilityTraitsModifier(traits: traits))
        #else
        self
        #endif
    }

    /// Remueve accessibility traits específicos del view
    public func removeAccessibleTraits(_ traits: AccessibilityTraits) -> some View {
        #if os(iOS) || os(tvOS)
        self.accessibilityRemoveTraits(traits.swiftUITraits)
        #else
        self
        #endif
    }

    // MARK: - Identifier

    /// Aplica un accessibility identifier al view (para UI testing)
    ///
    /// - Parameter identifier: AccessibilityIdentifier único
    /// - Returns: View modificado con el identifier
    public func accessibleIdentifier(_ identifier: AccessibilityIdentifier) -> some View {
        self.modifier(AccessibilityIdentifierModifier(identifier: identifier))
    }

    /// Aplica un accessibility identifier desde un String
    public func accessibleIdentifier(_ id: String) -> some View {
        self.accessibleIdentifier(AccessibilityIdentifier.custom(id))
    }

    // MARK: - Hidden

    /// Oculta el elemento de accessibility (screen readers lo ignoran)
    ///
    /// Usa con precaución. Solo oculta elementos decorativos o redundantes.
    ///
    /// - Parameter isHidden: Si el elemento debe ocultarse
    /// - Returns: View modificado
    public func accessibleHidden(_ isHidden: Bool = true) -> some View {
        self.accessibilityHidden(isHidden)
    }

    // MARK: - Combined Configuration

    /// Configura múltiples propiedades de accesibilidad a la vez
    ///
    /// Ejemplo:
    /// ```swift
    /// Button("Save") { }
    ///     .accessibleConfiguration(
    ///         label: .button(action: "Save"),
    ///         hint: .saves("your changes"),
    ///         traits: .button,
    ///         identifier: .button(module: "app", screen: "main", action: "save")
    ///     )
    /// ```
    public func accessibleConfiguration(
        label: AccessibilityLabel? = nil,
        hint: AccessibilityHint? = nil,
        value: String? = nil,
        traits: AccessibilityTraits? = nil,
        identifier: AccessibilityIdentifier? = nil,
        isHidden: Bool = false
    ) -> some View {
        self
            .modifier(AccessibilityConfigurationModifier(
                label: label,
                hint: hint,
                value: value,
                traits: traits,
                identifier: identifier,
                isHidden: isHidden
            ))
    }

    // MARK: - Grouping

    /// Agrupa elementos relacionados para accesibilidad
    ///
    /// Útil para combinar elementos que forman una unidad lógica.
    ///
    /// - Parameter children: Cómo tratar los children (.ignore, .contain, .combine)
    /// - Returns: View modificado como elemento de accesibilidad
    public func accessibilityGrouped(
        children: AccessibilityChildBehavior = .combine
    ) -> some View {
        self.accessibilityElement(children: children)
    }

    // MARK: - Actions

    /// Añade una acción custom de accesibilidad
    ///
    /// Permite a VoiceOver users activar acciones específicas via rotor.
    ///
    /// - Parameters:
    ///   - name: Nombre de la acción (ej: "Delete", "Share")
    ///   - action: Closure que ejecuta la acción
    /// - Returns: View modificado con la acción
    public func accessibleAction(named name: String, _ action: @escaping () -> Void) -> some View {
        self.accessibilityAction(named: name, action)
    }

    // MARK: - Focus

    /// Añade un sort priority para determinar el orden de focus de VoiceOver
    ///
    /// Mayor prioridad = más temprano en el orden de lectura.
    ///
    /// - Parameter priority: Prioridad de ordenamiento (default 0)
    /// - Returns: View modificado
    public func accessibleSortPriority(_ priority: Double) -> some View {
        self.accessibilitySortPriority(priority)
    }
}

// MARK: - Identifier Modifier

private struct AccessibilityIdentifierModifier: ViewModifier {
    let identifier: AccessibilityIdentifier

    func body(content: Content) -> some View {
        content
            .accessibilityIdentifier(identifier.id)
            .onAppear {
                // Registrar el identifier para detección de duplicados
                _ = AccessibilityIdentifierRegistry.shared.register(identifier)
            }
    }
}

// MARK: - Configuration Modifier

private struct AccessibilityConfigurationModifier: ViewModifier {
    let label: AccessibilityLabel?
    let hint: AccessibilityHint?
    let value: String?
    let traits: AccessibilityTraits?
    let identifier: AccessibilityIdentifier?
    let isHidden: Bool

    func body(content: Content) -> some View {
        Group {
            if let label = label {
                content.accessibleLabel(label)
            } else {
                content
            }
        }
        .modifier(HintModifier(hint: hint, label: label))
        .modifier(ValueModifier(value: value))
        .modifier(TraitsModifier(traits: traits))
        .modifier(IdentifierModifierOptional(identifier: identifier))
        .accessibilityHidden(isHidden)
    }
}

private struct HintModifier: ViewModifier {
    let hint: AccessibilityHint?
    let label: AccessibilityLabel?

    func body(content: Content) -> some View {
        if let hint = hint, AccessibilityHint.shouldShow(hint: hint, label: label) {
            content.accessibleHint(hint)
        } else {
            content
        }
    }
}

private struct ValueModifier: ViewModifier {
    let value: String?

    func body(content: Content) -> some View {
        if let value = value {
            content.accessibleValue(value)
        } else {
            content
        }
    }
}

private struct TraitsModifier: ViewModifier {
    let traits: AccessibilityTraits?

    func body(content: Content) -> some View {
        if let traits = traits {
            content.accessibleTraits(traits)
        } else {
            content
        }
    }
}

private struct IdentifierModifierOptional: ViewModifier {
    let identifier: AccessibilityIdentifier?

    func body(content: Content) -> some View {
        if let identifier = identifier {
            content.accessibleIdentifier(identifier)
        } else {
            content
        }
    }
}

// MARK: - macOS Traits Modifier

#if os(macOS)
private struct MacOSAccessibilityTraitsModifier: ViewModifier {
    let traits: AccessibilityTraits

    func body(content: Content) -> some View {
        content
            .accessibilityElement()
            // En macOS, los traits se mapean principalmente a roles
            // Los roles nativos de SwiftUI ya manejan la mayoría de casos
            // isEnabled se maneja via el modifier .disabled() del component mismo
    }
}
#endif

// MARK: - Convenience View Extensions para Elementos Comunes

extension View {
    /// Marca este view como un botón accesible con configuración completa
    ///
    /// Configura automáticamente traits, label y hint apropiados para un botón.
    ///
    /// Ejemplo:
    /// ```swift
    /// MyCustomButton()
    ///     .asAccessibleButton(
    ///         label: "Save document",
    ///         hint: "Saves your changes to the cloud"
    ///     )
    /// ```
    public func asAccessibleButton(
        label: String,
        hint: String? = nil,
        identifier: AccessibilityIdentifier? = nil
    ) -> some View {
        self
            .accessibleLabel(label)
            .accessibleHint(hint.map { AccessibilityHint.text($0) }, shouldShow: hint != nil)
            .accessibleTraits(.button)
            .modifier(OptionalIdentifierModifier(identifier: identifier))
    }

    /// Marca este view como un link accesible
    public func asAccessibleLink(
        destination: String,
        identifier: AccessibilityIdentifier? = nil
    ) -> some View {
        self
            .accessibleLabel("Link to \(destination)")
            .accessibleTraits(.link)
            .modifier(OptionalIdentifierModifier(identifier: identifier))
    }

    /// Marca este view como un header accesible
    public func asAccessibleHeader(
        title: String,
        identifier: AccessibilityIdentifier? = nil
    ) -> some View {
        self
            .accessibleLabel("\(title) heading")
            .accessibleTraits(.header)
            .modifier(OptionalIdentifierModifier(identifier: identifier))
    }
}

// MARK: - Optional Identifier Modifier

private struct OptionalIdentifierModifier: ViewModifier {
    let identifier: AccessibilityIdentifier?

    func body(content: Content) -> some View {
        if let identifier = identifier {
            content.accessibleIdentifier(identifier)
        } else {
            content
        }
    }
}
