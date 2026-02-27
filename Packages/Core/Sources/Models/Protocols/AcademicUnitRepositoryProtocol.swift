//  AcademicUnitRepositoryProtocol.swift
//  Models
//
//  Copyright © 2026 EduGo. All rights reserved.
//  Licensed under the MIT License.

import Foundation

/// Protocol defining repository operations for AcademicUnit entities.
///
/// This protocol abstracts the persistence layer for academic units, allowing
/// implementations for in-memory, local database, or network storage.
///
/// ## Conformance
///
/// Implementations must be `Sendable` to ensure thread-safety
/// in concurrent contexts.
public protocol AcademicUnitRepositoryProtocol: Sendable {
    /// Retrieves an academic unit by its ID.
    ///
    /// - Parameter id: The UUID of the unit to find.
    /// - Returns: The unit if found, `nil` otherwise.
    /// - Throws: Repository error if there are data access issues.
    func get(id: UUID) async throws -> AcademicUnit?

    /// Saves or updates an academic unit in the repository.
    ///
    /// If the unit already exists (same ID), it will be updated.
    /// If it doesn't exist, a new one will be created.
    ///
    /// - Parameter unit: The academic unit to save.
    /// - Throws: Repository error if there are persistence issues.
    func save(_ unit: AcademicUnit) async throws

    /// Deletes an academic unit from the repository by its ID.
    ///
    /// - Parameter id: The UUID of the unit to delete.
    /// - Throws: Repository error if the unit doesn't exist or deletion fails.
    func delete(id: UUID) async throws

    /// Retrieves all academic units from the repository.
    ///
    /// - Returns: Array with all units. Empty if none exist.
    /// - Throws: Repository error if there are data access issues.
    func list() async throws -> [AcademicUnit]

    /// Retrieves all academic units belonging to a specific school.
    ///
    /// - Parameter schoolID: The UUID of the school.
    /// - Returns: Array of units for the school.
    /// - Throws: Repository error if there are data access issues.
    func listBySchool(schoolID: UUID) async throws -> [AcademicUnit]

    /// Retrieves all child units of a parent unit.
    ///
    /// - Parameter parentID: The UUID of the parent unit.
    /// - Returns: Array of child units.
    /// - Throws: Repository error if there are data access issues.
    func listChildren(parentID: UUID) async throws -> [AcademicUnit]

    /// Retrieves the root units (units with no parent) for a school.
    ///
    /// - Parameter schoolID: The UUID of the school.
    /// - Returns: Array of root units for the school.
    /// - Throws: Repository error if there are data access issues.
    func listRoots(schoolID: UUID) async throws -> [AcademicUnit]
}
