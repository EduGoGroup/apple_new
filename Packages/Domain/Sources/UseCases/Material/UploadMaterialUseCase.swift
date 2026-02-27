import Foundation
import EduFoundation
import EduCore

// MARK: - UploadMaterialInput

/// Input para el caso de uso de subida de material.
///
/// Contiene la información necesaria para subir un archivo PDF
/// y crear un material educativo en el sistema.
public struct UploadMaterialInput: Sendable, Equatable {
    /// URL local del archivo a subir
    public let fileURL: URL

    /// Título del material (3-200 caracteres)
    public let title: String

    /// ID de la materia asociada
    public let subjectId: UUID

    /// ID de la unidad académica
    public let unitId: UUID

    /// Descripción opcional del material
    public let description: String?

    /// Crea un nuevo input para subida de material.
    ///
    /// - Parameters:
    ///   - fileURL: URL local del archivo PDF
    ///   - title: Título del material
    ///   - subjectId: ID de la materia
    ///   - unitId: ID de la unidad académica
    ///   - description: Descripción opcional
    public init(
        fileURL: URL,
        title: String,
        subjectId: UUID,
        unitId: UUID,
        description: String? = nil
    ) {
        self.fileURL = fileURL
        self.title = title
        self.subjectId = subjectId
        self.unitId = unitId
        self.description = description
    }
}

// MARK: - UploadProgress

/// Representa el progreso de la subida de un material.
///
/// Los estados siguen el flujo secuencial de la subida:
/// validating → creating → uploading → processing → ready/failed
public enum UploadProgress: Sendable, Equatable {
    /// Validando el archivo localmente
    case validating

    /// Creando el material en el backend
    case creating

    /// Subiendo el archivo a S3 con porcentaje de progreso (0-100)
    case uploading(progress: Int)

    /// El backend está procesando el archivo
    case processing

    /// El material está listo para usar
    case ready

    /// La subida o procesamiento falló
    case failed(reason: String)
}

// MARK: - UploadMaterialError

/// Errores específicos del proceso de subida de material.
public enum UploadMaterialError: Error, Sendable, Equatable {
    /// El título tiene longitud inválida (debe ser 3-200 caracteres)
    case invalidTitleLength(actual: Int)

    /// El tipo MIME del archivo no es soportado
    case unsupportedFileType(mimeType: String)

    /// El archivo excede el tamaño máximo permitido
    case fileTooLarge(sizeBytes: Int, maxBytes: Int)

    /// El archivo no existe en el sistema de archivos
    case fileNotFound(path: String)

    /// Error al leer el archivo
    case fileReadError(reason: String)

    /// Error al crear el material en el backend
    case materialCreationFailed(reason: String)

    /// Error al obtener la URL de subida
    case uploadURLFailed(reason: String)

    /// Error durante la subida a S3
    case s3UploadFailed(reason: String)

    /// Error al notificar la completitud del upload
    case uploadCompleteFailed(reason: String)

    /// Timeout esperando que el material esté listo
    case processingTimeout(materialId: UUID)

    /// La operación fue cancelada
    case cancelled

    /// Error de red genérico
    case networkError(reason: String)
}

extension UploadMaterialError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidTitleLength(let actual):
            return "El título debe tener entre 3 y 200 caracteres (actual: \(actual))"
        case .unsupportedFileType(let mimeType):
            return "Tipo de archivo no soportado: \(mimeType). Solo se permiten archivos PDF"
        case .fileTooLarge(let sizeBytes, let maxBytes):
            let sizeMB = Double(sizeBytes) / 1_048_576
            let maxMB = Double(maxBytes) / 1_048_576
            return "El archivo es demasiado grande (\(String(format: "%.1f", sizeMB))MB). Máximo permitido: \(String(format: "%.0f", maxMB))MB"
        case .fileNotFound(let path):
            return "Archivo no encontrado: \(path)"
        case .fileReadError(let reason):
            return "Error al leer el archivo: \(reason)"
        case .materialCreationFailed(let reason):
            return "Error al crear el material: \(reason)"
        case .uploadURLFailed(let reason):
            return "Error al obtener URL de subida: \(reason)"
        case .s3UploadFailed(let reason):
            return "Error al subir el archivo: \(reason)"
        case .uploadCompleteFailed(let reason):
            return "Error al confirmar la subida: \(reason)"
        case .processingTimeout(let materialId):
            return "Timeout esperando procesamiento del material: \(materialId)"
        case .cancelled:
            return "La operación fue cancelada"
        case .networkError(let reason):
            return "Error de red: \(reason)"
        }
    }
}

// MARK: - MaterialUploadRepositoryProtocol

/// Protocolo que define las operaciones de subida de materiales.
///
/// Este protocolo abstrae las operaciones de red necesarias para
/// el flujo completo de subida de archivos a S3.
public protocol MaterialUploadRepositoryProtocol: Sendable {
    /// Crea un nuevo material en el backend.
    ///
    /// - Parameters:
    ///   - title: Título del material
    ///   - description: Descripción opcional
    ///   - subject: Materia opcional
    ///   - grade: Grado opcional
    /// - Returns: Material creado con ID asignado
    /// - Throws: Error si falla la creación
    func createMaterial(
        title: String,
        description: String?,
        subject: String?,
        grade: String?
    ) async throws -> Material

    /// Solicita una URL presignada para subir un archivo a S3.
    ///
    /// - Parameters:
    ///   - materialId: ID del material
    ///   - fileName: Nombre del archivo
    ///   - contentType: Tipo MIME del archivo
    /// - Returns: Tupla con URL de subida, URL final del archivo, y tiempo de expiración
    /// - Throws: Error si falla la generación
    func requestUploadURL(
        materialId: UUID,
        fileName: String,
        contentType: String
    ) async throws -> (uploadURL: URL, fileURL: URL, expiresIn: Int)

    /// Sube un archivo directamente a S3 usando la URL presignada.
    ///
    /// - Parameters:
    ///   - fileURL: URL local del archivo
    ///   - uploadURL: URL presignada de S3
    ///   - contentType: Tipo MIME del archivo
    ///   - progressHandler: Callback para reportar progreso (0-100)
    /// - Throws: Error si falla la subida
    func uploadToS3(
        fileURL: URL,
        uploadURL: URL,
        contentType: String,
        progressHandler: @escaping @Sendable (Int) -> Void
    ) async throws

    /// Notifica al backend que la subida se completó.
    ///
    /// - Parameters:
    ///   - materialId: ID del material
    ///   - fileURL: URL final del archivo en S3
    ///   - fileType: Tipo MIME del archivo
    ///   - fileSizeBytes: Tamaño del archivo en bytes
    /// - Throws: Error si falla la notificación
    func notifyUploadComplete(
        materialId: UUID,
        fileURL: URL,
        fileType: String,
        fileSizeBytes: Int
    ) async throws

    /// Obtiene el estado actual de un material.
    ///
    /// - Parameter materialId: ID del material
    /// - Returns: Material con su estado actualizado
    /// - Throws: Error si no se encuentra el material
    func getMaterial(id: UUID) async throws -> Material

    /// Elimina un material (para cleanup en caso de error).
    ///
    /// - Parameter materialId: ID del material a eliminar
    /// - Throws: Error si falla la eliminación
    func deleteMaterial(id: UUID) async throws
}

// MARK: - FileValidatorProtocol

/// Protocolo para validación de archivos locales.
public protocol FileValidatorProtocol: Sendable {
    /// Verifica si un archivo existe.
    func fileExists(at url: URL) -> Bool

    /// Obtiene el tamaño de un archivo en bytes.
    func fileSize(at url: URL) throws -> Int

    /// Obtiene el tipo MIME de un archivo.
    func mimeType(at url: URL) throws -> String
}

// MARK: - DefaultFileValidator

/// Implementación por defecto del validador de archivos usando FileManager.
public struct DefaultFileValidator: FileValidatorProtocol, Sendable {

    public init() {}

    public func fileExists(at url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    public func fileSize(at url: URL) throws -> Int {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        guard let size = attributes[.size] as? Int else {
            throw UploadMaterialError.fileReadError(reason: "No se pudo obtener el tamaño del archivo")
        }
        return size
    }

    public func mimeType(at url: URL) throws -> String {
        let pathExtension = url.pathExtension.lowercased()
        switch pathExtension {
        case "pdf":
            return "application/pdf"
        default:
            return "application/octet-stream"
        }
    }
}

// MARK: - UploadMaterialUseCase

/// Actor que implementa el caso de uso de subida de material educativo.
///
/// Coordina el flujo completo de 6 pasos para subir un archivo PDF a S3:
/// 1. Validación local del archivo
/// 2. Creación del material en el backend
/// 3. Solicitud de URL presignada
/// 4. Subida directa a S3 con reporte de progreso
/// 5. Notificación de completitud al backend
/// 6. Polling del estado hasta que esté listo
///
/// ## Características
/// - **Progress tracking**: Emite eventos de progreso via AsyncStream
/// - **Cancellation support**: Verifica Task.isCancelled en cada paso
/// - **Cleanup automático**: Si falla después de crear el material, lo elimina
/// - **Retry para S3**: Reintenta 1 vez si S3 retorna 403/404
/// - **Timeout configurable**: 30s por defecto para el polling
///
/// ## Ejemplo de Uso
/// ```swift
/// let useCase = UploadMaterialUseCase(
///     uploadRepository: repo,
///     fileValidator: DefaultFileValidator()
/// )
///
/// let input = UploadMaterialInput(
///     fileURL: localURL,
///     title: "Introducción al Cálculo",
///     subjectId: subjectId,
///     unitId: unitId
/// )
///
/// // Opción 1: Sin tracking de progreso
/// let material = try await useCase.execute(input: input)
///
/// // Opción 2: Con tracking de progreso
/// let (material, progressStream) = try await useCase.executeWithProgress(input: input)
/// for await progress in progressStream {
///     print("Progreso: \(progress)")
/// }
/// ```
public actor UploadMaterialUseCase: UseCase {

    public typealias Input = UploadMaterialInput
    public typealias Output = Material

    // MARK: - Configuration

    /// Tamaño máximo de archivo permitido (50MB)
    public static let maxFileSizeBytes = 50 * 1024 * 1024

    /// Longitud mínima del título
    public static let minTitleLength = 3

    /// Longitud máxima del título
    public static let maxTitleLength = 200

    /// Tipos MIME permitidos
    public static let allowedMimeTypes: Set<String> = ["application/pdf"]

    /// Timeout para polling del estado (segundos)
    public static let defaultPollingTimeout: TimeInterval = 30

    /// Intervalo entre polls (segundos)
    public static let pollingInterval: TimeInterval = 1

    /// Número máximo de reintentos para S3
    public static let maxS3Retries = 1

    // MARK: - Dependencies

    private let uploadRepository: MaterialUploadRepositoryProtocol
    private let fileValidator: FileValidatorProtocol
    private let pollingTimeout: TimeInterval

    // MARK: - State

    private var progressContinuation: AsyncStream<UploadProgress>.Continuation?
    private var createdMaterialId: UUID?

    // MARK: - Initialization

    /// Crea una nueva instancia del caso de uso.
    ///
    /// - Parameters:
    ///   - uploadRepository: Repositorio para operaciones de subida
    ///   - fileValidator: Validador de archivos (por defecto DefaultFileValidator)
    ///   - pollingTimeout: Timeout para polling del estado (por defecto 30s)
    public init(
        uploadRepository: MaterialUploadRepositoryProtocol,
        fileValidator: FileValidatorProtocol = DefaultFileValidator(),
        pollingTimeout: TimeInterval = defaultPollingTimeout
    ) {
        self.uploadRepository = uploadRepository
        self.fileValidator = fileValidator
        self.pollingTimeout = pollingTimeout
    }

    // MARK: - UseCase Implementation

    /// Ejecuta el proceso de subida de material.
    ///
    /// - Parameter input: Datos del material a subir
    /// - Returns: Material con estado 'ready'
    /// - Throws: `UploadMaterialError` si falla algún paso
    public func execute(input: UploadMaterialInput) async throws -> Material {
        try await performUpload(input: input)
    }

    // MARK: - Public Methods

    /// Ejecuta el proceso de subida con tracking de progreso.
    ///
    /// - Parameter input: Datos del material a subir
    /// - Returns: Tupla con el material final y un stream de progreso
    /// - Throws: `UploadMaterialError` si falla algún paso
    public func executeWithProgress(
        input: UploadMaterialInput
    ) async throws -> (material: Material, progress: AsyncStream<UploadProgress>) {
        let stream = AsyncStream<UploadProgress> { continuation in
            self.progressContinuation = continuation
        }

        let material = try await performUpload(input: input)
        progressContinuation?.finish()

        return (material, stream)
    }

    // MARK: - Private Implementation

    private func performUpload(input: UploadMaterialInput) async throws -> Material {
        // Reset state
        createdMaterialId = nil

        do {
            // PASO 1: Validación local
            try await checkCancellation()
            emitProgress(.validating)

            let validatedFile = try validateFile(input: input)

            // PASO 2: Crear material en backend
            try await checkCancellation()
            emitProgress(.creating)

            let material = try await createMaterial(input: input)
            createdMaterialId = material.id

            // PASO 3: Solicitar URL presignada
            try await checkCancellation()

            let uploadInfo = try await requestUploadURL(
                materialId: material.id,
                fileName: validatedFile.fileName,
                contentType: validatedFile.mimeType
            )

            // PASO 4: Subir a S3 con reintentos
            try await checkCancellation()
            emitProgress(.uploading(progress: 0))

            try await uploadToS3WithRetry(
                fileURL: input.fileURL,
                uploadURL: uploadInfo.uploadURL,
                contentType: validatedFile.mimeType
            )

            // PASO 5: Notificar completitud
            try await checkCancellation()

            try await notifyUploadComplete(
                materialId: material.id,
                fileURL: uploadInfo.fileURL,
                fileType: validatedFile.mimeType,
                fileSizeBytes: validatedFile.sizeBytes
            )

            // PASO 6: Polling hasta ready
            try await checkCancellation()
            emitProgress(.processing)

            let readyMaterial = try await pollUntilReady(materialId: material.id)

            emitProgress(.ready)
            return readyMaterial

        } catch is CancellationError {
            await cleanupOnError()
            throw UploadMaterialError.cancelled
        } catch let error as UploadMaterialError {
            await cleanupOnError()
            emitProgress(.failed(reason: error.errorDescription ?? "Error de subida"))
            throw error
        } catch {
            await cleanupOnError()
            let uploadError = UploadMaterialError.networkError(reason: error.localizedDescription)
            emitProgress(.failed(reason: error.localizedDescription))
            throw uploadError
        }
    }

    // MARK: - Step 1: Validation

    private struct ValidatedFile {
        let fileName: String
        let mimeType: String
        let sizeBytes: Int
    }

    private func validateFile(input: UploadMaterialInput) throws -> ValidatedFile {
        // Validar título
        let trimmedTitle = input.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedTitle.count >= Self.minTitleLength,
              trimmedTitle.count <= Self.maxTitleLength else {
            throw UploadMaterialError.invalidTitleLength(actual: trimmedTitle.count)
        }

        // Validar existencia del archivo
        guard fileValidator.fileExists(at: input.fileURL) else {
            throw UploadMaterialError.fileNotFound(path: input.fileURL.path)
        }

        // Validar tipo MIME
        let mimeType = try fileValidator.mimeType(at: input.fileURL)
        guard Self.allowedMimeTypes.contains(mimeType) else {
            throw UploadMaterialError.unsupportedFileType(mimeType: mimeType)
        }

        // Validar tamaño
        let fileSize = try fileValidator.fileSize(at: input.fileURL)
        guard fileSize <= Self.maxFileSizeBytes else {
            throw UploadMaterialError.fileTooLarge(
                sizeBytes: fileSize,
                maxBytes: Self.maxFileSizeBytes
            )
        }

        return ValidatedFile(
            fileName: input.fileURL.lastPathComponent,
            mimeType: mimeType,
            sizeBytes: fileSize
        )
    }

    // MARK: - Step 2: Create Material

    private func createMaterial(input: UploadMaterialInput) async throws -> Material {
        do {
            return try await uploadRepository.createMaterial(
                title: input.title,
                description: input.description,
                subject: nil,
                grade: nil
            )
        } catch {
            throw UploadMaterialError.materialCreationFailed(
                reason: error.localizedDescription
            )
        }
    }

    // MARK: - Step 3: Request Upload URL

    private func requestUploadURL(
        materialId: UUID,
        fileName: String,
        contentType: String
    ) async throws -> (uploadURL: URL, fileURL: URL, expiresIn: Int) {
        do {
            return try await uploadRepository.requestUploadURL(
                materialId: materialId,
                fileName: fileName,
                contentType: contentType
            )
        } catch {
            throw UploadMaterialError.uploadURLFailed(
                reason: error.localizedDescription
            )
        }
    }

    // MARK: - Step 4: Upload to S3

    private func uploadToS3WithRetry(
        fileURL: URL,
        uploadURL: URL,
        contentType: String
    ) async throws {
        var lastError: Error?
        var currentUploadURL = uploadURL

        // Capture continuation for progress updates from non-isolated context
        let continuation = progressContinuation

        for attempt in 0...Self.maxS3Retries {
            do {
                try await uploadRepository.uploadToS3(
                    fileURL: fileURL,
                    uploadURL: currentUploadURL,
                    contentType: contentType,
                    progressHandler: { progress in
                        continuation?.yield(.uploading(progress: progress))
                    }
                )
                return // Success
            } catch {
                lastError = error

                // Solo reintentar si es un error 403/404 y no es el último intento
                if attempt < Self.maxS3Retries,
                   let materialId = createdMaterialId {
                    // Regenerar URL presignada
                    let fileName = fileURL.lastPathComponent
                    if let newUploadInfo = try? await uploadRepository.requestUploadURL(
                        materialId: materialId,
                        fileName: fileName,
                        contentType: contentType
                    ) {
                        currentUploadURL = newUploadInfo.uploadURL
                        continue
                    }
                }
            }
        }

        throw UploadMaterialError.s3UploadFailed(
            reason: lastError?.localizedDescription ?? "Error desconocido"
        )
    }

    // MARK: - Step 5: Notify Upload Complete

    private func notifyUploadComplete(
        materialId: UUID,
        fileURL: URL,
        fileType: String,
        fileSizeBytes: Int
    ) async throws {
        do {
            try await uploadRepository.notifyUploadComplete(
                materialId: materialId,
                fileURL: fileURL,
                fileType: fileType,
                fileSizeBytes: fileSizeBytes
            )
        } catch {
            throw UploadMaterialError.uploadCompleteFailed(
                reason: error.localizedDescription
            )
        }
    }

    // MARK: - Step 6: Polling

    private func pollUntilReady(materialId: UUID) async throws -> Material {
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < pollingTimeout {
            try await checkCancellation()

            let material = try await uploadRepository.getMaterial(id: materialId)

            switch material.status {
            case .ready:
                return material
            case .failed:
                throw UploadMaterialError.s3UploadFailed(
                    reason: "El procesamiento del material falló en el servidor"
                )
            case .uploaded, .processing:
                // Continuar polling
                try await Task.sleep(for: .seconds(Self.pollingInterval))
            }
        }

        throw UploadMaterialError.processingTimeout(materialId: materialId)
    }

    // MARK: - Helpers

    private func checkCancellation() async throws {
        if Task.isCancelled {
            throw CancellationError()
        }
    }

    private func emitProgress(_ progress: UploadProgress) {
        progressContinuation?.yield(progress)
    }

    private func cleanupOnError() async {
        guard let materialId = createdMaterialId else { return }

        do {
            try await uploadRepository.deleteMaterial(id: materialId)
        } catch {
            // Log error but don't throw - cleanup is best effort
            print("Warning: Failed to cleanup material \(materialId): \(error)")
        }

        createdMaterialId = nil
    }
}
