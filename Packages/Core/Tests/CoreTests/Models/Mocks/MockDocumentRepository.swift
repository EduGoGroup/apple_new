//
// MockDocumentRepository.swift
// ModelsTests
//
// Created by EduGo Team on 27/01/2026.
// Copyright © 2026 EduGo. All rights reserved.
//

import Foundation
@testable import EduModels

/// Mock de DocumentRepository para testing que captura llamadas y permite configurar respuestas.
///
/// Permite verificar que las operaciones de repositorio se llaman correctamente
/// sin depender de una base de datos real. Thread-safe mediante actor isolation.
///
/// ## Ejemplo de uso:
/// ```swift
/// let mock = MockDocumentRepository()
/// let doc = try Document(title: "Test", content: "Content", type: .lesson, ownerID: UUID())
/// mock.stubbedDocument = doc
///
/// let result = try await mock.get(id: doc.id)
/// #expect(result == doc)
/// #expect(await mock.getCallCount == 1)
/// ```
public actor MockDocumentRepository: DocumentRepositoryProtocol {

    // MARK: - Storage

    /// Almacenamiento interno de documentos.
    private var storage: [UUID: Document] = [:]

    // MARK: - Stubbed Responses

    /// Documento a retornar en `get(id:)`. Si es nil, busca en storage.
    public var stubbedDocument: Document?

    /// Resultados a retornar en `search(query:)`. Si es nil, realiza búsqueda en storage.
    public var stubbedSearchResults: [Document]?

    /// Error a lanzar en cualquier operación. Si está configurado, se lanza antes de ejecutar.
    public var stubbedError: Error?

    // MARK: - Call Tracking

    /// Número de veces que se llamó a `get(id:)`.
    public private(set) var getCallCount = 0

    /// Último ID usado en `get(id:)`.
    public private(set) var lastGetID: UUID?

    /// Número de veces que se llamó a `save(_:)`.
    public private(set) var saveCallCount = 0

    /// Último documento guardado con `save(_:)`.
    public private(set) var lastSavedDocument: Document?

    /// Número de veces que se llamó a `delete(id:)`.
    public private(set) var deleteCallCount = 0

    /// Último ID usado en `delete(id:)`.
    public private(set) var lastDeleteID: UUID?

    /// Número de veces que se llamó a `search(query:)`.
    public private(set) var searchCallCount = 0

    /// Última consulta usada en `search(query:)`.
    public private(set) var lastSearchQuery: String?

    // MARK: - Initialization

    public init() {}

    /// Inicializa con documentos precargados.
    public init(documents: [Document]) {
        for document in documents {
            storage[document.id] = document
        }
    }

    // MARK: - DocumentRepositoryProtocol

    public func get(id: UUID) async throws -> Document? {
        getCallCount += 1
        lastGetID = id

        if let error = stubbedError {
            throw error
        }

        if let stubbed = stubbedDocument {
            return stubbed
        }

        return storage[id]
    }

    public func save(_ document: Document) async throws {
        saveCallCount += 1
        lastSavedDocument = document

        if let error = stubbedError {
            throw error
        }

        storage[document.id] = document
    }

    public func delete(id: UUID) async throws {
        deleteCallCount += 1
        lastDeleteID = id

        if let error = stubbedError {
            throw error
        }

        storage.removeValue(forKey: id)
    }

    public func search(query: String) async throws -> [Document] {
        searchCallCount += 1
        lastSearchQuery = query

        if let error = stubbedError {
            throw error
        }

        if let stubbed = stubbedSearchResults {
            return stubbed
        }

        // Búsqueda simple en título y contenido
        let lowercasedQuery = query.lowercased()
        return storage.values.filter { doc in
            doc.title.lowercased().contains(lowercasedQuery) ||
            doc.content.lowercased().contains(lowercasedQuery)
        }
    }

    // MARK: - Test Helpers

    /// Limpia todo el estado del mock.
    public func reset() {
        storage.removeAll()
        stubbedDocument = nil
        stubbedSearchResults = nil
        stubbedError = nil
        getCallCount = 0
        lastGetID = nil
        saveCallCount = 0
        lastSavedDocument = nil
        deleteCallCount = 0
        lastDeleteID = nil
        searchCallCount = 0
        lastSearchQuery = nil
    }

    /// Limpia solo los contadores de llamadas.
    public func resetCallCounts() {
        getCallCount = 0
        lastGetID = nil
        saveCallCount = 0
        lastSavedDocument = nil
        deleteCallCount = 0
        lastDeleteID = nil
        searchCallCount = 0
        lastSearchQuery = nil
    }

    /// Número total de documentos en el storage.
    public var count: Int {
        storage.count
    }

    /// Verifica si un documento existe en el storage.
    public func contains(id: UUID) -> Bool {
        storage[id] != nil
    }

    /// Obtiene todos los documentos del storage interno.
    public var allStoredDocuments: [Document] {
        Array(storage.values)
    }

    /// Precarga documentos en el storage para testing.
    public func preload(_ documents: [Document]) {
        for document in documents {
            storage[document.id] = document
        }
    }

    /// Filtra documentos por tipo.
    public func documents(ofType type: DocumentType) -> [Document] {
        storage.values.filter { $0.type == type }
    }

    /// Filtra documentos por estado.
    public func documents(inState state: DocumentState) -> [Document] {
        storage.values.filter { $0.state == state }
    }

    /// Filtra documentos por propietario.
    public func documents(ownedBy ownerID: UUID) -> [Document] {
        storage.values.filter { $0.ownerID == ownerID }
    }

    /// Verifica que se llamó a save con un documento de título específico.
    public func verifySaved(documentWithTitle title: String) -> Bool {
        lastSavedDocument?.title == title
    }

    /// Verifica que se llamó a delete con un ID específico.
    public func verifyDeleted(id: UUID) -> Bool {
        lastDeleteID == id
    }

    /// Verifica que se llamó a search con una consulta específica.
    public func verifySearched(query: String) -> Bool {
        lastSearchQuery == query
    }
}
