import Foundation
import SwiftData
import EduCore
import EduFoundation

/// Local repository for School entities using SwiftData
///
/// This actor implements `SchoolRepositoryProtocol` and provides thread-safe
/// CRUD operations for School entities persisted in SwiftData.
public actor LocalSchoolRepository: SchoolRepositoryProtocol {
    private let containerProvider: PersistenceContainerProvider
    private var cachedSchools: [School]?

    /// Creates a new LocalSchoolRepository
    ///
    /// - Parameter containerProvider: The persistence container provider (defaults to shared)
    public init(containerProvider: PersistenceContainerProvider = .shared) {
        self.containerProvider = containerProvider
    }

    public func get(id: UUID) async throws -> School? {
        if let cachedSchools = cachedSchools {
            return cachedSchools.first { $0.id == id }
        }

        do {
            return try await containerProvider.perform { context in
                let predicate = #Predicate<SchoolModel> { model in
                    model.id == id
                }
                var descriptor = FetchDescriptor(predicate: predicate)
                descriptor.fetchLimit = 1

                guard let model = try context.fetch(descriptor).first else {
                    return nil
                }

                return try SchoolPersistenceMapper.toDomain(model)
            }
        } catch let error as RepositoryError {
            throw error
        } catch let error as DomainError {
            throw RepositoryError.fetchFailed(reason: "Failed to map school: \(error.localizedDescription)")
        } catch {
            throw RepositoryError.fetchFailed(reason: error.localizedDescription)
        }
    }

    public func getByCode(code: String) async throws -> School? {
        do {
            return try await containerProvider.perform { context in
                let predicate = #Predicate<SchoolModel> { model in
                    model.code == code
                }
                var descriptor = FetchDescriptor(predicate: predicate)
                descriptor.fetchLimit = 1

                guard let model = try context.fetch(descriptor).first else {
                    return nil
                }

                return try SchoolPersistenceMapper.toDomain(model)
            }
        } catch let error as DomainError {
            throw RepositoryError.fetchFailed(reason: "Failed to map school: \(error.localizedDescription)")
        } catch {
            throw RepositoryError.fetchFailed(reason: error.localizedDescription)
        }
    }

    public func save(_ school: School) async throws {
        do {
            try await containerProvider.perform { context in
                let predicate = #Predicate<SchoolModel> { model in
                    model.id == school.id
                }
                var descriptor = FetchDescriptor(predicate: predicate)
                descriptor.fetchLimit = 1

                let existing = try context.fetch(descriptor).first
                let model = SchoolPersistenceMapper.toModel(school, existing: existing)

                if existing == nil {
                    context.insert(model)
                }

                try context.save()
            }

            if cachedSchools != nil {
                if let index = cachedSchools?.firstIndex(where: { $0.id == school.id }) {
                    cachedSchools?[index] = school
                } else {
                    cachedSchools?.append(school)
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
                let predicate = #Predicate<SchoolModel> { model in
                    model.id == id
                }
                var descriptor = FetchDescriptor(predicate: predicate)
                descriptor.fetchLimit = 1

                guard let model = try context.fetch(descriptor).first else {
                    throw RepositoryError.deleteFailed(reason: "School with id \(id) not found")
                }

                context.delete(model)
                try context.save()
            }

            cachedSchools?.removeAll { $0.id == id }
        } catch let error as RepositoryError {
            throw error
        } catch {
            throw RepositoryError.deleteFailed(reason: error.localizedDescription)
        }
    }

    public func list() async throws -> [School] {
        do {
            let schools = try await containerProvider.perform { context in
                let descriptor = FetchDescriptor<SchoolModel>()
                let models = try context.fetch(descriptor)
                return try models.map { try SchoolPersistenceMapper.toDomain($0) }
            }

            cachedSchools = schools
            return schools
        } catch let error as RepositoryError {
            throw error
        } catch let error as DomainError {
            throw RepositoryError.fetchFailed(reason: "Failed to map schools: \(error.localizedDescription)")
        } catch {
            throw RepositoryError.fetchFailed(reason: error.localizedDescription)
        }
    }
}
