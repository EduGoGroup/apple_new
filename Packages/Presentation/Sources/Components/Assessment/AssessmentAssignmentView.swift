import SwiftUI
import EduDomain
import EduCore

/// Vista para gestionar las asignaciones de un assessment.
///
/// Permite asignar un assessment publicado a estudiantes individuales
/// o a unidades academicas completas, con una fecha limite opcional.
///
/// ## Tabs
/// - **Por alumno**: seleccionar estudiantes individuales
/// - **Por unidad**: seleccionar unidad academica
///
/// ## Ejemplo de uso
/// ```swift
/// AssessmentAssignmentView(
///     viewModel: assignmentViewModel,
///     onDismiss: { dismiss() }
/// )
/// ```
@available(iOS 26.0, macOS 26.0, *)
@MainActor
public struct AssessmentAssignmentView: View {

    // MARK: - Properties

    @Bindable private var viewModel: AssessmentAssignmentViewModel
    private let onDismiss: () -> Void

    @State private var showDatePicker: Bool = false

    // MARK: - Initialization

    /// Crea la vista de asignacion de assessment.
    ///
    /// - Parameters:
    ///   - viewModel: ViewModel de asignaciones.
    ///   - onDismiss: Callback al cerrar la vista.
    public init(
        viewModel: AssessmentAssignmentViewModel,
        onDismiss: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                tabPicker
                tabContent
            }
            .navigationTitle("Asignar evaluacion")
            #if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Asignar") {
                        Task {
                            switch viewModel.activeTab {
                            case .students:
                                await viewModel.assignToStudents()
                            case .unit:
                                await viewModel.assignToUnit()
                            }
                        }
                    }
                    .disabled(!viewModel.canAssign)
                }
            }
            .task {
                await viewModel.loadAssignments()
            }
            .alert("Error", isPresented: .constant(viewModel.hasError)) {
                Button("Aceptar") { viewModel.clearError() }
            } message: {
                Text(viewModel.errorMessage ?? "Error desconocido")
            }
        }
    }

    // MARK: - Subviews

    private var tabPicker: some View {
        Picker("Tipo de asignacion", selection: $viewModel.activeTab) {
            ForEach(AssessmentAssignmentViewModel.AssignmentTab.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, DesignTokens.Spacing.large)
        .padding(.vertical, DesignTokens.Spacing.small)
    }

    @ViewBuilder
    private var tabContent: some View {
        List {
            dueDateSection

            switch viewModel.activeTab {
            case .students:
                studentsSection
            case .unit:
                unitSection
            }

            if viewModel.hasAssignments {
                existingAssignmentsSection
            }
        }
    }

    private var dueDateSection: some View {
        EduFormSection(title: "Fecha limite (opcional)") {
            Toggle("Establecer fecha limite", isOn: $showDatePicker)

            if showDatePicker {
                DatePicker(
                    "Fecha limite",
                    selection: Binding(
                        get: { viewModel.dueDate ?? Date().addingTimeInterval(7 * 24 * 3600) },
                        set: { viewModel.dueDate = $0 }
                    ),
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
            }
        }
    }

    private var studentsSection: some View {
        EduFormSection(title: "Seleccionar estudiantes") {
            // Placeholder para lista de estudiantes
            // En la integracion real, se cargaran desde la API
            ContentUnavailableView {
                Label("Estudiantes", systemImage: "person.3")
            } description: {
                Text("La lista de estudiantes se cargara desde tu grupo o unidad academica")
            }

            if viewModel.isAssigning {
                HStack {
                    Spacer()
                    ProgressView("Asignando...")
                    Spacer()
                }
            }
        }
    }

    private var unitSection: some View {
        EduFormSection(title: "Seleccionar unidad academica") {
            // Placeholder para lista de unidades
            // En la integracion real, se cargaran desde la API
            ContentUnavailableView {
                Label("Unidades academicas", systemImage: "building.2")
            } description: {
                Text("Las unidades academicas se cargaran desde tu escuela")
            }

            if viewModel.isAssigning {
                HStack {
                    Spacer()
                    ProgressView("Asignando...")
                    Spacer()
                }
            }
        }
    }

    private var existingAssignmentsSection: some View {
        EduFormSection(title: "Asignaciones existentes (\(viewModel.assignmentsCount))") {
            ForEach(viewModel.assignments) { assignment in
                assignmentRow(assignment)
            }
            .onDelete(perform: deleteAssignments)
        }
    }

    private func assignmentRow(_ assignment: AssignmentResponseDTO) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            HStack {
                if let studentId = assignment.studentId {
                    Label(studentId, systemImage: "person")
                        .font(.subheadline)
                        .lineLimit(1)
                } else if let unitId = assignment.academicUnitId {
                    Label(unitId, systemImage: "building.2")
                        .font(.subheadline)
                        .lineLimit(1)
                }

                Spacer()

                if let dueDate = assignment.dueDate {
                    Text(dueDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text("Asignado: \(assignment.assignedAt)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Actions

    private func deleteAssignments(at offsets: IndexSet) {
        let assignmentsToDelete = offsets.map { viewModel.assignments[$0] }
        for assignment in assignmentsToDelete {
            Task {
                await viewModel.removeAssignment(assignment.id)
            }
        }
    }
}
