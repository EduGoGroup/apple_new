//  UserContextProtocol.swift
//  EduGoCommon
//
//  Copyright © 2026 EduGo. All rights reserved.
//  Licensed under the MIT License.

import Foundation

/// Protocolo que define el contexto del usuario autenticado.
///
/// Este protocolo abstrae la información del usuario que otros módulos necesitan
/// sin crear dependencias directas con el módulo de autenticación.
///
/// ## Propósito
///
/// Permite que módulos como Roles, Analytics, etc. accedan a información básica
/// del usuario sin depender directamente de AuthManager, manteniendo así la
/// independencia modular.
///
/// ## Thread Safety
///
/// Las implementaciones de este protocolo deben garantizar thread-safety.
/// Se recomienda usar `actor` para implementaciones concretas.
///
/// ## Uso en TIER-0
///
/// Este protocolo se define en TIER-0 (Foundation) para que pueda ser usado
/// por cualquier módulo de tiers superiores sin crear dependencias circulares.
///
/// ## Ejemplo de Implementación
///
/// ```swift
/// // En TIER-3 Auth module
/// public actor AuthManager: UserContextProtocol {
///     public var currentUserId: UUID? { ... }
///     public var isAuthenticated: Bool { ... }
/// }
/// ```
///
/// ## Ejemplo de Uso
///
/// ```swift
/// // En TIER-3 Roles module
/// public actor RolesManager {
///     private let userContext: any UserContextProtocol
///
///     public init(userContext: any UserContextProtocol) {
///         self.userContext = userContext
///     }
///
///     public func loadUserRole() async {
///         guard let userId = await userContext.currentUserId else { return }
///         // Load role for user...
///     }
/// }
/// ```
public protocol UserContextProtocol: Sendable {
    /// ID del usuario actualmente autenticado.
    ///
    /// - Returns: UUID del usuario si está autenticado, `nil` en caso contrario.
    var currentUserId: UUID? { get async }

    /// Indica si hay un usuario autenticado en el sistema.
    ///
    /// - Returns: `true` si hay un usuario autenticado, `false` en caso contrario.
    var isAuthenticated: Bool { get async }

    /// Email del usuario actualmente autenticado.
    ///
    /// Esta propiedad es útil para logging, analytics y debugging.
    ///
    /// - Returns: Email del usuario si está autenticado, `nil` en caso contrario.
    var currentUserEmail: String? { get async }
}
