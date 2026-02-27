import SwiftUI

// MARK: - SwipeAction

/// Define una acción de swipe para EduRow (solo iOS).
@available(iOS 26.0, macOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 2.0, *)
public struct SwipeAction: Sendable {
    /// Título de la acción.
    public let title: String

    /// Icono de la acción.
    public let icon: String?

    /// Rol de la acción (define el color y comportamiento).
    public let role: SwipeActionRole

    /// Closure que se ejecuta al activar la acción.
    public let action: @Sendable () -> Void

    /// Crea una nueva acción de swipe.
    public init(title: String, icon: String? = nil, role: SwipeActionRole = .normal, action: @escaping @Sendable () -> Void) {
        self.title = title
        self.icon = icon
        self.role = role
        self.action = action
    }
}

/// Rol de una acción de swipe.
@available(iOS 26.0, macOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 2.0, *)
public enum SwipeActionRole: Sendable {
    case normal
    case destructive
}

// MARK: - EduRow

/// Vista reutilizable para crear filas de lista consistentes en la aplicación con soporte para swipe actions en iOS.
///
/// `EduRow` proporciona un componente de fila personalizable con soporte para:
/// - Contenido principal con título y descripción opcional
/// - Vistas leading y trailing opcionales
/// - Acciones de tap personalizables
/// - Divisor configurable
/// - Swipe actions para iOS (trailing y leading)
///
/// ## Ejemplo básico
///
///     List {
///         EduRow("Título", description: "Descripción")
///         EduRow("Solo título")
///         EduRow("Con acción") {
///             print("Tapped")
///         }
///     }
///
/// ## Swipe Actions (solo iOS)
///
/// `EduRow` soporta acciones de swipe tanto leading como trailing usando el tipo `SwipeAction`, que permite personalizar título, icono, rol y acción para cada operación.
///
/// ## Personalización
///
/// El componente es completamente personalizable mediante vistas SwiftUI:
///
///     EduRow(
///         "Notificaciones",
///         description: "Recibir alertas",
///         leading: Image(systemName: "bell.fill"),
///         trailing: Toggle("", isOn: $enabled)
///     )
///
@available(iOS 26.0, macOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 2.0, *)
public struct EduRow<Leading: View, Trailing: View>: View {
    /// Título principal de la fila.
    public let title: String

    /// Descripción opcional debajo del título.
    public let description: String?

    /// Vista opcional que aparece a la izquierda del contenido.
    private let _leading: Leading?

    /// Vista opcional que aparece a la derecha del contenido.
    private let _trailing: Trailing?

    /// Indica si se debe mostrar un divisor debajo de la fila.
    public let showDivider: Bool

    /// Acción a ejecutar al hacer tap en la fila.
    public let onTap: (@Sendable () -> Void)?

    /// Acciones de swipe desde el lado derecho (solo iOS).
    public let trailingSwipeActions: [SwipeAction]

    /// Acciones de swipe desde el lado izquierdo (solo iOS).
    public let leadingSwipeActions: [SwipeAction]

    /// Indica si se permite el full swipe en las acciones trailing (solo iOS).
    /// Cuando es true, hacer swipe completo ejecuta automáticamente la primera acción.
    public let allowsFullSwipe: Bool

    /// Inicializa una nueva fila con el contenido especificado.
    ///
    /// - Parameters:
    ///   - title: Título principal de la fila.
    ///   - description: Descripción opcional debajo del título.
    ///   - leading: Vista opcional que aparece a la izquierda del contenido.
    ///   - trailing: Vista opcional que aparece a la derecha del contenido.
    ///   - showDivider: Indica si se debe mostrar un divisor debajo de la fila. Por defecto es `true`.
    ///   - trailingSwipeActions: Acciones de swipe desde el lado derecho (solo iOS).
    ///   - leadingSwipeActions: Acciones de swipe desde el lado izquierdo (solo iOS).
    ///   - allowsFullSwipe: Si es true, hacer swipe completo ejecuta automáticamente la primera acción trailing (solo iOS).
    ///   - onTap: Closure opcional que se ejecuta cuando se toca la fila.
    public init(
        _ title: String,
        description: String? = nil,
        leading: Leading? = nil,
        trailing: Trailing? = nil,
        showDivider: Bool = true,
        trailingSwipeActions: [SwipeAction] = [],
        leadingSwipeActions: [SwipeAction] = [],
        allowsFullSwipe: Bool = true,
        onTap: (@Sendable () -> Void)? = nil
    ) {
        self.title = title
        self.description = description
        self.showDivider = showDivider
        self.trailingSwipeActions = trailingSwipeActions
        self.leadingSwipeActions = leadingSwipeActions
        self.allowsFullSwipe = allowsFullSwipe
        self.onTap = onTap
        self._leading = leading
        self._trailing = trailing
    }

    public var body: some View {
        VStack(spacing: 0) {
            rowContent
                .applySwipeActions(
                    trailing: trailingSwipeActions,
                    leading: leadingSwipeActions,
                    allowsFullSwipe: allowsFullSwipe
                )

            if showDivider {
                Divider()
                    .padding(.leading, _leading != nil ? 44 : 16)
            }
        }
    }

    // MARK: - Private Views

    @ViewBuilder
    private var rowContent: some View {
        Button(action: {
            onTap?()
        }) {
            HStack(spacing: DesignTokens.Spacing.medium) {
                // Vista leading opcional
                if let _leading {
                    _leading
                        .foregroundStyle(.secondary)
                }

                // Contenido principal
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(.primary)

                    if let description {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Vista trailing opcional
                if let _trailing {
                    _trailing
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, DesignTokens.Spacing.medium)
            .padding(.horizontal, DesignTokens.Spacing.large)
        }
        .buttonStyle(.plain)
        // MARK: - Accessibility
        .rowGrouped(title: title, subtitle: description)
        .accessibilityHint(swipeActionsHint)
        // MARK: - Keyboard Navigation
        .tabPriority(45)
    }

    // MARK: - Accessibility Helpers

    private var swipeActionsHint: String {
        var hints: [String] = []
        if !trailingSwipeActions.isEmpty {
            let actions = trailingSwipeActions.map { $0.title }.joined(separator: ", ")
            hints.append("Swipe left for \(actions)")
        }
        if !leadingSwipeActions.isEmpty {
            let actions = leadingSwipeActions.map { $0.title }.joined(separator: ", ")
            hints.append("Swipe right for \(actions)")
        }
        return hints.joined(separator: ". ")
    }
}

// MARK: - View Extensions

@available(iOS 26.0, macOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 2.0, *)
private extension View {
    /// Aplica swipe actions solo en iOS.
    @ViewBuilder
    func applySwipeActions(
        trailing: [SwipeAction],
        leading: [SwipeAction],
        allowsFullSwipe: Bool
    ) -> some View {
        #if os(iOS)
        self
            .conditionalSwipeActions(edge: .trailing, allowsFullSwipe: allowsFullSwipe, actions: trailing)
            .conditionalSwipeActions(edge: .leading, allowsFullSwipe: false, actions: leading)
        #else
        self
        #endif
    }

    #if os(iOS)
    /// Aplica swipe actions condicionalmente si hay acciones definidas.
    @ViewBuilder
    func conditionalSwipeActions(
        edge: HorizontalEdge,
        allowsFullSwipe: Bool,
        actions: [SwipeAction]
    ) -> some View {
        if !actions.isEmpty {
            self.swipeActions(edge: edge, allowsFullSwipe: allowsFullSwipe) {
                ForEach(actions.indices, id: \.self) { index in
                    Button(role: actions[index].role == .destructive ? .destructive : nil) {
                        actions[index].action()
                    } label: {
                        if let icon = actions[index].icon {
                            Label(actions[index].title, systemImage: icon)
                        } else {
                            Text(actions[index].title)
                        }
                    }
                }
            }
        } else {
            self
        }
    }
    #endif
}

// MARK: - Convenience Initializers

@available(iOS 26.0, macOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 2.0, *)
extension EduRow where Leading == EmptyView {
    /// Inicializa una fila sin vista leading.
    public init(
        _ title: String,
        description: String? = nil,
        trailing: Trailing? = nil,
        showDivider: Bool = true,
        trailingSwipeActions: [SwipeAction] = [],
        leadingSwipeActions: [SwipeAction] = [],
        allowsFullSwipe: Bool = true,
        onTap: (@Sendable () -> Void)? = nil
    ) {
        self.init(
            title,
            description: description,
            leading: nil as EmptyView?,
            trailing: trailing,
            showDivider: showDivider,
            trailingSwipeActions: trailingSwipeActions,
            leadingSwipeActions: leadingSwipeActions,
            allowsFullSwipe: allowsFullSwipe,
            onTap: onTap
        )
    }
}

@available(iOS 26.0, macOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 2.0, *)
extension EduRow where Trailing == EmptyView {
    /// Inicializa una fila sin vista trailing.
    public init(
        _ title: String,
        description: String? = nil,
        leading: Leading? = nil,
        showDivider: Bool = true,
        trailingSwipeActions: [SwipeAction] = [],
        leadingSwipeActions: [SwipeAction] = [],
        allowsFullSwipe: Bool = true,
        onTap: (@Sendable () -> Void)? = nil
    ) {
        self.init(
            title,
            description: description,
            leading: leading,
            trailing: nil as EmptyView?,
            showDivider: showDivider,
            trailingSwipeActions: trailingSwipeActions,
            leadingSwipeActions: leadingSwipeActions,
            allowsFullSwipe: allowsFullSwipe,
            onTap: onTap
        )
    }
}

@available(iOS 26.0, macOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 2.0, *)
extension EduRow where Leading == EmptyView, Trailing == EmptyView {
    /// Inicializa una fila solo con contenido de texto.
    public init(
        _ title: String,
        description: String? = nil,
        showDivider: Bool = true,
        trailingSwipeActions: [SwipeAction] = [],
        leadingSwipeActions: [SwipeAction] = [],
        allowsFullSwipe: Bool = true,
        onTap: (@Sendable () -> Void)? = nil
    ) {
        self.init(
            title,
            description: description,
            leading: nil as EmptyView?,
            trailing: nil as EmptyView?,
            showDivider: showDivider,
            trailingSwipeActions: trailingSwipeActions,
            leadingSwipeActions: leadingSwipeActions,
            allowsFullSwipe: allowsFullSwipe,
            onTap: onTap
        )
    }
}

// MARK: - Previews

@available(iOS 26.0, macOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 2.0, *)
#Preview("EduRow - Basic") {
    List {
        EduRow("Título", description: "Descripción")
        EduRow("Título sin descripción")
        EduRow("Con onTap") {
            print("Tapped")
        }
    }
}

@available(iOS 26.0, macOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 2.0, *)
#Preview("EduRow - With Leading & Trailing") {
    List {
        EduRow(
            "Usuario",
            description: "usuario@example.com",
            leading: Image(systemName: "person.circle.fill")
                .font(.title2),
            trailing: Image(systemName: "chevron.right")
                .font(.caption)
        )

        EduRow(
            "Notificaciones",
            leading: Image(systemName: "bell.fill")
                .foregroundStyle(.blue),
            trailing: Toggle("", isOn: .constant(true))
                .labelsHidden()
        )
    }
}

#if os(iOS)
@available(iOS 26.0, *)
#Preview("EduRow - With Swipe Actions (iOS only)") {
    List {
        EduRow(
            "Email importante",
            description: "Swipe para ver acciones",
            leading: Image(systemName: "envelope.fill"),
            trailingSwipeActions: [
                SwipeAction(title: "Eliminar", icon: "trash", role: .destructive) {
                    print("Deleted")
                },
                SwipeAction(title: "Archivar", icon: "archivebox") {
                    print("Archived")
                }
            ],
            leadingSwipeActions: [
                SwipeAction(title: "Marcar", icon: "flag.fill") {
                    print("Flagged")
                }
            ]
        )

        EduRow(
            "Mensaje",
            description: "Full swipe para eliminar rápido",
            trailingSwipeActions: [
                SwipeAction(title: "Eliminar", icon: "trash", role: .destructive) {
                    print("Quick deleted")
                }
            ],
            allowsFullSwipe: true
        )

        EduRow(
            "Tarea",
            description: "Full swipe deshabilitado",
            trailingSwipeActions: [
                SwipeAction(title: "Completar", icon: "checkmark") {
                    print("Completed")
                }
            ],
            allowsFullSwipe: false
        )
    }
}
#endif

@available(iOS 26.0, macOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 2.0, *)
#Preview("EduRow - Without Divider") {
    List {
        EduRow("Primera fila", showDivider: false)
        EduRow("Segunda fila", showDivider: false)
        EduRow("Tercera fila", showDivider: false)
    }
}
