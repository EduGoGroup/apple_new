import SwiftUI
import UniformTypeIdentifiers
import EduDomain
import EduCore

/// View for uploading educational materials (PDFs) with file validation and progress tracking.
///
/// Uses the existing `MaterialUploadViewModel` which handles:
/// - File validation (extension, MIME, magic numbers, size)
/// - Upload via CQRS `UploadMaterialCommand`
/// - Progress tracking
/// - Error handling
///
/// ## Features
/// - File picker restricted to PDF files
/// - Real-time upload progress bar
/// - Form validation (title required, file selected)
/// - Success and error states
///
/// ## Example
/// ```swift
/// MaterialUploadView(
///     viewModel: materialUploadViewModel,
///     subjectId: selectedSubjectId,
///     unitId: selectedUnitId
/// )
/// ```
@available(iOS 26.0, macOS 26.0, *)
@MainActor
public struct MaterialUploadView: View {

    // MARK: - Properties

    @Bindable private var viewModel: MaterialUploadViewModel
    @State private var showFilePicker = false
    @State private var title: String = ""
    @State private var description: String = ""
    @Environment(\.dismiss) private var dismiss

    /// Subject ID for the material upload.
    private let subjectId: UUID

    /// Unit ID for the material upload.
    private let unitId: UUID

    // MARK: - Initialization

    /// Creates the material upload view.
    ///
    /// - Parameters:
    ///   - viewModel: ViewModel managing the upload state.
    ///   - subjectId: ID of the subject to associate with the material.
    ///   - unitId: ID of the academic unit.
    public init(
        viewModel: MaterialUploadViewModel,
        subjectId: UUID,
        unitId: UUID
    ) {
        self.viewModel = viewModel
        self.subjectId = subjectId
        self.unitId = unitId
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            Form {
                materialInfoSection
                fileSection
                progressSection
                uploadButtonSection
            }
            .navigationTitle("Subir Material")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        viewModel.reset()
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.pdf]
            ) { result in
                handleFileSelection(result)
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
            .onChange(of: viewModel.isUploadSuccessful) { _, isSuccess in
                if isSuccess {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Sections

    private var materialInfoSection: some View {
        Section("Informacion del material") {
            TextField("Titulo", text: $title)
                .textContentType(.name)

            TextField("Descripcion (opcional)", text: $description, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    private var fileSection: some View {
        Section("Archivo") {
            Button {
                showFilePicker = true
            } label: {
                Label(
                    viewModel.selectedFileName ?? "Seleccionar PDF",
                    systemImage: "doc.badge.plus"
                )
            }
            .tint(.primary)

            if let fileName = viewModel.selectedFileName {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(fileName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if let validationError = viewModel.fileValidationError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(validationError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Text("Formatos: \(viewModel.allowedExtensionsDescription). Max: \(viewModel.maxFileSizeDescription)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var progressSection: some View {
        if viewModel.isUploading {
            Section("Progreso") {
                ProgressView(value: viewModel.uploadProgress)
                    .progressViewStyle(.linear)

                Text("Subiendo... \(viewModel.progressPercentage)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var uploadButtonSection: some View {
        Section {
            Button {
                Task {
                    await viewModel.uploadMaterial(
                        title: title,
                        description: description.isEmpty ? nil : description,
                        subjectId: subjectId,
                        unitId: unitId
                    )
                }
            } label: {
                HStack {
                    Spacer()
                    if viewModel.isUploading {
                        ProgressView()
                            .padding(.trailing, DesignTokens.Spacing.small)
                        Text("Subiendo...")
                    } else {
                        Label("Subir material", systemImage: "arrow.up.circle.fill")
                    }
                    Spacer()
                }
            }
            .disabled(isUploadDisabled)
        }
    }

    // MARK: - Computed Properties

    private var isUploadDisabled: Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedTitle.count < 3
            || !viewModel.hasSelectedFile
            || viewModel.isUploading
            || viewModel.hasFileValidationError
    }

    // MARK: - File Handling

    private func handleFileSelection(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }

            // Copy to temp directory to avoid security scope issues
            let tempDir = FileManager.default.temporaryDirectory
            let tempURL = tempDir.appending(path: url.lastPathComponent)

            // Remove existing temp file if any
            try? FileManager.default.removeItem(at: tempURL)

            do {
                try FileManager.default.copyItem(at: url, to: tempURL)
                let _ = viewModel.validateFile(tempURL)
            } catch {
                viewModel.clearFileValidationError()
            }

        case .failure:
            // User cancelled or file picker error — no action needed
            break
        }
    }
}

// MARK: - Previews

#Preview("Material Upload") {
    Text("Upload Preview requires ViewModel")
}
