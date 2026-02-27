import Foundation
import EduModels
import EduNetwork

/// Typealias para desambiguar JSONValue entre EduModels y EduNetwork.
public typealias DynamicJSONValue = EduModels.JSONValue

/// Actor responsable de cargar datos dinamicos con soporte dual-API.
public actor DataLoader {
    private let networkClient: NetworkClientProtocol
    private let adminBaseURL: String
    private let mobileBaseURL: String

    public init(
        networkClient: NetworkClientProtocol,
        adminBaseURL: String,
        mobileBaseURL: String
    ) {
        self.networkClient = networkClient
        self.adminBaseURL = adminBaseURL
        self.mobileBaseURL = mobileBaseURL
    }

    /// Carga datos de un endpoint con routing dual-API.
    /// Soporta respuestas JSON tanto como objeto `{}` como array `[]`.
    public func loadData(
        endpoint: String,
        config: DataConfig?,
        params: [String: String]? = nil
    ) async throws -> [String: EduModels.JSONValue] {
        var request = buildRequest(endpoint: endpoint, config: config, offset: 0)

        if let params {
            request = request.queryParams(params)
        }

        return try await fetchAndNormalize(request)
    }

    /// Carga la siguiente pagina de datos (offset-based).
    public func loadNextPage(
        endpoint: String,
        config: DataConfig?,
        currentOffset: Int
    ) async throws -> [String: EduModels.JSONValue] {
        let request = buildRequest(endpoint: endpoint, config: config, offset: currentOffset)
        return try await fetchAndNormalize(request)
    }

    // MARK: - Private

    private func buildRequest(endpoint: String, config: DataConfig?, offset: Int) -> HTTPRequest {
        let (baseURL, path) = resolveEndpoint(endpoint)
        var request = HTTPRequest.get(baseURL + path)

        if let defaultParams = config?.defaultParams {
            request = request.queryParams(defaultParams)
        }

        if let pagination = config?.pagination {
            let limitKey = pagination.limitParam ?? "limit"
            let offsetKey = pagination.offsetParam ?? pagination.pageParam ?? "offset"
            let size = pagination.pageSize ?? 20
            request = request
                .queryParam(limitKey, String(size))
                .queryParam(offsetKey, String(offset))
        }

        return request
    }

    /// Ejecuta el request y normaliza la respuesta a diccionario.
    /// Si la API devuelve un array, lo envuelve en {"items": [...]}.
    private func fetchAndNormalize(_ request: HTTPRequest) async throws -> [String: EduModels.JSONValue] {
        let (data, _) = try await networkClient.requestData(request)

        let decoder = JSONDecoder()

        // Intentar como diccionario primero
        if let dict = try? decoder.decode([String: EduModels.JSONValue].self, from: data) {
            return dict
        }

        // Si falla, intentar como array y envolver
        let array = try decoder.decode([EduModels.JSONValue].self, from: data)
        return ["items": .array(array)]
    }

    /// Resuelve el endpoint a una URL base y path.
    /// - "admin:" prefix -> adminBaseURL
    /// - "mobile:" prefix -> mobileBaseURL
    /// - No prefix -> mobileBaseURL (default)
    private func resolveEndpoint(_ endpoint: String) -> (baseURL: String, path: String) {
        if endpoint.hasPrefix("admin:") {
            let path = String(endpoint.dropFirst("admin:".count))
            return (adminBaseURL, path)
        } else if endpoint.hasPrefix("mobile:") {
            let path = String(endpoint.dropFirst("mobile:".count))
            return (mobileBaseURL, path)
        } else {
            return (mobileBaseURL, endpoint)
        }
    }
}
