import Foundation

/// Base protocol for all domain entities.
///
/// `Entity` establishes a fundamental contract for domain objects, ensuring:
/// - **Unique identification** via `Identifiable`
/// - **Value equality** via `Equatable`
/// - **Concurrency safety** via `Sendable`
///
/// ## Thread Safety
///
/// Conforming types must be `Sendable`, meaning:
/// - All stored properties must be immutable (`let`) or thread-safe
/// - No mutable shared state
/// - Safe to use across actor boundaries and in structured concurrency
///
/// ## Usage Example
///
/// ```swift
/// struct Student: Entity {
///     let id: UUID
///     let createdAt: Date
///     let updatedAt: Date
///     let name: String
/// }
/// ```
///
/// - Note: All properties should be immutable (`let`) for thread safety
/// - Important: Conforming types should be `struct` or final `class`
///
public protocol Entity: Identifiable, Equatable, Sendable where ID == UUID {
    /// Unique identifier for the entity.
    /// Must be stable and never change during entity lifetime.
    var id: UUID { get }

    /// Timestamp when the entity was created.
    var createdAt: Date { get }

    /// Timestamp when the entity was last updated.
    var updatedAt: Date { get }
}
