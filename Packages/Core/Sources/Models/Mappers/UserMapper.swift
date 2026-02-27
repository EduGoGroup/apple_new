// UserMapper.swift
// Models
//
// Bidirectional mapper between UserDTO and User domain entity.

import Foundation
import EduFoundation

/// Mapper for bidirectional conversion between `UserDTO` and `User` domain entity.
///
/// This mapper handles the conversion between the backend's JSON representation
/// and the application's domain model, delegating validation to the `User` initializer.
///
/// ## Overview
/// `UserMapper` provides type-safe conversion that:
/// - Maps `first_name`/`last_name` (snake_case) to `firstName`/`lastName` (camelCase)
/// - Handles timestamp fields (`created_at`/`updated_at`)
/// - Delegates email and name validation to `User.init`
/// - Preserves all user properties during roundtrip conversion
///
/// ## Example
/// ```swift
/// // DTO from backend
/// let dto = UserDTO(
///     id: UUID(),
///     firstName: "John",
///     lastName: "Doe",
///     email: "john@example.com",
///     isActive: true,
///     createdAt: Date(),
///     updatedAt: Date()
/// )
///
/// // Convert to domain
/// let user = try UserMapper.toDomain(dto)
///
/// // Convert back to DTO
/// let backToDTO = UserMapper.toDTO(user)
/// ```
///
/// ## Error Handling
/// The `toDomain` method throws errors from `User.init`:
/// - `DomainError.validationFailed(field: "firstName", ...)` if first name is empty
/// - `DomainError.validationFailed(field: "lastName", ...)` if last name is empty
/// - `DomainError.validationFailed(field: "email", ...)` if email is invalid
///
/// ## Notes
/// - Roles are NOT mapped here; they are managed through `Membership` entities
/// - The extension methods on `UserDTO` and `User` (`toDomain()`, `toDTO()`) are preferred
///   for direct conversion. This mapper exists for `MapperProtocol` conformance.
public struct UserMapper: MapperProtocol {
    public typealias DTO = UserDTO
    public typealias Domain = User

    /// Converts a `UserDTO` from the backend to a `User` domain entity.
    ///
    /// - Parameter dto: The data transfer object from the backend.
    /// - Returns: A validated `User` domain entity.
    /// - Throws: `DomainError.validationFailed` if email or names are invalid.
    /// - Note: `User.init` normalizes email to lowercase and trims whitespace from names/email.
    public static func toDomain(_ dto: UserDTO) throws -> User {
        try dto.toDomain()
    }

    /// Converts a `User` domain entity to a `UserDTO` for the backend.
    ///
    /// - Parameter domain: The domain entity to convert.
    /// - Returns: A `UserDTO` suitable for sending to the backend.
    public static func toDTO(_ domain: User) -> UserDTO {
        domain.toDTO()
    }
}
