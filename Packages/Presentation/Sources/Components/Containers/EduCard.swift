import SwiftUI

/// Card genérico y reutilizable para agrupar contenido.
///
/// Características:
/// - Padding configurable
/// - Corner radius adaptativo
/// - Shadow/elevation por plataforma
/// - Contenido genérico
/// - Estados: normal, highlighted, disabled
/// - Semantic colors para theming
@MainActor
public struct EduCard<Content: View>: View {
    // MARK: - Types

    public enum Elevation {
        case none
        case low
        case medium
        case high

        var shadowRadius: CGFloat {
            switch self {
            case .none: return DesignTokens.Shadow.none
            case .low: return DesignTokens.Shadow.small
            case .medium: return DesignTokens.Shadow.medium
            case .high: return DesignTokens.Shadow.large
            }
        }

        var shadowY: CGFloat {
            switch self {
            case .none: return 0
            case .low: return 1
            case .medium: return 2
            case .high: return 4
            }
        }
    }

    // MARK: - Properties

    private let content: Content
    private let padding: EdgeInsets
    private let cornerRadius: CGFloat
    private let elevation: Elevation
    private let backgroundColor: Color
    private let isHighlighted: Bool
    private let isDisabled: Bool
    private let accessibilityLabel: String?
    private let onTap: (() -> Void)?

    // MARK: - Initializer

    /// Inicializa un EduCard con todas las opciones de personalización.
    ///
    /// - Parameters:
    ///   - padding: Padding interno del card (default: 16 todos los lados)
    ///   - cornerRadius: Radio de esquinas (default: 12)
    ///   - elevation: Nivel de elevación/shadow (default: .medium)
    ///   - backgroundColor: Color de fondo (default: .cardBackground)
    ///   - isHighlighted: Si el card está destacado
    ///   - isDisabled: Si el card está deshabilitado
    ///   - accessibilityLabel: Label para VoiceOver (opcional)
    ///   - onTap: Closure opcional que se ejecuta al tocar el card
    ///   - content: Contenido del card
    public init(
        padding: EdgeInsets = DesignTokens.Insets.cardDefault,
        cornerRadius: CGFloat = DesignTokens.CornerRadius.xl,
        elevation: Elevation = .medium,
        backgroundColor: Color = .cardBackground,
        isHighlighted: Bool = false,
        isDisabled: Bool = false,
        accessibilityLabel: String? = nil,
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.elevation = elevation
        self.backgroundColor = backgroundColor
        self.isHighlighted = isHighlighted
        self.isDisabled = isDisabled
        self.accessibilityLabel = accessibilityLabel
        self.onTap = onTap
        self.content = content()
    }

    // MARK: - Body

    public var body: some View {
        Group {
            if let onTap = onTap {
                Button(action: onTap) {
                    cardContent
                }
                .buttonStyle(.plain)
                .disabled(isDisabled)
            } else {
                cardContent
            }
        }
    }

    private var cardContent: some View {
        content
            .padding(padding)
            .background(effectiveBackgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(
                color: shadowColor,
                radius: elevation.shadowRadius,
                x: 0,
                y: elevation.shadowY
            )
            .opacity(isDisabled ? 0.6 : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: isHighlighted ? DesignTokens.BorderWidth.medium : 0)
            )
            // MARK: - Accessibility
            .cardGrouped(headerLabel: accessibilityLabel ?? "Card")
            .accessibilityAddTraits(onTap != nil ? .isButton : [])
            .accessibilityRemoveTraits(isDisabled ? .isButton : [])
            // MARK: - Keyboard Navigation
            .tabPriority(onTap != nil ? 40 : 100)
    }

    // MARK: - Styling Helpers

    private var effectiveBackgroundColor: Color {
        if isHighlighted {
            return backgroundColor.opacity(0.95)
        }
        return backgroundColor
    }

    private var shadowColor: Color {
        Color.black.opacity(0.1)
    }

    private var borderColor: Color {
        isHighlighted ? .accentColor : .clear
    }
}

// MARK: - Convenience Initializers

// MARK: - Specialized Card Functions

/// Crea un card hero con elevación alta y padding generoso.
@MainActor
public func EduHeroCardFunction<C: View>(@ViewBuilder content: () -> C) -> EduCard<C> {
    EduCard(
        padding: DesignTokens.Insets.cardHero,
        elevation: .high,
        content: content
    )
}

/// Crea un card de lista con padding compacto.
@MainActor
public func EduListCardFunction<C: View>(@ViewBuilder content: () -> C) -> EduCard<C> {
    EduCard(
        padding: DesignTokens.Insets.cardList,
        elevation: .low,
        content: content
    )
}

// MARK: - Color Extension

extension Color {
    /// Color semántico para fondos de cards.
    public static var cardBackground: Color {
        #if os(iOS) || os(visionOS)
        return Color(uiColor: .secondarySystemBackground)
        #elseif os(macOS)
        return Color(nsColor: .controlBackgroundColor)
        #else
        return Color(white: 0.95)
        #endif
    }
}

// MARK: - Specialized Cards

/// Card hero para contenido destacado.
@MainActor
public struct EduHeroCard<Content: View>: View {
    private let content: Content
    private let onTap: (() -> Void)?

    public init(
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.onTap = onTap
        self.content = content()
    }

    public var body: some View {
        EduHeroCardFunction {
            content
        }
    }
}

/// Card para elementos de lista.
@MainActor
public struct EduListCard<Content: View>: View {
    private let content: Content
    private let onTap: (() -> Void)?

    public init(
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.onTap = onTap
        self.content = content()
    }

    public var body: some View {
        EduListCardFunction {
            content
        }
    }
}

// MARK: - Previews

#Preview("Card Simple") {
    EduCard {
        VStack(alignment: .leading, spacing: 8) {
            Text("Título del Card")
                .font(.headline)
            Text("Este es un card simple con contenido de ejemplo.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
    .padding()
}

#Preview("Card con Elevaciones") {
    VStack(spacing: 16) {
        EduCard(elevation: .none) {
            Text("Sin Elevación")
        }

        EduCard(elevation: .low) {
            Text("Elevación Baja")
        }

        EduCard(elevation: .medium) {
            Text("Elevación Media")
        }

        EduCard(elevation: .high) {
            Text("Elevación Alta")
        }
    }
    .padding()
}

#Preview("Card Destacado") {
    EduCard(isHighlighted: true) {
        VStack(alignment: .leading, spacing: 8) {
            Text("Card Destacado")
                .font(.headline)
            Text("Este card tiene un borde de acento.")
                .font(.body)
        }
    }
    .padding()
}

#Preview("Card Deshabilitado") {
    EduCard(isDisabled: true) {
        VStack(alignment: .leading, spacing: 8) {
            Text("Card Deshabilitado")
                .font(.headline)
            Text("Este card está en estado deshabilitado.")
                .font(.body)
        }
    }
    .padding()
}

#Preview("Card Interactivo") {
    @Previewable @State var tapped = false

    EduCard(onTap: {
        tapped.toggle()
    }) {
        VStack(alignment: .leading, spacing: 8) {
            Text("Card Interactivo")
                .font(.headline)
            Text("Toca este card para interactuar")
                .font(.body)
            Text("Tapped: \(tapped ? "Sí" : "No")")
                .font(.caption)
                .foregroundStyle(tapped ? .green : .secondary)
        }
    }
    .padding()
}

#Preview("Hero Card") {
    EduHeroCard {
        VStack(spacing: 16) {
            Image(systemName: "star.fill")
                .font(.system(size: 48))
                .foregroundStyle(.yellow)

            Text("Contenido Hero")
                .font(.title)
                .fontWeight(.bold)

            Text("Este es un card hero con padding generoso y elevación alta.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    .padding()
}

#Preview("List Card") {
    VStack(spacing: 8) {
        ForEach(0..<5, id: \.self) { index in
            EduListCard {
                HStack {
                    Image(systemName: "doc.fill")
                        .foregroundStyle(Color.accentColor)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Elemento \(index + 1)")
                            .font(.body)
                        Text("Descripción breve")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    .padding()
}

#Preview("Dark Mode") {
    VStack(spacing: 16) {
        EduCard {
            Text("Card en Dark Mode")
        }

        EduCard(isHighlighted: true) {
            Text("Card Destacado")
        }

        EduHeroCard {
            Text("Hero Card")
        }
    }
    .padding()
    .preferredColorScheme(.dark)
}
