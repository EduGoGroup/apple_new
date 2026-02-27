import Foundation
import EduFoundation
import EduCore

// MARK: - UpdateUserProfileInput

/// Input para el caso de uso de actualización de perfil de usuario.
public struct UpdateUserProfileInput: Sendable, Equatable {
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

    /// Inicializa el input para actualización de perfil.
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
}

// MARK: - UserProfileRepositoryProtocol

/// Protocolo para actualizar el perfil del usuario en backend.
///
/// Esta abstracción permite implementar repositorios remotos
/// sin acoplar el UseCase a la capa de red.
public protocol UserProfileRepositoryProtocol: Sendable {
    /// Actualiza el perfil del usuario en backend.
    ///
    /// - Parameters:
    ///   - userId: ID del usuario a actualizar
    ///   - firstName: Nuevo nombre
    ///   - lastName: Nuevo apellido
    ///   - email: Nuevo email
    ///   - metadata: Metadata opcional para tracing
    /// - Returns: Usuario actualizado desde backend
    func updateUserProfile(
        userId: UUID,
        firstName: String,
        lastName: String,
        email: String,
        metadata: [String: String]?
    ) async throws -> User
}

// MARK: - UpdateUserProfileUseCase

/// Actor que implementa la actualización del perfil del usuario.
///
/// ## Flujo de ejecución
/// 1. Validar campos (nombre, apellido, email)
/// 2. Actualizar perfil en backend via UserProfileRepository
/// 3. Persistir usuario actualizado en repositorio local
/// 4. Retornar usuario actualizado
public actor UpdateUserProfileUseCase: UseCase {

    public typealias Input = UpdateUserProfileInput
    public typealias Output = User

    // MARK: - Dependencies

    private let profileRepository: UserProfileRepositoryProtocol
    private let userRepository: UserRepositoryProtocol

    // MARK: - Initialization

    /// Crea una nueva instancia del caso de uso.
    ///
    /// - Parameters:
    ///   - profileRepository: Repositorio remoto para actualizar perfil
    ///   - userRepository: Repositorio local para persistir usuario actualizado
    public init(
        profileRepository: UserProfileRepositoryProtocol,
        userRepository: UserRepositoryProtocol
    ) {
        self.profileRepository = profileRepository
        self.userRepository = userRepository
    }

    // MARK: - UseCase Implementation

    /// Ejecuta la actualización del perfil.
    ///
    /// - Parameter input: Datos a actualizar
    /// - Returns: Usuario actualizado
    /// - Throws: UseCaseError si falla la validación o el backend
    public func execute(input: UpdateUserProfileInput) async throws -> User {
        let trimmedFirstName = input.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLastName = input.lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = input.email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedFirstName.isEmpty else {
            throw UseCaseError.preconditionFailed(
                description: "El nombre no puede estar vacío"
            )
        }

        guard !trimmedLastName.isEmpty else {
            throw UseCaseError.preconditionFailed(
                description: "El apellido no puede estar vacío"
            )
        }

        do {
            try EmailValidator.validate(trimmedEmail)
        } catch {
            throw UseCaseError.preconditionFailed(
                description: "Formato de email inválido"
            )
        }

        do {
            // Actualizar en backend
            let updatedUser = try await profileRepository.updateUserProfile(
                userId: input.userId,
                firstName: trimmedFirstName,
                lastName: trimmedLastName,
                email: trimmedEmail,
                metadata: input.metadata
            )

            // Persistir localmente para cache
            try await userRepository.save(updatedUser)

            return updatedUser
        } catch let error as RepositoryError {
            throw UseCaseError.repositoryError(error)
        } catch let error as DomainError {
            throw UseCaseError.domainError(error)
        } catch {
            throw UseCaseError.executionFailed(
                reason: "Error actualizando perfil: \(error.localizedDescription)"
            )
        }
    }
}
