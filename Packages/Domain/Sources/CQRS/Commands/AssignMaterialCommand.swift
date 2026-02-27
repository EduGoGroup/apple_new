import Foundation

// MARK: - AssignMaterialCommand

/// Command para asignar un material a una unidad académica.
///
/// Este command encapsula los datos necesarios para asignar un material
/// educativo a una unidad, con validaciones pre-ejecución.
///
/// ## Validaciones
/// - MaterialId no puede ser nil
/// - UnitId no puede ser nil
/// - AssignedBy (userId) no puede ser nil
/// - DueDate debe ser futura (si se proporciona)
///
/// ## Eventos Emitidos
/// - `MaterialAssignedEvent`: Cuando la asignación se completa exitosamente
/// - `MaterialListInvalidatedEvent`: Para invalidar cache de materiales de la unidad
///
/// ## Ejemplo de Uso
/// ```swift
/// let command = AssignMaterialCommand(
///     materialId: materialId,
///     unitId: unitId,
///     assignedBy: teacherId,
///     dueDate: nextWeek,
///     visible: true,
///     notifyStudents: true
/// )
///
/// let result = try await mediator.execute(command)
/// if result.isSuccess, let assignment = result.getValue() {
///     print("Asignado: \(assignment.material.title)")
///     print("Eventos: \(result.events)")
/// }
/// ```
public struct AssignMaterialCommand: Command {

    public typealias Result = MaterialAssignment

    // MARK: - Properties

    /// ID del material a asignar
    public let materialId: UUID

    /// ID de la unidad académica destino
    public let unitId: UUID

    /// ID del usuario que realiza la asignación (profesor/admin)
    public let assignedBy: UUID

    /// Fecha límite opcional para la asignación
    public let dueDate: Date?

    /// Si el material es visible para los estudiantes
    public let visible: Bool

    /// Si se debe notificar a los estudiantes
    public let notifyStudents: Bool

    /// Metadata opcional para tracing
    public let metadata: [String: String]?

    // MARK: - Initialization

    /// Crea un nuevo command para asignar material.
    ///
    /// - Parameters:
    ///   - materialId: ID del material a asignar
    ///   - unitId: ID de la unidad destino
    ///   - assignedBy: ID del usuario que asigna
    ///   - dueDate: Fecha límite opcional
    ///   - visible: Si es visible (default: true)
    ///   - notifyStudents: Si notificar (default: true)
    ///   - metadata: Metadata opcional
    public init(
        materialId: UUID,
        unitId: UUID,
        assignedBy: UUID,
        dueDate: Date? = nil,
        visible: Bool = true,
        notifyStudents: Bool = true,
        metadata: [String: String]? = nil
    ) {
        self.materialId = materialId
        self.unitId = unitId
        self.assignedBy = assignedBy
        self.dueDate = dueDate
        self.visible = visible
        self.notifyStudents = notifyStudents
        self.metadata = metadata
    }

    // MARK: - Command Protocol

    /// Valida el command antes de la ejecución.
    ///
    /// Verifica que:
    /// - La fecha límite, si existe, sea futura
    ///
    /// - Throws: `ValidationError` si alguna validación falla
    public func validate() throws {
        // Validar fecha límite si existe
        if let dueDate = dueDate {
            guard dueDate > Date() else {
                throw ValidationError.outOfRange(
                    fieldName: "dueDate",
                    min: nil,
                    max: nil,
                    actual: Int(dueDate.timeIntervalSince1970)
                )
            }
        }
    }
}

// MARK: - AssignMaterialCommandHandler

/// Handler que procesa AssignMaterialCommand usando AssignMaterialToUnitUseCase.
///
/// Coordina el proceso de asignación de material, emite eventos de dominio
/// e invalida caches relacionados.
///
/// ## Responsabilidades
/// 1. Ejecutar AssignMaterialToUnitUseCase
/// 2. Emitir MaterialAssignedEvent
/// 3. Invalidar cache de MaterialListReadModel para la unidad
/// 4. Envolver resultado en CommandResult
///
/// ## Ejemplo de Uso
/// ```swift
/// let handler = AssignMaterialCommandHandler(
///     useCase: assignMaterialUseCase,
///     eventBus: eventBus,
///     materialListHandler: materialListQueryHandler
/// )
/// try await mediator.registerCommandHandler(handler)
/// ```
public actor AssignMaterialCommandHandler: CommandHandler {

    public typealias CommandType = AssignMaterialCommand

    // MARK: - Dependencies

    private let useCase: any AssignMaterialUseCaseProtocol

    /// EventBus para publicar eventos
    private let eventBus: EventBus?

    /// Handler de ListMaterialsQuery para invalidar cache
    private weak var materialListHandler: ListMaterialsQueryHandler?

    // MARK: - Initialization

    /// Crea un nuevo handler para AssignMaterialCommand.
    ///
    /// - Parameters:
    ///   - useCase: Use case que ejecuta la asignación
    ///   - eventBus: Bus de eventos para publicar (opcional)
    ///   - materialListHandler: Handler para invalidar cache (opcional)
    public init(
        useCase: any AssignMaterialUseCaseProtocol,
        eventBus: EventBus? = nil,
        materialListHandler: ListMaterialsQueryHandler? = nil
    ) {
        self.useCase = useCase
        self.eventBus = eventBus
        self.materialListHandler = materialListHandler
    }

    // MARK: - CommandHandler Protocol

    /// Procesa el command y retorna el resultado.
    ///
    /// - Parameter command: Command con datos de la asignación
    /// - Returns: CommandResult con MaterialAssignment y eventos emitidos
    /// - Throws: Error si falla la validación o la asignación
    public func handle(_ command: AssignMaterialCommand) async throws -> CommandResult<MaterialAssignment> {
        // Crear input para el use case
        let input = AssignMaterialInput(
            materialId: command.materialId,
            unitId: command.unitId,
            assignedBy: command.assignedBy,
            dueDate: command.dueDate,
            metadata: AssignmentMetadata(
                visible: command.visible,
                notifyStudents: command.notifyStudents
            )
        )

        // Ejecutar use case
        do {
            let assignment = try await useCase.execute(input: input)

            // Crear y publicar evento
            let event = MaterialAssignedEvent(
                assignmentId: assignment.id,
                materialId: assignment.material.id,
                materialTitle: assignment.material.title,
                unitId: assignment.unit.id,
                unitName: assignment.unit.name,
                assignedBy: assignment.assignedBy.id,
                dueDate: assignment.dueDate,
                isVisible: assignment.isVisible,
                wasAlreadyAssigned: assignment.wasAlreadyAssigned
            )

            // Publicar evento si hay eventBus
            if let eventBus = eventBus {
                await eventBus.publish(event)
            }

            // Invalidar cache de lista de materiales para esta unidad
            await materialListHandler?.invalidateCache()

            // Emitir eventos de dominio
            var events = ["MaterialAssignedEvent"]
            if !assignment.wasAlreadyAssigned {
                events.append("MaterialListInvalidatedEvent")
            }

            // Crear metadata del resultado
            let resultMetadata: [String: String] = [
                "assignmentId": assignment.id.uuidString,
                "materialId": assignment.material.id.uuidString,
                "unitId": assignment.unit.id.uuidString,
                "wasAlreadyAssigned": assignment.wasAlreadyAssigned ? "true" : "false",
                "assignedAt": ISO8601DateFormatter().string(from: assignment.assignedAt)
            ]

            return .success(
                assignment,
                events: events,
                metadata: resultMetadata
            )

        } catch let error as AssignMaterialError {
            return .failure(
                error,
                metadata: [
                    "materialId": command.materialId.uuidString,
                    "unitId": command.unitId.uuidString,
                    "errorType": String(describing: type(of: error))
                ]
            )
        } catch {
            return .failure(
                error,
                metadata: [
                    "materialId": command.materialId.uuidString,
                    "unitId": command.unitId.uuidString,
                    "errorDescription": error.localizedDescription
                ]
            )
        }
    }

    // MARK: - Configuration

    /// Configura el handler de materiales para invalidación de cache.
    public func setMaterialListHandler(_ handler: ListMaterialsQueryHandler) {
        self.materialListHandler = handler
    }
}
