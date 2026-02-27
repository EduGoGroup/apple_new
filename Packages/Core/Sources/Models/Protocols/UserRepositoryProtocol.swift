//  UserRepositoryProtocol.swift
//  Models
//
//  Copyright © 2026 EduGo. All rights reserved.
//  Licensed under the MIT License.

import Foundation

/// Resultado de una operación batch que puede tener éxitos parciales.
///
/// Encapsula los resultados exitosos y los errores de operaciones
/// que se ejecutan en lote, permitiendo al llamador decidir cómo
/// manejar fallos parciales.
public struct BatchOperationResult<T: Sendable>: Sendable {
    /// Resultados exitosos con sus índices originales.
    public let successes: [(index: Int, value: T)]

    /// Errores ocurridos con sus índices originales.
    public let failures: [(index: Int, error: String)]

    /// Indica si todas las operaciones fueron exitosas.
    public var allSucceeded: Bool {
        failures.isEmpty
    }

    /// Indica si todas las operaciones fallaron.
    public var allFailed: Bool {
        successes.isEmpty && !failures.isEmpty
    }

    /// Indica si hubo resultados mixtos (algunos éxitos, algunos fallos).
    public var hasPartialSuccess: Bool {
        !successes.isEmpty && !failures.isEmpty
    }

    /// Número total de operaciones.
    public var totalCount: Int {
        successes.count + failures.count
    }

    /// Tasa de éxito (0.0 - 1.0).
    public var successRate: Double {
        guard totalCount > 0 else { return 0 }
        return Double(successes.count) / Double(totalCount)
    }

    /// Valores exitosos en orden original.
    public var values: [T] {
        successes.sorted { $0.index < $1.index }.map { $0.value }
    }

    /// Mensajes de error en orden original.
    public var errorMessages: [String] {
        failures.sorted { $0.index < $1.index }.map { $0.error }
    }

    public init(
        successes: [(index: Int, value: T)],
        failures: [(index: Int, error: String)]
    ) {
        self.successes = successes
        self.failures = failures
    }
}

/// Protocolo que define las operaciones de repositorio para la entidad User.
///
/// Este protocolo abstrae la capa de persistencia de usuarios, permitiendo
/// implementaciones en memoria, base de datos local o red.
///
/// ## Conformance
///
/// Las implementaciones deben ser `Sendable` para garantizar thread-safety
/// en contextos de concurrencia.
///
/// ## Operaciones Single-Item
///
/// - `get(id:)`: Obtener un usuario por su ID
/// - `save(_:)`: Guardar o actualizar un usuario
/// - `delete(id:)`: Eliminar un usuario por su ID
/// - `list()`: Obtener todos los usuarios
///
/// ## Operaciones Batch
///
/// - `saveUsers(_:)`: Guardar múltiples usuarios concurrentemente
/// - `deleteUsers(ids:)`: Eliminar múltiples usuarios concurrentemente
/// - `getUsers(ids:)`: Obtener múltiples usuarios concurrentemente
///
/// ## Ejemplo de Implementación
///
/// ```swift
/// actor InMemoryUserRepository: UserRepositoryProtocol {
///     private var storage: [UUID: User] = [:]
///
///     func get(id: UUID) async throws -> User? {
///         return storage[id]
///     }
///
///     func save(_ user: User) async throws {
///         storage[user.id] = user
///     }
///
///     func delete(id: UUID) async throws {
///         storage.removeValue(forKey: id)
///     }
///
///     func list() async throws -> [User] {
///         return Array(storage.values)
///     }
///
///     // Batch operations use default implementations
/// }
/// ```
public protocol UserRepositoryProtocol: Sendable {
    // MARK: - Single-Item Operations

    /// Obtiene un usuario por su ID.
    ///
    /// - Parameter id: El UUID del usuario a buscar.
    /// - Returns: El usuario si existe, `nil` en caso contrario.
    /// - Throws: Error de repositorio si hay problemas de acceso a datos.
    func get(id: UUID) async throws -> User?

    /// Guarda o actualiza un usuario en el repositorio.
    ///
    /// Si el usuario ya existe (mismo ID), se actualiza.
    /// Si no existe, se crea nuevo.
    ///
    /// - Parameter user: El usuario a guardar.
    /// - Throws: Error de repositorio si hay problemas de persistencia.
    func save(_ user: User) async throws

    /// Elimina un usuario del repositorio por su ID.
    ///
    /// Si el usuario no existe, la operación no hace nada (idempotente).
    ///
    /// - Parameter id: El UUID del usuario a eliminar.
    /// - Throws: Error de repositorio si hay problemas de acceso a datos.
    func delete(id: UUID) async throws

    /// Obtiene todos los usuarios del repositorio.
    ///
    /// - Returns: Array con todos los usuarios. Vacío si no hay usuarios.
    /// - Throws: Error de repositorio si hay problemas de acceso a datos.
    func list() async throws -> [User]

    // MARK: - Batch Operations

    /// Guarda múltiples usuarios concurrentemente.
    ///
    /// Las operaciones se ejecutan en paralelo con un límite de concurrencia
    /// para evitar sobrecarga. Los errores parciales no detienen la operación
    /// completa.
    ///
    /// - Parameter users: Array de usuarios a guardar.
    /// - Returns: Resultado con éxitos y fallos de cada operación.
    /// - Throws: `RepositoryError` si la validación de input falla.
    ///
    /// ## Ejemplo
    ///
    /// ```swift
    /// let result = try await repository.saveUsers(usersToCreate)
    /// if result.hasPartialSuccess {
    ///     print("Guardados: \(result.successes.count), Fallidos: \(result.failures.count)")
    /// }
    /// ```
    func saveUsers(_ users: [User]) async throws -> BatchOperationResult<User>

    /// Elimina múltiples usuarios concurrentemente.
    ///
    /// Las operaciones se ejecutan en paralelo. Los errores parciales
    /// no detienen la operación completa.
    ///
    /// - Parameter ids: Array de UUIDs de usuarios a eliminar.
    /// - Returns: Resultado con éxitos (IDs eliminados) y fallos.
    /// - Throws: `RepositoryError` si la validación de input falla.
    func deleteUsers(ids: [UUID]) async throws -> BatchOperationResult<UUID>

    /// Obtiene múltiples usuarios concurrentemente.
    ///
    /// - Parameter ids: Array de UUIDs de usuarios a obtener.
    /// - Returns: Resultado con usuarios encontrados y errores.
    /// - Throws: `RepositoryError` si la validación de input falla.
    func getUsers(ids: [UUID]) async throws -> BatchOperationResult<User>
}

// MARK: - Default Implementations

extension UserRepositoryProtocol {
    /// Implementación por defecto que ejecuta saves secuencialmente.
    ///
    /// Las implementaciones concretas pueden sobrescribir esto
    /// para usar `TaskGroupCoordinator` con concurrencia real.
    public func saveUsers(_ users: [User]) async throws -> BatchOperationResult<User> {
        var successes: [(index: Int, value: User)] = []
        var failures: [(index: Int, error: String)] = []

        for (index, user) in users.enumerated() {
            do {
                try await save(user)
                successes.append((index, user))
            } catch {
                failures.append((index, error.localizedDescription))
            }
        }

        return BatchOperationResult(successes: successes, failures: failures)
    }

    /// Implementación por defecto que ejecuta deletes secuencialmente.
    public func deleteUsers(ids: [UUID]) async throws -> BatchOperationResult<UUID> {
        var successes: [(index: Int, value: UUID)] = []
        var failures: [(index: Int, error: String)] = []

        for (index, id) in ids.enumerated() {
            do {
                try await delete(id: id)
                successes.append((index, id))
            } catch {
                failures.append((index, error.localizedDescription))
            }
        }

        return BatchOperationResult(successes: successes, failures: failures)
    }

    /// Implementación por defecto que ejecuta gets secuencialmente.
    public func getUsers(ids: [UUID]) async throws -> BatchOperationResult<User> {
        var successes: [(index: Int, value: User)] = []
        var failures: [(index: Int, error: String)] = []

        for (index, id) in ids.enumerated() {
            do {
                if let user = try await get(id: id) {
                    successes.append((index, user))
                } else {
                    failures.append((index, "User not found with id: \(id)"))
                }
            } catch {
                failures.append((index, error.localizedDescription))
            }
        }

        return BatchOperationResult(successes: successes, failures: failures)
    }
}
