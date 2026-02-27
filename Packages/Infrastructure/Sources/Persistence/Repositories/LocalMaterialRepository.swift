import Foundation
import SwiftData
import EduCore
import EduFoundation

/// Local repository for Material entities using SwiftData
///
/// This actor implements `MaterialRepositoryProtocol` and provides thread-safe
/// CRUD operations for Material entities persisted in SwiftData.
public actor LocalMaterialRepository: MaterialRepositoryProtocol {
    private let containerProvider: PersistenceContainerProvider
    private var cachedMaterials: [Material]?

    /// Creates a new LocalMaterialRepository
    ///
    /// - Parameter containerProvider: The persistence container provider (defaults to shared)
    public init(containerProvider: PersistenceContainerProvider = .shared) {
        self.containerProvider = containerProvider
    }

    public func get(id: UUID) async throws -> Material? {
        if let cachedMaterials = cachedMaterials {
            return cachedMaterials.first { $0.id == id }
        }

        do {
            return try await containerProvider.perform { context in
                let predicate = #Predicate<MaterialModel> { model in
                    model.id == id
                }
                var descriptor = FetchDescriptor(predicate: predicate)
                descriptor.fetchLimit = 1

                guard let model = try context.fetch(descriptor).first else {
                    return nil
                }

                return try MaterialPersistenceMapper.toDomain(model)
            }
        } catch let error as RepositoryError {
            throw error
        } catch let error as DomainError {
            throw RepositoryError.fetchFailed(reason: "Failed to map material: \(error.localizedDescription)")
        } catch {
            throw RepositoryError.fetchFailed(reason: error.localizedDescription)
        }
    }

    public func save(_ material: Material) async throws {
        do {
            try await containerProvider.perform { context in
                let predicate = #Predicate<MaterialModel> { model in
                    model.id == material.id
                }
                var descriptor = FetchDescriptor(predicate: predicate)
                descriptor.fetchLimit = 1

                let existing = try context.fetch(descriptor).first
                let model = MaterialPersistenceMapper.toModel(material, existing: existing)

                if existing == nil {
                    context.insert(model)
                }

                try context.save()
            }

            if cachedMaterials != nil {
                if let index = cachedMaterials?.firstIndex(where: { $0.id == material.id }) {
                    cachedMaterials?[index] = material
                } else {
                    cachedMaterials?.append(material)
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
                let predicate = #Predicate<MaterialModel> { model in
                    model.id == id
                }
                var descriptor = FetchDescriptor(predicate: predicate)
                descriptor.fetchLimit = 1

                guard let model = try context.fetch(descriptor).first else {
                    throw RepositoryError.deleteFailed(reason: "Material with id \(id) not found")
                }

                context.delete(model)
                try context.save()
            }

            cachedMaterials?.removeAll { $0.id == id }
        } catch let error as RepositoryError {
            throw error
        } catch {
            throw RepositoryError.deleteFailed(reason: error.localizedDescription)
        }
    }

    public func list() async throws -> [Material] {
        do {
            let materials = try await containerProvider.perform { context in
                let descriptor = FetchDescriptor<MaterialModel>()
                let models = try context.fetch(descriptor)
                return try models.map { try MaterialPersistenceMapper.toDomain($0) }
            }

            cachedMaterials = materials
            return materials
        } catch let error as RepositoryError {
            throw error
        } catch let error as DomainError {
            throw RepositoryError.fetchFailed(reason: "Failed to map materials: \(error.localizedDescription)")
        } catch {
            throw RepositoryError.fetchFailed(reason: error.localizedDescription)
        }
    }

    public func listBySchool(schoolID: UUID) async throws -> [Material] {
        do {
            return try await containerProvider.perform { context in
                let predicate = #Predicate<MaterialModel> { model in
                    model.schoolID == schoolID
                }
                let descriptor = FetchDescriptor(predicate: predicate)
                let models = try context.fetch(descriptor)
                return try models.map { try MaterialPersistenceMapper.toDomain($0) }
            }
        } catch let error as DomainError {
            throw RepositoryError.fetchFailed(reason: "Failed to map materials: \(error.localizedDescription)")
        } catch {
            throw RepositoryError.fetchFailed(reason: error.localizedDescription)
        }
    }

    public func listByAcademicUnit(unitID: UUID) async throws -> [Material] {
        do {
            return try await containerProvider.perform { context in
                let predicate = #Predicate<MaterialModel> { model in
                    model.academicUnitID == unitID
                }
                let descriptor = FetchDescriptor(predicate: predicate)
                let models = try context.fetch(descriptor)
                return try models.map { try MaterialPersistenceMapper.toDomain($0) }
            }
        } catch let error as DomainError {
            throw RepositoryError.fetchFailed(reason: "Failed to map materials: \(error.localizedDescription)")
        } catch {
            throw RepositoryError.fetchFailed(reason: error.localizedDescription)
        }
    }
}
