import SwiftUI

/// A view modifier that displays a loading overlay with optional message.
///
/// This modifier disables the content, applies a blur effect, and shows
/// a centered loading indicator when active.
///
/// ## Usage
/// ```swift
/// Form {
///     // form content
/// }
/// .loadingOverlay(isLoading: viewModel.isSubmitting, message: "Saving...")
/// ```
public struct LoadingOverlayModifier: ViewModifier {

    /// Whether the loading overlay is active.
    private let isLoading: Bool

    /// Optional message to display below the spinner.
    private let message: String?

    /// Style configuration for the loading overlay.
    private let style: LoadingOverlayStyle

    /// Creates a loading overlay modifier.
    /// - Parameters:
    ///   - isLoading: Whether to show the loading overlay.
    ///   - message: Optional message to display. Defaults to `nil`.
    ///   - style: The visual style configuration. Defaults to `.default`.
    public init(
        isLoading: Bool,
        message: String? = nil,
        style: LoadingOverlayStyle = .default
    ) {
        self.isLoading = isLoading
        self.message = message
        self.style = style
    }

    public func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)
                .blur(radius: isLoading ? style.blurRadius : 0)

            if isLoading {
                loadingView
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: style.animationDuration), value: isLoading)
    }

    @ViewBuilder
    private var loadingView: some View {
        let container = VStack(spacing: style.contentSpacing) {
            ProgressView()
                .scaleEffect(style.spinnerScale)
                .tint(style.spinnerColor)

            if let message {
                Text(message)
                    .font(style.messageFont)
                    .foregroundColor(style.messageColor)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(style.containerPadding)

        if style.usesGlassEffect {
            container
                .glassEffect(.regular, in: .rect(cornerRadius: style.containerCornerRadius))
                .shadow(
                    color: style.shadowColor,
                    radius: style.shadowRadius,
                    x: 0,
                    y: style.shadowY
                )
        } else {
            container
                .background(
                    RoundedRectangle(cornerRadius: style.containerCornerRadius)
                        .fill(style.containerBackground)
                )
                .shadow(
                    color: style.shadowColor,
                    radius: style.shadowRadius,
                    x: 0,
                    y: style.shadowY
                )
        }
    }
}

// MARK: - Style Configuration

/// Configuration for loading overlay visual appearance.
public struct LoadingOverlayStyle: Sendable {

    /// Blur radius applied to content when loading.
    public let blurRadius: CGFloat

    /// Scale factor for the progress spinner.
    public let spinnerScale: CGFloat

    /// Color of the progress spinner.
    public let spinnerColor: Color?

    /// Spacing between spinner and message.
    public let contentSpacing: CGFloat

    /// Font for the message text.
    public let messageFont: Font

    /// Color for the message text.
    public let messageColor: Color

    /// Padding inside the loading container.
    public let containerPadding: CGFloat

    /// Corner radius of the loading container.
    public let containerCornerRadius: CGFloat

    /// Whether to use Liquid Glass effect for the container.
    public let usesGlassEffect: Bool

    /// Background style for the container (used only when `usesGlassEffect` is false).
    public let containerBackground: AnyShapeStyle

    /// Shadow color.
    public let shadowColor: Color

    /// Shadow blur radius.
    public let shadowRadius: CGFloat

    /// Shadow vertical offset.
    public let shadowY: CGFloat

    /// Animation duration for transitions.
    public let animationDuration: Double

    /// Default loading overlay style with Liquid Glass.
    public static let `default` = LoadingOverlayStyle(
        blurRadius: 2,
        spinnerScale: 1.5,
        spinnerColor: nil,
        contentSpacing: 16,
        messageFont: .subheadline,
        messageColor: .secondary,
        containerPadding: 24,
        containerCornerRadius: 12,
        usesGlassEffect: true,
        containerBackground: AnyShapeStyle(Color.clear),
        shadowColor: .black.opacity(0.1),
        shadowRadius: 10,
        shadowY: 4,
        animationDuration: 0.2
    )

    /// Fullscreen loading style without container.
    public static let fullscreen = LoadingOverlayStyle(
        blurRadius: 3,
        spinnerScale: 2.0,
        spinnerColor: nil,
        contentSpacing: 20,
        messageFont: .headline,
        messageColor: .primary,
        containerPadding: 0,
        containerCornerRadius: 0,
        usesGlassEffect: false,
        containerBackground: AnyShapeStyle(Color.clear),
        shadowColor: .clear,
        shadowRadius: 0,
        shadowY: 0,
        animationDuration: 0.3
    )

    /// Themed style with Liquid Glass and accent colors.
    @MainActor
    public static let themed = LoadingOverlayStyle(
        blurRadius: 2,
        spinnerScale: 1.5,
        spinnerColor: .accentColor,
        contentSpacing: 16,
        messageFont: .subheadline,
        messageColor: .secondary,
        containerPadding: 24,
        containerCornerRadius: 12,
        usesGlassEffect: true,
        containerBackground: AnyShapeStyle(Color.clear),
        shadowColor: Color.black.opacity(0.12),
        shadowRadius: 10,
        shadowY: 4,
        animationDuration: 0.2
    )

    /// Creates a custom loading overlay style.
    public init(
        blurRadius: CGFloat,
        spinnerScale: CGFloat,
        spinnerColor: Color?,
        contentSpacing: CGFloat,
        messageFont: Font,
        messageColor: Color,
        containerPadding: CGFloat,
        containerCornerRadius: CGFloat,
        usesGlassEffect: Bool = true,
        containerBackground: AnyShapeStyle = AnyShapeStyle(Color.clear),
        shadowColor: Color,
        shadowRadius: CGFloat,
        shadowY: CGFloat,
        animationDuration: Double
    ) {
        self.blurRadius = blurRadius
        self.spinnerScale = spinnerScale
        self.spinnerColor = spinnerColor
        self.contentSpacing = contentSpacing
        self.messageFont = messageFont
        self.messageColor = messageColor
        self.containerPadding = containerPadding
        self.containerCornerRadius = containerCornerRadius
        self.usesGlassEffect = usesGlassEffect
        self.containerBackground = containerBackground
        self.shadowColor = shadowColor
        self.shadowRadius = shadowRadius
        self.shadowY = shadowY
        self.animationDuration = animationDuration
    }
}

// MARK: - View Extension

extension View {

    /// Adds a loading overlay to a view.
    ///
    /// - Parameters:
    ///   - isLoading: Whether to show the loading overlay.
    ///   - message: Optional message to display. Defaults to `nil`.
    ///   - style: The visual style configuration. Defaults to `.default`.
    /// - Returns: A view with loading overlay applied.
    @MainActor
    public func loadingOverlay(
        isLoading: Bool,
        message: String? = nil,
        style: LoadingOverlayStyle = .default
    ) -> some View {
        modifier(LoadingOverlayModifier(
            isLoading: isLoading,
            message: message,
            style: style
        ))
    }
}
