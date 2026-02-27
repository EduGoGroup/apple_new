// MenuFilter.swift
// EduDomain
//
// Static filter logic for transforming MenuItemDTOs into permission-aware MenuItems.

import EduCore

/// Filtro que transforma `MenuItemDTO` en `MenuItem` aplicando permisos.
///
/// Reglas de filtrado:
/// - Un item es visible si el usuario tiene AL MENOS uno de sus permisos requeridos
/// - Un item sin permisos requeridos es visible para todos
/// - Un padre es visible si tiene hijos visibles, incluso sin permiso propio
/// - Los resultados se ordenan por `sortOrder`
public struct MenuFilter: Sendable {

    /// Filtra items del menu segun los permisos del usuario.
    ///
    /// - Parameters:
    ///   - items: Items crudos del backend.
    ///   - permissions: Permisos del usuario actual.
    /// - Returns: Items filtrados y ordenados.
    public static func filter(items: [MenuItemDTO], permissions: [String]) -> [MenuItem] {
        let permissionSet = Set(permissions)
        return filterRecursive(items: items, permissionSet: permissionSet)
    }

    private static func filterRecursive(items: [MenuItemDTO], permissionSet: Set<String>) -> [MenuItem] {
        var result: [MenuItem] = []

        for dto in items {
            let filteredChildren = filterRecursive(
                items: dto.children ?? [],
                permissionSet: permissionSet
            )

            let hasPermission = dto.permissions.isEmpty
                || dto.permissions.contains(where: { permissionSet.contains($0) })

            let isVisible = hasPermission || !filteredChildren.isEmpty

            if isVisible {
                let item = MenuItem(
                    key: dto.key,
                    displayName: dto.displayName,
                    icon: dto.icon,
                    sortOrder: dto.sortOrder,
                    screens: dto.screens,
                    children: filteredChildren,
                    requiredPermissions: dto.permissions
                )
                result.append(item)
            }
        }

        return result.sorted { $0.sortOrder < $1.sortOrder }
    }
}
