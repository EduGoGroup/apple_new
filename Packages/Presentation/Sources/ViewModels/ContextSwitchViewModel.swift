import Foundation
import OSLog
import SwiftUI
import EduDomain
import EduCore
import EduFoundation
import EduDomain
import EduDomain

// MARK: - MembershipRole to SystemRole Conversion

extension MembershipRole {
    /// Convierte MembershipRole a SystemRole para uso con RoleManager.
    ///
    /// La conversion sigue la logica:
    /// - owner -> admin (administrador de la unidad)
    /// - teacher, assistant -> teacher (roles de ensenanza)
    /// - student -> student
    /// - guardian -> guardian
    func toSystemRole() -> SystemRole {
        switch self {
        case .owner:
            return .admin
        case .teacher, .assistant:
            return .teacher
        case .student:
            return .student
        case .guardian:
            return .guardian
        }
    }
}

/// ViewModel para gestionar el cambio de contexto (rol, escuela, unidad academica).
///
/// Este ViewModel gestiona el cambio de contexto con validacion de permisos
/// y actualizacion global del estado de la aplicacion.
///
/// ## Responsabilidades
/// - Cargar contextos disponibles (memberships, escuelas)
/// - Ejecutar cambio de contexto via SwitchContextCommand
/// - Actualizar RoleManager con el nuevo rol
/// - Publicar eventos de cambio de contexto
///
/// ## Integracion con CQRS
/// - **Queries**: GetUserContextQuery (cargar contexto actual)
/// - **Commands**: SwitchContextCommand (cambiar contexto)
/// - **Events**: ContextSwitchedEvent (notificar cambio)
///
/// ## Ejemplo de uso
/// ```swift
/// let viewModel = ContextSwitchViewModel(
///     mediator: mediator,
///     roleManager: roleManager,
///     eventBus: eventBus,
///     userId: currentUserId
/// )
///
/// // Cambiar a otro membership
/// await viewModel.switchMembership(to: membershipId)
/// ```
@MainActor
@Observable
public final class ContextSwitchViewModel {

    // MARK: - Published State

    /// Memberships disponibles para el usuario
    public var availableMemberships: [Membership] = []

    /// Mapa de escuelas por ID para acceso rapido
    public var schoolsMap: [UUID: School] = [:]

    /// Mapa de unidades por ID para acceso rapido
    public var unitsMap: [UUID: AcademicUnit] = [:]

    /// Contexto actual del usuario
    public var currentContext: UserContext?

    /// Membership actualmente seleccionado
    public var currentMembershipId: UUID?

    /// Indica si esta procesando el cambio
    public var isSwitching: Bool = false

    /// Indica si esta cargando contextos
    public var isLoading: Bool = false

    /// Error actual si lo hay
    public var error: Error?

    /// Indica si el cambio fue exitoso
    public var switchSuccess: Bool = false

    // MARK: - Dependencies

    /// Mediator CQRS para dispatch de queries y commands
    private let mediator: Mediator

    /// Gestor de roles para actualizacion global
    private let roleManager: RoleManager

    /// EventBus para suscripcion a eventos
    private let eventBus: EventBus

    /// ID del usuario actual
    private let userId: UUID

    /// IDs de suscripciones a eventos
    private var subscriptionIds: [UUID] = []

    /// Logger para debugging y monitoreo
    private let logger = Logger(subsystem: "com.edugo.viewmodels", category: "ContextSwitch")

    // MARK: - Task Management

    /// Task de carga inicial de contextos para cancelación en cleanup
    private var contextLoadTask: Task<Void, Never>?

    // MARK: - Initialization

    /// Crea un nuevo ContextSwitchViewModel.
    ///
    /// - Parameters:
    ///   - mediator: Mediator CQRS para ejecutar queries/commands
    ///   - roleManager: Gestor de roles para actualizar permisos
    ///   - eventBus: EventBus para eventos de dominio
    ///   - userId: ID del usuario actual
    public init(
        mediator: Mediator,
        roleManager: RoleManager,
        eventBus: EventBus,
        userId: UUID
    ) {
        self.mediator = mediator
        self.roleManager = roleManager
        self.eventBus = eventBus
        self.userId = userId

        // Cargar contextos disponibles, guardar Task para cleanup
        contextLoadTask = Task {
            await loadAvailableContexts()
        }
    }

    // MARK: - Load Contexts

    /// Carga los contextos disponibles para el usuario.
    ///
    /// Obtiene el UserContext completo via GetUserContextQuery,
    /// incluyendo memberships, escuelas y unidades disponibles.
    public func loadAvailableContexts() async {
        isLoading = true
        error = nil

        do {
            let query = GetUserContextQuery(
                forceRefresh: false,
                metadata: [
                    "source": "ContextSwitchViewModel",
                    "timestamp": ISO8601DateFormatter().string(from: Date())
                ]
            )

            let context = try await mediator.send(query)

            currentContext = context
            availableMemberships = context.memberships
            schoolsMap = context.schoolsMap
            unitsMap = context.unitsMap

            // Determinar membership actual (primer activo si no hay uno seleccionado)
            if currentMembershipId == nil,
               let firstActive = context.memberships.first(where: { $0.isCurrentlyActive }) {
                currentMembershipId = firstActive.id
            }

            logger.info("Contextos cargados: \(context.memberships.count) memberships")

        } catch {
            self.error = error
            logger.error("Error cargando contextos: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Refresca los contextos disponibles forzando recarga.
    public func refresh() async {
        isLoading = true
        error = nil

        do {
            let query = GetUserContextQuery(
                forceRefresh: true,
                metadata: [
                    "source": "ContextSwitchViewModel",
                    "action": "refresh"
                ]
            )

            let context = try await mediator.send(query)

            currentContext = context
            availableMemberships = context.memberships
            schoolsMap = context.schoolsMap
            unitsMap = context.unitsMap

            logger.info("Contextos refrescados: \(context.memberships.count) memberships")

        } catch {
            self.error = error
            logger.error("Error refrescando contextos: \(error.localizedDescription)")
        }

        isLoading = false
    }

    // MARK: - Switch Context

    /// Cambia el contexto al membership especificado.
    ///
    /// Ejecuta SwitchContextCommand para cambiar de membership/escuela,
    /// actualiza el RoleManager y publica eventos de cambio.
    ///
    /// - Parameter membershipId: ID del membership destino
    public func switchMembership(to membershipId: UUID) async {
        // Validar que el membership esta disponible
        guard availableMemberships.contains(where: { $0.id == membershipId }) else {
            error = ValidationError.invalidFormat(
                fieldName: "membershipId",
                reason: "Membership no disponible para este usuario"
            )
            return
        }

        // Validar que no es el mismo membership
        guard membershipId != currentMembershipId else {
            // No es un error, simplemente no hay nada que hacer
            logger.debug("Ya está en este contexto, no se realiza cambio")
            return
        }

        isSwitching = true
        error = nil
        switchSuccess = false

        do {
            let command = SwitchContextCommand(
                userId: userId,
                targetMembershipId: membershipId,
                reason: .userInitiated,
                forceSwitch: false,
                metadata: [
                    "source": "ContextSwitchViewModel",
                    "timestamp": ISO8601DateFormatter().string(from: Date())
                ]
            )

            let result = try await mediator.execute(command)

            if result.isSuccess, let output = result.getValue() {
                // Actualizar estado local
                currentMembershipId = membershipId

                // Actualizar RoleManager con el rol del nuevo contexto
                if let membership = availableMemberships.first(where: { $0.id == membershipId }) {
                    let systemRole = membership.role.toSystemRole()
                    await roleManager.setRole(systemRole)
                }

                switchSuccess = true
                logger.info("Contexto cambiado a: \(output.newContext.school.name)")

            } else if let resultError = result.getError() {
                self.error = resultError
                logger.error("Error al cambiar contexto: \(resultError.localizedDescription)")
            }

        } catch {
            self.error = error
            logger.error("Error ejecutando SwitchContextCommand: \(error.localizedDescription)")
        }

        isSwitching = false
    }

    /// Cambia a la escuela especificada.
    ///
    /// Busca el primer membership activo de la escuela y cambia a el.
    ///
    /// - Parameter schoolId: ID de la escuela destino
    public func switchSchool(to schoolId: UUID) async {
        // Buscar el primer membership activo de esta escuela
        guard let membership = availableMemberships.first(where: { membership in
            guard membership.isCurrentlyActive,
                  let unit = unitsMap[membership.unitID] else {
                return false
            }
            return unit.schoolID == schoolId
        }) else {
            error = ValidationError.invalidFormat(
                fieldName: "schoolId",
                reason: "No hay membership activo para esta escuela"
            )
            return
        }

        await switchMembership(to: membership.id)
    }

    // MARK: - Error Handling

    /// Limpia el error actual.
    public func clearError() {
        error = nil
    }

    /// Limpia el estado de exito.
    public func clearSuccess() {
        switchSuccess = false
    }

    /// Resetea el estado del ViewModel.
    public func reset() {
        availableMemberships = []
        schoolsMap = [:]
        unitsMap = [:]
        currentContext = nil
        currentMembershipId = nil
        isSwitching = false
        isLoading = false
        error = nil
        switchSuccess = false
    }
}

// MARK: - Convenience Computed Properties

extension ContextSwitchViewModel {
    /// Indica si hay contextos disponibles
    public var hasContexts: Bool {
        !availableMemberships.isEmpty
    }

    /// Indica si puede cambiar de contexto
    public var canSwitchContext: Bool {
        availableMemberships.count > 1 && !isSwitching && !isLoading
    }

    /// Numero de memberships disponibles
    public var membershipCount: Int {
        availableMemberships.count
    }

    /// Escuelas unicas disponibles
    public var availableSchools: [School] {
        let schoolIds = Set(availableMemberships.compactMap { membership in
            unitsMap[membership.unitID]?.schoolID
        })
        return schoolIds.compactMap { schoolsMap[$0] }
    }

    /// Indica si puede cambiar de escuela
    public var canSwitchSchool: Bool {
        availableSchools.count > 1 && !isSwitching && !isLoading
    }

    /// Numero de escuelas disponibles
    public var schoolCount: Int {
        availableSchools.count
    }

    /// Nombre de la escuela actual
    public var currentSchoolName: String {
        guard let membershipId = currentMembershipId,
              let membership = availableMemberships.first(where: { $0.id == membershipId }),
              let unit = unitsMap[membership.unitID],
              let school = schoolsMap[unit.schoolID] else {
            return "Sin escuela"
        }
        return school.name
    }

    /// Nombre de la unidad actual
    public var currentUnitName: String {
        guard let membershipId = currentMembershipId,
              let membership = availableMemberships.first(where: { $0.id == membershipId }),
              let unit = unitsMap[membership.unitID] else {
            return "Sin unidad"
        }
        return unit.displayName
    }

    /// Rol actual del usuario (convertido a SystemRole)
    public var currentRole: SystemRole? {
        guard let membershipId = currentMembershipId,
              let membership = availableMemberships.first(where: { $0.id == membershipId }) else {
            return nil
        }
        return membership.role.toSystemRole()
    }

    /// Rol de membership actual
    public var currentMembershipRole: MembershipRole? {
        guard let membershipId = currentMembershipId,
              let membership = availableMemberships.first(where: { $0.id == membershipId }) else {
            return nil
        }
        return membership.role
    }

    /// Nombre del rol actual
    public var currentRoleName: String {
        currentRole?.displayName ?? "Sin rol"
    }

    /// Membership actual
    public var currentMembership: Membership? {
        guard let membershipId = currentMembershipId else { return nil }
        return availableMemberships.first(where: { $0.id == membershipId })
    }

    /// Indica si hay un error
    public var hasError: Bool {
        error != nil
    }

    /// Mensaje de error legible
    public var errorMessage: String? {
        guard let error = error else { return nil }

        if let validationError = error as? ValidationError {
            return validationError.localizedDescription
        }

        if let mediatorError = error as? MediatorError {
            switch mediatorError {
            case .handlerNotFound:
                return "Error de configuracion del sistema. Contacte soporte."
            case .validationError(let message, _):
                return message
            case .executionError(let message, _):
                return "Error al cambiar contexto: \(message)"
            case .registrationError:
                return "Error de configuracion del sistema."
            }
        }

        if let switchError = error as? SwitchSchoolContextError {
            return switchError.localizedDescription
        }

        return error.localizedDescription
    }

    /// Indica si el usuario esta cargando datos o cambiando
    public var isBusy: Bool {
        isLoading || isSwitching
    }
}
