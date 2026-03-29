import SwiftUI
import EduCore
import EduDomain

/// Teacher-facing list of educational materials with infinite scroll.
///
/// Displays a searchable, pull-to-refresh list where each row shows the
/// material title, status badge, file type, file size, and creation date.
/// Tapping a row navigates to the material detail view.
///
/// ## Features
/// - Pull to refresh
/// - Infinite scroll with cursor-based pagination
/// - Status badge per material (Uploaded, Processing, Ready, Failed)
/// - File type and size indicators
/// - Loading, error, and empty states
/// - Toolbar button to upload new material
///
/// ## Example
/// ```swift
/// MaterialListView(
///     viewModel: materialListViewModel,
///     onMaterialTapped: { material in
///         coordinator.showMaterialDetail(materialId: material.id)
///     },
///     onUploadTapped: {
///         coordinator.showUploadMaterial()
///     }
/// )
/// ```
@available(iOS 26.0, macOS 26.0, *)
@MainActor
public struct MaterialListView: View {

    // MARK: - Properties

    @Bindable private var viewModel: MaterialListViewModel
    private let onMaterialTapped: (EduCore.Material) -> Void
    private let onUploadTapped: () -> Void

    // MARK: - Initialization

    /// Creates the material list view.
    ///
    /// - Parameters:
    ///   - viewModel: ViewModel managing the material list state.
    ///   - onMaterialTapped: Callback when a material row is tapped.
    ///   - onUploadTapped: Callback when the upload button is tapped.
    public init(
        viewModel: MaterialListViewModel,
        onMaterialTapped: @escaping (EduCore.Material) -> Void,
        onUploadTapped: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onMaterialTapped = onMaterialTapped
        self.onUploadTapped = onUploadTapped
    }

    // MARK: - Body

    public var body: some View {
        List {
            if viewModel.hasMaterials {
                materialRows
            }

            if viewModel.hasMore && !viewModel.isLoadingMore {
                Color.clear
                    .frame(height: 1)
                    .task { await viewModel.loadMore() }
            }

            if viewModel.isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }
        }
        .navigationTitle("Materiales")
        .searchable(
            text: $viewModel.searchQuery,
            prompt: "Buscar materiales"
        )
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    onUploadTapped()
                } label: {
                    Label("Subir", systemImage: "plus")
                }
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            if viewModel.materials.isEmpty {
                await viewModel.loadMaterials()
            }
        }
        .overlay {
            if viewModel.isLoading && viewModel.materials.isEmpty {
                ProgressView("Cargando materiales...")
            } else if viewModel.materials.isEmpty && !viewModel.isLoading {
                emptyState
            }
        }
        .alert(
            "Error",
            isPresented: .constant(viewModel.hasError),
            presenting: viewModel.errorMessage
        ) { _ in
            Button("Aceptar") { viewModel.clearError() }
        } message: { message in
            Text(message)
        }
    }

    // MARK: - Subviews

    private var materialRows: some View {
        ForEach(viewModel.materials) { material in
            MaterialRowView(material: material)
                .contentShape(Rectangle())
                .onTapGesture {
                    onMaterialTapped(material)
                }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Sin materiales", systemImage: "doc.text")
        } description: {
            Text(viewModel.emptyStateMessage)
        } actions: {
            Button("Subir material") {
                onUploadTapped()
            }
            .buttonStyle(.bordered)
        }
    }
}

// MARK: - MaterialRowView

/// A row displaying summary information for a single material.
@available(iOS 26.0, macOS 26.0, *)
@MainActor
struct MaterialRowView: View {

    let material: EduCore.Material

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            // Title and status
            HStack {
                Text(material.title)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                statusBadge
            }

            // Description
            if let description = material.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            // Metadata row
            HStack(spacing: DesignTokens.Spacing.medium) {
                if let fileType = material.fileType {
                    Label(fileTypeLabel(fileType), systemImage: fileTypeIcon(fileType))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let sizeBytes = material.fileSizeBytes {
                    Label(formattedFileSize(sizeBytes), systemImage: "doc")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(material.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, DesignTokens.Spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(material.title), \(material.status.description)")
        .accessibilityHint("Toca para ver el detalle del material")
    }

    // MARK: - Status Badge

    private var statusBadge: some View {
        StatusBadge(text: statusText, color: statusColor)
    }

    private var statusText: String {
        switch material.status {
        case .uploaded:
            return "Subido"
        case .processing:
            return "Procesando"
        case .ready:
            return "Listo"
        case .failed:
            return "Error"
        }
    }

    private var statusColor: Color {
        switch material.status {
        case .uploaded:
            return .blue
        case .processing:
            return .orange
        case .ready:
            return .green
        case .failed:
            return .red
        }
    }

    // MARK: - Helpers

    private func fileTypeLabel(_ mimeType: String) -> String {
        switch mimeType {
        case "application/pdf":
            return "PDF"
        case "application/vnd.openxmlformats-officedocument.wordprocessingml.document":
            return "DOCX"
        case "application/vnd.openxmlformats-officedocument.presentationml.presentation":
            return "PPTX"
        case "video/mp4":
            return "MP4"
        default:
            return mimeType.components(separatedBy: "/").last?.uppercased() ?? "Archivo"
        }
    }

    private func fileTypeIcon(_ mimeType: String) -> String {
        switch mimeType {
        case "application/pdf":
            return "doc.richtext"
        case "video/mp4":
            return "film"
        default:
            return "doc"
        }
    }

    private func formattedFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Previews

#Preview("Material List - Loaded") {
    NavigationStack {
        Text("Material List Preview")
            .navigationTitle("Materiales")
    }
}
