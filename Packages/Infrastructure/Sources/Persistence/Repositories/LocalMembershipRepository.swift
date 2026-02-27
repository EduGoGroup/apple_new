import Foundation
import SwiftData
import EduCore
import EduFoundation

/// Local repository for Membership entities using SwiftData
///
/// This actor implements `MembershipRepositoryProtocol` and provides thread-safe
/// CRUD operations for Membership entities persisted in SwiftData.
public actor LocalMembershipRepository: MembershipRepositoryProtocol {
    private let containerProvider: PersistenceContainerProvider
    private var cachedMemberships: [Membership]?

    /// Creates a new LocalMembershipRepository
    ///
    /// - Parameter containerProvider: The persistence container provider (defaults to shared)
    public init(containerProvider: PersistenceContainerProvider = .shared) {
        self.containerProvider = containerProvider
    }

    public func get(id: UUID) async throws -> Membership? {
        if let cachedMemberships = cachedMemberships {
            return cachedMemberships.first { $0.id == id }
        }

        do {
            return try await containerProvider.perform { context in
                let predicate = #Predicate<MembershipModel> { model in
                    model.id == id
                }
                var descriptor = FetchDescriptor(predicate: predicate)
                descriptor.fetchLimit = 1

                guard let model = try context.fetch(descriptor).first else {
                    return nil
                }

                return try MembershipPersistenceMapper.toDomain(model)
            }
        } catch let error as RepositoryError {
            throw error
        } catch let error as DomainError {
            throw RepositoryError.fetchFailed(reason: "Failed to map membership: \(error.localizedDescription)")
        } catch {
            throw RepositoryError.fetchFailed(reason: error.localizedDescription)
        }
    }

    public func get(userID: UUID, unitID: UUID) async throws -> Membership? {
        do {
            return try await containerProvider.perform { context in
                let predicate = #Predicate<MembershipModel> { model in
                    model.userID == userID && model.unitID == unitID
                }
                var descriptor = FetchDescriptor(predicate: predicate)
                descriptor.fetchLimit = 1

                guard let model = try context.fetch(descriptor).first else {
                    return nil
                }

                return try MembershipPersistenceMapper.toDomain(model)
            }
        } catch let error as DomainError {
            throw RepositoryError.fetchFailed(reason: "Failed to map membership: \(error.localizedDescription)")
        } catch {
            throw RepositoryError.fetchFailed(reason: error.localizedDescription)
        }
    }

    public func save(_ membership: Membership) async throws {
        do {
            try await containerProvider.perform { context in
                let predicate = #Predicate<MembershipModel> { model in
                    model.id == membership.id
                }
                var descriptor = FetchDescriptor(predicate: predicate)
                descriptor.fetchLimit = 1

                let existing = try context.fetch(descriptor).first
                let model = MembershipPersistenceMapper.toModel(membership, existing: existing)

                if existing == nil {
                    context.insert(model)
                }

                try context.save()
            }

            if cachedMemberships != nil {
                if let index = cachedMemberships?.firstIndex(where: { $0.id == membership.id }) {
                    cachedMemberships?[index] = membership
                } else {
                    cachedMemberships?.append(membership)
                }
            }
        } catch let error as RepositoryError {
            throw error
        } catch {
            throw RepositoryError.saveFailed(reason: error.localizedDescription)
        }
    }

    public func delete(id: UUID) async throws {
        do {
            try await containerProvider.perform { context in
                let predicate = #Predicate<MembershipModel> { model in
                    model.id == id
                }
                var descriptor = FetchDescriptor(predicate: predicate)
                descriptor.fetchLimit = 1

                guard let model = try context.fetch(descriptor).first else {
                    throw RepositoryError.deleteFailed(reason: "Membership with id \(id) not found")
                }

                context.delete(model)
                try context.save()
            }

            cachedMemberships?.removeAll { $0.id == id }
        } catch let error as RepositoryError {
            throw error
        } catch {
            throw RepositoryError.deleteFailed(reason: error.localizedDescription)
        }
    }

    public func list() async throws -> [Membership] {
        do {
            let memberships = try await containerProvider.perform { context in
                let descriptor = FetchDescriptor<MembershipModel>()
                let models = try context.fetch(descriptor)
                return try models.map { try MembershipPersistenceMapper.toDomain($0) }
            }

            cachedMemberships = memberships
            return memberships
        } catch let error as RepositoryError {
            throw error
        } catch let error as DomainError {
            throw RepositoryError.fetchFailed(reason: "Failed to map memberships: \(error.localizedDescription)")
        } catch {
            throw RepositoryError.fetchFailed(reason: error.localizedDescription)
        }
    }

    public func listByUser(userID: UUID) async throws -> [Membership] {
        do {
            return try await containerProvider.perform { context in
                let predicate = #Predicate<MembershipModel> { model in
                    model.userID == userID
                }
                let descriptor = FetchDescriptor(predicate: predicate)
                let models = try context.fetch(descriptor)
                return try models.map { try MembershipPersistenceMapper.toDomain($0) }
            }
        } catch let error as DomainError {
            throw RepositoryError.fetchFailed(reason: "Failed to map memberships: \(error.localizedDescription)")
        } catch {
            throw RepositoryError.fetchFailed(reason: error.localizedDescription)
        }
    }

    public func listByUnit(unitID: UUID) async throws -> [Membership] {
        do {
            return try await containerProvider.perform { context in
                let predicate = #Predicate<MembershipModel> { model in
                    model.unitID == unitID
                }
                let descriptor = FetchDescriptor(predicate: predicate)
                let models = try context.fetch(descriptor)
                return try models.map { try MembershipPersistenceMapper.toDomain($0) }
            }
        } catch let error as DomainError {
            throw RepositoryError.fetchFailed(reason: "Failed to map memberships: \(error.localizedDescription)")
        } catch {
            throw RepositoryError.fetchFailed(reason: error.localizedDescription)
        }
    }
}
