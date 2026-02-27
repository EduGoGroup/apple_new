import Foundation
import EduFoundation
import EduCore

// MARK: - Input Types

/// Metadata para la asignación de material.
public struct AssignmentMetadata: Sendable, Equatable {
    /// Si el material es visible para estudiantes
    public let visible: Bool
    /// Si se debe notificar a los estudiantes
    public let notifyStudents: Bool

    public init(visible: Bool = true, notifyStudents: Bool = true) {
        self.visible = visible
        self.notifyStudents = notifyStudents
    }

    /// Metadata por defecto.
    public static let `default` = AssignmentMetadata()
}

/// Input para asignar un material a una unidad.
public struct AssignMaterialInput: Sendable, Equatable {
    /// ID del material a asignar
    public let materialId: UUID
    /// ID de la unidad académica
    public let unitId: UUID
    /// ID del usuario que asigna (profesor)
    public let assignedBy: UUID
    /// Fecha límite opcional
    public let dueDate: Date?
    /// Metadata de la asignación
    public let metadata: AssignmentMetadata

    public init(
        materialId: UUID,
        unitId: UUID,
        assignedBy: UUID,
        dueDate: Date? = nil,
        metadata: AssignmentMetadata = .default
    ) {
        self.materialId = materialId
        self.unitId = unitId
        self.assignedBy = assignedBy
        self.dueDate = dueDate
        self.metadata = metadata
    }
}

// MARK: - Output Types

/// Información simplificada del usuario que asignó.
public struct AssignerInfo: Sendable, Equatable, Codable {
    public let id: UUID
    public let fullName: String
    public let email: String

    public init(id: UUID, fullName: String, email: String) {
        self.id = id
        self.fullName = fullName
        self.email = email
    }
}

/// Información simplificada de la unidad.
public struct UnitInfo: Sendable, Equatable, Codable {
    public let id: UUID
    public let name: String
    public let schoolId: UUID

    public init(id: UUID, name: String, schoolId: UUID) {
        self.id = id
        self.name = name
        self.schoolId = schoolId
    }
}

/// Resultado de la asignación de material.
public struct MaterialAssignment: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let material: Material
    public let unit: UnitInfo
    public let assignedAt: Date
    public let dueDate: Date?
    public let assignedBy: AssignerInfo
    public let isVisible: Bool
    public let wasAlreadyAssigned: Bool

    public init(
        id: UUID,
        material: Material,
        unit: UnitInfo,
        assignedAt: Date,
        dueDate: Date?,
        assignedBy: AssignerInfo,
        isVisible: Bool,
        wasAlreadyAssigned: Bool = false
    ) {
        self.id = id
        self.material = material
        self.unit = unit
        self.assignedAt = assignedAt
        self.dueDate = dueDate
        self.assignedBy = assignedBy
        self.isVisible = isVisible
        self.wasAlreadyAssigned = wasAlreadyAssigned
    }
}

/// Resultado de las notificaciones.
public struct NotificationResult: Sendable, Equatable {
    public let totalStudents: Int
    public let successCount: Int
    public let failedCount: Int
    public let failures: [NotificationFailure]

    public init(
        totalStudents: Int,
        successCount: Int,
        failedCount: Int,
        failures: [NotificationFailure] = []
    ) {
        self.totalStudents = totalStudents
        self.successCount = successCount
        self.failedCount = failedCount
        self.failures = failures
    }

    public static let skipped = NotificationResult(
        totalStudents: 0,
        successCount: 0,
        failedCount: 0
    )
}

/// Fallo de notificación para retry.
public struct NotificationFailure: Sendable, Equatable {
    public let studentId: UUID
    public let error: String

    public init(studentId: UUID, error: String) {
        self.studentId = studentId
        self.error = error
    }
}

// MARK: - Errors

/// Errores específicos de asignación de material.
public enum AssignMaterialError: Error, Sendable, Equatable {
    case materialNotFound(UUID)
    case materialNotReady(UUID, currentStatus: String)
    case unitNotFound(UUID)
    case userNotFound(UUID)
    case insufficientPermissions(userId: UUID, unitId: UUID)
    case dueDateInPast(Date)
    case assignmentFailed(String)
}

extension AssignMaterialError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .materialNotFound(let id):
            return "Material no encontrado: \(id)"
        case .materialNotReady(let id, let status):
            return "Material \(id) no está listo (estado: \(status))"
        case .unitNotFound(let id):
            return "Unidad académica no encontrada: \(id)"
        case .userNotFound(let id):
            return "Usuario no encontrado: \(id)"
        case .insufficientPermissions(let userId, let unitId):
            return "Usuario \(userId) no tiene permisos en unidad \(unitId)"
        case .dueDateInPast(let date):
            return "La fecha límite debe ser futura: \(date)"
        case .assignmentFailed(let reason):
            return "Error al asignar material: \(reason)"
        }
    }
}

// MARK: - Repository Protocols

/// Protocolo del repositorio de materiales para asignación.
public protocol AssignMaterialsRepositoryProtocol: Sendable {
    /// Obtiene un material por ID.
    func get(id: UUID) async throws -> Material

    /// Crea una asignación de material a unidad.
    func createAssignment(
        materialId: UUID,
        unitId: UUID,
        assignedBy: UUID,
        dueDate: Date?,
        visible: Bool
    ) async throws -> MaterialAssignmentDTO

    /// Obtiene una asignación existente si existe.
    func getExistingAssignment(materialId: UUID, unitId: UUID) async -> MaterialAssignmentDTO?
}

/// DTO de asignación del repositorio.
public struct MaterialAssignmentDTO: Sendable, Equatable {
    public let id: UUID
    public let materialId: UUID
    public let unitId: UUID
    public let assignedBy: UUID
    public let assignedAt: Date
    public let dueDate: Date?
    public let visible: Bool

    public init(
        id: UUID,
        materialId: UUID,
        unitId: UUID,
        assignedBy: UUID,
        assignedAt: Date,
        dueDate: Date?,
        visible: Bool
    ) {
        self.id = id
        self.materialId = materialId
        self.unitId = unitId
        self.assignedBy = assignedBy
        self.assignedAt = assignedAt
        self.dueDate = dueDate
        self.visible = visible
    }
}

/// Protocolo del repositorio de unidades.
public protocol AssignUnitsRepositoryProtocol: Sendable {
    /// Obtiene una unidad por ID.
    func get(id: UUID) async throws -> UnitInfo

    /// Lista estudiantes de una unidad.
    func listStudents(unitId: UUID) async throws -> [UUID]
}

/// Protocolo del repositorio de memberships para verificar permisos.
public protocol AssignMembershipsRepositoryProtocol: Sendable {
    /// Verifica si un usuario tiene rol de teacher o admin en una unidad.
    func hasTeacherOrAdminRole(userId: UUID, unitId: UUID) async throws -> Bool

    /// Obtiene información del usuario.
    func getUserInfo(userId: UUID) async throws -> AssignerInfo
}

/// Protocolo del servicio de notificaciones.
public protocol NotificationServiceProtocol: Sendable {
    /// Envía notificación a un estudiante.
    func notifyStudent(
        studentId: UUID,
        materialTitle: String,
        unitName: String,
        dueDate: Date?
    ) async throws
}

// MARK: - AssignMaterialToUnitUseCase

/// Actor que coordina la asignación de un material a una unidad académica.
///
/// Implementa:
/// - Validación de permisos (teacher/admin)
/// - Validación de estado del material (must be 'ready')
/// - Validación de fecha límite (must be future)
/// - Idempotency (retorna existing si ya existe)
/// - Notificaciones paralelas a estudiantes
///
/// ## Ejemplo de Uso
/// ```swift
/// let useCase = AssignMaterialToUnitUseCase(
///     materialsRepository: materialsRepo,
///     unitsRepository: unitsRepo,
///     membershipsRepository: membershipsRepo,
///     notificationService: notificationService
/// )
///
/// let input = AssignMaterialInput(
///     materialId: materialId,
///     unitId: unitId,
///     assignedBy: teacherId,
///     dueDate: nextWeek,
///     metadata: AssignmentMetadata(visible: true, notifyStudents: true)
/// )
///
/// let assignment = try await useCase.execute(input: input)
/// print("Assigned: \(assignment.material.title) to \(assignment.unit.name)")
/// ```
public actor AssignMaterialToUnitUseCase: UseCase {

    public typealias Input = AssignMaterialInput
    public typealias Output = MaterialAssignment

    // MARK: - Dependencies

    private let materialsRepository: AssignMaterialsRepositoryProtocol
    private let unitsRepository: AssignUnitsRepositoryProtocol
    private let membershipsRepository: AssignMembershipsRepositoryProtocol
    private let notificationService: NotificationServiceProtocol?

    // MARK: - Configuration

    private let notificationTimeout: TimeInterval = 2.0

    // MARK: - State

    private var lastNotificationResult: NotificationResult?

    // MARK: - Initialization

    /// Crea una nueva instancia del caso de uso.
    ///
    /// - Parameters:
    ///   - materialsRepository: Repositorio de materiales
    ///   - unitsRepository: Repositorio de unidades
    ///   - membershipsRepository: Repositorio de memberships
    ///   - notificationService: Servicio de notificaciones (opcional)
    public init(
        materialsRepository: AssignMaterialsRepositoryProtocol,
        unitsRepository: AssignUnitsRepositoryProtocol,
        membershipsRepository: AssignMembershipsRepositoryProtocol,
        notificationService: NotificationServiceProtocol? = nil
    ) {
        self.materialsRepository = materialsRepository
        self.unitsRepository = unitsRepository
        self.membershipsRepository = membershipsRepository
        self.notificationService = notificationService
    }

    // MARK: - UseCase Implementation

    /// Ejecuta la asignación de material a unidad.
    ///
    /// - Parameter input: Datos de la asignación
    /// - Returns: Asignación creada o existente
    /// - Throws: AssignMaterialError si las validaciones fallan
    public func execute(input: AssignMaterialInput) async throws -> MaterialAssignment {
        // 1. Validar fecha límite si existe
        if let dueDate = input.dueDate, dueDate < Date() {
            throw AssignMaterialError.dueDateInPast(dueDate)
        }

        // 2. Verificar permisos del usuario
        let hasPermission = try await membershipsRepository.hasTeacherOrAdminRole(
            userId: input.assignedBy,
            unitId: input.unitId
        )

        guard hasPermission else {
            throw AssignMaterialError.insufficientPermissions(
                userId: input.assignedBy,
                unitId: input.unitId
            )
        }

        // 3. Verificar que el material existe y está listo
        let material: Material
        do {
            material = try await materialsRepository.get(id: input.materialId)
        } catch {
            throw AssignMaterialError.materialNotFound(input.materialId)
        }

        guard material.status == .ready else {
            throw AssignMaterialError.materialNotReady(
                input.materialId,
                currentStatus: material.status.rawValue
            )
        }

        // 4. Verificar que la unidad existe
        let unit: UnitInfo
        do {
            unit = try await unitsRepository.get(id: input.unitId)
        } catch {
            throw AssignMaterialError.unitNotFound(input.unitId)
        }

        // 5. Obtener información del usuario que asigna
        let assigner: AssignerInfo
        do {
            assigner = try await membershipsRepository.getUserInfo(userId: input.assignedBy)
        } catch {
            throw AssignMaterialError.userNotFound(input.assignedBy)
        }

        // 6. Verificar idempotency - si ya existe, retornar existente
        if let existing = await materialsRepository.getExistingAssignment(
            materialId: input.materialId,
            unitId: input.unitId
        ) {
            return MaterialAssignment(
                id: existing.id,
                material: material,
                unit: unit,
                assignedAt: existing.assignedAt,
                dueDate: existing.dueDate,
                assignedBy: assigner,
                isVisible: existing.visible,
                wasAlreadyAssigned: true
            )
        }

        // 7. Crear la asignación
        let assignmentDTO: MaterialAssignmentDTO
        do {
            assignmentDTO = try await materialsRepository.createAssignment(
                materialId: input.materialId,
                unitId: input.unitId,
                assignedBy: input.assignedBy,
                dueDate: input.dueDate,
                visible: input.metadata.visible
            )
        } catch {
            throw AssignMaterialError.assignmentFailed(error.localizedDescription)
        }

        // 8. Enviar notificaciones si está habilitado (no falla la operación)
        if input.metadata.notifyStudents, notificationService != nil {
            let notificationResult = await sendNotifications(
                material: material,
                unit: unit,
                dueDate: input.dueDate
            )
            lastNotificationResult = notificationResult
        } else {
            lastNotificationResult = .skipped
        }

        // 9. Retornar resultado
        return MaterialAssignment(
            id: assignmentDTO.id,
            material: material,
            unit: unit,
            assignedAt: assignmentDTO.assignedAt,
            dueDate: assignmentDTO.dueDate,
            assignedBy: assigner,
            isVisible: assignmentDTO.visible,
            wasAlreadyAssigned: false
        )
    }

    /// Obtiene el resultado de las últimas notificaciones enviadas.
    public var notificationResult: NotificationResult? {
        lastNotificationResult
    }

    // MARK: - Private Methods

    /// Envía notificaciones a todos los estudiantes de la unidad en paralelo.
    private func sendNotifications(
        material: Material,
        unit: UnitInfo,
        dueDate: Date?
    ) async -> NotificationResult {
        guard let service = notificationService else {
            return .skipped
        }

        // Obtener lista de estudiantes
        let students: [UUID]
        do {
            students = try await unitsRepository.listStudents(unitId: unit.id)
        } catch {
            return NotificationResult(
                totalStudents: 0,
                successCount: 0,
                failedCount: 0,
                failures: [NotificationFailure(studentId: UUID(), error: "Error listing students")]
            )
        }

        guard !students.isEmpty else {
            return NotificationResult(
                totalStudents: 0,
                successCount: 0,
                failedCount: 0
            )
        }

        // Enviar notificaciones en paralelo con TaskGroup
        return await withTaskGroup(of: (UUID, Bool, String?).self) { group in
            for studentId in students {
                group.addTask {
                    do {
                        try await self.withTimeout(seconds: self.notificationTimeout) {
                            try await service.notifyStudent(
                                studentId: studentId,
                                materialTitle: material.title,
                                unitName: unit.name,
                                dueDate: dueDate
                            )
                        }
                        return (studentId, true, nil)
                    } catch {
                        return (studentId, false, error.localizedDescription)
                    }
                }
            }

            var successCount = 0
            var failures: [NotificationFailure] = []

            for await (studentId, success, errorMessage) in group {
                if success {
                    successCount += 1
                } else {
                    failures.append(NotificationFailure(
                        studentId: studentId,
                        error: errorMessage ?? "Unknown error"
                    ))
                }
            }

            return NotificationResult(
                totalStudents: students.count,
                successCount: successCount,
                failedCount: failures.count,
                failures: failures
            )
        }
    }

    /// Ejecuta una operación con timeout.
    private func withTimeout<T: Sendable>(
        seconds: TimeInterval,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw NotificationTimeoutError()
            }

            guard let result = try await group.next() else {
                throw NotificationTimeoutError()
            }

            group.cancelAll()
            return result
        }
    }
}

// MARK: - Helper Types

/// Error de timeout de notificación.
private struct NotificationTimeoutError: Error, Sendable {
    var localizedDescription: String {
        "Notification timed out"
    }
}
