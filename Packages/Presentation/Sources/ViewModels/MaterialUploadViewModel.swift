import Foundation
import OSLog
import SwiftUI
import EduDomain
import EduCore
import EduFoundation

/// ViewModel para gestionar la carga de materiales educativos usando CQRS Mediator.
///
/// Este ViewModel gestiona la subida de archivos con validación previa,
/// progreso de carga en tiempo real y manejo de errores específicos.
///
/// ## Responsabilidades
/// - Validar archivos antes de la subida (extensión, tamaño)
/// - Ejecutar UploadMaterialCommand via Mediator
/// - Gestionar progreso de carga en tiempo real
/// - Publicar MaterialUploadedEvent después de subida exitosa
///
/// ## Integración con CQRS
/// - **Commands**: UploadMaterialCommand (con validación pre-ejecución)
/// - **Events**: MaterialUploadedEvent (publicado automáticamente por handler)
///
/// ## Validaciones
/// - Extensiones permitidas: pdf, docx, pptx, mp4
/// - Tamaño máximo: 50MB
///
/// ## Ejemplo de uso
/// ```swift
/// @StateObject private var viewModel = MaterialUploadViewModel(
///     mediator: mediator,
///     eventBus: eventBus
/// )
///
/// // Validar archivo seleccionado
/// if viewModel.validateFile(selectedFileURL) {
///     await viewModel.uploadMaterial(
///         title: "Introducción",
///         description: "Material introductorio",
///         subjectId: subjectId,
///         unitId: unitId
///     )
/// }
/// ```
@MainActor
@Observable
public final class MaterialUploadViewModel {

    // MARK: - Published State

    /// Progreso de la carga (0.0 - 1.0)
    public var uploadProgress: Double = 0.0

    /// Indica si está subiendo un archivo
    public var isUploading: Bool = false

    /// Error actual si lo hay
    public var error: Error?

    /// Material subido exitosamente
    public var uploadedMaterial: EduCore.Material?

    // MARK: - Validation State

    /// Archivo seleccionado para subir
    public var selectedFile: URL?

    /// Error de validación del archivo
    public var fileValidationError: String?

    // MARK: - Dependencies

    /// Mediator CQRS para dispatch de commands
    private let mediator: Mediator

    /// EventBus para suscripción a eventos
    private let eventBus: EventBus

    /// IDs de suscripciones a eventos (para cleanup)
    private var subscriptionIds: [UUID] = []

    /// Logger para debugging y monitoreo
    private let logger = Logger(subsystem: "com.edugo.viewmodels", category: "MaterialUpload")

    // MARK: - Constants

    /// Tamaño máximo de archivo en bytes (50MB)
    private let maxFileSize: Int = 50 * 1024 * 1024

    /// Extensiones de archivo permitidas
    private let allowedExtensions: Set<String> = ["pdf", "docx", "pptx", "mp4"]

    /// Directorios base permitidos para archivos de usuario
    private let allowedBaseDirectories: [URL] = [
        FileManager.default.temporaryDirectory,
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!,
        FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
    ]

    // MARK: - Rate Limiting

    /// Timestamp de la última llamada a uploadMaterial para throttling
    private var lastUploadAttempt: Date?

    /// Intervalo mínimo entre intentos de subida (en segundos)
    private let minimumUploadInterval: TimeInterval = 0.5

    /// Timeout recomendado para operaciones de subida (en segundos)
    private let uploadTimeout: TimeInterval = 60.0

    // MARK: - Initialization

    /// Crea un nuevo MaterialUploadViewModel.
    ///
    /// - Parameters:
    ///   - mediator: Mediator CQRS para ejecutar commands
    ///   - eventBus: EventBus para suscribirse a eventos de dominio
    public init(
        mediator: Mediator,
        eventBus: EventBus
    ) {
        self.mediator = mediator
        self.eventBus = eventBus
    }

    // MARK: - Deinitialization

    /// Limpia recursos al destruir el ViewModel
    deinit {
        logger.debug("MaterialUploadViewModel deinicializado - recursos limpiados")
    }

    // MARK: - Public Methods

    /// Valida un archivo antes de la subida.
    ///
    /// Implementa validación multi-capa contra extension spoofing:
    /// 1. Validación de extensión
    /// 2. Validación de MIME type
    /// 3. Validación de file signatures (magic numbers)
    /// 4. Validación de tamaño
    ///
    /// - Parameter fileURL: URL del archivo a validar
    /// - Returns: `true` si el archivo es válido, `false` en caso contrario
    public func validateFile(_ fileURL: URL) -> Bool {
        // SEGURIDAD: Verificar que el archivo esté en directorio permitido (previene path traversal)
        guard isFileInAllowedDirectory(fileURL) else {
            fileValidationError = "El archivo no está en un directorio permitido"
            return false
        }

        // 1. Validar extensión (primera capa)
        let ext = fileURL.pathExtension.lowercased()
        guard allowedExtensions.contains(ext) else {
            fileValidationError = "Tipo de archivo no permitido. Use: \(allowedExtensions.joined(separator: ", "))"
            return false
        }

        // 2. Validar MIME type (segunda capa)
        guard let mimeType = getMimeType(for: fileURL) else {
            fileValidationError = "No se pudo determinar el tipo de archivo"
            return false
        }

        let allowedMimeTypes: Set<String> = [
            "application/pdf",
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            "application/vnd.openxmlformats-officedocument.presentationml.presentation",
            "video/mp4"
        ]

        guard allowedMimeTypes.contains(mimeType) else {
            fileValidationError = "El tipo de archivo (\(mimeType)) no es válido"
            return false
        }

        // 3. Validar file headers/magic numbers (tercera capa)
        guard validateFileSignature(fileURL, expectedExtension: ext) else {
            fileValidationError = "El contenido del archivo no coincide con su extensión"
            return false
        }

        // Validar tamaño
        guard let fileSize = try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int,
              fileSize <= maxFileSize else {
            fileValidationError = "El archivo excede el tamaño máximo de 50MB"
            return false
        }

        selectedFile = fileURL
        fileValidationError = nil
        return true
    }

    // MARK: - File Validation Helpers

    /// Obtiene el MIME type del archivo usando URLResourceValues
    private func getMimeType(for url: URL) -> String? {
        guard let resourceValues = try? url.resourceValues(forKeys: [.contentTypeKey]),
              let utType = resourceValues.contentType else {
            return nil
        }
        return utType.preferredMIMEType
    }

    /// Valida la firma del archivo (magic numbers) comparando con la extensión esperada
    private func validateFileSignature(_ fileURL: URL, expectedExtension: String) -> Bool {
        guard let fileHandle = try? FileHandle(forReadingFrom: fileURL),
              let headerData = try? fileHandle.read(upToCount: 8) else {
            return false
        }

        let bytes = [UInt8](headerData)

        switch expectedExtension {
        case "pdf":
            // PDF magic number: %PDF (0x25 0x50 0x44 0x46)
            return bytes.count >= 4 && bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46
        case "docx", "pptx":
            // ZIP-based formats (docx, pptx) start with PK (0x50 0x4B)
            return bytes.count >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4B
        case "mp4":
            // MP4 has 'ftyp' at offset 4-8
            return bytes.count >= 8 &&
                   bytes[4] == 0x66 && bytes[5] == 0x74 &&
                   bytes[6] == 0x79 && bytes[7] == 0x70
        default:
            return false
        }
    }

    /// Valida que el archivo esté en un directorio permitido
    /// - Parameter fileURL: URL del archivo a validar
    /// - Returns: true si el archivo está en un directorio permitido
    /// - Note: Previene path traversal attacks usando canonicalización de paths
    private func isFileInAllowedDirectory(_ fileURL: URL) -> Bool {
        // Canonicalizar el path (resuelve symlinks, ., ..)
        let canonicalURL = fileURL.standardizedFileURL.resolvingSymlinksInPath()

        // Verificar que esté dentro de algún directorio permitido
        return allowedBaseDirectories.contains { allowedBase in
            let canonicalBase = allowedBase.standardizedFileURL.resolvingSymlinksInPath()
            return canonicalURL.path.hasPrefix(canonicalBase.path)
        }
    }

    /// Sube un material educativo.
    ///
    /// Crea un UploadMaterialCommand y lo ejecuta via Mediator.
    /// El progreso se actualiza en tiempo real si el handler lo soporta.
    ///
    /// - Parameters:
    ///   - title: Título del material (3-200 caracteres)
    ///   - description: Descripción opcional del material
    ///   - subjectId: ID de la materia asociada
    ///   - unitId: ID de la unidad académica
    public func uploadMaterial(
        title: String,
        description: String?,
        subjectId: UUID,
        unitId: UUID
    ) async {
        // SEGURIDAD: Prevenir race conditions - validar que no haya operación en progreso
        guard !isUploading else {
            logger.warning("Intento de subir material mientras ya hay una subida en progreso")
            return
        }

        // SEGURIDAD: Rate limiting - prevenir llamadas muy rápidas (throttling)
        let now = Date()
        if let lastAttempt = self.lastUploadAttempt {
            let timeSinceLastAttempt = now.timeIntervalSince(lastAttempt)
            if timeSinceLastAttempt < self.minimumUploadInterval {
                logger.warning("Intento de subida demasiado rápido. Esperando \(self.minimumUploadInterval - timeSinceLastAttempt)s")
                return
            }
        }
        self.lastUploadAttempt = now

        guard let fileURL = selectedFile else {
            error = ValidationError.emptyField(fieldName: "file")
            return
        }

        // VALIDACIÓN: Verificar título no esté vacío
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            error = ValidationError.emptyField(fieldName: "title")
            return
        }

        // VALIDACIÓN: Verificar longitud del título (3-200 caracteres según documentación)
        guard trimmedTitle.count >= 3 else {
            error = ValidationError.outOfRange(
                fieldName: "title",
                min: 3,
                max: 200,
                actual: trimmedTitle.count
            )
            return
        }

        guard trimmedTitle.count <= 200 else {
            error = ValidationError.outOfRange(
                fieldName: "title",
                min: 3,
                max: 200,
                actual: trimmedTitle.count
            )
            return
        }

        // VALIDACIÓN: Verificar longitud de descripción si existe (máximo 1000 caracteres)
        let trimmedDescription: String?
        if let desc = description {
            let trimmed = desc.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.count <= 1000 else {
                error = ValidationError.outOfRange(
                    fieldName: "description",
                    min: nil,
                    max: 1000,
                    actual: trimmed.count
                )
                return
            }
            trimmedDescription = trimmed.isEmpty ? nil : trimmed
        } else {
            trimmedDescription = nil
        }

        isUploading = true
        uploadProgress = 0.0
        error = nil

        // PERFORMANCE: Tracking de tiempo para detectar operaciones lentas
        let startTime = Date()
        logger.info("Iniciando subida de material: \(trimmedTitle)")

        do {
            // Crear command con datos del material validados y limpios
            let command = UploadMaterialCommand(
                fileURL: fileURL,
                title: trimmedTitle,
                subjectId: subjectId,
                unitId: unitId,
                description: trimmedDescription,
                metadata: [
                    "source": "MaterialUploadViewModel",
                    "timestamp": ISO8601DateFormatter().string(from: Date())
                ]
            )

            // Ejecutar command via Mediator (con validación automática)
            let result = try await mediator.execute(command)

            // Verificar resultado del command
            if result.isSuccess, let material = result.getValue() {
                // Subida exitosa
                self.uploadedMaterial = material
                self.uploadProgress = 1.0
                self.isUploading = false

                // PERFORMANCE: Log del tiempo total de subida
                let duration = Date().timeIntervalSince(startTime)
                logger.info("Material subido exitosamente: \(material.id) en \(String(format: "%.2f", duration))s")
                logger.debug("Eventos publicados: \(result.events)")

                if duration > self.uploadTimeout {
                    logger.warning("⚠️ Subida excedió el timeout recomendado de \(self.uploadTimeout)s (tomó \(String(format: "%.2f", duration))s)")
                }

            } else if let resultError = result.getError() {
                // Subida falló
                self.error = resultError
                self.isUploading = false

                logger.error("Error al subir material: \(resultError.localizedDescription)")
            }

        } catch {
            // Manejar errores de validación o ejecución
            self.error = error
            self.isUploading = false

            print("❌ Error en uploadMaterial: \(error.localizedDescription)")
        }
    }

    /// Limpia el estado del ViewModel para una nueva carga.
    public func reset() {
        selectedFile = nil
        uploadProgress = 0.0
        isUploading = false
        error = nil
        uploadedMaterial = nil
        fileValidationError = nil
    }

    /// Limpia el error actual.
    public func clearError() {
        error = nil
    }

    /// Limpia el error de validación de archivo.
    public func clearFileValidationError() {
        fileValidationError = nil
    }
}

// MARK: - Convenience Computed Properties

extension MaterialUploadViewModel {
    /// Indica si hay un archivo seleccionado
    public var hasSelectedFile: Bool {
        selectedFile != nil
    }

    /// Indica si hay un error
    public var hasError: Bool {
        error != nil
    }

    /// Indica si hay un error de validación de archivo
    public var hasFileValidationError: Bool {
        fileValidationError != nil
    }

    /// Indica si la subida fue exitosa
    public var isUploadSuccessful: Bool {
        uploadedMaterial != nil
    }

    /// Nombre del archivo seleccionado
    public var selectedFileName: String? {
        selectedFile?.lastPathComponent
    }

    /// Extensión del archivo seleccionado
    public var selectedFileExtension: String? {
        selectedFile?.pathExtension.lowercased()
    }

    /// Indica si el formulario es válido para enviar
    public var isFormValid: Bool {
        selectedFile != nil && fileValidationError == nil
    }

    /// Indica si el botón de subir debe estar deshabilitado
    public var isUploadButtonDisabled: Bool {
        isUploading || !isFormValid
    }

    /// Mensaje de error legible
    public var errorMessage: String? {
        guard let error = error else { return nil }

        // Personalizar mensajes según tipo de error
        if let validationError = error as? ValidationError {
            return validationError.localizedDescription
        }

        if let mediatorError = error as? MediatorError {
            switch mediatorError {
            case .handlerNotFound:
                return "Error de configuración del sistema. Contacte soporte."
            case .validationError(let message, _):
                return message
            case .executionError(let message, _):
                return "Error al subir: \(message)"
            case .registrationError:
                return "Error de configuración del sistema."
            }
        }

        return error.localizedDescription
    }

    /// Porcentaje de progreso formateado
    public var progressPercentage: String {
        let percentage = Int(uploadProgress * 100)
        return "\(percentage)%"
    }

    /// Lista de extensiones permitidas para mostrar al usuario
    public var allowedExtensionsDescription: String {
        allowedExtensions.sorted().joined(separator: ", ")
    }

    /// Tamaño máximo formateado para mostrar al usuario
    public var maxFileSizeDescription: String {
        let sizeMB = maxFileSize / (1024 * 1024)
        return "\(sizeMB)MB"
    }
}
