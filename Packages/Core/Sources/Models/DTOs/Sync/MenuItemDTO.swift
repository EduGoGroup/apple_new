// MenuItemDTO.swift
// Models
//
// Data Transfer Object for navigation menu items from Sync Bundle API.

import Foundation

/// Data Transfer Object representing a navigation menu item.
///
/// Menu items form a recursive tree structure, where each item may contain
/// children representing sub-navigation options.
///
/// ## JSON Structure (from backend)
/// ```json
/// {
///     "key": "dashboard",
///     "display_name": "Dashboard",
///     "icon": "house.fill",
///     "scope": "student",
///     "sort_order": 1,
///     "permissions": ["view_dashboard"],
///     "screens": { "main": "dashboard_main" },
///     "children": []
/// }
/// ```
public struct MenuItemDTO: Codable, Sendable, Hashable, Identifiable {
    /// Unique key identifying this menu item.
    public let key: String

    /// Localized display name for the menu item.
    public let displayName: String

    /// Optional SF Symbol or icon identifier.
    public let icon: String?

    /// Scope this menu item belongs to (e.g. "student", "teacher").
    public let scope: String

    /// Sort order for display within its level.
    public let sortOrder: Int

    /// Permissions required to see this menu item (empty if accessible to all).
    public let permissions: [String]

    /// Map of screen slot names to screen keys.
    public let screens: [String: String]

    /// Optional child menu items for nested navigation.
    public let children: [MenuItemDTO]?

    /// Identifiable conformance using the unique key.
    public var id: String { key }

    enum CodingKeys: String, CodingKey {
        case key
        case displayName = "display_name"
        case icon
        case scope
        case sortOrder = "sort_order"
        case permissions
        case screens
        case children
    }

    public init(
        key: String,
        displayName: String,
        icon: String? = nil,
        scope: String,
        sortOrder: Int,
        permissions: [String] = [],
        screens: [String: String] = [:],
        children: [MenuItemDTO]? = nil
    ) {
        self.key = key
        self.displayName = displayName
        self.icon = icon
        self.scope = scope
        self.sortOrder = sortOrder
        self.permissions = permissions
        self.screens = screens
        self.children = children
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = try container.decode(String.self, forKey: .key)
        displayName = try container.decode(String.self, forKey: .displayName)
        icon = try container.decodeIfPresent(String.self, forKey: .icon)
        scope = try container.decodeIfPresent(String.self, forKey: .scope) ?? ""
        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        permissions = try container.decodeIfPresent([String].self, forKey: .permissions) ?? []
        screens = try container.decodeIfPresent([String: String].self, forKey: .screens) ?? [:]
        children = try container.decodeIfPresent([MenuItemDTO].self, forKey: .children)
    }
}
