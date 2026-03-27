import Foundation
import Observation
import EduDomain
import EduCore
import EduInfrastructure

/// ViewModel para la lista de gestion de assessments del profesor.
///
/// Gestiona la carga, filtrado, busqueda y acciones sobre assessments
/// (publicar, archivar). Usa el protocolo `AssessmentManagementDataProvider`
/// para abstraer la capa de red.
///
/// ## Responsabilidades
/// - Cargar assessments con paginacion
/// - Filtrar por estado (draft, published, archived)
/// - Busqueda por texto
/// - Acciones: publicar, archivar
///
/// ## Ejemplo de uso
/// ```swift
/// let viewModel = AssessmentManagementViewModel(
///     dataProvider: assessmentManagementDataProvider
/// )
///
/// // En la vista
/// List(viewModel.filteredAssessments) { assessment in
///     AssessmentRow(assessment: assessment)
/// }
/// .task { await viewModel.loadAssessments() }
/// ```
@MainActor
@Observable
public final class AssessmentManagementViewModel {

    // MARK: - Published State

    /// Assessments cargados del servidor.
    public var assessments: [AssessmentManagementResponseDTO] = []

    /// Indica si se esta cargando datos.
    public var isLoading: Bool = false

    /// Error actual si lo hay.
    public var error: Error?

    /// Filtro de estado activo (nil = todos).
    public var statusFilter: String?

    /// Texto de busqueda.
    public var searchText: String = ""

    // MARK: - Dependencies

    private let dataProvider: any AssessmentManagementDataProvider

    // MARK: - Constants

    private let pageSize = 20

    // MARK: - Initialization

    /// Crea un nuevo AssessmentManagementViewModel.
    ///
    /// - Parameter dataProvider: Proveedor de datos de gestion de assessments.
    public init(dataProvider: any AssessmentManagementDataProvider) {
        self.dataProvider = dataProvider
    }

    // MARK: - Public Methods

    /// Carga la lista de assessments del servidor.
    public func loadAssessments() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            let response = try await dataProvider.listAssessments(
                status: statusFilter,
                page: 1,
                limit: pageSize
            )
            self.assessments = response.items
            self.isLoading = false
        } catch {
            self.error = error
            self.isLoading = false
        }
    }

    /// Publica un assessment (cambia de draft a published).
    ///
    /// - Parameter id: ID del assessment a publicar.
    public func publishAssessment(_ id: String) async {
        do {
            let updated = try await dataProvider.publishAssessment(id: id)
            if let index = assessments.firstIndex(where: { $0.id == id }) {
                assessments[index] = updated
            }
        } catch {
            self.error = error
        }
    }

    /// Archiva un assessment.
    ///
    /// - Parameter id: ID del assessment a archivar.
    public func archiveAssessment(_ id: String) async {
        do {
            let updated = try await dataProvider.archiveAssessment(id: id)
            if let index = assessments.firstIndex(where: { $0.id == id }) {
                assessments[index] = updated
            }
        } catch {
            self.error = error
        }
    }

    /// Limpia el error actual.
    public func clearError() {
        error = nil
    }

    /// Refresca la lista desde el servidor, ignorando el guard isLoading.
    public func refresh() async {
        isLoading = true
        error = nil

        do {
            let response = try await dataProvider.listAssessments(
                status: statusFilter,
                page: 1,
                limit: pageSize
            )
            self.assessments = response.items
        } catch {
            self.error = error
        }
        self.isLoading = false
    }

    // MARK: - Computed Properties

    /// Assessments filtrados por texto de busqueda.
    public var filteredAssessments: [AssessmentManagementResponseDTO] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return assessments }
        return assessments.filter { assessment in
            assessment.title.lowercased().contains(trimmed)
            || (assessment.description?.lowercased().contains(trimmed) ?? false)
        }
    }

    /// Indica si hay un error.
    public var hasError: Bool {
        error != nil
    }

    /// Mensaje de error legible.
    public var errorMessage: String? {
        error?.localizedDescription
    }

    /// Indica si hay assessments cargados.
    public var hasAssessments: Bool {
        !assessments.isEmpty
    }

    /// Mensaje para estado vacio.
    public var emptyStateMessage: String {
        if statusFilter != nil || !searchText.isEmpty {
            return "No se encontraron evaluaciones con los filtros aplicados"
        }
        return "No hay evaluaciones creadas"
    }
}
