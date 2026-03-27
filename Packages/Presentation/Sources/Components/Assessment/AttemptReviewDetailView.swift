import SwiftUI
import EduCore

/// Vista de detalle para revisar un intento individual de un estudiante.
///
/// Muestra las respuestas del estudiante, permite calificar respuestas
/// pendientes y finalizar la revision del intento.
///
/// ## Funcionalidad
/// - Header con nombre del estudiante y puntaje actual
/// - Lista de respuestas auto-calificadas (solo lectura)
/// - Respuestas pendientes editables (puntos + feedback)
/// - Boton "Finalizar Revision" al final
///
/// ## Ejemplo de uso
/// ```swift
/// AttemptReviewDetailView(
///     viewModel: reviewViewModel,
///     attemptId: attempt.attemptId,
///     onFinalized: { dismiss() }
/// )
/// ```
@available(iOS 26.0, macOS 26.0, *)
@MainActor
public struct AttemptReviewDetailView: View {

    // MARK: - Properties

    @Bindable private var viewModel: AssessmentReviewViewModel
    private let attemptId: String
    private let onFinalized: () -> Void

    // MARK: - State

    @State private var showFinalizeConfirmation: Bool = false

    // MARK: - Initialization

    /// Crea la vista de detalle de revision de intento.
    ///
    /// - Parameters:
    ///   - viewModel: ViewModel de revision de assessments.
    ///   - attemptId: ID del intento a revisar.
    ///   - onFinalized: Callback al finalizar la revision.
    public init(
        viewModel: AssessmentReviewViewModel,
        attemptId: String,
        onFinalized: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.attemptId = attemptId
        self.onFinalized = onFinalized
    }

    // MARK: - Body

    public var body: some View {
        Group {
            if let attempt = viewModel.selectedAttempt {
                attemptContent(attempt)
            } else if viewModel.isLoading {
                ProgressView("Cargando revision...")
            } else {
                ContentUnavailableView(
                    "No se pudo cargar",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Intenta de nuevo mas tarde")
                )
            }
        }
        .task {
            await viewModel.loadAttemptForReview(attemptId: attemptId)
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.hasError },
            set: { if !$0 { viewModel.clearError() } }
        )) {
            Button("Aceptar", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Error desconocido")
        }
        .confirmationDialog(
            "Finalizar Revision",
            isPresented: $showFinalizeConfirmation,
            titleVisibility: .visible
        ) {
            Button("Finalizar", role: .destructive) {
                Task {
                    await viewModel.finalizeAttempt(attemptId: attemptId)
                    if !viewModel.hasError {
                        onFinalized()
                    }
                }
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("Una vez finalizada, el puntaje sera definitivo y visible para el estudiante.")
        }
    }

    // MARK: - Subviews

    private func attemptContent(_ attempt: AttemptReviewDetailDTO) -> some View {
        List {
            headerSection(attempt)

            ForEach(attempt.answers) { answer in
                answerSection(answer)
            }

            finalizeSection
        }
        .navigationTitle("Revision")
    }

    private func headerSection(_ attempt: AttemptReviewDetailDTO) -> some View {
        Section {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                HStack {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text(attempt.studentName)
                            .font(.title3.bold())

                        Text(attempt.studentEmail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: DesignTokens.Spacing.xs) {
                        Text(String(format: "%.1f / %.1f", attempt.currentScore, attempt.maxScore))
                            .font(.title2.bold())
                            .foregroundStyle(.primary)

                        Text("Puntaje actual")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                attemptStatusBadge(attempt.status)
            }
        }
    }

    private func attemptStatusBadge(_ status: String) -> some View {
        let displayName: String
        let color: Color

        switch status {
        case "pending_review":
            displayName = "Pendiente de revision"
            color = .orange
        case "completed":
            displayName = "Completado"
            color = .green
        case "in_progress":
            displayName = "En progreso"
            color = .blue
        default:
            displayName = status.capitalized
            color = .secondary
        }

        return Text(displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, DesignTokens.Spacing.small)
            .padding(.vertical, DesignTokens.Spacing.xs)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    @ViewBuilder
    private func answerSection(_ answer: AnswerForReviewDTO) -> some View {
        Section {
            switch answer.reviewStatus {
            case "auto_graded", "reviewed":
                ReadOnlyAnswerCard(answer: answer)
            default:
                EditableAnswerCard(
                    answer: answer,
                    attemptId: attemptId,
                    viewModel: viewModel
                )
            }
        } header: {
            Text("Pregunta \(answer.questionIndex + 1)")
        }
    }

    private var finalizeSection: some View {
        Section {
            Button {
                showFinalizeConfirmation = true
            } label: {
                HStack {
                    Spacer()
                    if viewModel.isFinalizing {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text("Finalizar Revision")
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.selectedAttemptHasPendingAnswers || viewModel.isFinalizing)
            .listRowInsets(EdgeInsets(
                top: DesignTokens.Spacing.medium,
                leading: DesignTokens.Spacing.large,
                bottom: DesignTokens.Spacing.medium,
                trailing: DesignTokens.Spacing.large
            ))

            if viewModel.selectedAttemptHasPendingAnswers {
                Text("Revisa todas las respuestas pendientes antes de finalizar")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}

// MARK: - Read-Only Answer Card

@available(iOS 26.0, macOS 26.0, *)
@MainActor
private struct ReadOnlyAnswerCard: View {
    let answer: AnswerForReviewDTO

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            // Question text
            Text(answer.questionText)
                .font(.subheadline.weight(.medium))

            // Student answer
            if let studentAnswer = answer.studentAnswer {
                HStack(alignment: .top, spacing: DesignTokens.Spacing.small) {
                    Image(systemName: correctnessIcon)
                        .foregroundStyle(correctnessColor)

                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text("Respuesta del estudiante")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(studentAnswer)
                            .font(.body)
                    }
                }
            }

            // Correct answer (if different)
            if let correctAnswer = answer.correctAnswer, correctAnswer != answer.studentAnswer {
                HStack(alignment: .top, spacing: DesignTokens.Spacing.small) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)

                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text("Respuesta correcta")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(correctAnswer)
                            .font(.body)
                    }
                }
            }

            // Points
            HStack {
                Spacer()
                Text(String(format: "%.1f / %.1f pts", answer.pointsEarned ?? 0, answer.maxPoints))
                    .font(.callout.bold())
                    .foregroundStyle(pointsColor)
            }

            // Feedback
            if let feedback = answer.reviewFeedback, !feedback.isEmpty {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("Feedback")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(feedback)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .padding(DesignTokens.Spacing.small)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
            }
        }
    }

    private var correctnessIcon: String {
        if let isCorrect = answer.isCorrect {
            return isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill"
        }
        return "questionmark.circle"
    }

    private var correctnessColor: Color {
        if let isCorrect = answer.isCorrect {
            return isCorrect ? .green : .red
        }
        return .secondary
    }

    private var pointsColor: Color {
        guard let earned = answer.pointsEarned else { return .secondary }
        if earned >= answer.maxPoints { return .green }
        if earned > 0 { return .orange }
        return .red
    }
}

// MARK: - Editable Answer Card

@available(iOS 26.0, macOS 26.0, *)
@MainActor
private struct EditableAnswerCard: View {
    let answer: AnswerForReviewDTO
    let attemptId: String
    @Bindable var viewModel: AssessmentReviewViewModel

    @State private var pointsAwarded: Double = 0
    @State private var feedback: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            // Question text
            Text(answer.questionText)
                .font(.subheadline.weight(.medium))

            // Question type badge
            Text(questionTypeDisplayName)
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, DesignTokens.Spacing.small)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.15))
                .foregroundStyle(.blue)
                .clipShape(Capsule())

            // Student answer
            if let studentAnswer = answer.studentAnswer {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("Respuesta del estudiante")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(studentAnswer)
                        .font(.body)
                        .padding(DesignTokens.Spacing.small)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
                }
            } else {
                Text("Sin respuesta")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .italic()
            }

            // Correct answer hint
            if let correctAnswer = answer.correctAnswer {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("Respuesta esperada")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(correctAnswer)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // Points stepper
            HStack {
                Text("Puntos:")
                    .font(.subheadline)

                Spacer()

                Text(String(format: "%.1f / %.1f", pointsAwarded, answer.maxPoints))
                    .font(.subheadline.bold())
                    .foregroundStyle(pointsColor)

                Stepper(
                    "",
                    value: $pointsAwarded,
                    in: 0...answer.maxPoints,
                    step: 0.5
                )
                .labelsHidden()
                .fixedSize()
            }

            // Feedback text editor
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text("Feedback")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $feedback)
                    .frame(minHeight: 60)
                    .scrollContentBackground(.hidden)
                    .padding(DesignTokens.Spacing.small)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
            }

            // Save button
            Button {
                Task {
                    await viewModel.reviewAnswer(
                        attemptId: attemptId,
                        answerId: answer.answerId,
                        points: pointsAwarded,
                        feedback: feedback
                    )
                }
            } label: {
                HStack {
                    if viewModel.isSavingReview {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text("Guardar Calificacion")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isSavingReview)
        }
        .onAppear {
            pointsAwarded = answer.pointsEarned ?? 0
            feedback = answer.reviewFeedback ?? ""
        }
    }

    private var questionTypeDisplayName: String {
        switch answer.questionType {
        case "multiple_choice": return "Opcion Multiple"
        case "open_ended": return "Respuesta Abierta"
        case "true_false": return "Verdadero/Falso"
        case "short_answer": return "Respuesta Corta"
        default: return answer.questionType.capitalized
        }
    }

    private var pointsColor: Color {
        if pointsAwarded >= answer.maxPoints { return .green }
        if pointsAwarded > 0 { return .orange }
        return .red
    }
}
