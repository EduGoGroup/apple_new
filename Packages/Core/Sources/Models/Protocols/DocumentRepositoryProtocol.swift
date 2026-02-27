//  DocumentRepositoryProtocol.swift
//  Models
//
//  Copyright © 2026 EduGo. All rights reserved.
//  Licensed under the MIT License.

import Foundation

/// Protocolo que define las operaciones de repositorio para la entidad Document.
///
/// Este protocolo abstrae la capa de persistencia de documentos, permitiendo
/// implementaciones en memoria, base de datos local o red.
///
/// ## Conformance
///
/// Las implementaciones deben ser `Sendable` para garantizar thread-safety
/// en contextos de concurrencia.
///
/// ## Operaciones
///
/// - `get(id:)`: Obtener un documento por su ID
/// - `save(_:)`: Guardar o actualizar un documento
/// - `delete(id:)`: Eliminar un documento por su ID
/// - `search(query:)`: Buscar documentos por texto
///
/// ## Ejemplo de Implementación
///
/// ```swift
/// actor InMemoryDocumentRepository: DocumentRepositoryProtocol {
///     private var storage: [UUID: Document] = [:]
///
///     func get(id: UUID) async throws -> Document? {
///         return storage[id]
///     }
///
///     func save(_ document: Document) async throws {
///         storage[document.id] = document
///     }
///
///     func delete(id: UUID) async throws {
///         storage.removeValue(forKey: id)
///     }
///
///     func search(query: String) async throws -> [Document] {
///         let lowercasedQuery = query.lowercased()
///         return storage.values.filter { doc in
///             doc.title.lowercased().contains(lowercasedQuery) ||
///             doc.content.lowercased().contains(lowercasedQuery)
///         }
///     }
/// }
/// ```
///
/// ## Testing
///
/// ```swift
/// final class MockDocumentRepository: DocumentRepositoryProtocol, @unchecked Sendable {
///     var documents: [UUID: Document] = [:]
///     var searchResults: [Document] = []
///
///     func search(query: String) async throws -> [Document] {
///         return searchResults
///     }
///     // ... otros métodos
/// }
/// ```
public protocol DocumentRepositoryProtocol: Sendable {
    /// Obtiene un documento por su ID.
    ///
    /// - Parameter id: El UUID del documento a buscar.
    /// - Returns: El documento si existe, `nil` en caso contrario.
    /// - Throws: Error de repositorio si hay problemas de acceso a datos.
    func get(id: UUID) async throws -> Document?

    /// Guarda o actualiza un documento en el repositorio.
    ///
    /// Si el documento ya existe (mismo ID), se actualiza.
    /// Si no existe, se crea nuevo.
    ///
    /// - Parameter document: El documento a guardar.
    /// - Throws: Error de repositorio si hay problemas de persistencia.
    func save(_ document: Document) async throws

    /// Elimina un documento del repositorio por su ID.
    ///
    /// Si el documento no existe, la operación no hace nada (idempotente).
    ///
    /// - Parameter id: El UUID del documento a eliminar.
    /// - Throws: Error de repositorio si hay problemas de acceso a datos.
    func delete(id: UUID) async throws

    /// Busca documentos que coincidan con la consulta.
    ///
    /// La búsqueda se realiza sobre el título y contenido del documento.
    /// La implementación específica determina el algoritmo de matching.
    ///
    /// - Parameter query: Texto de búsqueda.
    /// - Returns: Array de documentos que coinciden. Vacío si no hay resultados.
    /// - Throws: Error de repositorio si hay problemas de acceso a datos.
    func search(query: String) async throws -> [Document]
}
