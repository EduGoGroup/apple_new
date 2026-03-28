import SwiftUI
import EduDomain

/// Main exam-taking screen that presents questions one at a time with
/// navigation controls, a timer, and a submit action.
///
/// ## Features
/// - Question-by-question navigation with Previous / Next buttons
/// - Progress bar showing current position (``QuestionProgress``)
/// - Countdown timer when the assessment is timed (``TimerBar``)
/// - Current question rendered via ``QuestionView``
/// - Submit button with a confirmation dialog
/// - Warning badge for unanswered questions before submission
///
/// ## Integration
/// This view reads assessment data and answer state from an
/// ``AssessmentViewModel`` passed by the parent. It does NOT own
/// or modify the ViewModel directly.
///
/// ## Example
/// ```swift
/// AssessmentTakeView(
///     assessment: loadedAssessment,
///     answers: viewModel.answers,
///     elapsedSeconds: viewModel.elapsedSeconds,
///     isSubmitting: viewModel.isSubmitting,
///     onSaveAnswer: { qId, optId in viewModel.saveAnswer(...) },
///     onSubmit: { await viewModel.submitAssessment() },
///     onCancel: { coordinator.goBack() }
/// )
/// ```
@available(iOS 26.0, macOS 26.0, *)
@MainActor
public struct AssessmentTakeView: View {

    // MARK: - Properties

    private let assessment: Assessment
    private let answers: [UUID: UserAnswer]
    private let elapsedSeconds: Int
    private let isSubmitting: Bool
    private let onSaveAnswer: (UUID, UUID) -> Void
    private let onSaveTextAnswer: ((UUID, String) -> Void)?
    private let onSubmit: () async -> Void
    private let onCancel: () -> Void

    // MARK: - State

    @State private var currentQuestionIndex: Int = 0
    @State private var showSubmitConfirmation: Bool = false
    @State private var showCancelConfirmation: Bool = false
    @State private var textAnswers: [UUID: String] = [:]

    // MARK: - Initialization

    /// Creates the exam-taking view.
    ///
    /// - Parameters:
    ///   - assessment: The loaded assessment with questions.
    ///   - answers: Current map of question-ID to UserAnswer.
    ///   - elapsedSeconds: Seconds elapsed since the attempt started.
    ///   - isSubmitting: Whether a submission is currently in flight.
    ///   - onSaveAnswer: Callback to persist an answer (questionId, optionId).
    ///   - onSaveTextAnswer: Callback to persist a text answer (questionId, text). Optional for backwards compatibility.
    ///   - onSubmit: Async callback to submit the assessment.
    ///   - onCancel: Callback to cancel and leave the assessment.
    public init(
        assessment: Assessment,
        answers: [UUID: UserAnswer],
        elapsedSeconds: Int,
        isSubmitting: Bool,
        onSaveAnswer: @escaping (UUID, UUID) -> Void,
        onSaveTextAnswer: ((UUID, String) -> Void)? = nil,
        onSubmit: @escaping () async -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.assessment = assessment
        self.answers = answers
        self.elapsedSeconds = elapsedSeconds
        self.isSubmitting = isSubmitting
        self.onSaveAnswer = onSaveAnswer
        self.onSaveTextAnswer = onSaveTextAnswer
        self.onSubmit = onSubmit
        self.onCancel = onCancel
        self.sortedQuestions = assessment.questions.sorted { $0.orderIndex < $1.orderIndex }
    }

    // MARK: - Precomputed

    /// Questions sorted by orderIndex, computed once at init time.
    private let sortedQuestions: [AssessmentQuestion]

    // MARK: - Computed

    private var currentQuestion: AssessmentQuestion? {
        guard sortedQuestions.indices.contains(currentQuestionIndex) else { return nil }
        return sortedQuestions[currentQuestionIndex]
    }

    private var unansweredCount: Int {
        let required = assessment.questions.filter { $0.isRequired }
        let answeredIds = Set(answers.keys)
        return required.filter { !answeredIds.contains($0.id) }.count
    }

    private var isFirstQuestion: Bool {
        currentQuestionIndex == 0
    }

    private var isLastQuestion: Bool {
        currentQuestionIndex == sortedQuestions.count - 1
    }

    private var remainingSeconds: Int {
        guard let limit = assessment.timeLimitSeconds else { return 0 }
        return max(0, limit - elapsedSeconds)
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 0) {
            // Timer (if timed)
            if assessment.timeLimitSeconds != nil {
                TimerBar(
                    remainingSeconds: remainingSeconds,
                    totalSeconds: assessment.timeLimitSeconds ?? 1
                )
            }

            // Progress
            QuestionProgress(
                current: currentQuestionIndex + 1,
                total: sortedQuestions.count
            )
            .padding(.horizontal, DesignTokens.Spacing.large)
            .padding(.top, DesignTokens.Spacing.medium)

            Divider()
                .padding(.top, DesignTokens.Spacing.small)

            // Question content
            ScrollView {
                if let question = currentQuestion {
                    questionContent(question)
                        .padding(DesignTokens.Spacing.large)
                        .id(question.id)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }

            Divider()

            // Navigation controls
            navigationBar
        }
        .navigationTitle(assessment.title)
        #if os(iOS) || os(visionOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Salir") {
                    showCancelConfirmation = true
                }
            }
        }
        .confirmationDialog(
            "Enviar evaluacion",
            isPresented: $showSubmitConfirmation,
            titleVisibility: .visible
        ) {
            Button("Enviar", role: .destructive) {
                Task { await onSubmit() }
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            if unansweredCount > 0 {
                Text("Tienes \(unansweredCount) pregunta(s) sin responder. Deseas enviar de todas formas?")
            } else {
                Text("Estas seguro de que deseas enviar la evaluacion? No podras cambiar tus respuestas.")
            }
        }
        .confirmationDialog(
            "Salir de la evaluacion",
            isPresented: $showCancelConfirmation,
            titleVisibility: .visible
        ) {
            Button("Salir", role: .destructive) {
                onCancel()
            }
            Button("Continuar", role: .cancel) { }
        } message: {
            Text("Tu progreso se guardara y podras continuar despues si tienes intentos restantes.")
        }
        .onChange(of: textAnswers) { oldValue, newValue in
            guard let onSaveTextAnswer else { return }
            for (questionId, text) in newValue where oldValue[questionId] != text {
                onSaveTextAnswer(questionId, text)
            }
        }
        .disabled(isSubmitting)
        .overlay {
            if isSubmitting {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay {
                        ProgressView("Enviando...")
                            .padding(DesignTokens.Spacing.xxl)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl))
                    }
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func questionContent(_ question: AssessmentQuestion) -> some View {
        let binding = Binding<String>(
            get: { textAnswers[question.id] ?? "" },
            set: { textAnswers[question.id] = $0 }
        )

        QuestionView(
            question: question,
            questionType: QuestionView.QuestionDisplayType(rawString: question.questionType),
            selectedOptionId: answers[question.id]?.selectedOptionId,
            textAnswer: binding,
            onOptionSelected: { optionId in
                onSaveAnswer(question.id, optionId)
            }
        )
    }

    private var navigationBar: some View {
        HStack(spacing: DesignTokens.Spacing.medium) {
            // Previous
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    currentQuestionIndex -= 1
                }
            } label: {
                Label("Anterior", systemImage: "chevron.left")
            }
            .disabled(isFirstQuestion)

            Spacer()

            // Answered indicator
            answeredIndicator

            Spacer()

            if isLastQuestion {
                // Submit
                Button {
                    showSubmitConfirmation = true
                } label: {
                    Label("Enviar", systemImage: "paperplane.fill")
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSubmitting)
            } else {
                // Next
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        currentQuestionIndex += 1
                    }
                } label: {
                    Label("Siguiente", systemImage: "chevron.right")
                }
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.large)
        .padding(.vertical, DesignTokens.Spacing.medium)
    }

    private var answeredIndicator: some View {
        let answered = answers.count
        let total = assessment.questions.count
        return Text("\(answered)/\(total)")
            .font(.caption)
            .foregroundStyle(answered == total ? .green : .secondary)
            .monospacedDigit()
            .accessibilityLabel("\(answered) de \(total) respondidas")
    }

}

// MARK: - Previews

#Preview("Assessment Take") {
    let options = (0..<4).map { i in
        QuestionOption(id: UUID(), text: "Opcion \(i + 1)", orderIndex: i)
    }
    let questions = (0..<5).map { i in
        AssessmentQuestion(
            id: UUID(),
            text: "Pregunta de ejemplo numero \(i + 1)?",
            options: options,
            isRequired: true,
            orderIndex: i
        )
    }
    let assessment = Assessment(
        id: UUID(),
        materialId: UUID(),
        title: "Evaluacion de Prueba",
        description: "Esta es una evaluacion de prueba",
        questions: questions,
        timeLimitSeconds: 1800,
        maxAttempts: 3,
        passThreshold: 70
    )

    NavigationStack {
        AssessmentTakeView(
            assessment: assessment,
            answers: [:],
            elapsedSeconds: 300,
            isSubmitting: false,
            onSaveAnswer: { _, _ in },
            onSubmit: { },
            onCancel: { }
        )
    }
}
