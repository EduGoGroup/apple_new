//
// MockUserRepository.swift
// ModelsTests
//
// Created by EduGo Team on 27/01/2026.
// Copyright © 2026 EduGo. All rights reserved.
//

import Foundation
@testable import EduModels

/// Mock de UserRepository para testing que captura llamadas y permite configurar respuestas.
///
/// Permite verificar que las operaciones de repositorio se llaman correctamente
/// sin depender de una base de datos real. Thread-safe mediante actor isolation.
///
/// ## Ejemplo de uso:
/// ```swift
/// let mock = MockUserRepository()
/// let user = try User(firstName: "Test", lastName: "User", email: "test@example.com")
/// mock.stubbedUser = user
///
/// let result = try await mock.get(id: user.id)
/// #expect(result == user)
/// #expect(await mock.getCallCount == 1)
/// ```
public actor MockUserRepository: UserRepositoryProtocol {

    // MARK: - Storage

    /// Almacenamiento interno de usuarios.
    private var storage: [UUID: User] = [:]

    // MARK: - Stubbed Responses

    /// Usuario a retornar en `get(id:)`. Si es nil, busca en storage.
    public var stubbedUser: User?

    /// Lista de usuarios a retornar en `list()`. Si es nil, retorna storage.values.
    public var stubbedUsers: [User]?

    /// Error a lanzar en cualquier operación. Si está configurado, se lanza antes de ejecutar.
    public var stubbedError: Error?

    // MARK: - Call Tracking

    /// Número de veces que se llamó a `get(id:)`.
    public private(set) var getCallCount = 0

    /// Último ID usado en `get(id:)`.
    public private(set) var lastGetID: UUID?

    /// Número de veces que se llamó a `save(_:)`.
    public private(set) var saveCallCount = 0

    /// Último usuario guardado con `save(_:)`.
    public private(set) var lastSavedUser: User?

    /// Número de veces que se llamó a `delete(id:)`.
    public private(set) var deleteCallCount = 0

    /// Último ID usado en `delete(id:)`.
    public private(set) var lastDeleteID: UUID?

    /// Número de veces que se llamó a `list()`.
    public private(set) var listCallCount = 0

    // MARK: - Initialization

    public init() {}

    /// Inicializa con usuarios precargados.
    public init(users: [User]) {
        for user in users {
            storage[user.id] = user
        }
    }

    // MARK: - UserRepositoryProtocol

    public func get(id: UUID) async throws -> User? {
        getCallCount += 1
        lastGetID = id

        if let error = stubbedError {
            throw error
        }

        if let stubbed = stubbedUser {
            return stubbed
        }

        return storage[id]
    }

    public func save(_ user: User) async throws {
        saveCallCount += 1
        lastSavedUser = user

        if let error = stubbedError {
            throw error
        }

        storage[user.id] = user
    }

    public func delete(id: UUID) async throws {
        deleteCallCount += 1
        lastDeleteID = id

        if let error = stubbedError {
            throw error
        }

        storage.removeValue(forKey: id)
    }

    public func list() async throws -> [User] {
        listCallCount += 1

        if let error = stubbedError {
            throw error
        }

        if let stubbed = stubbedUsers {
            return stubbed
        }

        return Array(storage.values)
    }

    // MARK: - Test Helpers

    /// Limpia todo el estado del mock.
    public func reset() {
        storage.removeAll()
        stubbedUser = nil
        stubbedUsers = nil
        stubbedError = nil
        getCallCount = 0
        lastGetID = nil
        saveCallCount = 0
        lastSavedUser = nil
        deleteCallCount = 0
        lastDeleteID = nil
        listCallCount = 0
    }

    /// Limpia solo los contadores de llamadas.
    public func resetCallCounts() {
        getCallCount = 0
        lastGetID = nil
        saveCallCount = 0
        lastSavedUser = nil
        deleteCallCount = 0
        lastDeleteID = nil
        listCallCount = 0
    }

    /// Número total de usuarios en el storage.
    public var count: Int {
        storage.count
    }

    /// Verifica si un usuario existe en el storage.
    public func contains(id: UUID) -> Bool {
        storage[id] != nil
    }

    /// Obtiene todos los usuarios del storage interno.
    public var allStoredUsers: [User] {
        Array(storage.values)
    }

    /// Precarga usuarios en el storage para testing.
    public func preload(_ users: [User]) {
        for user in users {
            storage[user.id] = user
        }
    }

    /// Verifica que se llamó a save con un usuario específico.
    public func verifySaved(userWithEmail email: String) -> Bool {
        lastSavedUser?.email == email
    }

    /// Verifica que se llamó a delete con un ID específico.
    public func verifyDeleted(id: UUID) -> Bool {
        lastDeleteID == id
    }
}
