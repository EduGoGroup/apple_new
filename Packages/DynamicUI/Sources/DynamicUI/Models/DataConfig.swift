/// Configuración de carga de datos para una pantalla.
public struct DataConfig: Codable, Sendable {
    public let defaultParams: [String: String]?
    public let pagination: PaginationConfig?
    public let refreshInterval: Int?

    enum CodingKeys: String, CodingKey {
        case defaultParams, pagination, refreshInterval
    }
}

/// Configuración de paginación offset-based.
public struct PaginationConfig: Codable, Sendable {
    public let pageSize: Int?
    public let limitParam: String?
    public let offsetParam: String?
    public let pageParam: String?
    public let type: String?
}
