/// Configuración de carga de datos para una pantalla.
public struct DataConfig: Codable, Sendable {
    public let defaultParams: [String: String]?
    public let pagination: PaginationConfig?
    public let refreshInterval: Int?
    public let fieldMapping: [String: String]?
    public let defaultValues: [String: String]?

    public init(
        defaultParams: [String: String]? = nil,
        pagination: PaginationConfig? = nil,
        refreshInterval: Int? = nil,
        fieldMapping: [String: String]? = nil,
        defaultValues: [String: String]? = nil
    ) {
        self.defaultParams = defaultParams
        self.pagination = pagination
        self.refreshInterval = refreshInterval
        self.fieldMapping = fieldMapping
        self.defaultValues = defaultValues
    }

    enum CodingKeys: String, CodingKey {
        case defaultParams, pagination, refreshInterval, fieldMapping, defaultValues
    }
}

/// Configuración de paginación offset-based.
public struct PaginationConfig: Codable, Sendable {
    public let pageSize: Int?
    public let limitParam: String?
    public let offsetParam: String?
    public let pageParam: String?
    public let type: String?

    public init(
        pageSize: Int? = nil,
        limitParam: String? = nil,
        offsetParam: String? = nil,
        pageParam: String? = nil,
        type: String? = nil
    ) {
        self.pageSize = pageSize
        self.limitParam = limitParam
        self.offsetParam = offsetParam
        self.pageParam = pageParam
        self.type = type
    }
}
