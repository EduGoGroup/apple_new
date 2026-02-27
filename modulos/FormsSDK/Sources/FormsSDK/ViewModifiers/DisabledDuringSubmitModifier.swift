import SwiftUI

/// A view modifier that disables a view during form submission.
///
/// This modifier automatically disables the content and reduces its opacity
/// when the form is submitting, providing visual feedback that the action
/// is in progress.
///
/// ## Usage
/// ```swift
/// Button("Submit") {
///     // submit action
/// }
/// .disabledDuringSubmit(viewModel.formState)
/// ```
public struct DisabledDuringSubmitModifier: ViewModifier {

    /// The form state to observe.
    private let formState: FormState

    /// Style configuration for the disabled state.
    private let style: DisabledDuringSubmitStyle

    /// Creates a disabled during submit modifier.
    /// - Parameters:
    ///   - formState: The form state to observe.
    ///   - style: The visual style configuration. Defaults to `.default`.
    public init(
        formState: FormState,
        style: DisabledDuringSubmitStyle = .default
    ) {
        self.formState = formState
        self.style = style
    }

    public func body(content: Content) -> some View {
        content
            .disabled(formState.isSubmitting)
            .opacity(formState.isSubmitting ? style.disabledOpacity : 1.0)
            .animation(.easeInOut(duration: style.animationDuration), value: formState.isSubmitting)
    }
}

// MARK: - Style Configuration

/// Configuration for disabled during submit visual appearance.
public struct DisabledDuringSubmitStyle: Sendable {

    /// Opacity when disabled.
    public let disabledOpacity: Double

    /// Animation duration for opacity transition.
    public let animationDuration: Double

    /// Default style.
    public static let `default` = DisabledDuringSubmitStyle(
        disabledOpacity: 0.6,
        animationDuration: 0.2
    )

    /// Subtle style with less opacity change.
    public static let subtle = DisabledDuringSubmitStyle(
        disabledOpacity: 0.8,
        animationDuration: 0.15
    )

    /// Creates a custom disabled during submit style.
    public init(
        disabledOpacity: Double,
        animationDuration: Double
    ) {
        self.disabledOpacity = disabledOpacity
        self.animationDuration = animationDuration
    }
}

// MARK: - View Extension

extension View {

    /// Disables the view during form submission.
    ///
    /// - Parameters:
    ///   - formState: The form state to observe.
    ///   - style: The visual style configuration. Defaults to `.default`.
    /// - Returns: A view that is disabled during form submission.
    @MainActor
    public func disabledDuringSubmit(
        _ formState: FormState,
        style: DisabledDuringSubmitStyle = .default
    ) -> some View {
        modifier(DisabledDuringSubmitModifier(
            formState: formState,
            style: style
        ))
    }
}
