import SwiftUI

/// Countdown timer bar that displays remaining time and changes color when
/// time is running low.
///
/// The bar transitions to red when fewer than 60 seconds remain. It shows
/// time in `MM:SS` format and includes a linear progress indicator.
///
/// ## Example
/// ```swift
/// TimerBar(
///     remainingSeconds: viewModel.remainingSeconds,
///     totalSeconds: assessment.timeLimitSeconds ?? 0
/// )
/// ```
@available(iOS 26.0, macOS 26.0, *)
@MainActor
public struct TimerBar: View {

    // MARK: - Properties

    private let remainingSeconds: Int
    private let totalSeconds: Int

    /// Threshold in seconds below which the bar turns red.
    private let warningThreshold: Int = 60

    // MARK: - Initialization

    /// Creates a countdown timer bar.
    ///
    /// - Parameters:
    ///   - remainingSeconds: Current remaining time in seconds.
    ///   - totalSeconds: Total allowed time in seconds (for progress calculation).
    public init(remainingSeconds: Int, totalSeconds: Int) {
        self.remainingSeconds = max(0, remainingSeconds)
        self.totalSeconds = max(1, totalSeconds)
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            HStack {
                Image(systemName: isWarning ? "exclamationmark.clock" : "clock")
                    .foregroundStyle(tintColor)
                    .font(.caption)

                Text(formattedTime)
                    .font(.system(.caption, design: .monospaced, weight: .semibold))
                    .foregroundStyle(tintColor)
                    .monospacedDigit()
                    .contentTransition(.numericText())

                Spacer()

                if isWarning {
                    Text("Tiempo limitado")
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .fontWeight(.medium)
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.secondary.opacity(0.15))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(tintColor)
                        .frame(width: geometry.size.width * progress)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, DesignTokens.Spacing.large)
        .padding(.vertical, DesignTokens.Spacing.small)
        .background(isWarning ? Color.red.opacity(0.06) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tiempo restante")
        .accessibilityValue(formattedTime)
        .accessibilityAddTraits(.updatesFrequently)
    }

    // MARK: - Computed Properties

    private var isWarning: Bool {
        remainingSeconds < warningThreshold && remainingSeconds > 0
    }

    private var tintColor: Color {
        if remainingSeconds <= 0 {
            return .red
        } else if isWarning {
            return .red
        } else {
            return .accentColor
        }
    }

    private var progress: Double {
        Double(remainingSeconds) / Double(totalSeconds)
    }

    private var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Previews

#Preview("Timer - Plenty of Time") {
    TimerBar(remainingSeconds: 1200, totalSeconds: 1800)
        .padding()
}

#Preview("Timer - Warning") {
    TimerBar(remainingSeconds: 45, totalSeconds: 1800)
        .padding()
}

#Preview("Timer - Expired") {
    TimerBar(remainingSeconds: 0, totalSeconds: 1800)
        .padding()
}

#Preview("Timer States") {
    VStack(spacing: DesignTokens.Spacing.large) {
        TimerBar(remainingSeconds: 900, totalSeconds: 1800)
        TimerBar(remainingSeconds: 120, totalSeconds: 1800)
        TimerBar(remainingSeconds: 30, totalSeconds: 1800)
        TimerBar(remainingSeconds: 0, totalSeconds: 1800)
    }
    .padding()
}
