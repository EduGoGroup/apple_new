import Foundation
import SwiftData
import EduCore
import EduFoundation

/// Local repository for AcademicUnit entities using SwiftData
///
/// This actor implements `AcademicUnitRepositoryProtocol` and provides thread-safe
/// CRUD operations for AcademicUnit entities persisted in SwiftData.
public actor LocalAcademicUnitRepository: AcademicUnitRepositoryProtocol {
    private let containerProvider: PersistenceContainerProvider
    private var cachedUnits: [AcademicUnit]?

    /// Creates a new LocalAcademicUnitRepository
    ///
    /// - Parameter containerProvider: The persistence container provider (defaults to shared)
    public init(containerProvider: PersistenceContainerProvider = .shared) {
        self.containerProvider = containerProvider
    }

    public func get(id: UUID) async throws -> AcademicUnit? {
        if let cachedUnits = cachedUnits {
            return cachedUnits.first { $0.id == id }
        }

        do {
            return try await containerProvider.perform { context in
                let predicate = #Predicate<AcademicUnitModel> { model in
                    model.id == id
                }
                var descriptor = FetchDescriptor(predicate: predicate)
                descriptor.fetchLimit = 1

                guard let model = try context.fetch(descriptor).first else {
                    return nil
                }

                return try AcademicUnitPersistenceMapper.toDomain(model)
            }
        } catch let error as RepositoryError {
            throw error
        } catch let error as DomainError {
            throw RepositoryError.fetchFailed(reason: "Failed to map academic unit: \(error.localizedDescription)")
        } catch {
            throw RepositoryError.fetchFailed(reason: error.localizedDescription)
        }
    }

    public func save(_ unit: AcademicUnit) async throws {
        do {
            try await containerProvider.perform { context in
                let predicate = #Predicate<AcademicUnitModel> { model in
                    model.id == unit.id
                }
                var descriptor = FetchDescriptor(predicate: predicate)
                descriptor.fetchLimit = 1

                let existing = try context.fetch(descriptor).first
                let model = AcademicUnitPersistenceMapper.toModel(unit, existing: existing)

                // Handle parent relationship if needed
                if let parentID = unit.parentUnitID {
                    let parentPredicate = #Predicate<AcademicUnitModel> { m in
                        m.id == parentID
                    }
                    var parentDescriptor = FetchDescriptor(predicate: parentPredicate)
                    parentDescriptor.fetchLimit = 1

                    if let parentModel = try context.fetch(parentDescriptor).first {
                        model.parentUnit = parentModel
                    }
                }

                if existing == nil {
                    context.insert(model)
                }

                try context.save()
            }

            if cachedUnits != nil {
                if let index = cachedUnits?.firstIndex(where: { $0.id == unit.id }) {
                    cachedUnits?[index] = unit
                } else {
                    cachedUnits?.append(unit)
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
                let predicate = #Predicate<AcademicUnitModel> { model in
                    model.id == id
                }
                var descriptor = FetchDescriptor(predicate: predicate)
                descriptor.fetchLimit = 1

                guard let model = try context.fetch(descriptor).first else {
                    throw RepositoryError.deleteFailed(reason: "AcademicUnit with id \(id) not found")
                }

                context.delete(model)
                try context.save()
            }

            cachedUnits?.removeAll { $0.id == id }
        } catch let error as RepositoryError {
            throw error
        } catch {
            throw RepositoryError.deleteFailed(reason: error.localizedDescription)
        }
    }

    public func list() async throws -> [AcademicUnit] {
        do {
            let units = try await containerProvider.perform { context in
                let descriptor = FetchDescriptor<AcademicUnitModel>()
                let models = try context.fetch(descriptor)
                return try models.map { try AcademicUnitPersistenceMapper.toDomain($0) }
            }

            cachedUnits = units
            return units
        } catch let error as RepositoryError {
            throw error
        } catch let error as DomainError {
            throw RepositoryError.fetchFailed(reason: "Failed to map academic units: \(error.localizedDescription)")
        } catch {
            throw RepositoryError.fetchFailed(reason: error.localizedDescription)
        }
    }

    public func listBySchool(schoolID: UUID) async throws -> [AcademicUnit] {
        do {
            return try await containerProvider.perform { context in
                let predicate = #Predicate<AcademicUnitModel> { model in
                    model.schoolID == schoolID
                }
                let descriptor = FetchDescriptor(predicate: predicate)
                let models = try context.fetch(descriptor)
                return try models.map { try AcademicUnitPersistenceMapper.toDomain($0) }
            }
        } catch let error as DomainError {
            throw RepositoryError.fetchFailed(reason: "Failed to map academic units: \(error.localizedDescription)")
        } catch {
            throw RepositoryError.fetchFailed(reason: error.localizedDescription)
        }
    }

    public func listChildren(parentID: UUID) async throws -> [AcademicUnit] {
        do {
            return try await containerProvider.perform { context in
                let predicate = #Predicate<AcademicUnitModel> { model in
                    model.parentUnit?.id == parentID
                }
                let descriptor = FetchDescriptor(predicate: predicate)
                let models = try context.fetch(descriptor)
                return try models.map { try AcademicUnitPersistenceMapper.toDomain($0) }
            }
        } catch let error as DomainError {
            throw RepositoryError.fetchFailed(reason: "Failed to map academic units: \(error.localizedDescription)")
        } catch {
            throw RepositoryError.fetchFailed(reason: error.localizedDescription)
        }
    }

    public func listRoots(schoolID: UUID) async throws -> [AcademicUnit] {
        do {
            return try await containerProvider.perform { context in
                let predicate = #Predicate<AcademicUnitModel> { model in
                    model.schoolID == schoolID && model.parentUnit == nil
                }
                let descriptor = FetchDescriptor(predicate: predicate)
                let models = try context.fetch(descriptor)
                return try models.map { try AcademicUnitPersistenceMapper.toDomain($0) }
            }
        } catch let error as DomainError {
            throw RepositoryError.fetchFailed(reason: "Failed to map academic units: \(error.localizedDescription)")
        } catch {
            throw RepositoryError.fetchFailed(reason: error.localizedDescription)
        }
    }
}
