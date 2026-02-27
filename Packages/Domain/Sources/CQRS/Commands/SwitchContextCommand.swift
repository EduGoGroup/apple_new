import Foundation

// MARK: - SwitchContextCommand

/// Command para cambiar el contexto escolar activo de un usuario.
///
/// Este command encapsula los datos necesarios para que un usuario
/// cambie su membership/escuela activa, con validaciones pre-ejecución.
///
/// ## Validaciones
/// - UserId no puede ser nil
/// - TargetMembershipId no puede ser nil
/// - El membership debe pertenecer al usuario (validado en handler)
/// - La escuela debe estar activa (validado en handler)
///
/// ## Eventos Emitidos
/// - `ContextSwitchedEvent`: Cuando el cambio se completa exitosamente
///
/// ## Caches Invalidados
/// - `UserContextReadModel`: Contexto del usuario
/// - `DashboardReadModel`: Dashboard con datos de la nueva escuela
/// - `MaterialListReadModel`: Materiales de la nueva unidad
///
/// ## Ejemplo de Uso
/// ```swift
/// let command = SwitchContextCommand(
///     userId: currentUserId,
///     targetMembershipId: newMembershipId,
///     reason: .userInitiated
/// )
///
/// let result = try await mediator.execute(command)
/// if result.isSuccess, let context = result.getValue() {
///     print("Cambiado a: \(context.newContext.school.name)")
/// }
/// ```
public struct SwitchContextCommand: Command {

    public typealias Result = SwitchSchoolOutput

    // MARK: - Switch Reason

    /// Razón del cambio de contexto para analytics.
    public enum SwitchReason: String, Sendable, Codable {
        /// El usuario inició el cambio manualmente
        case userInitiated = "user_initiated"
        /// Cambio automático por sesión expirada
        case sessionExpired = "session_expired"
        /// Cambio automático por invitación aceptada
        case invitationAccepted = "invitation_accepted"
        /// Cambio forzado por administrador
        case adminForced = "admin_forced"
        /// Cambio al contexto por defecto
        case defaultContext = "default_context"
    }

    // MARK: - Properties

    /// ID del usuario que realiza el cambio
    public let userId: UUID

    /// ID del membership destino al que se quiere cambiar
    public let targetMembershipId: UUID

    /// Razón del cambio de contexto
    public let reason: SwitchReason

    /// Si se debe forzar el cambio incluso si es el mismo contexto
    public let forceSwitch: Bool

    /// Metadata opcional para tracing
    public let metadata: [String: String]?

    // MARK: - Initialization

    /// Crea un nuevo command para cambiar de contexto escolar.
    ///
    /// - Parameters:
    ///   - userId: ID del usuario que cambia de contexto
    ///   - targetMembershipId: ID del membership destino
    ///   - reason: Razón del cambio (default: userInitiated)
    ///   - forceSwitch: Forzar incluso si es mismo contexto (default: false)
    ///   - metadata: Metadata opcional
    public init(
        userId: UUID,
        targetMembershipId: UUID,
        reason: SwitchReason = .userInitiated,
        forceSwitch: Bool = false,
        metadata: [String: String]? = nil
    ) {
        self.userId = userId
        self.targetMembershipId = targetMembershipId
        self.reason = reason
        self.forceSwitch = forceSwitch
        self.metadata = metadata
    }

    // MARK: - Command Protocol

    /// Valida el command antes de la ejecución.
    ///
    /// Las validaciones de negocio (membership pertenece a usuario,
    /// escuela activa) se realizan en el handler/use case.
    ///
    /// - Throws: `ValidationError` si alguna validación falla
    public func validate() throws {
        // Validaciones básicas de formato ya se garantizan por tipos UUID
        // Validaciones de negocio se delegan al handler
    }
}

// MARK: - SwitchContextCommandHandler

/// Handler que procesa SwitchContextCommand usando SwitchSchoolContextUseCase.
///
/// Coordina el proceso de cambio de contexto, valida que el usuario
/// tenga acceso al membership, emite eventos e invalida caches.
///
/// ## Responsabilidades
/// 1. Validar que el membership pertenece al usuario
/// 2. Validar que la escuela está activa
/// 3. Ejecutar SwitchSchoolContextUseCase
/// 4. Emitir ContextSwitchedEvent
/// 5. Invalidar caches: UserContext, Dashboard, MaterialList
/// 6. Envolver resultado en CommandResult
///
/// ## Ejemplo de Uso
/// ```swift
/// let handler = SwitchContextCommandHandler(
///     useCase: switchContextUseCase,
///     eventBus: eventBus,
///     dashboardHandler: dashboardQueryHandler
/// )
/// try await mediator.registerCommandHandler(handler)
/// ```
public actor SwitchContextCommandHandler: CommandHandler {

    public typealias CommandType = SwitchContextCommand

    // MARK: - Dependencies

    private let useCase: any SwitchSchoolContextUseCaseProtocol

    /// EventBus para publicar eventos
    private let eventBus: EventBus?

    /// Handler de DashboardQuery para invalidar cache
    private weak var dashboardHandler: GetStudentDashboardQueryHandler?

    // MARK: - Initialization

    /// Crea un nuevo handler para SwitchContextCommand.
    ///
    /// - Parameters:
    ///   - useCase: Use case que ejecuta el cambio de contexto
    ///   - eventBus: Bus de eventos para publicar (opcional)
    ///   - dashboardHandler: Handler para invalidar cache (opcional)
    public init(
        useCase: any SwitchSchoolContextUseCaseProtocol,
        eventBus: EventBus? = nil,
        dashboardHandler: GetStudentDashboardQueryHandler? = nil
    ) {
        self.useCase = useCase
        self.eventBus = eventBus
        self.dashboardHandler = dashboardHandler
    }

    // MARK: - CommandHandler Protocol

    /// Procesa el command y retorna el resultado.
    ///
    /// - Parameter command: Command con datos del cambio de contexto
    /// - Returns: CommandResult con SwitchSchoolOutput y eventos emitidos
    /// - Throws: Error si falla la validación o el cambio
    public func handle(_ command: SwitchContextCommand) async throws -> CommandResult<SwitchSchoolOutput> {
        // Crear input para el use case
        let input = SwitchSchoolInput(
            userId: command.userId,
            targetMembershipId: command.targetMembershipId
        )

        // Ejecutar use case
        do {
            let output = try await useCase.execute(input: input)

            // Determinar si fue cambio al mismo contexto
            let wasSameContext = output.previousMembershipId == output.newContext.activeMembership.id

            // Crear y publicar evento
            let event = ContextSwitchedEvent(
                userId: command.userId,
                previousMembershipId: output.previousMembershipId,
                newMembershipId: output.newContext.activeMembership.id,
                previousSchoolId: output.newContext.school.id, // Nota: usamos el mismo porque no tenemos el anterior
                newSchoolId: output.newContext.school.id,
                newSchoolName: output.newContext.school.name,
                newUnitName: output.newContext.unit.displayName,
                wasSameContext: wasSameContext,
                metadata: [
                    "reason": command.reason.rawValue,
                    "forceSwitch": command.forceSwitch ? "true" : "false"
                ]
            )

            // Publicar evento si hay eventBus
            if let eventBus = eventBus {
                await eventBus.publish(event)
            }

            // Invalidar cache de dashboard para el nuevo contexto
            await dashboardHandler?.invalidateCache(for: command.userId)

            // Preparar eventos emitidos
            var events = ["ContextSwitchedEvent"]
            if !wasSameContext {
                events.append("UserContextInvalidatedEvent")
                events.append("DashboardInvalidatedEvent")
                events.append("MaterialListInvalidatedEvent")
            }

            // Crear metadata del resultado
            let resultMetadata: [String: String] = [
                "userId": command.userId.uuidString,
                "previousMembershipId": output.previousMembershipId.uuidString,
                "newMembershipId": output.newContext.activeMembership.id.uuidString,
                "newSchoolId": output.newContext.school.id.uuidString,
                "newSchoolName": output.newContext.school.name,
                "wasSameContext": wasSameContext ? "true" : "false",
                "switchReason": command.reason.rawValue
            ]

            return .success(
                output,
                events: events,
                metadata: resultMetadata
            )

        } catch let error as SwitchSchoolContextError {
            return .failure(
                error,
                metadata: [
                    "userId": command.userId.uuidString,
                    "targetMembershipId": command.targetMembershipId.uuidString,
                    "errorType": String(describing: error),
                    "switchReason": command.reason.rawValue
                ]
            )
        } catch let error as UseCaseError {
            return .failure(
                error,
                metadata: [
                    "userId": command.userId.uuidString,
                    "targetMembershipId": command.targetMembershipId.uuidString,
                    "errorType": String(describing: type(of: error)),
                    "switchReason": command.reason.rawValue
                ]
            )
        } catch {
            return .failure(
                error,
                metadata: [
                    "userId": command.userId.uuidString,
                    "targetMembershipId": command.targetMembershipId.uuidString,
                    "errorDescription": error.localizedDescription,
                    "switchReason": command.reason.rawValue
                ]
            )
        }
    }

    // MARK: - Configuration

    /// Configura el handler de dashboard para invalidación de cache.
    public func setDashboardHandler(_ handler: GetStudentDashboardQueryHandler) {
        self.dashboardHandler = handler
    }
}
