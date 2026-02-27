import SwiftUI

/// A view modifier that displays a banner for form-level errors.
///
/// This modifier shows an error banner at the top of the view when
/// the form state contains a "form" error (typically from cross-field validation).
///
/// ## Usage
/// ```swift
/// Form {
///     // form fields
/// }
/// .formErrorBanner(viewModel.formState)
/// ```
public struct FormErrorBannerModifier: ViewModifier {

    /// The form state to observe for errors.
    private let formState: FormState

    /// Style configuration for the error banner.
    private let style: FormErrorBannerStyle

    /// Creates a form error banner modifier.
    /// - Parameters:
    ///   - formState: The form state to observe.
    ///   - style: The visual style configuration. Defaults to `.default`.
    public init(
        formState: FormState,
        style: FormErrorBannerStyle = .default
    ) {
        self.formState = formState
        self.style = style
    }

    public func body(content: Content) -> some View {
        VStack(spacing: 0) {
            if let formError = formState.errors["form"] {
                errorBanner(message: formError)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            content
        }
        .animation(.easeInOut(duration: style.animationDuration), value: formState.errors["form"])
    }

    @ViewBuilder
    private func errorBanner(message: String) -> some View {
        HStack(spacing: style.iconSpacing) {
            Image(systemName: style.iconName)
                .font(style.iconFont)
                .foregroundColor(style.textColor)

            Text(message)
                .font(style.messageFont)
                .foregroundColor(style.textColor)
                .multilineTextAlignment(.leading)

            Spacer()

            if style.showDismissButton {
                Button {
                    formState.clearError(for: "form")
                } label: {
                    Image(systemName: "xmark")
                        .font(style.dismissButtonFont)
                        .foregroundColor(style.textColor.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(style.padding)
        .frame(maxWidth: .infinity)
        .background(style.backgroundColor)
    }
}

// MARK: - Style Configuration

/// Configuration for form error banner visual appearance.
public struct FormErrorBannerStyle: Sendable {

    /// Icon name to display.
    public let iconName: String

    /// Font for the icon.
    public let iconFont: Font

    /// Spacing between icon and message.
    public let iconSpacing: CGFloat

    /// Font for the error message.
    public let messageFont: Font

    /// Text color for icon and message.
    public let textColor: Color

    /// Background color of the banner.
    public let backgroundColor: Color

    /// Padding inside the banner.
    public let padding: EdgeInsets

    /// Whether to show a dismiss button.
    public let showDismissButton: Bool

    /// Font for the dismiss button.
    public let dismissButtonFont: Font

    /// Animation duration for transitions.
    public let animationDuration: Double

    /// Default error banner style.
    public static let `default` = FormErrorBannerStyle(
        iconName: "exclamationmark.triangle.fill",
        iconFont: .body,
        iconSpacing: 12,
        messageFont: .subheadline,
        textColor: .white,
        backgroundColor: .red,
        padding: EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16),
        showDismissButton: true,
        dismissButtonFont: .caption.weight(.semibold),
        animationDuration: 0.3
    )

    /// Warning style for non-critical messages.
    public static let warning = FormErrorBannerStyle(
        iconName: "exclamationmark.circle.fill",
        iconFont: .body,
        iconSpacing: 12,
        messageFont: .subheadline,
        textColor: .black,
        backgroundColor: .yellow,
        padding: EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16),
        showDismissButton: true,
        dismissButtonFont: .caption.weight(.semibold),
        animationDuration: 0.3
    )

    /// Themed error style that uses semantic colors from the active theme.
    @MainActor
    public static let themed = FormErrorBannerStyle(
        iconName: "exclamationmark.triangle.fill",
        iconFont: .body,
        iconSpacing: 12,
        messageFont: .subheadline,
        textColor: .white,
        backgroundColor: .red,
        padding: EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16),
        showDismissButton: true,
        dismissButtonFont: .caption.weight(.semibold),
        animationDuration: 0.3
    )

    /// Themed warning style that uses semantic colors from the active theme.
    @MainActor
    public static let themedWarning = FormErrorBannerStyle(
        iconName: "exclamationmark.circle.fill",
        iconFont: .body,
        iconSpacing: 12,
        messageFont: .subheadline,
        textColor: .black,
        backgroundColor: .orange,
        padding: EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16),
        showDismissButton: true,
        dismissButtonFont: .caption.weight(.semibold),
        animationDuration: 0.3
    )

    /// Creates a custom form error banner style.
    public init(
        iconName: String,
        iconFont: Font,
        iconSpacing: CGFloat,
        messageFont: Font,
        textColor: Color,
        backgroundColor: Color,
        padding: EdgeInsets,
        showDismissButton: Bool,
        dismissButtonFont: Font,
        animationDuration: Double
    ) {
        self.iconName = iconName
        self.iconFont = iconFont
        self.iconSpacing = iconSpacing
        self.messageFont = messageFont
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.padding = padding
        self.showDismissButton = showDismissButton
        self.dismissButtonFont = dismissButtonFont
        self.animationDuration = animationDuration
    }
}

// MARK: - View Extension

extension View {

    /// Adds a form error banner above the view.
    ///
    /// - Parameters:
    ///   - formState: The form state to observe.
    ///   - style: The visual style configuration. Defaults to `.default`.
    /// - Returns: A view with form error banner applied.
    @MainActor
    public func formErrorBanner(
        _ formState: FormState,
        style: FormErrorBannerStyle = .default
    ) -> some View {
        modifier(FormErrorBannerModifier(
            formState: formState,
            style: style
        ))
    }
}
