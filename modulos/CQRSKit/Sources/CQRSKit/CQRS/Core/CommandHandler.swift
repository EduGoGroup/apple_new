import Foundation

/// Protocolo para handlers que procesan commands de modificación de estado.
///
/// Un CommandHandler es responsable de ejecutar la lógica de negocio asociada
/// a un Command específico y retornar su resultado envuelto en un `CommandResult`.
/// Los handlers son concurrentes y seguros (Sendable) por diseño.
///
/// # Ejemplo de uso:
/// ```swift
/// actor CreateUserCommandHandler: CommandHandler {
///     typealias CommandType = CreateUserCommand
///
///     private let userRepository: UserRepository
///     private let eventPublisher: EventPublisher
///
///     init(userRepository: UserRepository, eventPublisher: EventPublisher) {
///         self.userRepository = userRepository
///         self.eventPublisher = eventPublisher
///     }
///
///     func handle(_ command: CreateUserCommand) async throws -> CommandResult<User> {
///         // Validar el command
///         try command.validate()
///
///         // Ejecutar la lógica de negocio
///         let user = try await userRepository.create(
///             username: command.username,
///             email: command.email
///         )
///
///         // Publicar eventos de dominio
///         await eventPublisher.publish(UserCreatedEvent(userId: user.id))
///
///         // Retornar resultado exitoso
///         return .success(
///             user,
///             events: ["UserCreatedEvent"],
///             metadata: ["timestamp": Date().ISO8601Format()]
///         )
///     }
/// }
/// ```
public protocol CommandHandler: Sendable {
    /// Tipo de Command que este handler puede procesar
    associatedtype CommandType: Command

    /// Procesa el command de forma asíncrona y retorna el resultado.
    ///
    /// - Parameter command: El command a procesar
    /// - Returns: `CommandResult<CommandType.Result>` con el resultado de la operación
    /// - Throws: Errores durante la ejecución del command
    func handle(_ command: CommandType) async throws -> CommandResult<CommandType.Result>
}
