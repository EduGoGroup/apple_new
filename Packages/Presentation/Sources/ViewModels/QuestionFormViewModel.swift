import Foundation
import Observation
import EduDomain
import EduCore

/// ViewModel para el formulario de creacion/edicion de preguntas.
///
/// Gestiona el estado del formulario de pregunta, validacion,
/// y la creacion/actualizacion via red.
///
/// ## Tipos de pregunta soportados
/// - Multiple choice: opciones con una correcta
/// - True/false: dos opciones fijas
/// - Short answer: respuesta corta con texto correcto
/// - Open ended: respuesta abierta, calificacion manual
///
/// ## Ejemplo de uso
/// ```swift
/// let viewModel = QuestionFormViewModel(
///     dataProvider: assessmentManagementDataProvider,
///     assessmentId: "assessment-uuid"
/// )
///
/// // Crear nueva pregunta
/// viewModel.questionText = "Cual es la capital de Francia?"
/// viewModel.questionType = .multipleChoice
/// let success = await viewModel.save()
/// ```
@MainActor
@Observable
public final class QuestionFormViewModel {

    // MARK: - Form State

    /// Texto de la pregunta.
    public var questionText: String = ""

    /// Tipo de pregunta seleccionado.
    public var questionType: QuestionType = .multipleChoice

    /// Opciones editables (para multiple choice).
    public var options: [QuestionOptionEdit] = []

    /// Indice de la opcion correcta (para multiple choice y true/false).
    public var correctOptionIndex: Int?

    /// Respuesta correcta en texto (para short answer).
    public var correctAnswer: String?

    /// Explicacion del feedback.
    public var explanation: String = ""

    /// Puntos de la pregunta.
    public var points: Double = 1.0

    /// Dificultad de la pregunta.
    public var difficulty: String = "medium"

    /// Tags de la pregunta.
    public var tags: [String] = []

    /// Indica si se esta guardando.
    public var isSaving: Bool = false

    /// Error actual si lo hay.
    public var error: Error?

    // MARK: - Question Types

    /// Tipos de pregunta disponibles.
    public enum QuestionType: String, CaseIterable, Sendable {
        case multipleChoice = "multiple_choice"
        case trueFalse = "true_false"
        case shortAnswer = "short_answer"
        case openEnded = "open_ended"

        /// Nombre para mostrar en UI.
        public var displayName: String {
            switch self {
            case .multipleChoice: return "Opcion multiple"
            case .trueFalse: return "Verdadero / Falso"
            case .shortAnswer: return "Respuesta corta"
            case .openEnded: return "Respuesta abierta"
            }
        }

        /// Icono del sistema para cada tipo.
        public var systemImage: String {
            switch self {
            case .multipleChoice: return "list.bullet.circle"
            case .trueFalse: return "checkmark.circle"
            case .shortAnswer: return "text.cursor"
            case .openEnded: return "doc.text"
            }
        }
    }

    // MARK: - Option Edit Model

    /// Modelo editable para una opcion de pregunta.
    public struct QuestionOptionEdit: Identifiable, Sendable {
        public let id: UUID
        public var text: String
        public var sortOrder: Int

        public init(id: UUID = UUID(), text: String = "", sortOrder: Int = 0) {
            self.id = id
            self.text = text
            self.sortOrder = sortOrder
        }
    }

    // MARK: - Dependencies

    private let dataProvider: any AssessmentManagementDataProvider
    private let assessmentId: String
    private let questionId: String?

    // MARK: - Initialization

    /// Crea un nuevo QuestionFormViewModel.
    ///
    /// - Parameters:
    ///   - dataProvider: Proveedor de datos de gestion de assessments.
    ///   - assessmentId: ID del assessment al que pertenece la pregunta.
    ///   - questionId: ID de la pregunta para edicion. Nil para crear nueva.
    public init(
        dataProvider: any AssessmentManagementDataProvider,
        assessmentId: String,
        questionId: String? = nil
    ) {
        self.dataProvider = dataProvider
        self.assessmentId = assessmentId
        self.questionId = questionId

        // Inicializar con opciones por defecto para multiple choice
        if questionId == nil {
            setupDefaultOptions()
        }
    }

    // MARK: - Public Methods

    /// Carga los datos de la pregunta si es edicion.
    public func loadQuestion() async {
        guard let questionId else { return }

        do {
            let questions = try await dataProvider.listQuestions(assessmentId: assessmentId)
            guard let question = questions.first(where: { $0.id == questionId }) else { return }

            self.questionText = question.questionText
            self.questionType = QuestionType(rawValue: question.questionType) ?? .multipleChoice
            self.explanation = question.explanation ?? ""
            self.points = question.points
            self.difficulty = question.difficulty ?? "medium"
            self.tags = question.tags ?? []
            self.correctAnswer = question.correctAnswer

            if let responseOptions = question.options {
                self.options = responseOptions.map { opt in
                    QuestionOptionEdit(
                        text: opt.optionText,
                        sortOrder: opt.sortOrder
                    )
                }
            }
        } catch {
            self.error = error
        }
    }

    /// Guarda la pregunta (crear o actualizar).
    ///
    /// - Returns: `true` si se guardo exitosamente.
    public func save() async -> Bool {
        guard isValid else { return false }

        isSaving = true
        error = nil

        do {
            let request = buildRequest()

            if let questionId {
                _ = try await dataProvider.updateQuestion(
                    assessmentId: assessmentId,
                    questionId: questionId,
                    request
                )
            } else {
                _ = try await dataProvider.createQuestion(
                    assessmentId: assessmentId,
                    request
                )
            }

            isSaving = false
            return true
        } catch {
            self.error = error
            isSaving = false
            return false
        }
    }

    /// Agrega una nueva opcion vacia.
    public func addOption() {
        let newOption = QuestionOptionEdit(
            text: "",
            sortOrder: options.count
        )
        options.append(newOption)
    }

    /// Elimina una opcion por indice.
    ///
    /// - Parameter index: Indice de la opcion a eliminar.
    public func removeOption(at index: Int) {
        guard options.indices.contains(index) else { return }
        options.remove(at: index)
        // Reordenar
        for i in options.indices {
            options[i].sortOrder = i
        }
        // Ajustar correctOptionIndex si es necesario
        if let correctIndex = correctOptionIndex {
            if correctIndex == index {
                correctOptionIndex = nil
            } else if correctIndex > index {
                correctOptionIndex = correctIndex - 1
            }
        }
    }

    /// Configura las opciones por defecto al cambiar tipo de pregunta.
    public func setupDefaultOptions() {
        switch questionType {
        case .multipleChoice:
            if options.isEmpty {
                options = (0..<4).map { i in
                    QuestionOptionEdit(text: "", sortOrder: i)
                }
            }
            correctOptionIndex = nil
            correctAnswer = nil
        case .trueFalse:
            options = [
                QuestionOptionEdit(text: "Verdadero", sortOrder: 0),
                QuestionOptionEdit(text: "Falso", sortOrder: 1)
            ]
            correctOptionIndex = nil
            correctAnswer = nil
        case .shortAnswer:
            options = []
            correctOptionIndex = nil
            correctAnswer = correctAnswer ?? ""
        case .openEnded:
            options = []
            correctOptionIndex = nil
            correctAnswer = nil
        }
    }

    /// Limpia el error actual.
    public func clearError() {
        error = nil
    }

    // MARK: - Validation

    /// Indica si el formulario es valido para guardar.
    public var isValid: Bool {
        guard !questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        guard points > 0 else { return false }

        switch questionType {
        case .multipleChoice:
            let nonEmptyOptions = options.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            return nonEmptyOptions.count >= 2 && correctOptionIndex != nil
        case .trueFalse:
            return correctOptionIndex != nil
        case .shortAnswer:
            let answer = correctAnswer?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return !answer.isEmpty
        case .openEnded:
            return true
        }
    }

    /// Indica si es edicion (vs creacion).
    public var isEditing: Bool {
        questionId != nil
    }

    /// Indica si hay un error.
    public var hasError: Bool {
        error != nil
    }

    /// Mensaje de error legible.
    public var errorMessage: String? {
        error?.localizedDescription
    }

    // MARK: - Private Methods

    private func buildRequest() -> CreateQuestionRequestDTO {
        let requestOptions: [QuestionOptionRequestDTO]?
        let requestCorrectAnswer: String?

        switch questionType {
        case .multipleChoice, .trueFalse:
            requestOptions = options.enumerated().map { index, opt in
                QuestionOptionRequestDTO(
                    optionText: opt.text,
                    sortOrder: index
                )
            }
            if let correctIndex = correctOptionIndex, options.indices.contains(correctIndex) {
                requestCorrectAnswer = options[correctIndex].text
            } else {
                requestCorrectAnswer = nil
            }
        case .shortAnswer:
            requestOptions = nil
            requestCorrectAnswer = correctAnswer
        case .openEnded:
            requestOptions = nil
            requestCorrectAnswer = nil
        }

        return CreateQuestionRequestDTO(
            questionText: questionText.trimmingCharacters(in: .whitespacesAndNewlines),
            questionType: questionType.rawValue,
            options: requestOptions,
            correctAnswer: requestCorrectAnswer,
            explanation: explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil
                : explanation.trimmingCharacters(in: .whitespacesAndNewlines),
            points: points,
            difficulty: difficulty,
            tags: tags.isEmpty ? nil : tags
        )
    }
}
