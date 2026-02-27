// MenuItem.swift
// EduDomain
//
// Domain model representing a filtered, permission-aware menu item.

import Foundation

/// Elemento de menu filtrado por permisos del usuario.
///
/// A diferencia de `MenuItemDTO` (raw del backend), `MenuItem` ya ha sido
/// procesado por `MenuFilter` y solo contiene items visibles para el usuario.
public struct MenuItem: Sendable, Identifiable, Equatable {

    /// Clave unica del item.
    public let key: String

    /// Nombre visible del item.
    public let displayName: String

    /// Icono del backend (Material Icon name).
    public let icon: String?

    /// Orden de visualizacion.
    public let sortOrder: Int

    /// Mapa de screen slots a screen keys.
    public let screens: [String: String]

    /// Hijos filtrados por permisos.
    public let children: [MenuItem]

    /// Permisos requeridos para ver este item.
    public let requiredPermissions: [String]

    /// Identifiable conformance.
    public var id: String { key }

    public init(
        key: String,
        displayName: String,
        icon: String? = nil,
        sortOrder: Int,
        screens: [String: String] = [:],
        children: [MenuItem] = [],
        requiredPermissions: [String] = []
    ) {
        self.key = key
        self.displayName = displayName
        self.icon = icon
        self.sortOrder = sortOrder
        self.screens = screens
        self.children = children
        self.requiredPermissions = requiredPermissions
    }
}
