import SwiftUI

/// Extensiones y estilos personalizados de botones para EduGo.
///
/// Proporciona ButtonStyles reutilizables que complementan EduButton
/// y pueden aplicarse a Button estándar de SwiftUI.

// MARK: - Edu Button Styles

/// Estilo de botón primary con background de accentColor.
public struct EduPrimaryButtonStyle: ButtonStyle {
    public let size: EduButton.Size

    public init(size: EduButton.Size = .medium) {
        self.size = size
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.fontSize)
            .fontWeight(.semibold)
            .padding(size.padding)
            .frame(maxWidth: .infinity)
            .foregroundStyle(.white)
            .background(.tint)
            .cornerRadius(cornerRadius)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }

    private var cornerRadius: CGFloat {
        switch size {
        case .small: return DesignTokens.CornerRadius.small
        case .medium: return DesignTokens.CornerRadius.medium
        case .large: return DesignTokens.CornerRadius.large
        }
    }
}

/// Estilo de botón secondary con borde y background transparente.
public struct EduSecondaryButtonStyle: ButtonStyle {
    public let size: EduButton.Size

    public init(size: EduButton.Size = .medium) {
        self.size = size
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.fontSize)
            .fontWeight(.semibold)
            .padding(size.padding)
            .frame(maxWidth: .infinity)
            .foregroundStyle(.tint)
            .background(Color.clear)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.accentColor, lineWidth: DesignTokens.BorderWidth.medium)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }

    private var cornerRadius: CGFloat {
        switch size {
        case .small: return DesignTokens.CornerRadius.small
        case .medium: return DesignTokens.CornerRadius.medium
        case .large: return DesignTokens.CornerRadius.large
        }
    }
}

/// Estilo de botón destructive con tema rojo.
public struct EduDestructiveButtonStyle: ButtonStyle {
    public let size: EduButton.Size

    public init(size: EduButton.Size = .medium) {
        self.size = size
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.fontSize)
            .fontWeight(.semibold)
            .padding(size.padding)
            .frame(maxWidth: .infinity)
            .foregroundStyle(.red)
            .background(Color.clear)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.red, lineWidth: DesignTokens.BorderWidth.medium)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }

    private var cornerRadius: CGFloat {
        switch size {
        case .small: return DesignTokens.CornerRadius.small
        case .medium: return DesignTokens.CornerRadius.medium
        case .large: return DesignTokens.CornerRadius.large
        }
    }
}

/// Estilo de botón link simple sin background.
public struct EduLinkButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.tint)
            .underline(configuration.isPressed)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - View Extension

extension View {
    /// Aplica el estilo primary de EduGo al botón.
    public func eduPrimaryButtonStyle(size: EduButton.Size = .medium) -> some View {
        self.buttonStyle(EduPrimaryButtonStyle(size: size))
    }

    /// Aplica el estilo secondary de EduGo al botón.
    public func eduSecondaryButtonStyle(size: EduButton.Size = .medium) -> some View {
        self.buttonStyle(EduSecondaryButtonStyle(size: size))
    }

    /// Aplica el estilo destructive de EduGo al botón.
    public func eduDestructiveButtonStyle(size: EduButton.Size = .medium) -> some View {
        self.buttonStyle(EduDestructiveButtonStyle(size: size))
    }

    /// Aplica el estilo link de EduGo al botón.
    public func eduLinkButtonStyle() -> some View {
        self.buttonStyle(EduLinkButtonStyle())
    }
}

// MARK: - Platform-Specific Adaptations

#if os(iOS)
extension ButtonStyle where Self == EduPrimaryButtonStyle {
    /// Estilo primary optimizado para iOS.
    public static var eduPrimary: EduPrimaryButtonStyle {
        EduPrimaryButtonStyle(size: .medium)
    }
}

extension ButtonStyle where Self == EduSecondaryButtonStyle {
    /// Estilo secondary optimizado para iOS.
    public static var eduSecondary: EduSecondaryButtonStyle {
        EduSecondaryButtonStyle(size: .medium)
    }
}

extension ButtonStyle where Self == EduDestructiveButtonStyle {
    /// Estilo destructive optimizado para iOS.
    public static var eduDestructive: EduDestructiveButtonStyle {
        EduDestructiveButtonStyle(size: .medium)
    }
}

extension ButtonStyle where Self == EduLinkButtonStyle {
    /// Estilo link optimizado para iOS.
    public static var eduLink: EduLinkButtonStyle {
        EduLinkButtonStyle()
    }
}
#endif

#if os(macOS)
extension ButtonStyle where Self == EduPrimaryButtonStyle {
    /// Estilo primary optimizado para macOS.
    public static var eduPrimary: EduPrimaryButtonStyle {
        EduPrimaryButtonStyle(size: .medium)
    }
}

extension ButtonStyle where Self == EduSecondaryButtonStyle {
    /// Estilo secondary optimizado para macOS.
    public static var eduSecondary: EduSecondaryButtonStyle {
        EduSecondaryButtonStyle(size: .medium)
    }
}

extension ButtonStyle where Self == EduDestructiveButtonStyle {
    /// Estilo destructive optimizado para macOS.
    public static var eduDestructive: EduDestructiveButtonStyle {
        EduDestructiveButtonStyle(size: .medium)
    }
}

extension ButtonStyle where Self == EduLinkButtonStyle {
    /// Estilo link optimizado para macOS.
    public static var eduLink: EduLinkButtonStyle {
        EduLinkButtonStyle()
    }
}
#endif

// MARK: - Previews

#Preview("ButtonStyles Aplicados") {
    VStack(spacing: 16) {
        Button("Primary Style") { }
            .eduPrimaryButtonStyle()

        Button("Secondary Style") { }
            .eduSecondaryButtonStyle()

        Button("Destructive Style") { }
            .eduDestructiveButtonStyle()

        Button("Link Style") { }
            .eduLinkButtonStyle()
    }
    .padding()
}

#Preview("Tamaños Diferentes") {
    VStack(spacing: 16) {
        Button("Small") { }
            .eduPrimaryButtonStyle(size: .small)

        Button("Medium") { }
            .eduPrimaryButtonStyle(size: .medium)

        Button("Large") { }
            .eduPrimaryButtonStyle(size: .large)
    }
    .padding()
}

#Preview("Con Iconos") {
    VStack(spacing: 16) {
        Button(action: {}) {
            Label("Guardar", systemImage: "checkmark")
        }
        .eduPrimaryButtonStyle()

        Button(action: {}) {
            Label("Cancelar", systemImage: "xmark")
        }
        .eduSecondaryButtonStyle()

        Button(action: {}) {
            Label("Eliminar", systemImage: "trash")
        }
        .eduDestructiveButtonStyle()
    }
    .padding()
}

#Preview("Dark Mode") {
    VStack(spacing: 16) {
        Button("Primary") { }
            .eduPrimaryButtonStyle()

        Button("Secondary") { }
            .eduSecondaryButtonStyle()

        Button("Destructive") { }
            .eduDestructiveButtonStyle()

        Button("Link") { }
            .eduLinkButtonStyle()
    }
    .padding()
    .preferredColorScheme(.dark)
}

#Preview("Comparación: EduButton vs ButtonStyle") {
    VStack(spacing: 24) {
        VStack(spacing: 12) {
            Text("Usando EduButton")
                .font(.caption)
                .foregroundStyle(.secondary)

            EduButton.primary("EduButton Primary") { }
            EduButton.secondary("EduButton Secondary") { }
        }

        Divider()

        VStack(spacing: 12) {
            Text("Usando ButtonStyle")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Button Primary") { }
                .eduPrimaryButtonStyle()

            Button("Button Secondary") { }
                .eduSecondaryButtonStyle()
        }
    }
    .padding()
}
