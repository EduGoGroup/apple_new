// MapperProtocol.swift
// Models
//
// Protocol for bidirectional mapping between DTOs and Domain entities.

import Foundation

/// Protocol that defines bidirectional mapping between DTOs and Domain entities.
///
/// Mappers implementing this protocol provide type-safe conversion between
/// backend data transfer objects and domain models.
///
/// ## Overview
/// Use `MapperProtocol` to create consistent mapping logic across your application.
/// Each mapper handles conversion in both directions:
/// - `toDomain`: Converts backend DTO to domain entity (may throw on validation)
/// - `toDTO`: Converts domain entity to backend DTO (always succeeds)
///
/// ## Example
/// ```swift
/// struct UserMapper: MapperProtocol {
///     typealias DTO = UserDTO
///     typealias Domain = User
///
///     static func toDomain(_ dto: UserDTO) throws -> User {
///         try User(id: dto.id, name: dto.name, email: dto.email)
///     }
///
///     static func toDTO(_ domain: User) -> UserDTO {
///         UserDTO(id: domain.id, name: domain.name, email: domain.email)
///     }
/// }
/// ```
///
/// ## Thread Safety
/// Mappers conforming to this protocol must be `Sendable` to ensure
/// safe usage across concurrency boundaries in Swift 6.
public protocol MapperProtocol: Sendable {
    /// The Data Transfer Object type from the backend.
    associatedtype DTO: Codable & Sendable

    /// The Domain entity type used in the application.
    associatedtype Domain: Sendable

    /// Converts a backend DTO to a domain entity.
    ///
    /// - Parameter dto: The data transfer object from the backend.
    /// - Returns: The corresponding domain entity.
    /// - Throws: `DomainError.validationFailed` if the DTO contains invalid data.
    static func toDomain(_ dto: DTO) throws -> Domain

    /// Converts a domain entity to a backend DTO.
    ///
    /// - Parameter domain: The domain entity to convert.
    /// - Returns: The corresponding data transfer object for the backend.
    static func toDTO(_ domain: Domain) -> DTO
}
