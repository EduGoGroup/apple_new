import SwiftUI

/// Card that displays a single answer's review information after an
/// assessment is completed.
///
/// Shows the question text, the student's answer, whether it was correct,
/// a review status badge, and optional teacher feedback.
///
/// ## Example
/// ```swift
/// AnswerReviewCard(
///     questionText: "What is the capital of France?",
///     studentAnswer: "Paris",
///     isCorrect: true,
///     correctAnswer: "Paris",
///     explanation: "Paris is the capital of France.",
///     reviewStatus: "auto_graded"
/// )
/// ```
@available(iOS 26.0, macOS 26.0, *)
@MainActor
public struct AnswerReviewCard: View {

    // MARK: - Properties

    private let questionNumber: Int
    private let questionText: String
    private let studentAnswer: String
    private let isCorrect: Bool
    private let correctAnswer: String?
    private let explanation: String?
    private let reviewStatus: String
    private let teacherFeedback: String?

    // MARK: - Initialization

    /// Creates an answer review card.
    ///
    /// - Parameters:
    ///   - questionNumber: The 1-based question number.
    ///   - questionText: The question prompt.
    ///   - studentAnswer: The answer the student provided.
    ///   - isCorrect: Whether the answer was correct.
    ///   - correctAnswer: The correct answer (shown when wrong).
    ///   - explanation: Automated explanation of the correct answer.
    ///   - reviewStatus: One of `auto_graded`, `pending`, `reviewed`.
    ///   - teacherFeedback: Optional feedback written by the teacher.
    public init(
        questionNumber: Int,
        questionText: String,
        studentAnswer: String,
        isCorrect: Bool,
        correctAnswer: String? = nil,
        explanation: String? = nil,
        reviewStatus: String = "auto_graded",
        teacherFeedback: String? = nil
    ) {
        self.questionNumber = questionNumber
        self.questionText = questionText
        self.studentAnswer = studentAnswer
        self.isCorrect = isCorrect
        self.correctAnswer = correctAnswer
        self.explanation = explanation
        self.reviewStatus = reviewStatus
        self.teacherFeedback = teacherFeedback
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            // Header with question number, correctness icon, and status badge
            header

            // Question text
            Text(questionText)
                .font(.body)
                .foregroundStyle(.primary)

            // Student's answer
            answerSection

            // Correct answer if wrong
            if !isCorrect, let correctAnswer {
                correctAnswerSection(correctAnswer)
            }

            // Explanation
            if let explanation, !explanation.isEmpty {
                explanationSection(explanation)
            }

            // Teacher feedback
            if let teacherFeedback, !teacherFeedback.isEmpty {
                teacherFeedbackSection(teacherFeedback)
            }
        }
        .padding(DesignTokens.Insets.cardDefault)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl)
                .stroke(borderColor, lineWidth: DesignTokens.BorderWidth.thin)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Pregunta \(questionNumber), \(accessibleReviewStatus), \(isCorrect ? "correcta" : "incorrecta")")
    }

    // MARK: - Subviews

    private var header: some View {
        HStack {
            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(isCorrect ? .green : .red)
                .font(.title3)

            Text("Pregunta \(questionNumber)")
                .font(.headline)

            Spacer()

            StatusBadge.fromReviewStatus(reviewStatus)
        }
    }

    private var answerSection: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.small) {
            Text("Tu respuesta:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(studentAnswer)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(isCorrect ? .green : .red)
        }
    }

    private func correctAnswerSection(_ answer: String) -> some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.small) {
            Text("Correcta:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(answer)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.green)
        }
    }

    private func explanationSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Label("Explicacion", systemImage: "lightbulb")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(DesignTokens.Spacing.small)
        .background(Color.accentColor.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
    }

    private func teacherFeedbackSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Label("Feedback del profesor", systemImage: "person.bubble")
                .font(.caption)
                .foregroundStyle(.blue)

            Text(text)
                .font(.caption)
                .foregroundStyle(.primary)
        }
        .padding(DesignTokens.Spacing.small)
        .background(Color.blue.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
    }

    // MARK: - Styling

    private var borderColor: Color {
        isCorrect ? Color.green.opacity(0.2) : Color.red.opacity(0.2)
    }

    private var accessibleReviewStatus: String {
        switch reviewStatus {
        case "auto_graded": return "calificacion automatica"
        case "pending": return "pendiente de revision"
        case "reviewed": return "revisada por profesor"
        default: return reviewStatus
        }
    }
}

// MARK: - Previews

#Preview("Correct Answer") {
    AnswerReviewCard(
        questionNumber: 1,
        questionText: "Cual es la capital de Francia?",
        studentAnswer: "Paris",
        isCorrect: true,
        explanation: "Paris es la capital y ciudad mas grande de Francia."
    )
    .padding()
}

#Preview("Wrong Answer") {
    AnswerReviewCard(
        questionNumber: 2,
        questionText: "Cual es el rio mas largo del mundo?",
        studentAnswer: "Mississippi",
        isCorrect: false,
        correctAnswer: "Nilo",
        explanation: "El rio Nilo tiene aproximadamente 6,650 km de largo.",
        reviewStatus: "auto_graded"
    )
    .padding()
}

#Preview("With Teacher Feedback") {
    AnswerReviewCard(
        questionNumber: 3,
        questionText: "Explica el ciclo del agua.",
        studentAnswer: "El agua se evapora, forma nubes y llueve.",
        isCorrect: false,
        correctAnswer: nil,
        explanation: nil,
        reviewStatus: "reviewed",
        teacherFeedback: "Buen intento, pero falta mencionar la condensacion y la escorrentia."
    )
    .padding()
}
