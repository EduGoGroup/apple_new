//  MaterialRepositoryProtocol.swift
//  Models
//
//  Copyright © 2026 EduGo. All rights reserved.
//  Licensed under the MIT License.

import Foundation

/// Protocol defining repository operations for Material entities.
///
/// This protocol abstracts the persistence layer for materials, allowing
/// implementations for in-memory, local database, or network storage.
///
/// ## Conformance
///
/// Implementations must be `Sendable` to ensure thread-safety
/// in concurrent contexts.
public protocol MaterialRepositoryProtocol: Sendable {
    /// Retrieves a material by its ID.
    ///
    /// - Parameter id: The UUID of the material to find.
    /// - Returns: The material if found, `nil` otherwise.
    /// - Throws: Repository error if there are data access issues.
    func get(id: UUID) async throws -> Material?

    /// Saves or updates a material in the repository.
    ///
    /// If the material already exists (same ID), it will be updated.
    /// If it doesn't exist, a new one will be created.
    ///
    /// - Parameter material: The material to save.
    /// - Throws: Repository error if there are persistence issues.
    func save(_ material: Material) async throws

    /// Deletes a material from the repository by its ID.
    ///
    /// - Parameter id: The UUID of the material to delete.
    /// - Throws: Repository error if the material doesn't exist or deletion fails.
    func delete(id: UUID) async throws

    /// Retrieves all materials from the repository.
    ///
    /// - Returns: Array with all materials. Empty if none exist.
    /// - Throws: Repository error if there are data access issues.
    func list() async throws -> [Material]

    /// Retrieves all materials belonging to a specific school.
    ///
    /// - Parameter schoolID: The UUID of the school.
    /// - Returns: Array of materials for the school.
    /// - Throws: Repository error if there are data access issues.
    func listBySchool(schoolID: UUID) async throws -> [Material]

    /// Retrieves all materials associated with a specific academic unit.
    ///
    /// - Parameter unitID: The UUID of the academic unit.
    /// - Returns: Array of materials for the unit.
    /// - Throws: Repository error if there are data access issues.
    func listByAcademicUnit(unitID: UUID) async throws -> [Material]
}
