import SwiftUI

/// A view modifier that applies a shake animation effect.
///
/// This modifier is useful for indicating validation errors or invalid input
/// by shaking the view horizontally.
///
/// ## Usage
/// ```swift
/// TextField("Email", text: $email)
///     .shakeOnError(trigger: validationFailed)
/// ```
@MainActor
public struct ShakeEffectModifier: ViewModifier {

    /// Whether to trigger the shake animation.
    private let trigger: Bool

    /// Style configuration for the shake effect.
    private let style: ShakeEffectStyle

    /// Internal state for animation.
    @State private var shakeOffset: CGFloat = 0

    /// Creates a shake effect modifier.
    /// - Parameters:
    ///   - trigger: Whether to trigger the shake animation.
    ///   - style: The visual style configuration. Defaults to `.default`.
    public init(
        trigger: Bool,
        style: ShakeEffectStyle = .default
    ) {
        self.trigger = trigger
        self.style = style
    }

    public func body(content: Content) -> some View {
        content
            .offset(x: shakeOffset)
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    performShake()
                }
            }
    }

    private func performShake() {
        let animation = Animation
            .linear(duration: style.shakeDuration / Double(style.shakeCount * 2))

        Task { @MainActor in
            for _ in 0..<style.shakeCount {
                withAnimation(animation) {
                    shakeOffset = style.shakeAmplitude
                }
                try? await Task.sleep(for: .milliseconds(Int(style.shakeDuration / Double(style.shakeCount * 2) * 1000)))

                withAnimation(animation) {
                    shakeOffset = -style.shakeAmplitude
                }
                try? await Task.sleep(for: .milliseconds(Int(style.shakeDuration / Double(style.shakeCount * 2) * 1000)))
            }

            withAnimation(animation) {
                shakeOffset = 0
            }
        }
    }
}

// MARK: - Style Configuration

/// Configuration for shake effect visual appearance.
public struct ShakeEffectStyle: Sendable {

    /// Number of shake cycles.
    public let shakeCount: Int

    /// Maximum horizontal displacement.
    public let shakeAmplitude: CGFloat

    /// Total duration of the shake animation.
    public let shakeDuration: Double

    /// Default shake effect style.
    public static let `default` = ShakeEffectStyle(
        shakeCount: 3,
        shakeAmplitude: 10,
        shakeDuration: 0.4
    )

    /// Subtle shake for minor errors.
    public static let subtle = ShakeEffectStyle(
        shakeCount: 2,
        shakeAmplitude: 5,
        shakeDuration: 0.25
    )

    /// Intense shake for critical errors.
    public static let intense = ShakeEffectStyle(
        shakeCount: 5,
        shakeAmplitude: 15,
        shakeDuration: 0.5
    )

    /// Creates a custom shake effect style.
    public init(
        shakeCount: Int,
        shakeAmplitude: CGFloat,
        shakeDuration: Double
    ) {
        self.shakeCount = shakeCount
        self.shakeAmplitude = shakeAmplitude
        self.shakeDuration = shakeDuration
    }
}

// MARK: - View Extension

extension View {

    /// Applies a shake animation when triggered.
    ///
    /// - Parameters:
    ///   - trigger: Whether to trigger the shake animation.
    ///   - style: The visual style configuration. Defaults to `.default`.
    /// - Returns: A view with shake effect applied.
    @MainActor
    public func shakeOnError(
        trigger: Bool,
        style: ShakeEffectStyle = .default
    ) -> some View {
        modifier(ShakeEffectModifier(
            trigger: trigger,
            style: style
        ))
    }
}
