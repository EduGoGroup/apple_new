import SwiftUI
import EduDomain

/// Renders a single assessment question based on its type.
///
/// Adapts the input control depending on the question type:
/// - **multiple_choice / single_choice**: List of ``OptionCard`` views with radio selection.
/// - **true_false**: Two large Verdadero / Falso buttons.
/// - **short_answer**: Single-line `TextField`.
/// - **open_ended**: Multiline `TextEditor` with minimum height.
///
/// This view does not own the answer state; it communicates changes via
/// the `onOptionSelected` and `onTextChanged` callbacks so the parent
/// can persist the answer through the ViewModel.
///
/// ## Example
/// ```swift
/// QuestionView(
///     question: question,
///     questionType: .multipleChoice,
///     selectedOptionId: answers[question.id]?.selectedOptionId,
///     textAnswer: $textAnswers[question.id],
///     onOptionSelected: { optionId in
///         viewModel.saveAnswer(questionId: question.id, selectedOptionId: optionId)
///     }
/// )
/// ```
@available(iOS 26.0, macOS 26.0, *)
@MainActor
public struct QuestionView: View {

    // MARK: - Types

    /// Supported question types matching the backend enum values.
    public enum QuestionDisplayType: String, Sendable {
        case multipleChoice = "multiple_choice"
        case singleChoice = "single_choice"
        case trueFalse = "true_false"
        case shortAnswer = "short_answer"
        case openEnded = "open_ended"

        /// Creates a display type from a string, defaulting to singleChoice.
        public init(rawString: String) {
            self = QuestionDisplayType(rawValue: rawString) ?? .singleChoice
        }
    }

    // MARK: - Properties

    private let question: AssessmentQuestion
    private let questionType: QuestionDisplayType
    private let selectedOptionId: UUID?
    @Binding private var textAnswer: String
    private let onOptionSelected: (UUID) -> Void

    // MARK: - Initialization

    /// Creates a question view.
    ///
    /// - Parameters:
    ///   - question: The assessment question to render.
    ///   - questionType: The type of question (determines the input control).
    ///   - selectedOptionId: Currently selected option ID (for MC / TF).
    ///   - textAnswer: Binding to the text answer (for short_answer / open_ended).
    ///   - onOptionSelected: Callback when an option is tapped.
    public init(
        question: AssessmentQuestion,
        questionType: QuestionDisplayType,
        selectedOptionId: UUID?,
        textAnswer: Binding<String>,
        onOptionSelected: @escaping (UUID) -> Void
    ) {
        self.question = question
        self.questionType = questionType
        self.selectedOptionId = selectedOptionId
        self._textAnswer = textAnswer
        self.onOptionSelected = onOptionSelected
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.large) {
            questionHeader

            switch questionType {
            case .multipleChoice, .singleChoice:
                multipleChoiceContent
            case .trueFalse:
                trueFalseContent
            case .shortAnswer:
                shortAnswerContent
            case .openEnded:
                openEndedContent
            }
        }
    }

    // MARK: - Subviews

    private var questionHeader: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            Text(question.text)
                .font(.title3)
                .fontWeight(.semibold)
                .fixedSize(horizontal: false, vertical: true)

            if question.isRequired {
                Text("Obligatoria")
                    .font(.caption2)
                    .foregroundStyle(.red)
                    .fontWeight(.medium)
            }
        }
    }

    private var multipleChoiceContent: some View {
        VStack(spacing: DesignTokens.Spacing.small) {
            ForEach(question.options.sorted(by: { $0.orderIndex < $1.orderIndex })) { option in
                OptionCard(
                    text: option.text,
                    isSelected: selectedOptionId == option.id,
                    onTap: { onOptionSelected(option.id) }
                )
            }
        }
    }

    private var trueFalseContent: some View {
        HStack(spacing: DesignTokens.Spacing.medium) {
            // Find the "true" and "false" options from the question options
            // or create synthetic ones if not present
            let trueOption = question.options.first { $0.text.lowercased().contains("verdadero") || $0.text.lowercased() == "true" }
            let falseOption = question.options.first { $0.text.lowercased().contains("falso") || $0.text.lowercased() == "false" }

            trueFalseButton(
                label: "Verdadero",
                icon: "checkmark.circle.fill",
                color: .green,
                optionId: trueOption?.id,
                isSelected: trueOption.map { selectedOptionId == $0.id } ?? false
            )

            trueFalseButton(
                label: "Falso",
                icon: "xmark.circle.fill",
                color: .red,
                optionId: falseOption?.id,
                isSelected: falseOption.map { selectedOptionId == $0.id } ?? false
            )
        }
    }

    private func trueFalseButton(
        label: String,
        icon: String,
        color: Color,
        optionId: UUID?,
        isSelected: Bool
    ) -> some View {
        Button {
            if let optionId {
                onOptionSelected(optionId)
            }
        } label: {
            VStack(spacing: DesignTokens.Spacing.small) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundStyle(isSelected ? .white : color)

                Text(label)
                    .font(.headline)
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Spacing.xl)
            .background(isSelected ? color : Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl)
                    .stroke(color.opacity(0.3), lineWidth: DesignTokens.BorderWidth.thin)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var shortAnswerContent: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            TextField("Escribe tu respuesta", text: $textAnswer)
                .textFieldStyle(.roundedBorder)
                .font(.body)
                .accessibilityLabel("Respuesta corta")
        }
    }

    private var openEndedContent: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text("Escribe tu respuesta:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextEditor(text: $textAnswer)
                .font(.body)
                .frame(minHeight: 120)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: DesignTokens.BorderWidth.thin)
                )
                .accessibilityLabel("Respuesta abierta")

            Text("\(textAnswer.count) caracteres")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Previews

#Preview("Multiple Choice") {
    @Previewable @State var text = ""
    @Previewable @State var selected: UUID? = nil

    let options = (0..<4).map { i in
        QuestionOption(
            id: UUID(),
            text: "Opcion \(i + 1)",
            orderIndex: i
        )
    }

    let question = AssessmentQuestion(
        id: UUID(),
        text: "Cual es la capital de Francia?",
        options: options,
        isRequired: true,
        orderIndex: 0
    )

    QuestionView(
        question: question,
        questionType: .multipleChoice,
        selectedOptionId: selected,
        textAnswer: $text,
        onOptionSelected: { selected = $0 }
    )
    .padding()
}

#Preview("True/False") {
    @Previewable @State var text = ""
    @Previewable @State var selected: UUID? = nil

    let trueId = UUID()
    let falseId = UUID()
    let question = AssessmentQuestion(
        id: UUID(),
        text: "La Tierra es plana.",
        options: [
            QuestionOption(id: trueId, text: "Verdadero", orderIndex: 0),
            QuestionOption(id: falseId, text: "Falso", orderIndex: 1)
        ],
        isRequired: true,
        orderIndex: 0
    )

    QuestionView(
        question: question,
        questionType: .trueFalse,
        selectedOptionId: selected,
        textAnswer: $text,
        onOptionSelected: { selected = $0 }
    )
    .padding()
}

#Preview("Short Answer") {
    @Previewable @State var text = ""

    let question = AssessmentQuestion(
        id: UUID(),
        text: "Escribe el nombre del elemento quimico con simbolo Fe.",
        options: [],
        isRequired: true,
        orderIndex: 0
    )

    QuestionView(
        question: question,
        questionType: .shortAnswer,
        selectedOptionId: nil,
        textAnswer: $text,
        onOptionSelected: { _ in }
    )
    .padding()
}

#Preview("Open Ended") {
    @Previewable @State var text = ""

    let question = AssessmentQuestion(
        id: UUID(),
        text: "Describe el proceso de fotosintesis en tus propias palabras.",
        options: [],
        isRequired: true,
        orderIndex: 0
    )

    QuestionView(
        question: question,
        questionType: .openEnded,
        selectedOptionId: nil,
        textAnswer: $text,
        onOptionSelected: { _ in }
    )
    .padding()
}
