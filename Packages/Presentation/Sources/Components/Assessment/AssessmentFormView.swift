import SwiftUI
import EduDomain
import EduCore

/// Vista de formulario para crear o editar un assessment.
///
/// Permite configurar los campos del assessment (titulo, descripcion,
/// configuracion de examen) y gestionar las preguntas inline.
///
/// ## Secciones
/// - Informacion basica: titulo, descripcion
/// - Configuracion: umbral, intentos, tiempo, opciones
/// - Preguntas: lista de preguntas con boton para agregar
/// - Acciones: guardar borrador, publicar, asignar
///
/// ## Ejemplo de uso
/// ```swift
/// AssessmentFormView(
///     dataProvider: assessmentManagementDataProvider,
///     assessmentId: nil, // nil para crear, id para editar
///     sourceType: "manual",
///     onDismiss: { dismiss() }
/// )
/// ```
@available(iOS 26.0, macOS 26.0, *)
@MainActor
public struct AssessmentFormView: View {

    // MARK: - State

    @State private var title: String = ""
    @State private var description: String = ""
    @State private var passThreshold: Double = 60.0
    @State private var maxAttempts: Int = 1
    @State private var timeLimitMinutes: Double = 30.0
    @State private var isTimed: Bool = false
    @State private var shuffleQuestions: Bool = false
    @State private var showCorrectAnswers: Bool = true
    @State private var isSaving: Bool = false
    @State private var error: Error?
    @State private var showQuestionForm: Bool = false
    @State private var editingQuestionId: String?
    @State private var questions: [QuestionResponseDTO] = []
    @State private var assessmentId: String?
    @State private var assessmentStatus: String = "draft"

    // MARK: - Properties

    private let dataProvider: any AssessmentManagementDataProvider
    private let initialAssessmentId: String?
    private let sourceType: String
    private let onDismiss: () -> Void

    // MARK: - Initialization

    /// Crea la vista de formulario de assessment.
    ///
    /// - Parameters:
    ///   - dataProvider: Proveedor de datos de gestion de assessments.
    ///   - assessmentId: ID del assessment para edicion. Nil para crear nuevo.
    ///   - sourceType: Tipo de fuente ("manual" o "ai_generated").
    ///   - onDismiss: Callback al cerrar el formulario.
    public init(
        dataProvider: any AssessmentManagementDataProvider,
        assessmentId: String? = nil,
        sourceType: String = "manual",
        onDismiss: @escaping () -> Void
    ) {
        self.dataProvider = dataProvider
        self.initialAssessmentId = assessmentId
        self.sourceType = sourceType
        self.onDismiss = onDismiss
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            Form {
                basicInfoSection
                configurationSection
                questionsSection
                actionsSection
            }
            .navigationTitle(isEditing ? "Editar evaluacion" : "Nueva evaluacion")
            #if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { onDismiss() }
                }
            }
            .sheet(isPresented: $showQuestionForm) {
                if let assessmentId {
                    QuestionFormView(
                        dataProvider: dataProvider,
                        assessmentId: assessmentId,
                        questionId: editingQuestionId,
                        onSaved: {
                            showQuestionForm = false
                            Task { await loadQuestions() }
                        },
                        onDismiss: {
                            showQuestionForm = false
                        }
                    )
                }
            }
            .task {
                if let initialAssessmentId {
                    assessmentId = initialAssessmentId
                    await loadExistingAssessment()
                    await loadQuestions()
                }
            }
            .alert("Error", isPresented: .constant(error != nil)) {
                Button("Aceptar") { error = nil }
            } message: {
                Text(error?.localizedDescription ?? "Error desconocido")
            }
        }
    }

    // MARK: - Sections

    private var basicInfoSection: some View {
        EduFormSection(title: "Informacion basica") {
            EduFormField(label: "Titulo", isRequired: true) {
                TextField("Nombre de la evaluacion", text: $title)
            }

            EduFormField(label: "Descripcion") {
                TextField("Descripcion opcional", text: $description, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
    }

    private var configurationSection: some View {
        EduFormSection(title: "Configuracion") {
            EduFormField(label: "Umbral de aprobacion (\(Int(passThreshold))%)") {
                Slider(value: $passThreshold, in: 0...100, step: 5)
            }

            EduFormField(label: "Intentos maximos") {
                Stepper("\(maxAttempts)", value: $maxAttempts, in: 1...10)
            }

            Toggle("Evaluacion con tiempo", isOn: $isTimed)

            if isTimed {
                EduFormField(label: "Tiempo limite (\(Int(timeLimitMinutes)) min)") {
                    Slider(value: $timeLimitMinutes, in: 5...180, step: 5)
                }
            }

            Toggle("Mezclar preguntas", isOn: $shuffleQuestions)
            Toggle("Mostrar respuestas correctas", isOn: $showCorrectAnswers)
        }
    }

    private var questionsSection: some View {
        EduFormSection(title: "Preguntas (\(questions.count))") {
            if questions.isEmpty {
                Text("No hay preguntas agregadas")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } else {
                ForEach(questions) { question in
                    questionRow(question)
                }
                .onDelete(perform: deleteQuestions)
            }

            if assessmentId != nil {
                Button {
                    editingQuestionId = nil
                    showQuestionForm = true
                } label: {
                    Label("Agregar pregunta", systemImage: "plus.circle")
                }
            } else {
                Text("Guarda el borrador primero para agregar preguntas")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var actionsSection: some View {
        EduFormSection {
            Button {
                Task { await saveDraft() }
            } label: {
                HStack {
                    Spacer()
                    if isSaving {
                        ProgressView()
                            .padding(.trailing, DesignTokens.Spacing.small)
                    }
                    Text(isEditing ? "Guardar cambios" : "Guardar borrador")
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
            .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)

            if assessmentId != nil && !questions.isEmpty && assessmentStatus == "draft" {
                Button {
                    Task { await publish() }
                } label: {
                    HStack {
                        Spacer()
                        Text("Publicar")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .tint(.green)
            }
        }
    }

    // MARK: - Subviews

    private func questionRow(_ question: QuestionResponseDTO) -> some View {
        Button {
            editingQuestionId = question.id
            showQuestionForm = true
        } label: {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                HStack {
                    Text(question.questionText)
                        .font(.subheadline)
                        .lineLimit(2)
                        .foregroundStyle(.primary)

                    Spacer()

                    Text("\(Int(question.points)) pts")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: DesignTokens.Spacing.small) {
                    Text(questionTypeDisplayName(question.questionType))
                        .font(.caption2)
                        .padding(.horizontal, DesignTokens.Spacing.small)
                        .padding(.vertical, 2)
                        .background(.tint.opacity(0.1))
                        .clipShape(Capsule())

                    if let difficulty = question.difficulty {
                        Text(difficultyDisplayName(difficulty))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func saveDraft() async {
        isSaving = true
        error = nil

        do {
            let request = CreateAssessmentRequestDTO(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? nil
                    : description.trimmingCharacters(in: .whitespacesAndNewlines),
                sourceType: sourceType,
                passThreshold: passThreshold,
                maxAttempts: maxAttempts,
                timeLimitMinutes: isTimed ? timeLimitMinutes : nil,
                isTimed: isTimed,
                shuffleQuestions: shuffleQuestions,
                showCorrectAnswers: showCorrectAnswers
            )

            if let existingId = assessmentId {
                let updated = try await dataProvider.updateAssessment(id: existingId, request)
                assessmentStatus = updated.status
            } else {
                let created = try await dataProvider.createAssessment(request)
                assessmentId = created.id
                assessmentStatus = created.status
            }

            isSaving = false
        } catch {
            self.error = error
            isSaving = false
        }
    }

    private func publish() async {
        guard let id = assessmentId else { return }
        isSaving = true
        error = nil

        do {
            let updated = try await dataProvider.publishAssessment(id: id)
            assessmentStatus = updated.status
            isSaving = false
        } catch {
            self.error = error
            isSaving = false
        }
    }

    private func loadExistingAssessment() async {
        guard let id = assessmentId else { return }

        do {
            let assessment = try await dataProvider.getAssessment(id: id)
            title = assessment.title
            description = assessment.description ?? ""
            passThreshold = assessment.passThreshold ?? 60.0
            maxAttempts = assessment.maxAttempts ?? 1
            timeLimitMinutes = assessment.timeLimitMinutes ?? 30.0
            isTimed = assessment.isTimed
            shuffleQuestions = assessment.shuffleQuestions
            showCorrectAnswers = assessment.showCorrectAnswers
            assessmentStatus = assessment.status
        } catch {
            self.error = error
        }
    }

    private func loadQuestions() async {
        guard let id = assessmentId else { return }

        do {
            questions = try await dataProvider.listQuestions(assessmentId: id)
        } catch {
            self.error = error
        }
    }

    private func deleteQuestions(at offsets: IndexSet) {
        guard let id = assessmentId else { return }
        let questionsToDelete = offsets.map { questions[$0] }
        questions.remove(atOffsets: offsets)

        Task {
            for question in questionsToDelete {
                try? await dataProvider.deleteQuestion(assessmentId: id, questionId: question.id)
            }
        }
    }

    // MARK: - Helpers

    private var isEditing: Bool {
        initialAssessmentId != nil
    }

    private func questionTypeDisplayName(_ type: String) -> String {
        switch type {
        case "multiple_choice": return "Opcion multiple"
        case "true_false": return "V / F"
        case "short_answer": return "Respuesta corta"
        case "open_ended": return "Abierta"
        default: return type
        }
    }

    private func difficultyDisplayName(_ difficulty: String) -> String {
        switch difficulty {
        case "easy": return "Facil"
        case "medium": return "Media"
        case "hard": return "Dificil"
        default: return difficulty.capitalized
        }
    }
}
