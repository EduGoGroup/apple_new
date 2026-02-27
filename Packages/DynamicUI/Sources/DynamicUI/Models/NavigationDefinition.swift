/// Definición de la navegación server-driven.
public struct NavigationDefinition: Codable, Sendable {
    public let bottomNav: [NavItem]
    public let drawerItems: [NavItem]?
    public let version: Int

    enum CodingKeys: String, CodingKey {
        case bottomNav, drawerItems, version
    }
}

/// Item de navegación (tab o drawer).
public struct NavItem: Codable, Sendable, Identifiable {
    public let key: String
    public let label: String
    public let icon: String
    public let screenKey: String
    public let sortOrder: Int
    public let children: [NavItem]?

    public var id: String { key }
}
