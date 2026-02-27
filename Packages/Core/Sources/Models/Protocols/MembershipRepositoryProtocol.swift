//  MembershipRepositoryProtocol.swift
//  Models
//
//  Copyright © 2026 EduGo. All rights reserved.
//  Licensed under the MIT License.

import Foundation

/// Protocol defining repository operations for Membership entities.
///
/// This protocol abstracts the persistence layer for memberships, allowing
/// implementations for in-memory, local database, or network storage.
///
/// ## Conformance
///
/// Implementations must be `Sendable` to ensure thread-safety
/// in concurrent contexts.
public protocol MembershipRepositoryProtocol: Sendable {
    /// Retrieves a membership by its ID.
    ///
    /// - Parameter id: The UUID of the membership to find.
    /// - Returns: The membership if found, `nil` otherwise.
    /// - Throws: Repository error if there are data access issues.
    func get(id: UUID) async throws -> Membership?

    /// Retrieves a membership by user and unit IDs.
    ///
    /// - Parameters:
    ///   - userID: The UUID of the user.
    ///   - unitID: The UUID of the academic unit.
    /// - Returns: The membership if found, `nil` otherwise.
    /// - Throws: Repository error if there are data access issues.
    func get(userID: UUID, unitID: UUID) async throws -> Membership?

    /// Saves or updates a membership in the repository.
    ///
    /// If the membership already exists (same ID), it will be updated.
    /// If it doesn't exist, a new one will be created.
    ///
    /// - Parameter membership: The membership to save.
    /// - Throws: Repository error if there are persistence issues.
    func save(_ membership: Membership) async throws

    /// Deletes a membership from the repository by its ID.
    ///
    /// - Parameter id: The UUID of the membership to delete.
    /// - Throws: Repository error if the membership doesn't exist or deletion fails.
    func delete(id: UUID) async throws

    /// Retrieves all memberships from the repository.
    ///
    /// - Returns: Array with all memberships. Empty if none exist.
    /// - Throws: Repository error if there are data access issues.
    func list() async throws -> [Membership]

    /// Retrieves all memberships for a specific user.
    ///
    /// - Parameter userID: The UUID of the user.
    /// - Returns: Array of memberships for the user.
    /// - Throws: Repository error if there are data access issues.
    func listByUser(userID: UUID) async throws -> [Membership]

    /// Retrieves all memberships for a specific academic unit.
    ///
    /// - Parameter unitID: The UUID of the academic unit.
    /// - Returns: Array of memberships for the unit.
    /// - Throws: Repository error if there are data access issues.
    func listByUnit(unitID: UUID) async throws -> [Membership]
}
