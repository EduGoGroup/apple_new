import SwiftUI

/// Student-facing list of assigned assessments.
///
/// Displays a searchable, pull-to-refresh list where each row shows the
/// assessment title, due date, status badge, and remaining attempts.
/// Tapping a row navigates to the exam-taking flow.
///
/// ## Features
/// - Pull to refresh
/// - Searchable by title
/// - Status badge per assessment (Pending, Completed, Expired)
/// - Remaining attempts indicator
/// - Loading and empty states
///
/// ## Example
/// ```swift
/// AssessmentListView(
///     assessments: viewModel.assessments,
///     isLoading: viewModel.isLoading,
///     onRefresh: { await viewModel.loadAssessments() },
///     onAssessmentTapped: { assessment in
///         coordinator.showAssessment(assessmentId: assessment.id, userId: userId)
///     }
/// )
/// ```
@available(iOS 26.0, macOS 26.0, *)
@MainActor
public struct AssessmentListView: View {

    // MARK: - Types

    /// Summary information for displaying an assessment in the list.
    public struct AssessmentListItem: Identifiable, Sendable {
        public let id: UUID
        public let title: String
        public let description: String?
        public let dueDate: Date?
        public let status: Status
        public let attemptsUsed: Int
        public let maxAttempts: Int
        public let questionsCount: Int
        public let timeLimitSeconds: Int?

        public enum Status: String, Sendable {
            case pending
            case inProgress = "in_progress"
            case completed
            case expired

            public var displayName: String {
                switch self {
                case .pending: return "Pendiente"
                case .inProgress: return "En progreso"
                case .completed: return "Completado"
                case .expired: return "Expirado"
                }
            }

            public var color: Color {
                switch self {
                case .pending: return .orange
                case .inProgress: return .blue
                case .completed: return .green
                case .expired: return .gray
                }
            }
        }

        public var attemptsLeft: Int {
            max(0, maxAttempts - attemptsUsed)
        }

        public init(
            id: UUID,
            title: String,
            description: String? = nil,
            dueDate: Date? = nil,
            status: Status = .pending,
            attemptsUsed: Int = 0,
            maxAttempts: Int = 3,
            questionsCount: Int = 0,
            timeLimitSeconds: Int? = nil
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.dueDate = dueDate
            self.status = status
            self.attemptsUsed = attemptsUsed
            self.maxAttempts = maxAttempts
            self.questionsCount = questionsCount
            self.timeLimitSeconds = timeLimitSeconds
        }
    }

    // MARK: - Properties

    private let assessments: [AssessmentListItem]
    private let isLoading: Bool
    private let onRefresh: () async -> Void
    private let onAssessmentTapped: (AssessmentListItem) -> Void

    // MARK: - State

    @State private var searchText: String = ""

    // MARK: - Initialization

    /// Creates the student assessment list view.
    ///
    /// - Parameters:
    ///   - assessments: Array of assessment summary items to display.
    ///   - isLoading: Whether the list is currently loading data.
    ///   - onRefresh: Async callback for pull-to-refresh.
    ///   - onAssessmentTapped: Callback when a row is tapped.
    public init(
        assessments: [AssessmentListItem],
        isLoading: Bool,
        onRefresh: @escaping () async -> Void,
        onAssessmentTapped: @escaping (AssessmentListItem) -> Void
    ) {
        self.assessments = assessments
        self.isLoading = isLoading
        self.onRefresh = onRefresh
        self.onAssessmentTapped = onAssessmentTapped
    }

    // MARK: - Computed

    private var filteredAssessments: [AssessmentListItem] {
        if searchText.isEmpty {
            return assessments
        }
        let query = searchText.lowercased()
        return assessments.filter {
            $0.title.lowercased().contains(query)
            || ($0.description?.lowercased().contains(query) ?? false)
        }
    }

    // MARK: - Body

    public var body: some View {
        List {
            if filteredAssessments.isEmpty && !isLoading {
                emptyState
            } else {
                assessmentRows
            }
        }
        .searchable(text: $searchText, prompt: "Buscar evaluaciones")
        .refreshable {
            await onRefresh()
        }
        .overlay {
            if isLoading && assessments.isEmpty {
                ProgressView("Cargando evaluaciones...")
            }
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        Section {
            ContentUnavailableView {
                Label("Sin evaluaciones", systemImage: "doc.text.magnifyingglass")
            } description: {
                if searchText.isEmpty {
                    Text("No tienes evaluaciones asignadas en este momento.")
                } else {
                    Text("No se encontraron evaluaciones que coincidan con tu busqueda.")
                }
            }
        }
    }

    private var assessmentRows: some View {
        Section {
            ForEach(filteredAssessments) { item in
                AssessmentRow(item: item)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onAssessmentTapped(item)
                    }
            }
        }
    }
}

// MARK: - Assessment Row

@available(iOS 26.0, macOS 26.0, *)
@MainActor
private struct AssessmentRow: View {
    let item: AssessmentListView.AssessmentListItem

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            // Title and status
            HStack {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                StatusBadge(text: item.status.displayName, color: item.status.color)
            }

            // Description
            if let description = item.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            // Metadata row
            HStack(spacing: DesignTokens.Spacing.medium) {
                Label("\(item.questionsCount) preguntas", systemImage: "questionmark.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let timeLimit = item.timeLimitSeconds {
                    Label("\(timeLimit / 60) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                attemptsLabel
            }

            // Due date
            if let dueDate = item.dueDate {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text("Vence: \(dueDate, style: .date)")
                        .font(.caption)
                        .foregroundStyle(isDueSoon(dueDate) ? .red : .secondary)
                }
            }
        }
        .padding(.vertical, DesignTokens.Spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title), \(item.status.displayName)")
        .accessibilityHint("Toca para abrir la evaluacion")
    }

    private var attemptsLabel: some View {
        Group {
            if item.attemptsLeft > 0 {
                Label(
                    "\(item.attemptsLeft) intento\(item.attemptsLeft == 1 ? "" : "s")",
                    systemImage: "arrow.counterclockwise"
                )
                .font(.caption)
                .foregroundStyle(item.attemptsLeft == 1 ? .orange : .secondary)
            } else {
                Label("Sin intentos", systemImage: "xmark.circle")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private func isDueSoon(_ date: Date) -> Bool {
        let hoursLeft = date.timeIntervalSinceNow / 3600
        return hoursLeft > 0 && hoursLeft < 24
    }
}

// MARK: - Previews

#Preview("Assessment List") {
    let items: [AssessmentListView.AssessmentListItem] = [
        .init(
            id: UUID(),
            title: "Matematicas - Fracciones",
            description: "Evaluacion sobre operaciones con fracciones",
            dueDate: Date().addingTimeInterval(86400),
            status: .pending,
            attemptsUsed: 0,
            maxAttempts: 3,
            questionsCount: 10,
            timeLimitSeconds: 1800
        ),
        .init(
            id: UUID(),
            title: "Historia - Independencia",
            description: nil,
            dueDate: Date().addingTimeInterval(172800),
            status: .inProgress,
            attemptsUsed: 1,
            maxAttempts: 3,
            questionsCount: 15
        ),
        .init(
            id: UUID(),
            title: "Ciencias - Ecosistemas",
            description: "Evaluacion sobre tipos de ecosistemas",
            dueDate: Date().addingTimeInterval(-86400),
            status: .completed,
            attemptsUsed: 2,
            maxAttempts: 3,
            questionsCount: 8,
            timeLimitSeconds: 1200
        ),
        .init(
            id: UUID(),
            title: "Lengua - Comprension lectora",
            description: nil,
            dueDate: Date().addingTimeInterval(-172800),
            status: .expired,
            attemptsUsed: 0,
            maxAttempts: 1,
            questionsCount: 5
        )
    ]

    NavigationStack {
        AssessmentListView(
            assessments: items,
            isLoading: false,
            onRefresh: { },
            onAssessmentTapped: { _ in }
        )
        .navigationTitle("Mis Evaluaciones")
    }
}

#Preview("Empty State") {
    NavigationStack {
        AssessmentListView(
            assessments: [],
            isLoading: false,
            onRefresh: { },
            onAssessmentTapped: { _ in }
        )
        .navigationTitle("Mis Evaluaciones")
    }
}

#Preview("Loading") {
    NavigationStack {
        AssessmentListView(
            assessments: [],
            isLoading: true,
            onRefresh: { },
            onAssessmentTapped: { _ in }
        )
        .navigationTitle("Mis Evaluaciones")
    }
}
