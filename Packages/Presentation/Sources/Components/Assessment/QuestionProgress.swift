import SwiftUI

/// Displays "Question X of Y" text alongside a linear progress bar.
///
/// Tracks the student's position within the assessment and provides
/// both visual and textual feedback about their progress.
///
/// ## Example
/// ```swift
/// QuestionProgress(current: 3, total: 10)
/// ```
@available(iOS 26.0, macOS 26.0, *)
@MainActor
public struct QuestionProgress: View {

    // MARK: - Properties

    private let current: Int
    private let total: Int

    // MARK: - Initialization

    /// Creates a question progress indicator.
    ///
    /// - Parameters:
    ///   - current: The 1-based index of the current question.
    ///   - total: The total number of questions in the assessment.
    public init(current: Int, total: Int) {
        self.current = max(1, current)
        self.total = max(1, total)
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            HStack {
                Text("Pregunta \(current) de \(total)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            EduProgressBar(
                mode: .determinate(progress),
                style: .rounded,
                tint: .accentColor
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progreso de la evaluacion")
        .accessibilityValue("Pregunta \(current) de \(total)")
    }

    // MARK: - Computed Properties

    private var progress: Double {
        Double(current) / Double(total)
    }
}

// MARK: - Previews

#Preview("Question Progress") {
    VStack(spacing: DesignTokens.Spacing.large) {
        QuestionProgress(current: 1, total: 10)
        QuestionProgress(current: 5, total: 10)
        QuestionProgress(current: 10, total: 10)
    }
    .padding()
}
