import Foundation
import Observation
import EduDomain
import EduCore

/// ViewModel para la gestion de asignaciones de un assessment.
///
/// Gestiona la carga de asignaciones existentes, la creacion de nuevas
/// asignaciones (por estudiante o por unidad academica), y la eliminacion
/// de asignaciones.
///
/// ## Tabs
/// - **Por alumno**: seleccionar estudiantes individuales
/// - **Por unidad**: seleccionar unidad academica
///
/// ## Ejemplo de uso
/// ```swift
/// let viewModel = AssessmentAssignmentViewModel(
///     dataProvider: assessmentManagementDataProvider,
///     assessmentId: "assessment-uuid"
/// )
///
/// await viewModel.loadAssignments()
/// viewModel.selectedStudentIds.insert("student-uuid")
/// await viewModel.assignToStudents()
/// ```
@MainActor
@Observable
public final class AssessmentAssignmentViewModel {

    // MARK: - Published State

    /// Asignaciones existentes.
    public var assignments: [AssignmentResponseDTO] = []

    /// IDs de estudiantes seleccionados para asignar.
    public var selectedStudentIds: Set<String> = []

    /// ID de unidad academica seleccionada.
    public var selectedUnitId: String?

    /// Fecha limite opcional.
    public var dueDate: Date?

    /// Indica si se esta cargando datos.
    public var isLoading: Bool = false

    /// Indica si se esta asignando.
    public var isAssigning: Bool = false

    /// Error actual si lo hay.
    public var error: Error?

    /// Tab activo.
    public var activeTab: AssignmentTab = .students

    // MARK: - Assignment Tabs

    /// Tabs de asignacion disponibles.
    public enum AssignmentTab: String, CaseIterable, Sendable {
        case students = "Por alumno"
        case unit = "Por unidad"
    }

    // MARK: - Dependencies

    private let dataProvider: any AssessmentManagementDataProvider
    private let assessmentId: String

    // MARK: - Initialization

    /// Crea un nuevo AssessmentAssignmentViewModel.
    ///
    /// - Parameters:
    ///   - dataProvider: Proveedor de datos de gestion de assessments.
    ///   - assessmentId: ID del assessment.
    public init(
        dataProvider: any AssessmentManagementDataProvider,
        assessmentId: String
    ) {
        self.dataProvider = dataProvider
        self.assessmentId = assessmentId
    }

    // MARK: - Public Methods

    /// Carga las asignaciones existentes del assessment.
    public func loadAssignments() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            self.assignments = try await dataProvider.listAssignments(assessmentId: assessmentId)
            self.isLoading = false
        } catch {
            self.error = error
            self.isLoading = false
        }
    }

    /// Asigna el assessment a los estudiantes seleccionados.
    public func assignToStudents() async {
        guard !selectedStudentIds.isEmpty else { return }
        guard !isAssigning else { return }

        isAssigning = true
        error = nil

        do {
            let dueDateString = formatDueDate()
            let request = AssignAssessmentRequestDTO(
                studentIds: Array(selectedStudentIds),
                dueDate: dueDateString
            )
            let newAssignments = try await dataProvider.assignAssessment(
                assessmentId: assessmentId,
                request
            )
            self.assignments.append(contentsOf: newAssignments)
            self.selectedStudentIds.removeAll()
            self.isAssigning = false
        } catch {
            self.error = error
            self.isAssigning = false
        }
    }

    /// Asigna el assessment a la unidad academica seleccionada.
    public func assignToUnit() async {
        guard let unitId = selectedUnitId else { return }
        guard !isAssigning else { return }

        isAssigning = true
        error = nil

        do {
            let dueDateString = formatDueDate()
            let request = AssignAssessmentRequestDTO(
                academicUnitId: unitId,
                dueDate: dueDateString
            )
            let newAssignments = try await dataProvider.assignAssessment(
                assessmentId: assessmentId,
                request
            )
            self.assignments.append(contentsOf: newAssignments)
            self.selectedUnitId = nil
            self.isAssigning = false
        } catch {
            self.error = error
            self.isAssigning = false
        }
    }

    /// Elimina una asignacion existente.
    ///
    /// - Parameter id: ID de la asignacion a eliminar.
    public func removeAssignment(_ id: String) async {
        do {
            try await dataProvider.removeAssignment(
                assessmentId: assessmentId,
                assignmentId: id
            )
            self.assignments.removeAll { $0.id == id }
        } catch {
            self.error = error
        }
    }

    /// Limpia el error actual.
    public func clearError() {
        error = nil
    }

    // MARK: - Computed Properties

    /// Indica si hay un error.
    public var hasError: Bool {
        error != nil
    }

    /// Mensaje de error legible.
    public var errorMessage: String? {
        error?.localizedDescription
    }

    /// Indica si hay asignaciones existentes.
    public var hasAssignments: Bool {
        !assignments.isEmpty
    }

    /// Numero de asignaciones.
    public var assignmentsCount: Int {
        assignments.count
    }

    /// Indica si se puede asignar segun el tab activo.
    public var canAssign: Bool {
        switch activeTab {
        case .students:
            return !selectedStudentIds.isEmpty && !isAssigning
        case .unit:
            return selectedUnitId != nil && !isAssigning
        }
    }

    // MARK: - Private Methods

    private func formatDueDate() -> String? {
        guard let dueDate else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: dueDate)
    }
}
