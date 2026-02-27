import Foundation
import SwiftUI
import OSLog
import EduDomain
import EduCore
import EduFoundation
import EduDomain
import EduDomain

/// ViewModel para asignar materiales a unidades académicas usando CQRS Mediator.
///
/// Este ViewModel gestiona la asignación de materiales con verificación de permisos
/// y selección de unidades destino.
///
/// ## Responsabilidades
/// - Verificar permisos de asignación de materiales (profesor/admin)
/// - Gestionar selección múltiple de unidades destino
/// - Ejecutar AssignMaterialCommand via Mediator
/// - Gestionar fecha límite opcional
///
/// ## Integración con CQRS
/// - **Commands**: AssignMaterialCommand (con validación pre-ejecución)
/// - **Events**: MaterialAssignedEvent (publicado automáticamente por handler)
///
/// ## Verificación de Permisos
/// Utiliza RoleManager para verificar que el usuario tenga permisos
/// de edición de materiales antes de permitir la asignación.
///
/// ## Ejemplo de uso
/// ```swift
/// let viewModel = await MaterialAssignmentViewModel(
///     mediator: mediator,
///     roleManager: roleManager,
///     materialId: materialId,
///     assignedBy: currentUserId
/// )
///
/// // Seleccionar unidades
/// await viewModel.toggleUnit(unitId1)
/// await viewModel.toggleUnit(unitId2)
///
/// // Asignar material
/// await viewModel.assignMaterial()
/// ```
@MainActor
@Observable
public final class MaterialAssignmentViewModel {

    // MARK: - Published State

    /// IDs de las unidades seleccionadas para asignación
    public var selectedUnitIds: Set<UUID> = []

    /// Fecha límite opcional para la asignación
    public var assignmentDeadline: Date?

    /// Indica si está procesando la asignación
    public var isAssigning: Bool = false

    /// Error actual si lo hay
    public var error: Error? {
        didSet {
            // Invalidar caché cuando el error cambia
            cachedErrorMessage = nil
        }
    }

    /// Indica si la asignación fue exitosa
    public var assignmentSuccess: Bool = false

    /// Si el material debe ser visible para estudiantes
    public var isVisible: Bool = true

    /// Si se debe notificar a los estudiantes
    public var notifyStudents: Bool = true

    /// Resultados de asignaciones exitosas
    public var assignmentResults: [MaterialAssignment] = []

    // MARK: - Dependencies

    /// Mediator CQRS para dispatch de commands
    private let mediator: Mediator

    /// Gestor de roles para verificación de permisos
    private let roleManager: RoleManager

    /// ID del material a asignar
    private let materialId: UUID

    /// ID del usuario que realiza la asignación
    private let assignedBy: UUID

    /// Logger para debugging y monitoreo
    private let logger = Logger(subsystem: "com.edugo.viewmodels", category: "MaterialAssignment")

    // MARK: - Cached State

    /// Cache del estado de permisos
    private var cachedCanAssign: Bool = false

    /// Cache del mensaje de error para evitar re-cálculos costosos
    private var cachedErrorMessage: String?

    // MARK: - Rate Limiting

    /// Timestamp de la última llamada a assignMaterial para throttling
    private var lastAssignmentAttempt: Date?

    /// Intervalo mínimo entre intentos de asignación (en segundos)
    private let minimumAssignmentInterval: TimeInterval = 0.5

    /// Timeout para operaciones de asignación (en segundos)
    private let assignmentTimeout: TimeInterval = 30.0

    // MARK: - Task Management

    /// Task de carga inicial de permisos para cancelación en cleanup
    /// Marcado como nonisolated(unsafe) para acceso desde deinit
    nonisolated(unsafe) private var permissionLoadTask: Task<Void, Never>?

    // MARK: - Initialization

    /// Crea un nuevo MaterialAssignmentViewModel.
    ///
    /// - Parameters:
    ///   - mediator: Mediator CQRS para ejecutar commands
    ///   - roleManager: Gestor de roles para verificar permisos
    ///   - materialId: ID del material a asignar
    ///   - assignedBy: ID del usuario que realiza la asignación
    public init(
        mediator: Mediator,
        roleManager: RoleManager,
        materialId: UUID,
        assignedBy: UUID
    ) {
        self.mediator = mediator
        self.roleManager = roleManager
        self.materialId = materialId
        self.assignedBy = assignedBy

        // Cargar permisos de forma asíncrona y guardar Task para cleanup
        permissionLoadTask = Task {
            await loadPermissions()
        }
    }

    // MARK: - Deinitialization

    /// Limpia recursos al destruir el ViewModel
    deinit {
        // Cancelar tasks en progreso
        permissionLoadTask?.cancel()

        logger.debug("MaterialAssignmentViewModel deinicializado - recursos limpiados")
    }

    // MARK: - Permission Loading

    /// Carga los permisos desde RoleManager.
    public func loadPermissions() async {
        cachedCanAssign = await roleManager.hasPermission(.editMaterials)
    }

    // MARK: - Authorization

    /// Indica si el usuario puede asignar materiales.
    ///
    /// Verifica que el usuario tenga el permiso `.editMaterials`.
    public var canAssignMaterials: Bool {
        cachedCanAssign
    }

    // MARK: - Selection Methods

    /// Alterna la selección de una unidad.
    ///
    /// - Parameter unitId: ID de la unidad a alternar
    public func toggleUnit(_ unitId: UUID) {
        if selectedUnitIds.contains(unitId) {
            selectedUnitIds.remove(unitId)
        } else {
            selectedUnitIds.insert(unitId)
        }
    }

    /// Selecciona todas las unidades proporcionadas.
    ///
    /// - Parameter unitIds: Lista de IDs de unidades a seleccionar
    public func selectAll(_ unitIds: [UUID]) {
        selectedUnitIds = Set(unitIds)
    }

    /// Deselecciona todas las unidades.
    public func deselectAll() {
        selectedUnitIds.removeAll()
    }

    /// Verifica si una unidad está seleccionada.
    ///
    /// - Parameter unitId: ID de la unidad a verificar
    /// - Returns: `true` si la unidad está seleccionada
    public func isSelected(_ unitId: UUID) -> Bool {
        selectedUnitIds.contains(unitId)
    }

    // MARK: - Assignment

    /// Asigna el material a las unidades seleccionadas.
    ///
    /// Ejecuta AssignMaterialCommand para cada unidad seleccionada.
    /// Si alguna falla, continúa con las demás y reporta errores parciales.
    public func assignMaterial() async {
        // SEGURIDAD: Validación de permisos PRIMERO (fail fast)
        // Refresh permissions antes de validar para evitar race conditions
        // Los permisos pueden haber cambiado desde que se cargaron en init
        await loadPermissions()

        guard canAssignMaterials else {
            error = MediatorError.validationError(
                message: "No tiene permisos para asignar materiales",
                underlyingError: nil
            )
            return
        }

        // SEGURIDAD: Prevenir race conditions - validar que no haya operación en progreso
        guard !isAssigning else {
            logger.warning("Intento de asignar material mientras ya hay una asignación en progreso")
            return
        }

        // Validar selección temprano
        guard !selectedUnitIds.isEmpty else {
            error = ValidationError.emptyField(fieldName: "units")
            return
        }

        // SEGURIDAD: Rate limiting - prevenir llamadas muy rápidas (throttling)
        // Solo aplicar rate limit DESPUÉS de validaciones rápidas
        let now = Date()
        if let lastAttempt = self.lastAssignmentAttempt {
            let timeSinceLastAttempt = now.timeIntervalSince(lastAttempt)
            if timeSinceLastAttempt < self.minimumAssignmentInterval {
                let remainingTime = self.minimumAssignmentInterval - timeSinceLastAttempt
                logger.warning("Intento de asignación demasiado rápido. Esperando \(remainingTime, privacy: .public)s")
                return
            }
        }
        self.lastAssignmentAttempt = now

        isAssigning = true
        error = nil
        assignmentSuccess = false
        assignmentResults = []

        // PERFORMANCE: Tracking de tiempo para detectar operaciones lentas
        let startTime = Date()
        let unitCount = self.selectedUnitIds.count
        logger.info("Iniciando asignación de material a \(unitCount, privacy: .public) unidades")

        // Capturar propiedades antes del TaskGroup para evitar acceso async
        let materialId = self.materialId
        let assignedBy = self.assignedBy
        let deadline = self.assignmentDeadline
        let isVisible = self.isVisible
        let notifyStudents = self.notifyStudents
        let mediator = self.mediator

        // Procesar asignaciones en paralelo usando TaskGroup
        let results = await withTaskGroup(of: (UUID, Result<MaterialAssignment, Error>).self) { group in
            for unitId in selectedUnitIds {
                group.addTask { [weak self] in
                    guard let self = self else {
                        return (unitId, .failure(DomainError.invalidOperation(operation: "ViewModel fue liberado")))
                    }

                    do {
                        // Ejecutar con lógica de reintento para fallos transitorios
                        let assignment = try await self.executeWithRetry {
                            let command = AssignMaterialCommand(
                                materialId: materialId,
                                unitId: unitId,
                                assignedBy: assignedBy,
                                dueDate: deadline,
                                visible: isVisible,
                                notifyStudents: notifyStudents,
                                metadata: [
                                    "source": "MaterialAssignmentViewModel",
                                    "timestamp": ISO8601DateFormatter().string(from: Date())
                                ]
                            )

                            let result = try await mediator.execute(command)

                            // VALIDACIÓN: Verificar que la respuesta del backend sea coherente
                            guard let assignment = try result.getValue() else {
                                // Log detallado del problema para debugging (private para no exponer en producción)
                                self.logger.error("Backend retornó respuesta inválida - UnitID: \(unitId.uuidString, privacy: .private), Result: \(String(describing: result), privacy: .private)")

                                throw DomainError.invalidOperation(
                                    operation: "No se pudo completar la asignación del material. Intente nuevamente."
                                )
                            }


                            // VALIDACIÓN: Verificar que el assignment esté asociado a la unidad correcta
                            guard assignment.unit.id == unitId else {
                                self.logger.error("Backend retornó assignment con unitId incorrecto - Esperado: \(unitId.uuidString, privacy: .private), Recibido: \(assignment.unit.id.uuidString, privacy: .private)")

                                throw DomainError.invalidOperation(
                                    operation: "Respuesta inválida del servidor. Intente nuevamente."
                                )
                            }

                            return assignment
                        }

                        return (unitId, .success(assignment))
                    } catch {
                        return (unitId, .failure(error))
                    }
                }
            }

            // Recolectar resultados
            var taskResults: [(UUID, Result<MaterialAssignment, Error>)] = []
            for await result in group {
                taskResults.append(result)
            }
            return taskResults
        }

        // Procesar resultados
        var successfulAssignments: [MaterialAssignment] = []
        var failuresByUnit: [UUID: Error] = [:]

        for (unitId, result) in results {
            switch result {
            case .success(let assignment):
                successfulAssignments.append(assignment)
                logger.info("Material asignado a unidad: \(unitId)")
            case .failure(let error):
                failuresByUnit[unitId] = error
                logger.error("Error asignando material a unidad \(unitId): \(error.localizedDescription)")
            }
        }

        // Actualizar array de resultados (successfulAssignmentsCount se calcula automáticamente)
        self.assignmentResults = successfulAssignments

        isAssigning = false

        // PERFORMANCE: Log del tiempo total de ejecución
        let duration = Date().timeIntervalSince(startTime)
        logger.info("Asignación completada en \(duration, format: .fixed(precision: 2), privacy: .public)s")

        if duration > self.assignmentTimeout {
            logger.warning("⚠️ Operación excedió el timeout recomendado de \(self.assignmentTimeout, privacy: .public)s (tomó \(duration, format: .fixed(precision: 2), privacy: .public)s)")
        }

        // Determinar resultado final con información detallada
        let successCount = successfulAssignments.count
        let totalCount = selectedUnitIds.count

        if successCount == totalCount {
            // Todas exitosas
            assignmentSuccess = true
            logger.info("Todas las asignaciones completadas exitosamente (\(totalCount, privacy: .public) unidades)")
        } else if successCount > 0 {
            // Éxito parcial - crear error con detalles
            assignmentSuccess = true
            self.error = createAssignmentError(
                successCount: successCount,
                totalCount: totalCount,
                failures: failuresByUnit
            )
            logger.warning("Asignación parcial: \(successCount, privacy: .public)/\(totalCount, privacy: .public)")
        } else {
            // Todas fallaron
            assignmentSuccess = false
            self.error = createAssignmentError(
                successCount: 0,
                totalCount: totalCount,
                failures: failuresByUnit
            )
            logger.error("Todas las asignaciones fallaron (\(totalCount, privacy: .public) unidades)")
        }
    }

    // MARK: - Reset

    /// Limpia el estado del ViewModel.
    public func reset() {
        selectedUnitIds.removeAll()
        assignmentDeadline = nil
        isAssigning = false
        error = nil
        assignmentSuccess = false
        isVisible = true
        notifyStudents = true
        assignmentResults = []
    }

    /// Limpia el error actual.
    public func clearError() {
        error = nil
    }

    // MARK: - Error Helpers

    /// Crea un error descriptivo para éxito parcial
    /// Ejecuta una operación con lógica de reintento para fallos transitorios.
    ///
    /// - Parameters:
    ///   - maxAttempts: Número máximo de intentos (por defecto 3)
    ///   - operation: Operación asíncrona a ejecutar
    /// - Returns: Resultado de la operación
    /// - Throws: El último error si todos los intentos fallan
    ///
    /// ## Estrategia de Reintento
    /// - Exponential backoff: 0.5s, 1s, 2s
    /// - No reintenta errores de validación o dominio
    /// - Solo reintenta errores transitorios (network, timeout)
    private func executeWithRetry<T>(
        maxAttempts: Int = 3,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?

        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error

                // No reintentar errores de validación o dominio (son permanentes)
                if error is ValidationError || error is DomainError {
                    throw error
                }

                // No reintentar errores de permisos
                if let mediatorError = error as? MediatorError,
                   case .validationError = mediatorError {
                    throw error
                }

                // Si no es el último intento, esperar antes de reintentar
                if attempt < maxAttempts {
                    let delay = pow(2.0, Double(attempt - 1)) * 0.5
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    logger.warning("Reintento \(attempt, privacy: .public)/\(maxAttempts, privacy: .public) después de \(delay, format: .fixed(precision: 1), privacy: .public)s - Error: \(error.localizedDescription, privacy: .public)")
                }
            }
        }

        throw lastError!
    }

    /// Crea un error descriptivo para asignaciones fallidas (parcial o totalmente).
    ///
    /// - Parameters:
    ///   - successCount: Número de asignaciones exitosas
    ///   - totalCount: Número total de asignaciones intentadas
    ///   - failures: Diccionario de UUID a Error para las asignaciones fallidas
    /// - Returns: Error con mensaje amigable sin UUIDs expuestos
    private func createAssignmentError(
        successCount: Int,
        totalCount: Int,
        failures: [UUID: Error]
    ) -> Error {
        let failureCount = totalCount - successCount

        // SEGURIDAD: Logging detallado sin exponer al usuario
        // UUIDs marcados como private para redaction automática en producción
        for (unitId, error) in failures {
            logger.error("Asignación fallida - Unidad: \(unitId.uuidString, privacy: .private), Error: \(error.localizedDescription, privacy: .public)")
        }

        // Mensaje amigable sin UUIDs
        let message: String
        if successCount == 0 {
            // Todas fallaron
            message = "No se pudo completar la asignación en \(failureCount) \(failureCount == 1 ? "unidad" : "unidades"). Por favor, verifique los permisos e intente nuevamente."
        } else {
            // Éxito parcial
            message = "\(successCount) de \(totalCount) asignaciones completadas. \(failureCount) \(failureCount == 1 ? "asignación falló" : "asignaciones fallaron"). Por favor, verifique los permisos e intente nuevamente."
        }

        return MediatorError.executionError(
            message: message,
            underlyingError: nil
        )
    }
}

// MARK: - Convenience Computed Properties

extension MaterialAssignmentViewModel {
    /// Indica si hay unidades seleccionadas
    public var hasSelection: Bool {
        !selectedUnitIds.isEmpty
    }

    /// Número de unidades seleccionadas
    public var selectedCount: Int {
        selectedUnitIds.count
    }

    /// Indica si se puede proceder con la asignación
    public var canProceed: Bool {
        canAssignMaterials && hasSelection && !isAssigning
    }

    /// Indica si hay un error
    public var hasError: Bool {
        error != nil
    }

    /// Indica si el botón de asignar debe estar deshabilitado
    public var isAssignButtonDisabled: Bool {
        isAssigning || !canProceed
    }

    /// Número de asignaciones exitosas
    public var successfulAssignmentsCount: Int {
        assignmentResults.count
    }

    /// Indica si hubo éxito parcial
    public var isPartialSuccess: Bool {
        assignmentSuccess && error != nil
    }

    /// Mensaje de error legible
    public var errorMessage: String? {
        guard let error = error else { return nil }

        // Usar caché si está disponible
        if let cached = cachedErrorMessage {
            return cached
        }

        // Calcular y cachear
        let message: String
        if let validationError = error as? ValidationError {
            message = validationError.localizedDescription
        } else if let mediatorError = error as? MediatorError {
            switch mediatorError {
            case .handlerNotFound:
                message = "Error de configuración del sistema. Contacte soporte."
            case .validationError(let msg, _):
                message = msg
            case .executionError(let msg, _):
                message = "Error al asignar: \(msg)"
            case .registrationError:
                message = "Error de configuración del sistema."
            }
        } else if let assignError = error as? AssignMaterialError {
            message = assignError.localizedDescription
        } else {
            message = error.localizedDescription
        }

        cachedErrorMessage = message
        return message
    }

    /// Mensaje de resultado de la asignación
    public var resultMessage: String {
        if assignmentSuccess {
            if isPartialSuccess {
                return "Asignación parcial: \(successfulAssignmentsCount) de \(selectedCount) unidades"
            } else {
                return "Material asignado exitosamente a \(successfulAssignmentsCount) unidad(es)"
            }
        }
        return ""
    }
}
