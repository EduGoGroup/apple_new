import SwiftUI

/// A view modifier that provides visual feedback for validation states.
///
/// This modifier adds validation indicators (icons, borders, and error messages)
/// to any view, integrating with `BindableProperty.ValidationState`.
///
/// ## Usage
/// ```swift
/// TextField("Email", text: $viewModel.email)
///     .validated(viewModel.$email.validationState)
/// ```
public struct ValidationFieldModifier: ViewModifier {

    /// The validation state to observe.
    private let validationState: BindableProperty<String>.ValidationState

    /// Whether to show validation feedback.
    private let showValidation: Bool

    /// Style configuration for the validation display.
    private let style: ValidationFieldStyle

    /// Creates a validation field modifier.
    /// - Parameters:
    ///   - validationState: The validation state to observe.
    ///   - showValidation: Whether to show validation feedback. Defaults to `true`.
    ///   - style: The visual style configuration. Defaults to `.default`.
    public init(
        validationState: BindableProperty<String>.ValidationState,
        showValidation: Bool = true,
        style: ValidationFieldStyle = .default
    ) {
        self.validationState = validationState
        self.showValidation = showValidation
        self.style = style
    }

    public func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: style.errorSpacing) {
            content
                .overlay(alignment: .trailing) {
                    if showValidation && style.showIcon {
                        validationIcon
                            .padding(.trailing, style.iconPadding)
                    }
                }
                .overlay {
                    if showValidation && !validationState.isValid {
                        RoundedRectangle(cornerRadius: style.borderRadius)
                            .stroke(style.errorColor, lineWidth: style.borderWidth)
                    }
                }

            if showValidation, let errorMessage = validationState.errorMessage {
                Text(errorMessage)
                    .font(style.errorFont)
                    .foregroundColor(style.errorColor)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: style.animationDuration), value: validationState.isValid)
        .animation(.easeInOut(duration: style.animationDuration), value: validationState.errorMessage)
    }

    @ViewBuilder
    private var validationIcon: some View {
        Image(systemName: validationState.isValid ? style.validIconName : style.invalidIconName)
            .foregroundColor(validationState.isValid ? style.validColor : style.errorColor)
            .font(style.iconFont)
    }
}

// MARK: - Style Configuration

/// Configuration for validation field visual appearance.
public struct ValidationFieldStyle: Sendable {

    /// Whether to show the validation icon.
    public let showIcon: Bool

    /// Icon name for valid state.
    public let validIconName: String

    /// Icon name for invalid state.
    public let invalidIconName: String

    /// Color for valid state.
    public let validColor: Color

    /// Color for error state.
    public let errorColor: Color

    /// Border width for error state.
    public let borderWidth: CGFloat

    /// Border corner radius.
    public let borderRadius: CGFloat

    /// Padding for the trailing icon.
    public let iconPadding: CGFloat

    /// Font for the validation icon.
    public let iconFont: Font

    /// Font for error messages.
    public let errorFont: Font

    /// Spacing between field and error message.
    public let errorSpacing: CGFloat

    /// Duration for validation animations.
    public let animationDuration: Double

    /// Default validation field style.
    public static let `default` = ValidationFieldStyle(
        showIcon: true,
        validIconName: "checkmark.circle.fill",
        invalidIconName: "xmark.circle.fill",
        validColor: .green,
        errorColor: .red,
        borderWidth: 1,
        borderRadius: 8,
        iconPadding: 8,
        iconFont: .body,
        errorFont: .caption,
        errorSpacing: 4,
        animationDuration: 0.2
    )

    /// Minimal style without icons.
    public static let minimal = ValidationFieldStyle(
        showIcon: false,
        validIconName: "",
        invalidIconName: "",
        validColor: .green,
        errorColor: .red,
        borderWidth: 2,
        borderRadius: 8,
        iconPadding: 0,
        iconFont: .body,
        errorFont: .caption,
        errorSpacing: 4,
        animationDuration: 0.2
    )

    /// Themed style that uses semantic colors from the active theme.
    @MainActor
    public static let themed = ValidationFieldStyle(
        showIcon: true,
        validIconName: "checkmark.circle.fill",
        invalidIconName: "xmark.circle.fill",
        validColor: .green,
        errorColor: .red,
        borderWidth: 1,
        borderRadius: 8,
        iconPadding: 8,
        iconFont: .body,
        errorFont: .caption,
        errorSpacing: 4,
        animationDuration: 0.2
    )

    /// Creates a custom validation field style.
    public init(
        showIcon: Bool,
        validIconName: String,
        invalidIconName: String,
        validColor: Color,
        errorColor: Color,
        borderWidth: CGFloat,
        borderRadius: CGFloat,
        iconPadding: CGFloat,
        iconFont: Font,
        errorFont: Font,
        errorSpacing: CGFloat,
        animationDuration: Double
    ) {
        self.showIcon = showIcon
        self.validIconName = validIconName
        self.invalidIconName = invalidIconName
        self.validColor = validColor
        self.errorColor = errorColor
        self.borderWidth = borderWidth
        self.borderRadius = borderRadius
        self.iconPadding = iconPadding
        self.iconFont = iconFont
        self.errorFont = errorFont
        self.errorSpacing = errorSpacing
        self.animationDuration = animationDuration
    }
}

// MARK: - View Extension

extension View {

    /// Adds validation visual feedback to a view.
    ///
    /// - Parameters:
    ///   - validationState: The validation state to observe.
    ///   - showValidation: Whether to show validation feedback. Defaults to `true`.
    ///   - style: The visual style configuration. Defaults to `.default`.
    /// - Returns: A view with validation feedback applied.
    @MainActor
    public func validated(
        _ validationState: BindableProperty<String>.ValidationState,
        showValidation: Bool = true,
        style: ValidationFieldStyle = .default
    ) -> some View {
        modifier(ValidationFieldModifier(
            validationState: validationState,
            showValidation: showValidation,
            style: style
        ))
    }
}
