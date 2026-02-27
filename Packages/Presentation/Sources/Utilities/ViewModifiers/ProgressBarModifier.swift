import SwiftUI

/// A view modifier that displays a progress bar below the content.
///
/// This modifier shows a progress indicator when progress is between 0 and 1,
/// useful for upload/download operations or long-running tasks.
///
/// ## Usage
/// ```swift
/// Button("Upload") {
///     // upload action
/// }
/// .progressBar(progress: viewModel.uploadProgress)
/// ```
@MainActor
public struct ProgressBarModifier: ViewModifier {

    /// The current progress value (0.0 to 1.0).
    private let progress: Double

    /// Whether to show the percentage label.
    private let showLabel: Bool

    /// Style configuration for the progress bar.
    private let style: ProgressBarStyle

    /// Creates a progress bar modifier.
    /// - Parameters:
    ///   - progress: The current progress value (0.0 to 1.0).
    ///   - showLabel: Whether to show the percentage label. Defaults to `true`.
    ///   - style: The visual style configuration. Defaults to `.default`.
    public init(
        progress: Double,
        showLabel: Bool = true,
        style: ProgressBarStyle = .default
    ) {
        self.progress = progress
        self.showLabel = showLabel
        self.style = style
    }

    public func body(content: Content) -> some View {
        VStack(spacing: style.spacing) {
            content

            if progress > 0 && progress < 1 {
                progressView
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.easeInOut(duration: style.animationDuration), value: progress)
    }

    @ViewBuilder
    private var progressView: some View {
        HStack(spacing: style.labelSpacing) {
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(style.progressColor)

            if showLabel {
                Text("\(Int(progress * 100))%")
                    .font(style.labelFont)
                    .foregroundColor(style.labelColor)
                    .frame(width: style.labelWidth, alignment: .trailing)
                    .monospacedDigit()
            }
        }
    }
}

// MARK: - Style Configuration

/// Configuration for progress bar visual appearance.
public struct ProgressBarStyle: Sendable {

    /// Spacing between content and progress bar.
    public let spacing: CGFloat

    /// Spacing between progress bar and label.
    public let labelSpacing: CGFloat

    /// Width reserved for the percentage label.
    public let labelWidth: CGFloat

    /// Font for the percentage label.
    public let labelFont: Font

    /// Color for the percentage label.
    public let labelColor: Color

    /// Color for the progress bar.
    public let progressColor: Color?

    /// Animation duration for transitions.
    public let animationDuration: Double

    /// Default progress bar style.
    public static let `default` = ProgressBarStyle(
        spacing: 8,
        labelSpacing: 12,
        labelWidth: 40,
        labelFont: .caption,
        labelColor: .secondary,
        progressColor: nil,
        animationDuration: 0.2
    )

    /// Compact style without label.
    public static let compact = ProgressBarStyle(
        spacing: 4,
        labelSpacing: 0,
        labelWidth: 0,
        labelFont: .caption2,
        labelColor: .secondary,
        progressColor: nil,
        animationDuration: 0.15
    )

    /// Themed style that uses semantic colors from the active theme.
    @MainActor
    public static let themed = ProgressBarStyle(
        spacing: 8,
        labelSpacing: 12,
        labelWidth: 40,
        labelFont: .caption,
        labelColor: Color.theme.textSecondary,
        progressColor: Color.theme.interactive,
        animationDuration: 0.2
    )

    /// Creates a custom progress bar style.
    public init(
        spacing: CGFloat,
        labelSpacing: CGFloat,
        labelWidth: CGFloat,
        labelFont: Font,
        labelColor: Color,
        progressColor: Color?,
        animationDuration: Double
    ) {
        self.spacing = spacing
        self.labelSpacing = labelSpacing
        self.labelWidth = labelWidth
        self.labelFont = labelFont
        self.labelColor = labelColor
        self.progressColor = progressColor
        self.animationDuration = animationDuration
    }
}

// MARK: - View Extension

extension View {

    /// Adds a progress bar below the view.
    ///
    /// The progress bar is only visible when progress is between 0 and 1.
    ///
    /// - Parameters:
    ///   - progress: The current progress value (0.0 to 1.0).
    ///   - showLabel: Whether to show the percentage label. Defaults to `true`.
    ///   - style: The visual style configuration. Defaults to `.default`.
    /// - Returns: A view with progress bar applied.
    @MainActor
    public func progressBar(
        progress: Double,
        showLabel: Bool = true,
        style: ProgressBarStyle = .default
    ) -> some View {
        modifier(ProgressBarModifier(
            progress: progress,
            showLabel: showLabel,
            style: style
        ))
    }
}
