import SwiftUI
import EduCore
import EduDomain
import EduNetwork

/// Detail view for an educational material showing metadata, AI summary,
/// extracted sections, and action buttons.
///
/// ## Features
/// - Material metadata (title, status, subject, grade, file size, dates)
/// - AI-generated summary with key points
/// - Extracted sections list with previews
/// - Download PDF button
/// - "Create exam with AI" button (coming soon)
///
/// ## Data Loading
/// Uses injected async closures to load summary, sections, and download URL.
/// This keeps the view decoupled from the Infrastructure layer.
///
/// ## Example
/// ```swift
/// MaterialDetailView(
///     material: material,
///     loadSummary: { try await repository.getSummary(materialId: material.id.uuidString) },
///     loadSections: { try await repository.getSections(materialId: material.id.uuidString) },
///     loadDownloadURL: { try await repository.getDownloadURL(materialId: material.id.uuidString) }
/// )
/// ```
@available(iOS 26.0, macOS 26.0, *)
@MainActor
public struct MaterialDetailView: View {

    // MARK: - Properties

    private let material: EduCore.Material
    private let loadSummary: @Sendable () async throws -> MaterialSummaryDTO
    private let loadSections: @Sendable () async throws -> MaterialSectionsDTO
    private let loadDownloadURL: @Sendable () async throws -> PresignedURLDTO

    @State private var summary: MaterialSummaryDTO?
    @State private var sections: [SectionDTO] = []
    @State private var isLoadingSummary = true
    @State private var isLoadingSections = true
    @State private var isDownloading = false
    @State private var errorMessage: String?

    // MARK: - Initialization

    /// Creates the material detail view.
    ///
    /// - Parameters:
    ///   - material: The material to display.
    ///   - loadSummary: Async closure that loads the AI summary.
    ///   - loadSections: Async closure that loads the extracted sections.
    ///   - loadDownloadURL: Async closure that loads the presigned download URL.
    public init(
        material: EduCore.Material,
        loadSummary: @escaping @Sendable () async throws -> MaterialSummaryDTO,
        loadSections: @escaping @Sendable () async throws -> MaterialSectionsDTO,
        loadDownloadURL: @escaping @Sendable () async throws -> PresignedURLDTO
    ) {
        self.material = material
        self.loadSummary = loadSummary
        self.loadSections = loadSections
        self.loadDownloadURL = loadDownloadURL
    }

    // MARK: - Body

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.large) {
                materialHeader
                metadataSection

                if material.isReady {
                    summarySection
                    sectionsSection
                }

                actionButtons
            }
            .padding()
        }
        .navigationTitle(material.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .task {
            await loadData()
        }
        .alert(
            "Error",
            isPresented: .constant(errorMessage != nil),
            presenting: errorMessage
        ) { _ in
            Button("Aceptar") { errorMessage = nil }
        } message: { message in
            Text(message)
        }
    }

    // MARK: - Header

    private var materialHeader: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            HStack {
                Text(material.title)
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                StatusBadge(text: statusText, color: statusColor)
            }

            if let description = material.description, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Metadata

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            Text("Detalles")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: DesignTokens.Spacing.small) {
                if let subject = material.subject {
                    metadataItem(icon: "book", label: "Materia", value: subject)
                }
                if let grade = material.grade {
                    metadataItem(icon: "graduationcap", label: "Grado", value: grade)
                }
                if let fileType = material.fileType {
                    metadataItem(icon: "doc", label: "Tipo", value: fileTypeLabel(fileType))
                }
                if let sizeBytes = material.fileSizeBytes {
                    metadataItem(icon: "internaldrive", label: "Tamano", value: formattedFileSize(sizeBytes))
                }

                metadataItem(icon: "calendar", label: "Creado", value: material.createdAt.formatted(date: .abbreviated, time: .omitted))

                if let wordCount = summary?.wordCount {
                    metadataItem(icon: "text.word.spacing", label: "Palabras", value: "\(wordCount)")
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
    }

    private func metadataItem(icon: String, label: String, value: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.small) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .lineLimit(1)
            }

            Spacer()
        }
    }

    // MARK: - Summary Section

    @ViewBuilder
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            Text("Resumen")
                .font(.headline)

            if isLoadingSummary {
                HStack {
                    ProgressView()
                        .padding(.trailing, DesignTokens.Spacing.small)
                    Text("Cargando resumen...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
            } else if let summary {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
                    Text(summary.summary)
                        .font(.body)

                    if !summary.keyPoints.isEmpty {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                            Text("Puntos clave")
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            ForEach(Array(summary.keyPoints.enumerated()), id: \.offset) { _, point in
                                HStack(alignment: .top, spacing: DesignTokens.Spacing.small) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                    Text(point)
                                        .font(.subheadline)
                                }
                            }
                        }
                    }

                    HStack(spacing: DesignTokens.Spacing.medium) {
                        Label(summary.language, systemImage: "globe")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Label("\(summary.wordCount) palabras", systemImage: "text.word.spacing")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
            }
        }
    }

    // MARK: - Sections Section

    @ViewBuilder
    private var sectionsSection: some View {
        if isLoadingSections && sections.isEmpty {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                Text("Secciones")
                    .font(.headline)

                HStack {
                    ProgressView()
                        .padding(.trailing, DesignTokens.Spacing.small)
                    Text("Cargando secciones...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
        } else if !sections.isEmpty {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                Text("Secciones (\(sections.count))")
                    .font(.headline)

                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        HStack {
                            Text("\(section.index).")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            Text(section.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }

                        Text(section.preview)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
                }
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: DesignTokens.Spacing.medium) {
            // Download button
            Button {
                Task { await downloadPDF() }
            } label: {
                HStack {
                    if isDownloading {
                        ProgressView()
                            .padding(.trailing, DesignTokens.Spacing.small)
                    }
                    Label(
                        isDownloading ? "Preparando descarga..." : "Descargar PDF",
                        systemImage: "arrow.down.circle.fill"
                    )
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!material.isReady || isDownloading)

            // AI exam button (coming soon)
            Button {
                // Future feature
            } label: {
                VStack(spacing: 4) {
                    Label("Crear examen con IA", systemImage: "sparkles")
                    Text("Proximamente")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(true)
        }
    }

    // MARK: - Data Loading

    private func loadData() async {
        async let summaryTask: Void = loadSummaryData()
        async let sectionsTask: Void = loadSectionsData()
        _ = await (summaryTask, sectionsTask)
    }

    private func loadSummaryData() async {
        guard material.isReady else {
            isLoadingSummary = false
            return
        }

        do {
            summary = try await loadSummary()
        } catch {
            // Summary might not be available yet
            print("Failed to load summary: \(error.localizedDescription)")
        }
        isLoadingSummary = false
    }

    private func loadSectionsData() async {
        guard material.isReady else {
            isLoadingSections = false
            return
        }

        do {
            let dto = try await loadSections()
            sections = dto.sections
        } catch {
            // Sections might not be available yet
            print("Failed to load sections: \(error.localizedDescription)")
        }
        isLoadingSections = false
    }

    private func downloadPDF() async {
        isDownloading = true
        defer { isDownloading = false }

        do {
            let dto = try await loadDownloadURL()
            guard let url = URL(string: dto.url) else {
                errorMessage = "URL de descarga invalida"
                return
            }

            #if os(iOS)
            await UIApplication.shared.open(url)
            #elseif os(macOS)
            NSWorkspace.shared.open(url)
            #endif
        } catch {
            errorMessage = "Error al obtener URL de descarga: \(error.localizedDescription)"
        }
    }

    // MARK: - Helpers

    private var statusText: String {
        switch material.status {
        case .uploaded: return "Subido"
        case .processing: return "Procesando"
        case .ready: return "Listo"
        case .failed: return "Error"
        }
    }

    private var statusColor: Color {
        switch material.status {
        case .uploaded: return .blue
        case .processing: return .orange
        case .ready: return .green
        case .failed: return .red
        }
    }

    private func fileTypeLabel(_ mimeType: String) -> String {
        switch mimeType {
        case "application/pdf": return "PDF"
        default: return mimeType.components(separatedBy: "/").last?.uppercased() ?? "Archivo"
        }
    }

    private func formattedFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Previews

#Preview("Material Detail") {
    Text("Detail Preview requires Material + data loaders")
}
