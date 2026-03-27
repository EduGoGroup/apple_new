import SwiftUI
import EduCore

/// Dashboard de revision de assessments para el profesor.
///
/// Muestra estadisticas, lista de intentos filtrable y acciones de
/// finalizacion masiva. Sigue el patron de `AssessmentManagementListView`.
///
/// ## Funcionalidad
/// - Tarjetas de estadisticas (promedio, aprobados, pendientes)
/// - Filtro por estado: Todos / Pendientes / Completados
/// - Busqueda por nombre de estudiante
/// - Lista de intentos con puntaje y estado
/// - Boton "Finalizar Todos"
///
/// ## Ejemplo de uso
/// ```swift
/// AssessmentReviewDashboardView(
///     viewModel: reviewViewModel,
///     assessmentId: assessmentId,
///     assessmentTitle: "Evaluacion de Algebra",
///     onAttemptTapped: { attempt in
///         navigateToReview(attempt)
///     }
/// )
/// ```
@available(iOS 26.0, macOS 26.0, *)
@MainActor
public struct AssessmentReviewDashboardView: View {

    // MARK: - Properties

    @Bindable private var viewModel: AssessmentReviewViewModel
    private let assessmentId: String
    private let assessmentTitle: String
    private let onAttemptTapped: (TeacherAttemptSummaryDTO) -> Void

    // MARK: - State

    @State private var selectedFilter: AttemptFilter = .all
    @State private var showFinalizeAllConfirmation: Bool = false

    // MARK: - Types

    private enum AttemptFilter: String, CaseIterable {
        case all = "Todos"
        case pendingReview = "Pendientes"
        case completed = "Completados"

        var apiValue: String {
            switch self {
            case .all: return "all"
            case .pendingReview: return "pending_review"
            case .completed: return "completed"
            }
        }
    }

    // MARK: - Initialization

    /// Crea la vista de dashboard de revision.
    ///
    /// - Parameters:
    ///   - viewModel: ViewModel de revision de assessments.
    ///   - assessmentId: ID del assessment a revisar.
    ///   - assessmentTitle: Titulo del assessment para mostrar.
    ///   - onAttemptTapped: Callback al pulsar un intento para revisar.
    public init(
        viewModel: AssessmentReviewViewModel,
        assessmentId: String,
        assessmentTitle: String,
        onAttemptTapped: @escaping (TeacherAttemptSummaryDTO) -> Void
    ) {
        self.viewModel = viewModel
        self.assessmentId = assessmentId
        self.assessmentTitle = assessmentTitle
        self.onAttemptTapped = onAttemptTapped
    }

    // MARK: - Body

    public var body: some View {
        List {
            if let stats = viewModel.stats {
                statsSection(stats)
            }

            if viewModel.filteredAttempts.isEmpty && !viewModel.isLoading {
                emptyStateSection
            } else {
                attemptsListSection
            }
        }
        .navigationTitle(assessmentTitle)
        .searchable(text: $viewModel.searchText, prompt: "Buscar estudiante")
        .refreshable {
            await loadData()
        }
        .safeAreaInset(edge: .top) {
            filterPicker
        }
        .safeAreaInset(edge: .bottom) {
            if viewModel.hasAttempts {
                finalizeAllButton
            }
        }
        .overlay {
            if viewModel.isLoading && viewModel.attempts.isEmpty {
                ProgressView("Cargando intentos...")
            }
        }
        .task {
            await loadData()
        }
        .onChange(of: selectedFilter) {
            viewModel.filter = selectedFilter.apiValue
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
            "Finalizar Todas las Revisiones",
            isPresented: $showFinalizeAllConfirmation,
            titleVisibility: .visible
        ) {
            Button("Finalizar Todas", role: .destructive) {
                Task { await viewModel.finalizeAll(assessmentId: assessmentId) }
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("Esta accion finalizara todas las revisiones pendientes. No se puede deshacer.")
        }
    }

    // MARK: - Subviews

    private func statsSection(_ stats: AssessmentStatsDTO) -> some View {
        Section {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: DesignTokens.Spacing.medium) {
                StatCard(
                    title: "Promedio",
                    value: String(format: "%.1f%%", stats.averageScore),
                    icon: "chart.bar.fill"
                )
                StatCard(
                    title: "Aprobados",
                    value: String(format: "%.0f%%", stats.passRate * 100),
                    icon: "checkmark.circle.fill"
                )
                StatCard(
                    title: "Pendientes",
                    value: "\(stats.pendingReviews)",
                    icon: "clock.fill"
                )
            }
            .listRowInsets(EdgeInsets(
                top: DesignTokens.Spacing.small,
                leading: DesignTokens.Spacing.large,
                bottom: DesignTokens.Spacing.small,
                trailing: DesignTokens.Spacing.large
            ))
        } header: {
            Text("Estadisticas")
        }
    }

    private var filterPicker: some View {
        Picker("Filtro", selection: $selectedFilter) {
            ForEach(AttemptFilter.allCases, id: \.self) { filter in
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
                Label("Sin intentos", systemImage: "doc.text.magnifyingglass")
            } description: {
                Text(viewModel.emptyStateMessage)
            }
        }
    }

    private var attemptsListSection: some View {
        Section {
            ForEach(viewModel.filteredAttempts) { attempt in
                AttemptSummaryRow(attempt: attempt)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onAttemptTapped(attempt)
                    }
            }
        } header: {
            Text("Intentos (\(viewModel.filteredAttempts.count))")
        }
    }

    private var finalizeAllButton: some View {
        Button {
            showFinalizeAllConfirmation = true
        } label: {
            HStack {
                if viewModel.isFinalizing {
                    ProgressView()
                        .controlSize(.small)
                }
                Text("Finalizar Todas las Revisiones")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!viewModel.canFinalizeAll || viewModel.isFinalizing)
        .padding(.horizontal, DesignTokens.Spacing.large)
        .padding(.vertical, DesignTokens.Spacing.small)
        .background(.ultraThinMaterial)
    }

    // MARK: - Private Methods

    private func loadData() async {
        async let attemptsTask: () = viewModel.loadAttempts(assessmentId: assessmentId)
        async let statsTask: () = viewModel.loadStats(assessmentId: assessmentId)
        _ = await (attemptsTask, statsTask)
    }
}

// MARK: - Stat Card

@available(iOS 26.0, macOS 26.0, *)
@MainActor
private struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.primary)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignTokens.Spacing.medium)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.glass))
    }
}

// MARK: - Attempt Summary Row

@available(iOS 26.0, macOS 26.0, *)
@MainActor
private struct AttemptSummaryRow: View {
    let attempt: TeacherAttemptSummaryDTO

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            HStack {
                Text(attempt.studentName)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                statusBadge
            }

            Text(attempt.studentEmail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            HStack(spacing: DesignTokens.Spacing.medium) {
                if let score = attempt.score, let maxScore = attempt.maxScore {
                    Label(
                        String(format: "%.1f/%.1f", score, maxScore),
                        systemImage: "star.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                if let percentage = attempt.percentage {
                    Label(
                        String(format: "%.0f%%", percentage),
                        systemImage: "percent"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                if attempt.pendingReviews > 0 {
                    Label(
                        "\(attempt.pendingReviews) pendientes",
                        systemImage: "clock"
                    )
                    .font(.caption)
                    .foregroundStyle(.orange)
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
        switch attempt.status {
        case "pending_review": return "Pendiente"
        case "completed": return "Completado"
        case "in_progress": return "En progreso"
        default: return attempt.status.capitalized
        }
    }

    private var statusColor: Color {
        switch attempt.status {
        case "pending_review": return .orange
        case "completed": return .green
        case "in_progress": return .blue
        default: return .secondary
        }
    }
}
