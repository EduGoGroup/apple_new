import SwiftUI
import EduDomain

/// Post-exam results screen that shows the score, statistics, and
/// per-question answer review.
///
/// ## Features
/// - ``ScoreGauge`` circular gauge showing percentage (green if passed, red otherwise)
/// - Stats row: score X/Y, correct count, time spent
/// - Scrollable list of ``AnswerReviewCard`` per question
/// - Review status badge per answer (auto_graded, pending, reviewed)
/// - Teacher feedback when available
/// - Retry button if the student can retake the assessment
///
/// ## Example
/// ```swift
/// AssessmentResultView(
///     result: attemptResult,
///     assessment: loadedAssessment,
///     onRetry: { coordinator.showAssessment(assessmentId: id, userId: userId) },
///     onDone: { coordinator.returnToDashboard() }
/// )
/// ```
@available(iOS 26.0, macOS 26.0, *)
@MainActor
public struct AssessmentResultView: View {

    // MARK: - Properties

    private let result: AttemptResult
    private let assessment: Assessment?
    private let onRetry: (() -> Void)?
    private let onDone: () -> Void

    // MARK: - Initialization

    /// Creates the result view.
    ///
    /// - Parameters:
    ///   - result: The attempt result containing score and feedback.
    ///   - assessment: The original assessment (for question text lookup).
    ///   - onRetry: Optional callback when the student wants to retake (nil if no retakes).
    ///   - onDone: Callback to return to the previous screen.
    public init(
        result: AttemptResult,
        assessment: Assessment? = nil,
        onRetry: (() -> Void)? = nil,
        onDone: @escaping () -> Void
    ) {
        self.result = result
        self.assessment = assessment
        self.onRetry = onRetry
        self.onDone = onDone
    }

    // MARK: - Body

    public var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.xxl) {
                // Score gauge
                scoreSection

                // Stats row
                statsRow

                Divider()

                // Answer review list
                if !result.feedback.isEmpty {
                    answerReviewSection
                }

                // Actions
                actionButtons
            }
            .padding(DesignTokens.Spacing.large)
        }
        .navigationTitle("Resultados")
        #if os(iOS) || os(visionOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    // MARK: - Subviews

    private var scoreSection: some View {
        VStack(spacing: DesignTokens.Spacing.medium) {
            ScoreGauge(
                score: result.score,
                maxScore: result.maxScore,
                passThreshold: assessment?.passThreshold ?? 70
            )
            .frame(width: 160, height: 160)

            Text(result.passed ? "Felicitaciones!" : "Sigue intentando")
                .font(.title2)
                .fontWeight(.bold)

            if result.passed {
                Text("Has aprobado la evaluacion.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("No alcanzaste el puntaje minimo para aprobar.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: DesignTokens.Spacing.xl) {
            statItem(
                label: "Puntaje",
                value: "\(result.score)/\(result.maxScore)",
                icon: "star.fill",
                color: result.passed ? .green : .red
            )

            statItem(
                label: "Correctas",
                value: "\(result.correctAnswers)/\(result.totalQuestions)",
                icon: "checkmark.circle.fill",
                color: .green
            )

            statItem(
                label: "Tiempo",
                value: formattedTime,
                icon: "clock.fill",
                color: .blue
            )
        }
    }

    private func statItem(label: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.headline)
                .monospacedDigit()

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var answerReviewSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            Text("Revision de respuestas")
                .font(.title3)
                .fontWeight(.semibold)

            ForEach(Array(result.feedback.enumerated()), id: \.element.questionId) { index, feedback in
                let question = questionForFeedback(feedback)
                let studentAnswer = answerTextForFeedback(feedback)
                let correctAnswer = correctAnswerTextForFeedback(feedback)

                AnswerReviewCard(
                    questionNumber: index + 1,
                    questionText: question?.text ?? "Pregunta \(index + 1)",
                    studentAnswer: studentAnswer,
                    isCorrect: feedback.isCorrect,
                    correctAnswer: feedback.isCorrect ? nil : correctAnswer,
                    explanation: feedback.explanation,
                    reviewStatus: "auto_graded"
                )
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: DesignTokens.Spacing.medium) {
            if let onRetry, result.canRetake {
                Button {
                    onRetry()
                } label: {
                    Label("Reintentar", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            Button {
                onDone()
            } label: {
                Text(result.canRetake ? "Volver" : "Finalizar")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding(.top, DesignTokens.Spacing.medium)
    }

    // MARK: - Helpers

    private var formattedTime: String {
        let minutes = result.timeSpentSeconds / 60
        let seconds = result.timeSpentSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func questionForFeedback(_ feedback: AnswerFeedback) -> AssessmentQuestion? {
        assessment?.questions.first { $0.id == feedback.questionId }
    }

    private func answerTextForFeedback(_ feedback: AnswerFeedback) -> String {
        guard let question = questionForFeedback(feedback) else {
            return "---"
        }
        // Find the option the student selected by checking the correct option
        // The feedback only has correctOptionId; the student answer is implicit
        // from whether isCorrect is true
        if feedback.isCorrect {
            return question.options.first { $0.id == feedback.correctOptionId }?.text ?? "---"
        }
        // When wrong, we don't have the student's selected option in AnswerFeedback
        // Show a generic indicator
        return "Respuesta incorrecta"
    }

    private func correctAnswerTextForFeedback(_ feedback: AnswerFeedback) -> String {
        guard let question = questionForFeedback(feedback) else {
            return "---"
        }
        return question.options.first { $0.id == feedback.correctOptionId }?.text ?? "---"
    }
}

// MARK: - Previews

#Preview("Result - Passed") {
    let feedback = [
        AnswerFeedback(questionId: UUID(), isCorrect: true, correctOptionId: UUID(), explanation: "Correcto!"),
        AnswerFeedback(questionId: UUID(), isCorrect: true, correctOptionId: UUID()),
        AnswerFeedback(questionId: UUID(), isCorrect: false, correctOptionId: UUID(), explanation: "La respuesta correcta era otra."),
        AnswerFeedback(questionId: UUID(), isCorrect: true, correctOptionId: UUID()),
        AnswerFeedback(questionId: UUID(), isCorrect: true, correctOptionId: UUID())
    ]

    let result = AttemptResult(
        attemptId: UUID(),
        assessmentId: UUID(),
        userId: UUID(),
        score: 85,
        maxScore: 100,
        passed: true,
        correctAnswers: 4,
        totalQuestions: 5,
        timeSpentSeconds: 720,
        feedback: feedback,
        startedAt: Date().addingTimeInterval(-720),
        completedAt: Date(),
        canRetake: true
    )

    NavigationStack {
        AssessmentResultView(
            result: result,
            onRetry: { },
            onDone: { }
        )
    }
}

#Preview("Result - Failed") {
    let result = AttemptResult(
        attemptId: UUID(),
        assessmentId: UUID(),
        userId: UUID(),
        score: 40,
        maxScore: 100,
        passed: false,
        correctAnswers: 2,
        totalQuestions: 5,
        timeSpentSeconds: 480,
        feedback: [],
        startedAt: Date().addingTimeInterval(-480),
        completedAt: Date(),
        canRetake: true
    )

    NavigationStack {
        AssessmentResultView(
            result: result,
            onRetry: { },
            onDone: { }
        )
    }
}

#Preview("Result - No Retake") {
    let result = AttemptResult(
        attemptId: UUID(),
        assessmentId: UUID(),
        userId: UUID(),
        score: 60,
        maxScore: 100,
        passed: false,
        correctAnswers: 3,
        totalQuestions: 5,
        timeSpentSeconds: 600,
        feedback: [],
        startedAt: Date().addingTimeInterval(-600),
        completedAt: Date(),
        canRetake: false
    )

    NavigationStack {
        AssessmentResultView(
            result: result,
            onDone: { }
        )
    }
}
