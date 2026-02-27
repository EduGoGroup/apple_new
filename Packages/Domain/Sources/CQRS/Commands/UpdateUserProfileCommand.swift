import Foundation
import EduCore

// MARK: - UpdateUserProfileCommand

/// Command para actualizar el perfil del usuario.
///
/// Encapsula los datos necesarios para actualizar nombre, apellido y email
/// con validaciones pre-ejecución.
///
/// ## Validaciones
/// - firstName no puede estar vacío
/// - lastName no puede estar vacío
/// - email debe tener formato válido
///
/// ## Eventos Emitidos
/// - `UserProfileUpdatedEvent`: Cuando la actualización se completa exitosamente
/// - `UserContextInvalidatedEvent`: Para invalidar cache de contexto de usuario
public struct UpdateUserProfileCommand: Command {

    public typealias Result = User

    // MARK: - Properties

    /// ID del usuario a actualizar
    public let userId: UUID

    /// Nuevo nombre
    public let firstName: String

    /// Nuevo apellido
    public let lastName: String

    /// Nuevo email
    public let email: String

    /// Metadata opcional para tracing
    public let metadata: [String: String]?

    // MARK: - Initialization

    /// Crea un nuevo command para actualizar perfil.
    public init(
        userId: UUID,
        firstName: String,
        lastName: String,
        email: String,
        metadata: [String: String]? = nil
    ) {
        self.userId = userId
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.metadata = metadata
    }

    // MARK: - Command Protocol

    /// Valida el command antes de la ejecución.
    public func validate() throws {
        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedFirstName.isEmpty else {
            throw ValidationError.emptyField(fieldName: "firstName")
        }

        guard !trimmedLastName.isEmpty else {
            throw ValidationError.emptyField(fieldName: "lastName")
        }

        guard EmailValidator.isValid(trimmedEmail) else {
            throw ValidationError.invalidFormat(
                fieldName: "email",
                reason: "Formato de email inválido"
            )
        }
    }
}

// MARK: - UpdateUserProfileCommandHandler

/// Handler que procesa UpdateUserProfileCommand usando UpdateUserProfileUseCase.
public actor UpdateUserProfileCommandHandler: CommandHandler {

    public typealias CommandType = UpdateUserProfileCommand

    // MARK: - Dependencies

    private let useCase: any UpdateUserProfileUseCaseProtocol

    /// EventBus para publicar eventos
    private let eventBus: EventBus?

    /// Handler de UserContext para invalidar cache
    private weak var userContextHandler: GetUserContextQueryHandler?

    // MARK: - Initialization

    public init(
        useCase: any UpdateUserProfileUseCaseProtocol,
        eventBus: EventBus? = nil,
        userContextHandler: GetUserContextQueryHandler? = nil
    ) {
        self.useCase = useCase
        self.eventBus = eventBus
        self.userContextHandler = userContextHandler
    }

    // MARK: - CommandHandler Protocol

    public func handle(_ command: UpdateUserProfileCommand) async throws -> CommandResult<User> {
        let input = UpdateUserProfileInput(
            userId: command.userId,
            firstName: command.firstName,
            lastName: command.lastName,
            email: command.email,
            metadata: command.metadata
        )

        do {
            let updatedUser = try await useCase.execute(input: input)

            let event = UserProfileUpdatedEvent(
                userId: updatedUser.id,
                firstName: updatedUser.firstName,
                lastName: updatedUser.lastName,
                email: updatedUser.email,
                metadata: [
                    "source": "UpdateUserProfileCommand"
                ]
            )

            if let eventBus = eventBus {
                await eventBus.publish(event)
            }

            await userContextHandler?.invalidateCache()

            let resultMetadata: [String: String] = [
                "userId": updatedUser.id.uuidString,
                "email": updatedUser.email
            ]

            return .success(
                updatedUser,
                events: ["UserProfileUpdatedEvent", "UserContextInvalidatedEvent"],
                metadata: resultMetadata
            )

        } catch let error as UseCaseError {
            return .failure(
                error,
                metadata: [
                    "userId": command.userId.uuidString,
                    "errorType": String(describing: type(of: error))
                ]
            )
        } catch {
            return .failure(
                error,
                metadata: [
                    "userId": command.userId.uuidString,
                    "errorDescription": error.localizedDescription
                ]
            )
        }
    }

    // MARK: - Configuration

    /// Configura el handler de UserContext para invalidación de cache.
    public func setUserContextHandler(_ handler: GetUserContextQueryHandler) {
        self.userContextHandler = handler
    }
}
