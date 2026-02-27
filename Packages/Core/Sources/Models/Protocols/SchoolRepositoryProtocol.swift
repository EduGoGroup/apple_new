//  SchoolRepositoryProtocol.swift
//  Models
//
//  Copyright © 2026 EduGo. All rights reserved.
//  Licensed under the MIT License.

import Foundation

/// Protocol defining repository operations for School entities.
///
/// This protocol abstracts the persistence layer for schools, allowing
/// implementations for in-memory, local database, or network storage.
///
/// ## Conformance
///
/// Implementations must be `Sendable` to ensure thread-safety
/// in concurrent contexts.
public protocol SchoolRepositoryProtocol: Sendable {
    /// Retrieves a school by its ID.
    ///
    /// - Parameter id: The UUID of the school to find.
    /// - Returns: The school if found, `nil` otherwise.
    /// - Throws: Repository error if there are data access issues.
    func get(id: UUID) async throws -> School?

    /// Retrieves a school by its unique code.
    ///
    /// - Parameter code: The unique code of the school.
    /// - Returns: The school if found, `nil` otherwise.
    /// - Throws: Repository error if there are data access issues.
    func getByCode(code: String) async throws -> School?

    /// Saves or updates a school in the repository.
    ///
    /// If the school already exists (same ID), it will be updated.
    /// If it doesn't exist, a new one will be created.
    ///
    /// - Parameter school: The school to save.
    /// - Throws: Repository error if there are persistence issues.
    func save(_ school: School) async throws

    /// Deletes a school from the repository by its ID.
    ///
    /// - Parameter id: The UUID of the school to delete.
    /// - Throws: Repository error if the school doesn't exist or deletion fails.
    func delete(id: UUID) async throws

    /// Retrieves all schools from the repository.
    ///
    /// - Returns: Array with all schools. Empty if none exist.
    /// - Throws: Repository error if there are data access issues.
    func list() async throws -> [School]
}
