//
// LogCategoryExtensions.swift
// Logger
//
// Created by EduGo Team on 27/01/2026.
// Copyright © 2026 EduGo. All rights reserved.
//

import Foundation

// MARK: - Tier Detection

public extension LogCategory {

    /// Detecta el tier de la categoría basado en su identifier.
    ///
    /// - Returns: El número de tier (0-4) o nil si no se puede detectar
    var tier: Int? {
        if identifier.contains(".tier0.") { return 0 }
        if identifier.contains(".tier1.") { return 1 }
        if identifier.contains(".tier2.") { return 2 }
        if identifier.contains(".tier3.") { return 3 }
        if identifier.contains(".tier4.") { return 4 }
        return nil
    }

    /// Indica si la categoría pertenece a TIER-0 (Foundation).
    var isTier0: Bool { tier == 0 }

    /// Indica si la categoría pertenece a TIER-1 (Core).
    var isTier1: Bool { tier == 1 }

    /// Indica si la categoría pertenece a TIER-2 (Infrastructure).
    var isTier2: Bool { tier == 2 }

    /// Indica si la categoría pertenece a TIER-3 (Domain).
    var isTier3: Bool { tier == 3 }

    /// Indica si la categoría pertenece a TIER-4 (Features).
    var isTier4: Bool { tier == 4 }
}

// MARK: - Module Detection

public extension LogCategory {

    /// Extrae el nombre del módulo del identifier.
    ///
    /// Ejemplo: "com.edugo.tier1.logger.registry" → "logger"
    var moduleName: String? {
        let components = identifier.split(separator: ".")
        guard components.count >= 4 else { return nil }
        return String(components[3])
    }

    /// Extrae el subcomponente del identifier.
    ///
    /// Ejemplo: "com.edugo.tier1.logger.registry" → "registry"
    var subcomponent: String? {
        let components = identifier.split(separator: ".")
        guard components.count >= 5 else { return nil }
        return String(components[4])
    }
}

// MARK: - Filtering

public extension Array where Element: LogCategory {

    /// Filtra categorías por tier.
    func filterByTier(_ tier: Int) -> [Element] {
        filter { $0.tier == tier }
    }

    /// Filtra categorías por módulo.
    func filterByModule(_ moduleName: String) -> [Element] {
        filter { $0.moduleName == moduleName }
    }

    /// Filtra categorías que pertenecen a un subsistema.
    func filterBySubsystem(_ subsystem: String) -> [Element] {
        filter { $0.belongsTo(subsystem: subsystem) }
    }
}

// MARK: - Category Builder

/// Builder para crear identificadores de categoría siguiendo la convención.
public struct CategoryBuilder: Sendable {

    private let tier: Int
    private let module: String
    private var subcomponents: [String] = []

    /// Inicializa el builder con tier y módulo.
    public init(tier: Int, module: String) {
        self.tier = tier
        self.module = module
    }

    /// Añade un subcomponente.
    public func component(_ name: String) -> CategoryBuilder {
        var builder = self
        builder.subcomponents.append(name)
        return builder
    }

    /// Construye el identifier.
    public func build() -> String {
        var parts = ["com", "edugo", "tier\(tier)", module]
        parts.append(contentsOf: subcomponents)
        return parts.joined(separator: ".")
    }
}

// MARK: - Dynamic Category

/// Categoría dinámica creada en runtime.
///
/// Útil cuando necesitas crear categorías que no están predefinidas.
///
/// ## Ejemplo:
/// ```swift
/// let customCategory = DynamicLogCategory(
///     identifier: CategoryBuilder(tier: 2, module: "network")
///         .component("request")
///         .component("http")
///         .build(),
///     displayName: "Network HTTP Request"
/// )
///
/// await logger.info("Request sent", category: customCategory)
/// ```
public struct DynamicLogCategory: LogCategory, Sendable {

    public let identifier: String
    public let displayName: String

    /// Inicializa una categoría dinámica.
    ///
    /// - Parameters:
    ///   - identifier: El identifier completo de la categoría
    ///   - displayName: Nombre legible (opcional, se genera automáticamente)
    public init(identifier: String, displayName: String? = nil) {
        self.identifier = identifier
        self.displayName = displayName ?? {
            let components = identifier.split(separator: ".")
            return components
                .map { $0.prefix(1).uppercased() + $0.dropFirst() }
                .joined(separator: " ")
        }()
    }

    /// Crea una categoría usando el builder.
    public init(builder: CategoryBuilder, displayName: String? = nil) {
        self.init(identifier: builder.build(), displayName: displayName)
    }
}

// MARK: - Namespace Conveniences

public extension StandardLogCategory {

    /// Crea un builder para TIER-0.
    static func tier0(_ module: String) -> CategoryBuilder {
        CategoryBuilder(tier: 0, module: module)
    }

    /// Crea un builder para TIER-1.
    static func tier1(_ module: String) -> CategoryBuilder {
        CategoryBuilder(tier: 1, module: module)
    }

    /// Crea un builder para TIER-2.
    static func tier2(_ module: String) -> CategoryBuilder {
        CategoryBuilder(tier: 2, module: module)
    }

    /// Crea un builder para TIER-3.
    static func tier3(_ module: String) -> CategoryBuilder {
        CategoryBuilder(tier: 3, module: module)
    }

    /// Crea un builder para TIER-4.
    static func tier4(_ module: String) -> CategoryBuilder {
        CategoryBuilder(tier: 4, module: module)
    }
}

// MARK: - Validation

public extension LogCategory {

    /// Valida que el identifier siga la convención de naming.
    ///
    /// Convención: `com.edugo.tier<N>.<module>.<subcomponent>*`
    ///
    /// - Returns: `true` si el identifier es válido
    var isValidIdentifier: Bool {
        let pattern = #"^com\.edugo\.tier[0-4]\.[a-z]+(\.[a-z]+)*$"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(identifier.startIndex..., in: identifier)
        return regex?.firstMatch(in: identifier, range: range) != nil
    }

    /// Valida y retorna errores de validación.
    var validationErrors: [String] {
        var errors: [String] = []

        if !identifier.hasPrefix("com.edugo.") {
            errors.append("Identifier must start with 'com.edugo.'")
        }

        if tier == nil {
            errors.append("Identifier must contain a valid tier (tier0-tier4)")
        }

        if moduleName == nil {
            errors.append("Identifier must contain a module name")
        }

        let components = identifier.split(separator: ".")
        if components.count < 4 {
            errors.append("Identifier must have at least 4 components (com.edugo.tierN.module)")
        }

        return errors
    }
}
