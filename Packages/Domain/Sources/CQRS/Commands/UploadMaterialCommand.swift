import Foundation
import EduCore

// MARK: - UploadMaterialCommand

/// Command para subir un material educativo al sistema.
///
/// Este command encapsula toda la información necesaria para subir
/// un archivo PDF y crear un material, con validaciones pesadas
/// pre-ejecución.
///
/// ## Validaciones
/// - Archivo existe en el sistema de archivos
/// - Tamaño del archivo no excede 50MB
/// - Tipo MIME es 'application/pdf'
/// - Título tiene longitud válida (3-200 caracteres)
/// - SubjectId y UnitId son UUIDs válidos
///
/// ## Eventos Emitidos
/// - `MaterialUploadedEvent`: Cuando la subida se completa exitosamente
/// - `MaterialListInvalidatedEvent`: Para invalidar cache de ListMaterialsQuery
///
/// ## Ejemplo de Uso
/// ```swift
/// let command = UploadMaterialCommand(
///     fileURL: localFileURL,
///     title: "Introducción al Cálculo",
///     subjectId: mathSubjectId,
///     unitId: universityUnitId,
///     description: "Material introductorio..."
/// )
///
/// let result = try await mediator.execute(command)
/// if result.isSuccess, let material = result.getValue() {
///     print("Material subido: \(material.id)")
///     print("Eventos: \(result.events)")
/// }
/// ```
public struct UploadMaterialCommand: Command {

    public typealias Result = Material

    // MARK: - Properties

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

    /// Metadata opcional para tracing
    public let metadata: [String: String]?

    // MARK: - Initialization

    /// Crea un nuevo command para subir material.
    ///
    /// - Parameters:
    ///   - fileURL: URL local del archivo PDF
    ///   - title: Título del material
    ///   - subjectId: ID de la materia
    ///   - unitId: ID de la unidad académica
    ///   - description: Descripción opcional
    ///   - metadata: Metadata opcional para tracing
    public init(
        fileURL: URL,
        title: String,
        subjectId: UUID,
        unitId: UUID,
        description: String? = nil,
        metadata: [String: String]? = nil
    ) {
        self.fileURL = fileURL
        self.title = title
        self.subjectId = subjectId
        self.unitId = unitId
        self.description = description
        self.metadata = metadata
    }

    // MARK: - Command Protocol

    /// Valida el command antes de la ejecución.
    ///
    /// Verifica que:
    /// - El archivo existe
    /// - El tamaño del archivo no excede el máximo (50MB)
    /// - El tipo MIME es PDF
    /// - El título tiene longitud válida (3-200 caracteres)
    ///
    /// - Throws: `ValidationError` si alguna validación falla
    public func validate() throws {
        // Validar título
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedTitle.count >= 3 && trimmedTitle.count <= 200 else {
            throw ValidationError.invalidLength(
                fieldName: "title",
                expected: "3-200 caracteres",
                actual: trimmedTitle.count
            )
        }

        // Validar existencia del archivo
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw ValidationError.fileNotFound(path: fileURL.path)
        }

        // Validar tamaño del archivo
        do {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            if let fileSize = attributes[.size] as? Int {
                let maxSize = 50 * 1024 * 1024 // 50MB
                guard fileSize <= maxSize else {
                    throw ValidationError.outOfRange(
                        fieldName: "fileSize",
                        min: nil,
                        max: maxSize,
                        actual: fileSize
                    )
                }
            }
        } catch let error as ValidationError {
            throw error
        } catch {
            throw ValidationError.invalidFormat(
                fieldName: "file",
                reason: "No se pudo leer el tamaño del archivo: \(error.localizedDescription)"
            )
        }

        // Validar tipo MIME (debe ser PDF)
        let pathExtension = fileURL.pathExtension.lowercased()
        guard pathExtension == "pdf" else {
            throw ValidationError.unsupportedType(
                fieldName: "file",
                type: pathExtension,
                supported: ["pdf"]
            )
        }
    }
}

// MARK: - UploadMaterialCommandHandler

/// Handler que procesa UploadMaterialCommand usando UploadMaterialUseCase.
///
/// Coordina el proceso de subida de material, gestiona el estado usando
/// UploadStateMachine (de Historia 2) y emite eventos de dominio.
///
/// ## Responsabilidades
/// 1. Ejecutar UploadMaterialUseCase internamente
/// 2. Trackear progreso usando UploadStateMachine (si está disponible)
/// 3. Emitir eventos de dominio (MaterialUploadedEvent)
/// 4. Invalidar cache de ListMaterialsQuery
/// 5. Envolver resultado en CommandResult
///
/// ## Integración con State Machine
/// Si se proporciona un UploadStateMachine, el handler lo utilizará
/// para trackear el progreso de la subida a través de sus estados.
///
/// ## Integración con Queries
/// Después de una subida exitosa, este handler invalida el cache de
/// `ListMaterialsQuery` para reflejar el nuevo material.
///
/// ## Ejemplo de Uso
/// ```swift
/// let handler = UploadMaterialCommandHandler(
///     useCase: uploadUseCase,
///     materialListHandler: listMaterialsHandler
/// )
/// try await mediator.registerCommandHandler(handler)
/// ```
public actor UploadMaterialCommandHandler: CommandHandler {

    public typealias CommandType = UploadMaterialCommand

    // MARK: - Dependencies

    private let useCase: any UploadMaterialUseCaseProtocol

    /// Handler de ListMaterialsQuery para invalidar cache
    private weak var materialListHandler: ListMaterialsQueryHandler?

    // MARK: - Initialization

    /// Crea un nuevo handler para UploadMaterialCommand.
    ///
    /// - Parameters:
    ///   - useCase: Use case que ejecuta la subida (inyectado via protocolo para DI)
    ///   - materialListHandler: Handler para invalidar cache de lista (opcional)
    public init(
        useCase: any UploadMaterialUseCaseProtocol,
        materialListHandler: ListMaterialsQueryHandler? = nil
    ) {
        self.useCase = useCase
        self.materialListHandler = materialListHandler
    }

    // MARK: - CommandHandler Protocol

    /// Procesa el command y retorna el resultado.
    ///
    /// - Parameter command: Command con datos del material a subir
    /// - Returns: CommandResult con Material y eventos emitidos
    /// - Throws: Error si falla la validación o la subida
    public func handle(_ command: UploadMaterialCommand) async throws -> CommandResult<Material> {
        // Nota: La validación ya se ejecutó en el Mediator antes de llamar a handle()

        // Crear input para el use case
        let input = UploadMaterialInput(
            fileURL: command.fileURL,
            title: command.title,
            subjectId: command.subjectId,
            unitId: command.unitId,
            description: command.description
        )

        // Ejecutar use case
        do {
            let material = try await useCase.execute(input: input)

            // Invalidar cache de ListMaterialsQuery
            await invalidateMaterialListCache(for: material.id)

            // Emitir eventos de dominio
            let events = [
                "MaterialUploadedEvent",
                "MaterialListInvalidatedEvent"
            ]

            // Crear metadata con información de la subida
            let metadata: [String: String] = [
                "materialId": material.id.uuidString,
                "title": material.title,
                "fileName": command.fileURL.lastPathComponent,
                "uploadedAt": ISO8601DateFormatter().string(from: Date())
            ]

            // Retornar resultado exitoso
            return .success(
                material,
                events: events,
                metadata: metadata
            )

        } catch let error as UploadMaterialError {
            // Convertir UploadMaterialError a CommandResult de fallo
            return .failure(
                error,
                metadata: [
                    "title": command.title,
                    "fileName": command.fileURL.lastPathComponent,
                    "errorType": String(describing: type(of: error))
                ]
            )
        } catch {
            // Error inesperado
            return .failure(
                error,
                metadata: [
                    "title": command.title,
                    "fileName": command.fileURL.lastPathComponent,
                    "errorDescription": error.localizedDescription
                ]
            )
        }
    }

    // MARK: - Progress Tracking

    /// Ejecuta la subida con tracking de progreso.
    ///
    /// Esta versión alternativa retorna un stream de progreso además del resultado.
    /// Útil para UIs que necesitan mostrar el progreso de la subida.
    ///
    /// - Parameter command: Command con datos del material
    /// - Returns: Tupla con CommandResult y AsyncStream de progreso
    public func handleWithProgress(
        _ command: UploadMaterialCommand
    ) async throws -> (result: CommandResult<Material>, progress: AsyncStream<UploadProgress>) {
        // Crear input
        let input = UploadMaterialInput(
            fileURL: command.fileURL,
            title: command.title,
            subjectId: command.subjectId,
            unitId: command.unitId,
            description: command.description
        )

        // Ejecutar use case con progress
        let (material, progressStream) = try await useCase.executeWithProgress(input: input)

        // Invalidar cache
        await invalidateMaterialListCache(for: material.id)

        // Crear resultado exitoso
        let events = [
            "MaterialUploadedEvent",
            "MaterialListInvalidatedEvent"
        ]

        let metadata: [String: String] = [
            "materialId": material.id.uuidString,
            "title": material.title,
            "fileName": command.fileURL.lastPathComponent,
            "uploadedAt": ISO8601DateFormatter().string(from: Date())
        ]

        let result = CommandResult.success(
            material,
            events: events,
            metadata: metadata
        )

        return (result, progressStream)
    }

    // MARK: - Cache Management

    /// Configura el handler de ListMaterials para invalidación de cache.
    ///
    /// - Parameter handler: Handler de ListMaterialsQuery
    public func setMaterialListHandler(_ handler: ListMaterialsQueryHandler) {
        self.materialListHandler = handler
    }

    /// Invalida el cache de la lista de materiales.
    private func invalidateMaterialListCache(for materialId: UUID) async {
        await materialListHandler?.invalidateCache(for: materialId)
    }
}
