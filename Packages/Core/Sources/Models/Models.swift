import Foundation

/// Models - Core data models module
///
/// Defines domain models, DTOs, and shared data structures.
/// TIER-1 Core module.
///
/// ## Domain Entities
/// - ``User``: User entity with roles management
/// - ``Role``: Role entity with permission management
/// - ``Permission``: Granular permission with resource/action
/// - ``Document``: Document entity with lifecycle management
///
/// ## Domain Validation
/// - ``DomainValidation``: Centralized validation facade
/// - ``EmailValidator``: Email format validation
///
/// ## Value Types
/// All domain entities are immutable structs conforming to `Sendable`,
/// `Equatable`, `Identifiable`, and `Codable`.
///
/// ## Relationships
/// Relationships between entities are modeled via UUIDs (value semantics)
/// rather than object references, ensuring thread-safety.
///
/// ## Validation
/// Domain validations are centralized in the `Validation` module and use
/// typed errors (`DomainError`) from `EduGoCommon` for consistent error handling.
public protocol Model: Sendable, Codable, Identifiable {}
