//
// LogCategory.swift
// Logger
//
// Created by EduGo Team on 27/01/2026.
// Copyright © 2026 EduGo. All rights reserved.
//

import Foundation

/// Protocolo para categorización de logs por módulo o funcionalidad.
///
/// Las categorías permiten filtrar y organizar logs según su origen, facilitando
/// el debugging y el análisis de comportamiento por módulo. Cada módulo del sistema
/// puede definir sus propias categorías implementando este protocolo.
///
/// ## Ejemplo de uso:
/// ```swift
/// enum AuthCategory: String, LogCategory {
///     case login = "auth.login"
///     case logout = "auth.logout"
///     case tokenRefresh = "auth.token"
/// }
///
/// await logger.info("Usuario autenticado", category: AuthCategory.login)
/// ```
public protocol LogCategory: Sendable {

    /// Identificador único de la categoría.
    ///
    /// Debe seguir la convención de reverse-domain notation:
    /// - `com.edugo.auth.login`
    /// - `com.edugo.network.request`
    /// - `com.edugo.database.query`
    var identifier: String { get }

    /// Nombre legible de la categoría para UI/debugging.
    var displayName: String { get }
}

// MARK: - Default Implementation

public extension LogCategory where Self: RawRepresentable, RawValue == String {

    /// Implementación por defecto usando el rawValue como identifier.
    var identifier: String { rawValue }

    /// Implementación por defecto del nombre de display.
    var displayName: String {
        // Convertir "auth.login" → "Auth Login"
        let components = identifier.split(separator: ".")
        return components
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}

// MARK: - Predefined Categories

/// Categorías predefinidas del sistema para TIER-0 y TIER-1.
public enum SystemLogCategory: String, LogCategory {

    // TIER-0 Categories
    case commonError = "com.edugo.common.error"
    case commonDomain = "com.edugo.common.domain"
    case commonRepository = "com.edugo.common.repository"
    case commonUseCase = "com.edugo.common.usecase"

    // TIER-1 Categories
    case logger = "com.edugo.logger.system"
    case loggerRegistry = "com.edugo.logger.registry"
    case loggerConfig = "com.edugo.logger.config"

    // General
    case system = "com.edugo.system"
    case performance = "com.edugo.performance"
    case network = "com.edugo.network"
    case database = "com.edugo.database"
}

// MARK: - Category Extensions

public extension LogCategory {

    /// Verifica si esta categoría pertenece a un subsistema específico.
    ///
    /// - Parameter subsystem: El subsistema a verificar (ej: "auth", "network")
    /// - Returns: `true` si el identifier contiene el subsistema
    func belongsTo(subsystem: String) -> Bool {
        identifier.contains(subsystem)
    }
}
