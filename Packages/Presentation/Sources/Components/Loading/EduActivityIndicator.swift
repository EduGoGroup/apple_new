import SwiftUI

// MARK: - Activity Indicator Style

/// Estilos disponibles para el activity indicator
public enum EduActivityIndicatorStyle: Sendable {
    case small
    case medium
    case large

    #if os(iOS) || os(visionOS)
    var uiStyle: UIActivityIndicatorView.Style {
        switch self {
        case .small: return .medium
        case .medium: return .medium
        case .large: return .large
        }
    }
    #endif
}

// MARK: - Activity Indicator

/// Activity Indicator adaptativo por plataforma con accessibility
@MainActor
public struct EduActivityIndicator: View {
    private let style: EduActivityIndicatorStyle
    private let color: Color?

    public init(style: EduActivityIndicatorStyle = .medium, color: Color? = nil) {
        self.style = style
        self.color = color
    }

    public var body: some View {
        #if os(iOS) || os(visionOS)
        ProgressView()
            .progressViewStyle(.circular)
            .scaleEffect(scaleForStyle)
            .tint(color)
            .accessibilityLabel("Loading")
            .accessibilityAddTraits(.updatesFrequently)
            .accessibleIdentifier(.loading(module: "ui", screen: "activity"))
            // MARK: - Keyboard Navigation
            .skipInTabOrder()
            .onAppear {
                AccessibilityAnnouncements.announce("Loading", priority: .medium)
            }
            .onDisappear {
                AccessibilityAnnouncements.announce("Content loaded", priority: .low)
            }
        #elseif os(macOS)
        ProgressView()
            .progressViewStyle(.circular)
            .controlSize(controlSizeForStyle)
            .tint(color)
            .accessibilityLabel("Loading")
            .accessibilityAddTraits(.updatesFrequently)
            .accessibleIdentifier(.loading(module: "ui", screen: "activity"))
            // MARK: - Keyboard Navigation
            .skipInTabOrder()
            .onAppear {
                AccessibilityAnnouncements.announce("Loading", priority: .medium)
            }
            .onDisappear {
                AccessibilityAnnouncements.announce("Content loaded", priority: .low)
            }
        #endif
    }

    private var scaleForStyle: CGFloat {
        switch style {
        case .small: return 0.8
        case .medium: return 1.0
        case .large: return 1.5
        }
    }

    #if os(macOS)
    private var controlSizeForStyle: ControlSize {
        switch style {
        case .small: return .small
        case .medium: return .regular
        case .large: return .large
        }
    }
    #endif
}

// MARK: - Inline Loading

/// Loading inline para uso dentro de botones u otros componentes
@MainActor
public struct EduInlineLoader: View {
    private let style: EduActivityIndicatorStyle
    private let tint: Color?

    public init(style: EduActivityIndicatorStyle = .small, tint: Color? = nil) {
        self.style = style
        self.tint = tint
    }

    public var body: some View {
        EduActivityIndicator(style: style, color: tint)
            .frame(width: sizeForStyle, height: sizeForStyle)
    }

    private var sizeForStyle: CGFloat {
        switch style {
        case .small: return DesignTokens.IconSize.small
        case .medium: return DesignTokens.IconSize.medium
        case .large: return DesignTokens.IconSize.large
        }
    }
}

// MARK: - Previews

#Preview("Tamaños") {
    VStack(spacing: 32) {
        EduActivityIndicator(style: .small)
        EduActivityIndicator(style: .medium)
        EduActivityIndicator(style: .large)
    }
    .padding()
}

#Preview("Con color personalizado") {
    VStack(spacing: 32) {
        EduActivityIndicator(style: .medium, color: .blue)
        EduActivityIndicator(style: .medium, color: .green)
        EduActivityIndicator(style: .medium, color: .orange)
    }
    .padding()
}

#Preview("Inline Loader") {
    HStack(spacing: 16) {
        EduInlineLoader(style: .small)
        Text("Procesando...")
    }
    .padding()
}

#Preview("Dark Mode") {
    VStack(spacing: 32) {
        EduActivityIndicator(style: .small)
        EduActivityIndicator(style: .medium)
        EduActivityIndicator(style: .large)
    }
    .padding()
    .preferredColorScheme(.dark)
}
