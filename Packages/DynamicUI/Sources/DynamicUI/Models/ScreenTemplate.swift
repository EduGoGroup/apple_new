import Foundation

/// Template que define la estructura visual de una pantalla.
public struct ScreenTemplate: Codable, Sendable {
    public let navigation: NavigationConfig?
    public let zones: [Zone]
    public let platformOverrides: [String: PlatformOverride]?

    enum CodingKeys: String, CodingKey {
        case navigation, zones, platformOverrides
    }
}

/// Configuración de navegación de la pantalla.
public struct NavigationConfig: Codable, Sendable {
    public let topBar: TopBarConfig?
}

/// Configuración de la barra superior.
public struct TopBarConfig: Codable, Sendable {
    public let title: String?
    public let showBack: Bool?
}

/// Override de configuración por plataforma.
public struct PlatformOverride: Codable, Sendable {
    public let distribution: String?
    public let zones: [String: ZoneOverride]?
}

/// Override de una zona específica por plataforma.
public struct ZoneOverride: Codable, Sendable {
    public let visible: Bool?
    public let height: Int?
    public let distribution: String?
}
