import SwiftUI

/// Circular gauge that displays the assessment score as a percentage.
///
/// The gauge ring is green when the score meets or exceeds the pass threshold,
/// and red otherwise. A large percentage label sits at the center.
///
/// ## Example
/// ```swift
/// ScoreGauge(score: 85, maxScore: 100, passThreshold: 70)
/// ScoreGauge(percentage: 0.85, passed: true)
/// ```
@available(iOS 26.0, macOS 26.0, *)
@MainActor
public struct ScoreGauge: View {

    // MARK: - Properties

    private let percentage: Double
    private let passed: Bool

    // MARK: - Initialization (percentage-based)

    /// Creates a score gauge from a 0-1 percentage and pass/fail flag.
    ///
    /// - Parameters:
    ///   - percentage: Score as a fraction 0.0 to 1.0.
    ///   - passed: Whether the student passed the assessment.
    public init(percentage: Double, passed: Bool) {
        self.percentage = min(max(percentage, 0), 1)
        self.passed = passed
    }

    /// Creates a score gauge from raw score values and a pass threshold.
    ///
    /// - Parameters:
    ///   - score: Points earned.
    ///   - maxScore: Maximum possible points.
    ///   - passThreshold: Minimum percentage to pass (0-100 scale).
    public init(score: Int, maxScore: Int, passThreshold: Int) {
        let pct = maxScore > 0 ? Double(score) / Double(maxScore) : 0
        self.percentage = min(max(pct, 0), 1)
        self.passed = Int(pct * 100) >= passThreshold
    }

    // MARK: - Body

    public var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.secondary.opacity(0.15), lineWidth: 14)

            // Score ring
            Circle()
                .trim(from: 0, to: percentage)
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.8), value: percentage)

            // Center content
            VStack(spacing: 2) {
                Text("\(Int(percentage * 100))")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(ringColor)
                    .contentTransition(.numericText())

                Text("%")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(passed ? "Aprobado" : "Reprobado")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(ringColor)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Puntaje de la evaluacion")
        .accessibilityValue("\(Int(percentage * 100)) por ciento. \(passed ? "Aprobado" : "Reprobado")")
    }

    // MARK: - Computed Properties

    private var ringColor: Color {
        passed ? .green : .red
    }
}

// MARK: - Previews

#Preview("Score Gauge - Passed") {
    ScoreGauge(percentage: 0.85, passed: true)
        .frame(width: 160, height: 160)
        .padding()
}

#Preview("Score Gauge - Failed") {
    ScoreGauge(percentage: 0.45, passed: false)
        .frame(width: 160, height: 160)
        .padding()
}

#Preview("Score Gauge - From Scores") {
    HStack(spacing: DesignTokens.Spacing.xxl) {
        ScoreGauge(score: 9, maxScore: 10, passThreshold: 70)
            .frame(width: 120, height: 120)
        ScoreGauge(score: 5, maxScore: 10, passThreshold: 70)
            .frame(width: 120, height: 120)
    }
    .padding()
}

#Preview("Score Gauge - Perfect") {
    ScoreGauge(percentage: 1.0, passed: true)
        .frame(width: 160, height: 160)
        .padding()
}
