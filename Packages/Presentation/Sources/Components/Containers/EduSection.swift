import SwiftUI

/// Section con header/footer customizables y contenido colapsable.
///
/// Características:
/// - Header y footer opcionales
/// - Dividers configurables
/// - Contenido colapsable
/// - Adaptación por plataforma
@MainActor
public struct EduSection<Header: View, Content: View, Footer: View>: View {
    // MARK: - Properties

    private let header: Header?
    private let content: Content
    private let footer: Footer?
    private let showDivider: Bool
    private let isCollapsible: Bool

    @State private var isExpanded: Bool = true

    // MARK: - Initializers

    /// Inicializa un EduSection completo con header, content y footer.
    ///
    /// - Parameters:
    ///   - header: Vista del header
    ///   - footer: Vista del footer
    ///   - showDivider: Mostrar divider entre header y contenido
    ///   - isCollapsible: Si la sección puede colapsarse
    ///   - content: Contenido de la sección
    public init(
        header: () -> Header,
        footer: () -> Footer,
        showDivider: Bool = true,
        isCollapsible: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.header = header()
        self.footer = footer()
        self.showDivider = showDivider
        self.isCollapsible = isCollapsible
        self.content = content()
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            if let header = header {
                if isCollapsible {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded.toggle()
                        }
                    }) {
                        HStack {
                            header
                            Spacer()
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(.plain)
                } else {
                    header
                }

                if showDivider {
                    Divider()
                        .padding(.vertical, DesignTokens.Spacing.small)
                }
            }

            // Content (collapsible)
            if isExpanded {
                content
            }

            // Footer
            if let footer = footer, isExpanded {
                if showDivider {
                    Divider()
                        .padding(.vertical, DesignTokens.Spacing.small)
                }
                footer
            }
        }
        // MARK: - Accessibility
        .accessibilityElement(children: .contain)
        .accessibilityLabel(isCollapsible ? (isExpanded ? "Section expanded" : "Section collapsed") : "Section")
        // MARK: - Keyboard Navigation
        .tabGroup(id: "section", priority: 60)
    }
}

// MARK: - Convenience Initializers

extension EduSection where Header == EmptyView {
    /// Inicializa un EduSection sin header.
    public init(
        footer: () -> Footer,
        showDivider: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.header = nil
        self.footer = footer()
        self.showDivider = showDivider
        self.isCollapsible = false
        self.content = content()
    }
}

extension EduSection where Footer == EmptyView {
    /// Inicializa un EduSection sin footer.
    public init(
        header: () -> Header,
        showDivider: Bool = true,
        isCollapsible: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.header = header()
        self.footer = nil
        self.showDivider = showDivider
        self.isCollapsible = isCollapsible
        self.content = content()
    }
}

extension EduSection where Header == EmptyView, Footer == EmptyView {
    /// Inicializa un EduSection sin header ni footer.
    public init(
        showDivider: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.header = nil
        self.footer = nil
        self.showDivider = showDivider
        self.isCollapsible = false
        self.content = content()
    }
}

// MARK: - Standard Header/Footer Views

/// Header estándar para secciones.
@MainActor
public struct EduSectionHeader: View {
    private let title: String
    private let subtitle: String?
    private let icon: String?

    public init(_ title: String, subtitle: String? = nil, icon: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
    }

    public var body: some View {
        HStack(spacing: DesignTokens.Spacing.medium) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, DesignTokens.Spacing.small)
        // MARK: - Accessibility
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .accessibilityLabel(subtitle != nil ? "\(title), \(subtitle!)" : title)
    }
}

/// Footer estándar para secciones.
@MainActor
public struct EduSectionFooter: View {
    private let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.vertical, DesignTokens.Spacing.small)
    }
}

// MARK: - Previews

#Preview("Section Básica") {
    EduSection(
        header: {
            EduSectionHeader("Información Personal")
        }
    ) {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nombre: Juan Pérez")
            Text("Email: juan@ejemplo.com")
            Text("Teléfono: +1 234 567 890")
        }
        .padding(.vertical, 8)
    }
    .padding()
}

#Preview("Section con Header y Footer") {
    EduSection(
        header: {
            EduSectionHeader("Configuración de Cuenta", subtitle: "Actualiza tu información", icon: "person.circle")
        },
        footer: {
            EduSectionFooter("Estos cambios se sincronizarán automáticamente.")
        }
    ) {
        VStack(spacing: 12) {
            Text("Opción 1")
            Text("Opción 2")
            Text("Opción 3")
        }
        .padding(.vertical, 8)
    }
    .padding()
}

#Preview("Section Colapsable") {
    VStack(spacing: 16) {
        EduSection(
            header: {
                EduSectionHeader("Detalles Adicionales", icon: "info.circle")
            },
            showDivider: true,
            isCollapsible: true
        ) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Información adicional que puede ocultarse")
                Text("Línea 2")
                Text("Línea 3")
            }
            .padding(.vertical, 8)
        }

        EduSection(
            header: {
                EduSectionHeader("Otra Sección", icon: "list.bullet")
            },
            isCollapsible: true
        ) {
            Text("Contenido de la segunda sección")
                .padding(.vertical, 8)
        }
    }
    .padding()
}

#Preview("Section sin Divider") {
    EduSection(
        header: {
            Text("Header Personalizado")
                .font(.title2)
                .fontWeight(.bold)
        },
        showDivider: false
    ) {
        Text("Contenido sin divider entre header y content")
            .padding(.vertical, 8)
    }
    .padding()
}

#Preview("Section Solo Contenido") {
    EduSection {
        VStack(alignment: .leading, spacing: 12) {
            Text("Esta sección no tiene header ni footer")
            Text("Solo contiene el contenido principal")
        }
    }
    .padding()
}

#Preview("Múltiples Sections") {
    ScrollView {
        VStack(spacing: 24) {
            EduSection(
                header: {
                    EduSectionHeader("Sección 1", icon: "1.circle.fill")
                }
            ) {
                Text("Contenido de la sección 1")
                    .padding(.vertical, 8)
            }

            EduSection(
                header: {
                    EduSectionHeader("Sección 2", icon: "2.circle.fill")
                }
            ) {
                Text("Contenido de la sección 2")
                    .padding(.vertical, 8)
            }

            EduSection(
                header: {
                    EduSectionHeader("Sección 3", icon: "3.circle.fill")
                },
                footer: {
                    EduSectionFooter("Fin de las secciones")
                }
            ) {
                Text("Contenido de la sección 3")
                    .padding(.vertical, 8)
            }
        }
        .padding()
    }
}

#Preview("Dark Mode") {
    VStack(spacing: 16) {
        EduSection(
            header: {
                EduSectionHeader("Configuración", icon: "gearshape")
            }
        ) {
            Text("Contenido en dark mode")
                .padding(.vertical, 8)
        }

        EduSection(
            header: {
                EduSectionHeader("Opciones Avanzadas", icon: "wrench")
            },
            isCollapsible: true
        ) {
            Text("Contenido colapsable")
                .padding(.vertical, 8)
        }
    }
    .padding()
    .preferredColorScheme(.dark)
}
