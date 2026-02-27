import SwiftUI

/// GroupBox adaptativo con estilo nativo por plataforma.
///
/// Características:
/// - Estilo nativo según plataforma (iOS, macOS)
/// - Label customizable
/// - Contenido genérico
/// - Semantic colors para theming
public struct EduGroupBox<Label: View, Content: View>: View {
    // MARK: - Properties

    private let label: Label?
    private let content: Content

    // MARK: - Initializers

    /// Inicializa un EduGroupBox con label y contenido.
    ///
    /// - Parameters:
    ///   - label: Vista del label
    ///   - content: Contenido del group box
    public init(
        @ViewBuilder label: () -> Label,
        @ViewBuilder content: () -> Content
    ) {
        self.label = label()
        self.content = content()
    }

    // MARK: - Body

    public var body: some View {
        #if os(iOS) || os(visionOS)
        iosStyle
        #elseif os(macOS)
        macOSStyle
        #else
        genericStyle
        #endif
    }

    // MARK: - Platform Specific Styles

    @ViewBuilder
    private var iosStyle: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            if let label = label {
                label
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .accessibilityAddTraits(.isHeader)
            }

            content
                .padding(DesignTokens.Spacing.large)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.groupBoxBackground)
                .cornerRadius(DesignTokens.CornerRadius.xl)
        }
        // MARK: - Accessibility
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var macOSStyle: some View {
        GroupBox {
            content
                .padding(DesignTokens.Spacing.small)
        } label: {
            if let label = label {
                label
            }
        }
    }

    @ViewBuilder
    private var genericStyle: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            if let label = label {
                label
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
            }

            content
                .padding(DesignTokens.Spacing.large)
                .background(Color.groupBoxBackground)
                .cornerRadius(DesignTokens.CornerRadius.medium)
        }
        // MARK: - Accessibility
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Convenience Initializers

extension EduGroupBox where Label == Text {
    /// Inicializa un EduGroupBox con un label de texto.
    public init(
        _ label: String,
        @ViewBuilder content: () -> Content
    ) {
        self.label = Text(label)
        self.content = content()
    }
}

extension EduGroupBox where Label == EmptyView {
    /// Inicializa un EduGroupBox sin label.
    public init(
        @ViewBuilder content: () -> Content
    ) {
        self.label = nil
        self.content = content()
    }
}

// MARK: - Color Extension

extension Color {
    /// Color semántico para fondos de group boxes.
    public static var groupBoxBackground: Color {
        #if os(iOS) || os(visionOS)
        return Color(uiColor: .secondarySystemGroupedBackground)
        #elseif os(macOS)
        return Color(nsColor: .controlBackgroundColor)
        #else
        return Color(white: 0.96)
        #endif
    }
}

// MARK: - Standard Labels

/// Label estándar para GroupBox con icono.
public struct EduGroupBoxLabel: View {
    private let title: String
    private let icon: String?

    public init(_ title: String, icon: String? = nil) {
        self.title = title
        self.icon = icon
    }

    public var body: some View {
        HStack(spacing: DesignTokens.Spacing.small) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundStyle(Color.accentColor)
            }
            Text(title)
        }
        // MARK: - Accessibility
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Previews

#Preview("GroupBox Básico") {
    EduGroupBox("Información") {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nombre: Juan Pérez")
            Text("Email: juan@ejemplo.com")
            Text("Teléfono: +1 234 567 890")
        }
    }
    .padding()
}

#Preview("GroupBox con Label Customizado") {
    EduGroupBox {
        EduGroupBoxLabel("Configuración", icon: "gearshape")
    } content: {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Notificaciones")
                Spacer()
                Text("Activado")
                    .foregroundStyle(.secondary)
            }

            Divider()

            HStack {
                Text("Modo Oscuro")
                Spacer()
                Text("Auto")
                    .foregroundStyle(.secondary)
            }

            Divider()

            HStack {
                Text("Idioma")
                Spacer()
                Text("Español")
                    .foregroundStyle(.secondary)
            }
        }
    }
    .padding()
}

#Preview("GroupBox Sin Label") {
    EduGroupBox {
        VStack(spacing: 12) {
            Text("Este GroupBox no tiene label")
            Text("Solo contiene el contenido")
        }
    }
    .padding()
}

#Preview("Múltiples GroupBoxes") {
    ScrollView {
        VStack(spacing: 24) {
            EduGroupBox("Información Personal") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nombre: María García")
                    Text("Edad: 28 años")
                    Text("Ciudad: Madrid")
                }
            }

            EduGroupBox("Preferencias") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tema: Claro")
                    Text("Notificaciones: Activadas")
                    Text("Idioma: Español")
                }
            }

            EduGroupBox {
                EduGroupBoxLabel("Estadísticas", icon: "chart.bar")
            } content: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Cursos completados")
                        Spacer()
                        Text("12")
                            .fontWeight(.bold)
                    }

                    HStack {
                        Text("Horas de estudio")
                        Spacer()
                        Text("156")
                            .fontWeight(.bold)
                    }

                    HStack {
                        Text("Promedio")
                        Spacer()
                        Text("8.7")
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                    }
                }
            }
        }
        .padding()
    }
}

#Preview("GroupBox con Form") {
    EduGroupBox("Formulario de Contacto") {
        VStack(spacing: 16) {
            HStack {
                Text("Nombre:")
                    .frame(width: 80, alignment: .leading)
                TextField("Ingresa tu nombre", text: .constant(""))
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Text("Email:")
                    .frame(width: 80, alignment: .leading)
                TextField("tu@email.com", text: .constant(""))
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Text("Mensaje:")
                    .frame(width: 80, alignment: .leading)
                TextField("Escribe tu mensaje", text: .constant(""))
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
    .padding()
}

#Preview("GroupBox Anidados") {
    EduGroupBox("Configuración General") {
        VStack(spacing: 16) {
            EduGroupBox("Apariencia") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Modo: Automático")
                    Text("Tamaño de fuente: Medio")
                }
            }

            EduGroupBox("Privacidad") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Compartir datos: No")
                    Text("Tracking: Desactivado")
                }
            }
        }
    }
    .padding()
}

#Preview("Dark Mode") {
    VStack(spacing: 16) {
        EduGroupBox("Información") {
            Text("Contenido en dark mode")
        }

        EduGroupBox {
            EduGroupBoxLabel("Con Icono", icon: "star.fill")
        } content: {
            Text("GroupBox con label e icono")
        }
    }
    .padding()
    .preferredColorScheme(.dark)
}

#Preview("Comparación iOS vs macOS") {
    VStack(spacing: 24) {
        Text("iOS Style")
            .font(.caption)
            .foregroundStyle(.secondary)

        EduGroupBox("Ejemplo iOS") {
            Text("Este es el estilo iOS")
        }

        Divider()

        Text("El estilo se adapta automáticamente según la plataforma")
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }
    .padding()
}
