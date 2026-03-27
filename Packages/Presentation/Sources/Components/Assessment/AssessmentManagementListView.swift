import SwiftUI
import EduCore

/// Vista de lista para gestion de assessments del profesor.
///
/// Muestra la lista de assessments creados con capacidad de filtrado
/// por estado (todos, borradores, publicados), busqueda por texto,
/// y acciones deslizantes (publicar, archivar).
///
/// ## Funcionalidad
/// - Filtros por estado via Picker segmentado
/// - Busqueda por titulo y descripcion
/// - Pull to refresh
/// - Swipe actions segun estado
/// - Boton para crear nueva evaluacion
///
/// ## Ejemplo de uso
/// ```swift
/// AssessmentManagementListView(
///     viewModel: assessmentManagementViewModel,
///     onCreateTapped: { showModalitySheet = true },
///     onAssessmentTapped: { assessment in
///         navigateToDetail(assessment)
///     }
/// )
/// ```
@available(iOS 26.0, macOS 26.0, *)
@MainActor
public struct AssessmentManagementListView: View {

    // MARK: - Properties

    @Bindable private var viewModel: AssessmentManagementViewModel
    private let onCreateTapped: () -> Void
    private let onAssessmentTapped: (AssessmentManagementResponseDTO) -> Void

    // MARK: - State

    @State private var selectedFilter: StatusFilter = .all

    // MARK: - Types

    private enum StatusFilter: String, CaseIterable {
        case all = "Todos"
        case draft = "Borradores"
        case published = "Publicados"

        var apiValue: String? {
            switch self {
            case .all: return nil
            case .draft: return "draft"
            case .published: return "published"
            }
        }
    }

    // MARK: - Initialization

    /// Crea la vista de lista de gestion de assessments.
    ///
    /// - Parameters:
    ///   - viewModel: ViewModel de gestion de assessments.
    ///   - onCreateTapped: Callback al pulsar crear evaluacion.
    ///   - onAssessmentTapped: Callback al pulsar un assessment.
    public init(
        viewModel: AssessmentManagementViewModel,
        onCreateTapped: @escaping () -> Void,
        onAssessmentTapped: @escaping (AssessmentManagementResponseDTO) -> Void
    ) {
        self.viewModel = viewModel
        self.onCreateTapped = onCreateTapped
        self.onAssessmentTapped = onAssessmentTapped
    }

    // MARK: - Body

    public var body: some View {
        List {
            if viewModel.filteredAssessments.isEmpty && !viewModel.isLoading {
                emptyStateSection
            } else {
                assessmentListSection
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Buscar evaluaciones")
        .refreshable {
            await viewModel.refresh()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    onCreateTapped()
                } label: {
                    Label("Crear evaluacion", systemImage: "plus")
                }
            }
        }
        .safeAreaInset(edge: .top) {
            filterPicker
        }
        .overlay {
            if viewModel.isLoading && viewModel.assessments.isEmpty {
                ProgressView("Cargando evaluaciones...")
            }
        }
        .task {
            await viewModel.loadAssessments()
        }
        .onChange(of: selectedFilter) { _, newValue in
            viewModel.statusFilter = newValue.apiValue
            Task {
                await viewModel.loadAssessments()
            }
        }
        .alert("Error", isPresented: .constant(viewModel.hasError)) {
            Button("Aceptar") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "Error desconocido")
        }
    }

    // MARK: - Subviews

    private var filterPicker: some View {
        Picker("Filtro", selection: $selectedFilter) {
            ForEach(StatusFilter.allCases, id: \.self) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, DesignTokens.Spacing.large)
        .padding(.vertical, DesignTokens.Spacing.small)
    }

    private var emptyStateSection: some View {
        Section {
            ContentUnavailableView {
                Label("Sin evaluaciones", systemImage: "doc.text.magnifyingglass")
            } description: {
                Text(viewModel.emptyStateMessage)
            } actions: {
                Button("Crear evaluacion") {
                    onCreateTapped()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var assessmentListSection: some View {
        Section {
            ForEach(viewModel.filteredAssessments) { assessment in
                AssessmentManagementRow(assessment: assessment)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onAssessmentTapped(assessment)
                    }
                    .swipeActions(edge: .trailing) {
                        swipeActions(for: assessment)
                    }
            }
        }
    }

    @ViewBuilder
    private func swipeActions(for assessment: AssessmentManagementResponseDTO) -> some View {
        switch assessment.status {
        case "draft":
            Button {
                Task { await viewModel.publishAssessment(assessment.id) }
            } label: {
                Label("Publicar", systemImage: "paperplane")
            }
            .tint(.green)
        case "published":
            Button {
                Task { await viewModel.archiveAssessment(assessment.id) }
            } label: {
                Label("Archivar", systemImage: "archivebox")
            }
            .tint(.orange)
        default:
            EmptyView()
        }
    }
}

// MARK: - Assessment Management Row

@available(iOS 26.0, macOS 26.0, *)
@MainActor
private struct AssessmentManagementRow: View {
    let assessment: AssessmentManagementResponseDTO

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            HStack {
                Text(assessment.title)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                statusBadge
            }

            if let description = assessment.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: DesignTokens.Spacing.medium) {
                Label("\(assessment.questionsCount)", systemImage: "questionmark.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let sourceType = assessment.sourceType {
                    Label(
                        sourceType == "manual" ? "Manual" : "IA",
                        systemImage: sourceType == "manual" ? "hand.draw" : "sparkles"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                if assessment.isTimed, let minutes = assessment.timeLimitMinutes {
                    Label("\(Int(minutes)) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, DesignTokens.Spacing.xs)
    }

    private var statusBadge: some View {
        Text(statusDisplayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, DesignTokens.Spacing.small)
            .padding(.vertical, 2)
            .background(statusColor.opacity(0.15))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }

    private var statusDisplayName: String {
        switch assessment.status {
        case "draft": return "Borrador"
        case "published": return "Publicado"
        case "archived": return "Archivado"
        default: return assessment.status.capitalized
        }
    }

    private var statusColor: Color {
        switch assessment.status {
        case "draft": return .orange
        case "published": return .green
        case "archived": return .gray
        default: return .secondary
        }
    }
}
