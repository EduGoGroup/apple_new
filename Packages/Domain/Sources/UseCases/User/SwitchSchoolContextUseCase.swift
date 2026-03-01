import Foundation
import EduFoundation
import EduCore

// MARK: - SwitchSchoolInput

/// Input para el caso de uso de cambio de contexto escolar.
public struct SwitchSchoolInput: Sendable, Equatable {
    /// ID del usuario que realiza el cambio
    public let userId: UUID

    /// ID del membership objetivo al que se quiere cambiar
    public let targetMembershipId: UUID

    /// Inicializa el input para cambio de contexto.
    ///
    /// - Parameters:
    ///   - userId: ID del usuario
    ///   - targetMembershipId: ID del membership destino
    public init(userId: UUID, targetMembershipId: UUID) {
        self.userId = userId
        self.targetMembershipId = targetMembershipId
    }
}

// MARK: - SwitchSchoolOutput

/// Output del caso de uso de cambio de contexto escolar.
public struct SwitchSchoolOutput: Sendable, Equatable {
    /// Nuevo contexto del usuario después del cambio
    public let newContext: SwitchSchoolContext

    /// ID del membership anterior (antes del cambio)
    public let previousMembershipId: UUID

    /// Inicializa el output del cambio de contexto.
    ///
    /// - Parameters:
    ///   - newContext: El nuevo contexto activo
    ///   - previousMembershipId: ID del membership anterior
    public init(newContext: SwitchSchoolContext, previousMembershipId: UUID) {
        self.newContext = newContext
        self.previousMembershipId = previousMembershipId
    }
}

// MARK: - SwitchSchoolContext

/// Contexto resultante después de un cambio de escuela.
public struct SwitchSchoolContext: Sendable, Equatable {
    /// Membership activo actualmente
    public let activeMembership: Membership

    /// Unidad académica del nuevo contexto
    public let unit: AcademicUnit

    /// Escuela del nuevo contexto
    public let school: School

    /// Inicializa un nuevo contexto de escuela.
    ///
    /// - Parameters:
    ///   - activeMembership: El membership activo
    ///   - unit: La unidad académica
    ///   - school: La escuela
    public init(activeMembership: Membership, unit: AcademicUnit, school: School) {
        self.activeMembership = activeMembership
        self.unit = unit
        self.school = school
    }
}

// MARK: - SchoolContextChangedEvent

/// Evento emitido cuando el contexto escolar cambia.
///
/// Este evento es publicado via EventBus (CQRS) para que los suscriptores
/// (cache invalidation, analytics, navigation) puedan reaccionar.
///
/// - Note: Para suscripción, usar `ContextSwitchedEvent` via `EventBus`.
public struct SchoolContextChangedEvent: Sendable, Equatable {
    /// ID del usuario que cambió de contexto
    public let userId: UUID

    /// ID del membership anterior
    public let oldMembershipId: UUID

    /// ID del nuevo membership
    public let newMembershipId: UUID

    /// ID de la nueva escuela
    public let newSchoolId: UUID

    /// Timestamp del cambio
    public let timestamp: Date

    /// Inicializa un nuevo evento de cambio de contexto.
    ///
    /// - Parameters:
    ///   - userId: ID del usuario
    ///   - oldMembershipId: ID del membership anterior
    ///   - newMembershipId: ID del nuevo membership
    ///   - newSchoolId: ID de la nueva escuela
    ///   - timestamp: Timestamp del cambio (por defecto ahora)
    public init(
        userId: UUID,
        oldMembershipId: UUID,
        newMembershipId: UUID,
        newSchoolId: UUID,
        timestamp: Date = Date()
    ) {
        self.userId = userId
        self.oldMembershipId = oldMembershipId
        self.newMembershipId = newMembershipId
        self.newSchoolId = newSchoolId
        self.timestamp = timestamp
    }
}

// MARK: - SwitchSchoolContextError

/// Errores específicos del caso de uso de cambio de contexto.
public enum SwitchSchoolContextError: Error, LocalizedError, Sendable, Equatable {
    /// El membership no pertenece al usuario especificado
    case membershipNotOwnedByUser

    /// El membership no está activo
    case membershipNotActive

    /// El contexto (unit/school) no está disponible
    case contextNotAvailable(reason: String)

    /// Se intentó cambiar al mismo membership actual (noop)
    case sameContextSwitch

    public var errorDescription: String? {
        switch self {
        case .membershipNotOwnedByUser:
            return "El membership especificado no pertenece a este usuario"
        case .membershipNotActive:
            return "El membership no está activo"
        case .contextNotAvailable(let reason):
            return "El contexto no está disponible: \(reason)"
        case .sameContextSwitch:
            return "Ya se encuentra en este contexto"
        }
    }
}

// MARK: - UserSessionRepositoryProtocol

/// Protocolo para gestionar la sesión activa del usuario.
///
/// Maneja el estado de la sesión incluyendo el membership activo,
/// unidad y escuela actuales.
public protocol UserSessionRepositoryProtocol: Sendable {
    /// Obtiene el ID del membership activo actual.
    ///
    /// - Returns: UUID del membership activo, nil si no hay sesión
    func getCurrentMembershipId() async throws -> UUID?

    /// Actualiza la sesión con un nuevo contexto de forma atómica.
    ///
    /// Esta operación es transaccional: actualiza membership_id,
    /// current_unit_id y current_school_id de forma all-or-nothing.
    ///
    /// - Parameters:
    ///   - membershipId: Nuevo membership ID
    ///   - unitId: Nuevo unit ID
    ///   - schoolId: Nuevo school ID
    /// - Throws: `RepositoryError` si falla la actualización
    func updateSessionContext(
        membershipId: UUID,
        unitId: UUID,
        schoolId: UUID
    ) async throws
}

// MARK: - CacheInvalidatorProtocol

/// Protocolo para invalidar caches relacionados con el contexto.
public protocol CacheInvalidatorProtocol: Sendable {
    /// Invalida el cache del dashboard.
    func invalidateDashboardCache() async

    /// Invalida el cache de materiales.
    func invalidateMaterialsCache() async
}

// MARK: - SwitchSchoolContextUseCase

/// Actor que implementa el cambio de contexto escolar del usuario.
///
/// Este use case maneja el switch entre memberships de un usuario,
/// actualizando el estado de sesión de forma atómica y notificando
/// a los observadores del cambio.
///
/// ## Flujo de Ejecución
/// 1. **Validar membership**: verificar que targetMembershipId pertenece a userId
/// 2. **Load new context**: cargar unit + school del nuevo membership (parallel fetch)
/// 3. **Update session atomically**:
///    - Save new membership_id en SessionRepository
///    - Update current_unit_id
///    - Update current_school_id
///    - Transaction: all-or-nothing
/// 4. **Invalidar caches**: clear dashboard cache, clear materials cache
/// 5. **Emit event**: SchoolContextChanged para observadores
///
/// ## Validaciones
/// - targetMembershipId debe pertenecer a userId (security)
/// - Membership debe estar activa (status='active')
/// - Unit y School deben existir
/// - NO permitir switch al mismo membership (noop pero no error)
///
/// ## Rollback Support
/// - Si update session falla: NO cambiar nada, mantener contexto anterior
/// - Si cache invalidation falla: log warning pero NO rollback
///
/// ## Ejemplo de Uso
/// ```swift
/// let useCase = SwitchSchoolContextUseCase(
///     membershipRepository: membershipRepo,
///     unitRepository: unitRepo,
///     schoolRepository: schoolRepo,
///     sessionRepository: sessionRepo,
///     cacheInvalidator: cacheInvalidator
/// )
///
/// let input = SwitchSchoolInput(
///     userId: currentUserId,
///     targetMembershipId: newMembershipId
/// )
///
/// do {
///     let output = try await useCase.execute(input: input)
///     print("Cambiado a: \(output.newContext.school.name)")
/// } catch let error as SwitchSchoolContextError {
///     print("Error: \(error.localizedDescription)")
/// }
/// ```
public actor SwitchSchoolContextUseCase: UseCase {

    public typealias Input = SwitchSchoolInput
    public typealias Output = SwitchSchoolOutput

    // MARK: - Dependencies

    private let membershipRepository: MembershipRepositoryProtocol
    private let unitRepository: AcademicUnitRepositoryProtocol
    private let schoolRepository: SchoolRepositoryProtocol
    private let sessionRepository: UserSessionRepositoryProtocol
    private let cacheInvalidator: CacheInvalidatorProtocol?
    private let eventBus: EventBus?

    // MARK: - Initialization

    /// Crea una nueva instancia del caso de uso.
    ///
    /// - Parameters:
    ///   - membershipRepository: Repositorio de memberships
    ///   - unitRepository: Repositorio de unidades académicas
    ///   - schoolRepository: Repositorio de escuelas
    ///   - sessionRepository: Repositorio de sesión del usuario
    ///   - cacheInvalidator: Invalidador de caches (opcional)
    ///   - eventBus: EventBus para publicar eventos de dominio (opcional)
    public init(
        membershipRepository: MembershipRepositoryProtocol,
        unitRepository: AcademicUnitRepositoryProtocol,
        schoolRepository: SchoolRepositoryProtocol,
        sessionRepository: UserSessionRepositoryProtocol,
        cacheInvalidator: CacheInvalidatorProtocol? = nil,
        eventBus: EventBus? = nil
    ) {
        self.membershipRepository = membershipRepository
        self.unitRepository = unitRepository
        self.schoolRepository = schoolRepository
        self.sessionRepository = sessionRepository
        self.cacheInvalidator = cacheInvalidator
        self.eventBus = eventBus
    }

    // MARK: - UseCase Implementation

    /// Ejecuta el cambio de contexto escolar.
    ///
    /// - Parameter input: Los datos de entrada con userId y targetMembershipId
    /// - Returns: SwitchSchoolOutput con el nuevo contexto y membership anterior
    /// - Throws: `SwitchSchoolContextError` o `UseCaseError` si falla
    public func execute(input: SwitchSchoolInput) async throws -> SwitchSchoolOutput {
        // PASO 1: Obtener membership actual para comparación
        let currentMembershipId = try await sessionRepository.getCurrentMembershipId()

        // PASO 2: Verificar si es el mismo membership (noop permitido)
        if currentMembershipId == input.targetMembershipId {
            // Cargar contexto actual para retornarlo
            let context = try await loadContext(for: input.targetMembershipId, userId: input.userId)
            return SwitchSchoolOutput(
                newContext: context,
                previousMembershipId: input.targetMembershipId
            )
        }

        // PASO 3: Validar y cargar el nuevo membership
        guard let targetMembership = try await membershipRepository.get(id: input.targetMembershipId) else {
            throw UseCaseError.preconditionFailed(
                description: "Membership no encontrado: \(input.targetMembershipId)"
            )
        }

        // PASO 4: Validar que el membership pertenece al usuario
        guard targetMembership.userID == input.userId else {
            throw UseCaseError.unauthorized(action: "Cambiar a un membership que no le pertenece")
        }

        // PASO 5: Validar que el membership está activo
        guard targetMembership.isCurrentlyActive else {
            throw UseCaseError.preconditionFailed(
                description: "El membership no está activo"
            )
        }

        // PASO 6: Cargar unit y school en paralelo
        let (unit, school) = try await loadUnitAndSchool(for: targetMembership)

        // PASO 7: Actualizar sesión de forma atómica
        do {
            try await sessionRepository.updateSessionContext(
                membershipId: targetMembership.id,
                unitId: unit.id,
                schoolId: school.id
            )
        } catch let error as RepositoryError {
            throw UseCaseError.repositoryError(error)
        } catch {
            throw UseCaseError.executionFailed(
                reason: "Error al actualizar sesión: \(error.localizedDescription)"
            )
        }

        // PASO 8: Invalidar caches (no falla el flujo si hay error)
        await invalidateCaches()

        // PASO 9: Emitir evento de cambio de contexto via EventBus
        await emitContextChangedEvent(
            userId: input.userId,
            previousMembershipId: currentMembershipId ?? input.targetMembershipId,
            newMembership: targetMembership,
            unit: unit,
            school: school
        )

        // PASO 10: Retornar resultado
        let newContext = SwitchSchoolContext(
            activeMembership: targetMembership,
            unit: unit,
            school: school
        )

        return SwitchSchoolOutput(
            newContext: newContext,
            previousMembershipId: currentMembershipId ?? input.targetMembershipId
        )
    }

    // MARK: - Private Helpers

    /// Carga el contexto completo para un membership.
    private func loadContext(for membershipId: UUID, userId: UUID) async throws -> SwitchSchoolContext {
        guard let membership = try await membershipRepository.get(id: membershipId) else {
            throw UseCaseError.preconditionFailed(
                description: "Membership no encontrado"
            )
        }

        guard membership.userID == userId else {
            throw UseCaseError.unauthorized(action: "Acceder a membership ajeno")
        }

        let (unit, school) = try await loadUnitAndSchool(for: membership)

        return SwitchSchoolContext(
            activeMembership: membership,
            unit: unit,
            school: school
        )
    }

    /// Carga unit y school en paralelo para un membership.
    private func loadUnitAndSchool(for membership: Membership) async throws -> (AcademicUnit, School) {
        // Cargar unit primero (necesitamos su schoolID para cargar school)
        guard let unit = try await unitRepository.get(id: membership.unitID) else {
            throw UseCaseError.preconditionFailed(
                description: "Unidad académica no encontrada para el membership"
            )
        }

        // Verificar que la unidad no está eliminada
        guard !unit.isDeleted else {
            throw UseCaseError.preconditionFailed(
                description: "La unidad académica ha sido eliminada"
            )
        }

        // Cargar school
        guard let school = try await schoolRepository.get(id: unit.schoolID) else {
            throw UseCaseError.preconditionFailed(
                description: "Escuela no encontrada para la unidad"
            )
        }

        // Verificar que la escuela está activa
        guard school.isActive else {
            throw UseCaseError.preconditionFailed(
                description: "La escuela no está activa"
            )
        }

        return (unit, school)
    }

    /// Invalida los caches relacionados con el contexto.
    private func invalidateCaches() async {
        guard let invalidator = cacheInvalidator else { return }

        // Ejecutar invalidación en paralelo
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await invalidator.invalidateDashboardCache()
            }
            group.addTask {
                await invalidator.invalidateMaterialsCache()
            }

            // Esperar a que todas completen
            for await _ in group {}
        }
    }

    /// Emits the context changed event via the CQRS EventBus.
    private func emitContextChangedEvent(
        userId: UUID,
        previousMembershipId: UUID,
        newMembership: Membership,
        unit: AcademicUnit,
        school: School
    ) async {
        guard let eventBus = eventBus else { return }

        let event = ContextSwitchedEvent(
            userId: userId,
            previousMembershipId: previousMembershipId,
            newMembershipId: newMembership.id,
            previousSchoolId: school.id,
            newSchoolId: school.id,
            newSchoolName: school.name,
            newUnitName: unit.displayName
        )
        await eventBus.publish(event)
    }
}
