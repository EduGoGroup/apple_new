import Foundation
import SwiftData
import EduCore
import EduFoundation

/// Local repository for Document entities using SwiftData
///
/// This actor implements `DocumentRepositoryProtocol` and provides thread-safe
/// CRUD operations and text search for Document entities persisted in SwiftData.
///
/// ## Thread Safety
///
/// As an actor, all operations are automatically serialized, ensuring
/// thread-safe access to the underlying SwiftData context.
///
/// ## Usage
///
/// ```swift
/// let repository = LocalDocumentRepository()
///
/// // Save a document
/// let doc = try Document(title: "Lesson 1", content: "...", type: .lesson, ownerID: userID)
/// try await repository.save(doc)
///
/// // Search documents
/// let results = try await repository.search(query: "lesson")
///
/// // Delete a document
/// try await repository.delete(id: doc.id)
/// ```
public actor LocalDocumentRepository: DocumentRepositoryProtocol {
    private let containerProvider: PersistenceContainerProvider
    private var cachedDocuments: [Document]?

    /// Creates a new LocalDocumentRepository
    ///
    /// - Parameter containerProvider: The persistence container provider (defaults to shared)
    public init(containerProvider: PersistenceContainerProvider = .shared) {
        self.containerProvider = containerProvider
    }

    /// Retrieves a document by ID
    ///
    /// - Parameter id: The document's unique identifier
    /// - Returns: The document if found, nil otherwise
    /// - Throws: `RepositoryError.fetchFailed` if the query fails
    public func get(id: UUID) async throws -> Document? {
        if let cachedDocuments = cachedDocuments {
            return cachedDocuments.first { $0.id == id }
        }

        do {
            return try await containerProvider.perform { context in
                let predicate = #Predicate<DocumentModel> { model in
                    model.id == id
                }
                var descriptor = FetchDescriptor(predicate: predicate)
                descriptor.fetchLimit = 1

                let results = try context.fetch(descriptor)

                guard let model = results.first else {
                    return nil
                }

                return try DocumentPersistenceMapper.toDomain(model)
            }
        } catch let error as RepositoryError {
            throw error
        } catch let error as DomainError {
            throw RepositoryError.fetchFailed(reason: "Failed to map document: \(error.localizedDescription)")
        } catch {
            throw RepositoryError.fetchFailed(reason: error.localizedDescription)
        }
    }

    /// Saves a document (insert or update)
    ///
    /// If a document with the same ID exists, it will be updated with:
    /// - `modifiedAt` set to current date
    /// - `version` incremented by 1
    ///
    /// - Parameter document: The document to save
    /// - Throws: `RepositoryError.saveFailed` if the save operation fails
    public func save(_ document: Document) async throws {
        do {
            let savedDocument = try await containerProvider.perform { context in
                // Check if document already exists (upsert)
                let predicate = #Predicate<DocumentModel> { model in
                    model.id == document.id
                }
                var descriptor = FetchDescriptor(predicate: predicate)
                descriptor.fetchLimit = 1

                let existing = try context.fetch(descriptor).first

                // Prepare document with updated metadata for save
                let documentToSave: Document
                if existing != nil {
                    // Update modifiedAt and increment version for existing documents
                    let updatedMetadata = document.metadata.incrementVersion(modifiedAt: Date())
                    documentToSave = try Document(
                        id: document.id,
                        title: document.title,
                        content: document.content,
                        type: document.type,
                        state: document.state,
                        metadata: updatedMetadata,
                        ownerID: document.ownerID,
                        collaboratorIDs: document.collaboratorIDs
                    )
                } else {
                    documentToSave = document
                }

                // Convert domain to model (updates existing or creates new)
                let model = DocumentPersistenceMapper.toModel(documentToSave, existing: existing)

                // Insert only if new
                if existing == nil {
                    context.insert(model)
                }

                try context.save()
                return documentToSave
            }

            if cachedDocuments != nil {
                if let index = cachedDocuments?.firstIndex(where: { $0.id == savedDocument.id }) {
                    cachedDocuments?[index] = savedDocument
                } else {
                    cachedDocuments?.append(savedDocument)
                }
            }
        } catch let error as RepositoryError {
            throw error
        } catch let error as DomainError {
            throw RepositoryError.saveFailed(reason: "Validation failed: \(error.localizedDescription)")
        } catch {
            throw RepositoryError.saveFailed(reason: error.localizedDescription)
        }
    }

    /// Deletes a document by ID
    ///
    /// - Parameter id: The document's unique identifier
    /// - Throws: `RepositoryError.deleteFailed` if the document doesn't exist or deletion fails
    public func delete(id: UUID) async throws {
        do {
            try await containerProvider.perform { context in
                let predicate = #Predicate<DocumentModel> { model in
                    model.id == id
                }
                var descriptor = FetchDescriptor(predicate: predicate)
                descriptor.fetchLimit = 1

                guard let model = try context.fetch(descriptor).first else {
                    throw RepositoryError.deleteFailed(reason: "Document with id \(id) not found")
                }

                context.delete(model)
                try context.save()
            }

            if cachedDocuments != nil {
                cachedDocuments?.removeAll { $0.id == id }
            }
        } catch let error as RepositoryError {
            throw error
        } catch {
            throw RepositoryError.deleteFailed(reason: error.localizedDescription)
        }
    }

    /// Searches documents by title or content
    ///
    /// Performs a case-insensitive search in both title and content fields.
    ///
    /// - Parameter query: The search query string
    /// - Returns: An array of matching documents (empty if no matches)
    /// - Throws: `RepositoryError.fetchFailed` if the query fails
    public func search(query: String) async throws -> [Document] {
        // Return empty for empty query
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        if let cachedDocuments = cachedDocuments {
            return cachedDocuments.filter { document in
                document.title.localizedStandardContains(query) ||
                document.content.localizedStandardContains(query)
            }
        }

        do {
            return try await containerProvider.perform { [query] context in
                let predicate = #Predicate<DocumentModel> { model in
                    model.title.localizedStandardContains(query) ||
                    model.content.localizedStandardContains(query)
                }
                let descriptor = FetchDescriptor(predicate: predicate)

                let models = try context.fetch(descriptor)

                return try models.map { model in
                    try DocumentPersistenceMapper.toDomain(model)
                }
            }
        } catch let error as RepositoryError {
            throw error
        } catch let error as DomainError {
            throw RepositoryError.fetchFailed(reason: "Failed to map documents: \(error.localizedDescription)")
        } catch {
            throw RepositoryError.fetchFailed(reason: error.localizedDescription)
        }
    }

    /// Lists all documents
    ///
    /// - Returns: An array of all documents
    /// - Throws: `RepositoryError.fetchFailed` if the query fails
    func list() async throws -> [Document] {
        do {
            let documents = try await containerProvider.perform { context in
                let descriptor = FetchDescriptor<DocumentModel>()
                let models = try context.fetch(descriptor)

                return try models.map { model in
                    try DocumentPersistenceMapper.toDomain(model)
                }
            }

            cachedDocuments = documents
            return documents
        } catch let error as RepositoryError {
            throw error
        } catch let error as DomainError {
            throw RepositoryError.fetchFailed(reason: "Failed to map documents: \(error.localizedDescription)")
        } catch {
            throw RepositoryError.fetchFailed(reason: error.localizedDescription)
        }
    }
}
