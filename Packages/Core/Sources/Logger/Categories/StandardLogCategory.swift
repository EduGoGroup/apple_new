//
// StandardLogCategory.swift
// Logger
//
// Created by EduGo Team on 27/01/2026.
// Copyright © 2026 EduGo. All rights reserved.
//

import Foundation

/// Categorías de logging estándar para módulos TIER 0 y TIER 1.
///
/// Define categorías organizadas por módulo y subcomponente, siguiendo la
/// convención de naming `com.edugo.<tier>.<module>.<subcomponent>`.
///
/// ## Convención de Naming:
/// - Formato: `com.edugo.<tier>.<module>.<subcomponent>`
/// - Ejemplos:
///   - `com.edugo.tier0.common.entity`
///   - `com.edugo.tier1.logger.registry`
///   - `com.edugo.tier1.models.user`
///
/// ## Uso:
/// ```swift
/// await logger.info("Entidad creada", category: StandardLogCategory.TIER0.entity)
/// await logger.debug("Registry configurado", category: StandardLogCategory.TIER1.loggerRegistry)
/// ```
public enum StandardLogCategory {

    // MARK: - TIER 0: Foundation

    /// Categorías para módulo EduGoCommon (TIER-0).
    public enum TIER0: String, LogCategory {

        // Entity Protocol
        case entity = "com.edugo.tier0.common.entity"
        case entityEquality = "com.edugo.tier0.common.entity.equality"
        case entityIdentity = "com.edugo.tier0.common.entity.identity"

        // Repository Protocol
        case repository = "com.edugo.tier0.common.repository"
        case repositoryFetch = "com.edugo.tier0.common.repository.fetch"
        case repositoryCreate = "com.edugo.tier0.common.repository.create"
        case repositoryUpdate = "com.edugo.tier0.common.repository.update"
        case repositoryDelete = "com.edugo.tier0.common.repository.delete"

        // UseCase Protocol
        case useCase = "com.edugo.tier0.common.usecase"
        case useCaseExecution = "com.edugo.tier0.common.usecase.execution"
        case useCaseValidation = "com.edugo.tier0.common.usecase.validation"

        // Error Handling
        case error = "com.edugo.tier0.common.error"
        case domainError = "com.edugo.tier0.common.error.domain"
        case repositoryError = "com.edugo.tier0.common.error.repository"
        case useCaseError = "com.edugo.tier0.common.error.usecase"

        // General
        case system = "com.edugo.tier0.common.system"
        case lifecycle = "com.edugo.tier0.common.lifecycle"
    }

    // MARK: - TIER 1: Core

    /// Categorías para módulo Logger (TIER-1).
    public enum Logger: String, LogCategory {

        // Core Logger
        case system = "com.edugo.tier1.logger.system"
        case adapter = "com.edugo.tier1.logger.adapter"
        case factory = "com.edugo.tier1.logger.factory"

        // Registry
        case registry = "com.edugo.tier1.logger.registry"
        case registryCache = "com.edugo.tier1.logger.registry.cache"
        case registryCategory = "com.edugo.tier1.logger.registry.category"

        // Configuration
        case configuration = "com.edugo.tier1.logger.configuration"
        case configurator = "com.edugo.tier1.logger.configurator"
        case environment = "com.edugo.tier1.logger.environment"

        // Categories
        case category = "com.edugo.tier1.logger.category"
        case categoryManagement = "com.edugo.tier1.logger.category.management"

        // Performance
        case performance = "com.edugo.tier1.logger.performance"
    }

    /// Categorías para módulo Models (TIER-1).
    public enum Models: String, LogCategory {

        // User Models
        case user = "com.edugo.tier1.models.user"
        case userProfile = "com.edugo.tier1.models.user.profile"
        case userPreferences = "com.edugo.tier1.models.user.preferences"

        // Data Models
        case model = "com.edugo.tier1.models.system"
        case modelValidation = "com.edugo.tier1.models.validation"
        case modelSerialization = "com.edugo.tier1.models.serialization"

        // Relationships
        case relationships = "com.edugo.tier1.models.relationships"
    }
}

// MARK: - Convenience Extensions

public extension StandardLogCategory.TIER0 {

    /// Todas las categorías de Entity.
    static var entityCategories: [StandardLogCategory.TIER0] {
        [.entity, .entityEquality, .entityIdentity]
    }

    /// Todas las categorías de Repository.
    static var repositoryCategories: [StandardLogCategory.TIER0] {
        [.repository, .repositoryFetch, .repositoryCreate, .repositoryUpdate, .repositoryDelete]
    }

    /// Todas las categorías de UseCase.
    static var useCaseCategories: [StandardLogCategory.TIER0] {
        [.useCase, .useCaseExecution, .useCaseValidation]
    }

    /// Todas las categorías de Error.
    static var errorCategories: [StandardLogCategory.TIER0] {
        [.error, .domainError, .repositoryError, .useCaseError]
    }

    /// Todas las categorías de TIER-0.
    static var allCategories: [StandardLogCategory.TIER0] {
        entityCategories + repositoryCategories + useCaseCategories + errorCategories + [.system, .lifecycle]
    }
}

public extension StandardLogCategory.Logger {

    /// Todas las categorías de Registry.
    static var registryCategories: [StandardLogCategory.Logger] {
        [.registry, .registryCache, .registryCategory]
    }

    /// Todas las categorías de Configuration.
    static var configurationCategories: [StandardLogCategory.Logger] {
        [.configuration, .configurator, .environment]
    }

    /// Todas las categorías de Logger.
    static var allCategories: [StandardLogCategory.Logger] {
        [.system, .adapter, .factory] + registryCategories + configurationCategories +
        [.category, .categoryManagement, .performance]
    }
}

public extension StandardLogCategory.Models {

    /// Todas las categorías de User.
    static var userCategories: [StandardLogCategory.Models] {
        [.user, .userProfile, .userPreferences]
    }

    /// Todas las categorías de Models.
    static var allCategories: [StandardLogCategory.Models] {
        userCategories + [.model, .modelValidation, .modelSerialization, .relationships]
    }
}

// MARK: - Registration Helpers

public extension LoggerRegistry {

    /// Registra todas las categorías de TIER-0.
    @discardableResult
    func registerTIER0Categories() async -> Int {
        await register(categories: StandardLogCategory.TIER0.allCategories)
    }

    /// Registra todas las categorías de Logger.
    @discardableResult
    func registerLoggerCategories() async -> Int {
        await register(categories: StandardLogCategory.Logger.allCategories)
    }

    /// Registra todas las categorías de Models.
    @discardableResult
    func registerModelsCategories() async -> Int {
        await register(categories: StandardLogCategory.Models.allCategories)
    }

    /// Registra todas las categorías estándar (TIER 0-1).
    @discardableResult
    func registerAllStandardCategories() async -> Int {
        let tier0 = await registerTIER0Categories()
        let logger = await registerLoggerCategories()
        let models = await registerModelsCategories()
        let system = await registerSystemCategories()

        return tier0 + logger + models + system
    }
}
