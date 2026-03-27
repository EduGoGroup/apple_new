import SwiftUI
import EduDomain
import EduCore

/// Vista de formulario para crear o editar una pregunta de assessment.
///
/// Adapta los campos segun el tipo de pregunta seleccionado:
/// - **Multiple choice**: lista dinamica de opciones, seleccion de correcta
/// - **True/False**: dos opciones fijas, seleccion de correcta
/// - **Short answer**: campo de respuesta correcta
/// - **Open ended**: sin respuesta correcta (calificacion manual)
///
/// ## Ejemplo de uso
/// ```swift
/// QuestionFormView(
///     dataProvider: assessmentManagementDataProvider,
///     assessmentId: "assessment-uuid",
///     questionId: nil,
///     onSaved: { /* refresh list */ },
///     onDismiss: { /* close sheet */ }
/// )
/// ```
@available(iOS 26.0, macOS 26.0, *)
@MainActor
public struct QuestionFormView: View {

    // MARK: - Properties

    @State private var viewModel: QuestionFormViewModel
    private let onSaved: () -> Void
    private let onDismiss: () -> Void

    // MARK: - Initialization

    /// Crea la vista de formulario de pregunta.
    ///
    /// - Parameters:
    ///   - dataProvider: Proveedor de datos de gestion de assessments.
    ///   - assessmentId: ID del assessment.
    ///   - questionId: ID de la pregunta para edicion. Nil para crear nueva.
    ///   - onSaved: Callback al guardar exitosamente.
    ///   - onDismiss: Callback al cancelar.
    public init(
        dataProvider: any AssessmentManagementDataProvider,
        assessmentId: String,
        questionId: String? = nil,
        onSaved: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self._viewModel = State(
            initialValue: QuestionFormViewModel(
                dataProvider: dataProvider,
                assessmentId: assessmentId,
                questionId: questionId
            )
        )
        self.onSaved = onSaved
        self.onDismiss = onDismiss
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            Form {
                questionTypeSection
                questionTextSection
                answersSection
                metadataSection
            }
            .navigationTitle(viewModel.isEditing ? "Editar pregunta" : "Nueva pregunta")
            #if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        Task {
                            let success = await viewModel.save()
                            if success {
                                onSaved()
                            }
                        }
                    }
                    .disabled(!viewModel.isValid || viewModel.isSaving)
                }
            }
            .task {
                await viewModel.loadQuestion()
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.hasError },
                set: { if !$0 { viewModel.clearError() } }
            )) {
                Button("Aceptar", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "Error desconocido")
            }
        }
    }

    // MARK: - Sections

    private var questionTypeSection: some View {
        EduFormSection(title: "Tipo de pregunta") {
            Picker("Tipo", selection: $viewModel.questionType) {
                ForEach(QuestionFormViewModel.QuestionType.allCases, id: \.self) { type in
                    Label(type.displayName, systemImage: type.systemImage)
                        .tag(type)
                }
            }
            .onChange(of: viewModel.questionType) { _, _ in
                viewModel.setupDefaultOptions()
            }
        }
    }

    private var questionTextSection: some View {
        EduFormSection(title: "Pregunta") {
            EduFormField(
                label: "Texto de la pregunta",
                isRequired: true,
                validation: viewModel.questionText.isEmpty ? nil : .success()
            ) {
                TextField("Escribe tu pregunta aqui", text: $viewModel.questionText, axis: .vertical)
                    .lineLimit(3...8)
            }
        }
    }

    @ViewBuilder
    private var answersSection: some View {
        switch viewModel.questionType {
        case .multipleChoice:
            multipleChoiceSection
        case .trueFalse:
            trueFalseSection
        case .shortAnswer:
            shortAnswerSection
        case .openEnded:
            openEndedSection
        }
    }

    private var metadataSection: some View {
        EduFormSection(title: "Detalles") {
            EduFormField(label: "Puntos") {
                Stepper(
                    "\(Int(viewModel.points))",
                    value: $viewModel.points,
                    in: 1...100,
                    step: 1
                )
            }

            EduFormField(label: "Dificultad") {
                Picker("Dificultad", selection: $viewModel.difficulty) {
                    Text("Facil").tag("easy")
                    Text("Media").tag("medium")
                    Text("Dificil").tag("hard")
                }
                .pickerStyle(.segmented)
            }

            EduFormField(label: "Explicacion (opcional)", helpText: "Se muestra al estudiante despues de responder") {
                TextField("Explicacion del feedback", text: $viewModel.explanation, axis: .vertical)
                    .lineLimit(2...5)
            }
        }
    }

    // MARK: - Answer Type Sections

    private var multipleChoiceSection: some View {
        EduFormSection(title: "Opciones de respuesta") {
            ForEach(Array(viewModel.options.enumerated()), id: \.element.id) { index, option in
                HStack {
                    Button {
                        viewModel.correctOptionIndex = index
                    } label: {
                        Image(systemName: viewModel.correctOptionIndex == index
                            ? "checkmark.circle.fill"
                            : "circle")
                        .foregroundStyle(viewModel.correctOptionIndex == index ? .green : .secondary)
                    }
                    .buttonStyle(.plain)

                    TextField("Opcion \(index + 1)", text: binding(for: index))
                        .textFieldStyle(.roundedBorder)

                    if viewModel.options.count > 2 {
                        Button {
                            viewModel.removeOption(at: index)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Button {
                viewModel.addOption()
            } label: {
                Label("Agregar opcion", systemImage: "plus.circle")
            }

            if viewModel.correctOptionIndex == nil {
                Text("Selecciona la respuesta correcta")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var trueFalseSection: some View {
        EduFormSection(title: "Respuesta correcta") {
            ForEach(Array(viewModel.options.enumerated()), id: \.element.id) { index, option in
                Button {
                    viewModel.correctOptionIndex = index
                } label: {
                    HStack {
                        Image(systemName: viewModel.correctOptionIndex == index
                            ? "checkmark.circle.fill"
                            : "circle")
                        .foregroundStyle(viewModel.correctOptionIndex == index ? .green : .secondary)

                        Text(option.text)
                            .foregroundStyle(.primary)

                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }

            if viewModel.correctOptionIndex == nil {
                Text("Selecciona la respuesta correcta")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var shortAnswerSection: some View {
        EduFormSection(title: "Respuesta correcta") {
            EduFormField(label: "Respuesta esperada", isRequired: true) {
                TextField("Escribe la respuesta correcta", text: Binding(
                    get: { viewModel.correctAnswer ?? "" },
                    set: { viewModel.correctAnswer = $0 }
                ))
                .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var openEndedSection: some View {
        EduFormSection(title: "Informacion") {
            Label {
                Text("Esta pregunta requiere calificacion manual. No se verifica automaticamente.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "info.circle")
                    .foregroundStyle(.blue)
            }
        }
    }

    // MARK: - Helpers

    private func binding(for index: Int) -> Binding<String> {
        Binding(
            get: {
                guard viewModel.options.indices.contains(index) else { return "" }
                return viewModel.options[index].text
            },
            set: { newValue in
                guard viewModel.options.indices.contains(index) else { return }
                viewModel.options[index].text = newValue
            }
        )
    }
}
