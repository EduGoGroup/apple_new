import Foundation
import FoundationToolkit

/// Protocolo que define la interfaz de un cliente de red asíncrono.
///
/// Permite abstraer la implementación del cliente de red para facilitar
/// el testing y la inyección de dependencias.
///
/// ## Conformidad con Swift 6.2
/// - Hereda de `Sendable` para thread-safety
/// - Usa `async/await` para operaciones asíncronas
/// - Soporta tipos genéricos con `Decodable & Sendable`
///
/// ## Ejemplo de implementación de Mock
/// ```swift
/// actor MockNetworkClient: NetworkClientProtocol {
///     var mockResponse: Any?
///     var mockError: NetworkError?
///
///     func request<T: Decodable & Sendable>(
///         _ request: HTTPRequest
///     ) async throws -> T {
///         if let error = mockError {
///             throw error
///         }
///         guard let response = mockResponse as? T else {
///             throw NetworkError.noData
///         }
///         return response
///     }
/// }
/// ```
public protocol NetworkClientProtocol: Sendable {

    // MARK: - Request Methods

    /// Ejecuta una request HTTP y decodifica la respuesta.
    /// - Parameter request: Configuración de la request HTTP
    /// - Returns: Respuesta decodificada del tipo especificado
    /// - Throws: `NetworkError` si la request falla
    func request<T: Decodable & Sendable>(
        _ request: HTTPRequest
    ) async throws -> T

    /// Ejecuta una request HTTP y retorna los datos crudos.
    /// - Parameter request: Configuración de la request HTTP
    /// - Returns: Tupla con los datos y la respuesta HTTP
    /// - Throws: `NetworkError` si la request falla
    func requestData(
        _ request: HTTPRequest
    ) async throws -> (Data, HTTPURLResponse)

    // MARK: - Upload Methods

    /// Sube datos al servidor.
    /// - Parameters:
    ///   - data: Datos a subir
    ///   - request: Configuración de la request HTTP
    /// - Returns: Respuesta decodificada del tipo especificado
    /// - Throws: `NetworkError` si la subida falla
    func upload<T: Decodable & Sendable>(
        data: Data,
        request: HTTPRequest
    ) async throws -> T

    /// Sube un archivo al servidor.
    /// - Parameters:
    ///   - fileURL: URL local del archivo a subir
    ///   - request: Configuración de la request HTTP
    /// - Returns: Respuesta decodificada del tipo especificado
    /// - Throws: `NetworkError` si la subida falla
    func upload<T: Decodable & Sendable>(
        fileURL: URL,
        request: HTTPRequest
    ) async throws -> T

    // MARK: - Download Methods

    /// Descarga un archivo del servidor.
    /// - Parameter request: Configuración de la request HTTP
    /// - Returns: URL del archivo descargado en el sistema de archivos local
    /// - Throws: `NetworkError` si la descarga falla
    func download(
        _ request: HTTPRequest
    ) async throws -> URL

    /// Descarga datos del servidor.
    /// - Parameter request: Configuración de la request HTTP
    /// - Returns: Datos descargados
    /// - Throws: `NetworkError` si la descarga falla
    func downloadData(
        _ request: HTTPRequest
    ) async throws -> Data
}

// MARK: - Default Implementations

extension NetworkClientProtocol {

    /// Ejecuta una request GET y decodifica la respuesta.
    /// - Parameters:
    ///   - url: URL de la request
    ///   - headers: Headers adicionales opcionales
    /// - Returns: Respuesta decodificada
    /// - Throws: `NetworkError` si la request falla
    public func get<T: Decodable & Sendable>(
        _ url: String,
        headers: [String: String] = [:]
    ) async throws -> T {
        let httpRequest = HTTPRequest.get(url).headers(headers)
        return try await request(httpRequest)
    }

    /// Ejecuta una request POST con body JSON y decodifica la respuesta.
    /// - Parameters:
    ///   - url: URL de la request
    ///   - body: DTO a enviar como JSON (debe tener CodingKeys explícitos)
    ///   - headers: Headers adicionales opcionales
    /// - Returns: Respuesta decodificada
    /// - Throws: `NetworkError` si la request falla
    public func post<T: Decodable & Sendable, B: Encodable & Sendable>(
        _ url: String,
        body: B,
        headers: [String: String] = [:]
    ) async throws -> T {
        let bodyData = try await CodableSerializer.dtoSerializer.encode(body)
        let httpRequest = HTTPRequest.post(url)
            .headers(headers)
            .jsonBody(bodyData)
        return try await request(httpRequest)
    }

    /// Ejecuta una request PUT con body JSON y decodifica la respuesta.
    /// - Parameters:
    ///   - url: URL de la request
    ///   - body: DTO a enviar como JSON (debe tener CodingKeys explícitos)
    ///   - headers: Headers adicionales opcionales
    /// - Returns: Respuesta decodificada
    /// - Throws: `NetworkError` si la request falla
    public func put<T: Decodable & Sendable, B: Encodable & Sendable>(
        _ url: String,
        body: B,
        headers: [String: String] = [:]
    ) async throws -> T {
        let bodyData = try await CodableSerializer.dtoSerializer.encode(body)
        let httpRequest = HTTPRequest.put(url)
            .headers(headers)
            .jsonBody(bodyData)
        return try await request(httpRequest)
    }

    /// Ejecuta una request DELETE y decodifica la respuesta.
    /// - Parameters:
    ///   - url: URL de la request
    ///   - headers: Headers adicionales opcionales
    /// - Returns: Respuesta decodificada
    /// - Throws: `NetworkError` si la request falla
    public func delete<T: Decodable & Sendable>(
        _ url: String,
        headers: [String: String] = [:]
    ) async throws -> T {
        let httpRequest = HTTPRequest.delete(url).headers(headers)
        return try await request(httpRequest)
    }

    /// Ejecuta una request PATCH con body JSON y decodifica la respuesta.
    /// - Parameters:
    ///   - url: URL de la request
    ///   - body: DTO a enviar como JSON (debe tener CodingKeys explícitos)
    ///   - headers: Headers adicionales opcionales
    /// - Returns: Respuesta decodificada
    /// - Throws: `NetworkError` si la request falla
    public func patch<T: Decodable & Sendable, B: Encodable & Sendable>(
        _ url: String,
        body: B,
        headers: [String: String] = [:]
    ) async throws -> T {
        let bodyData = try await CodableSerializer.dtoSerializer.encode(body)
        let httpRequest = HTTPRequest.patch(url)
            .headers(headers)
            .jsonBody(bodyData)
        return try await request(httpRequest)
    }
}

// MARK: - Response Types

/// Respuesta vacía para requests que no retornan datos.
public struct EmptyResponse: Decodable, Sendable, Equatable {
    public init() {}

    public init(from decoder: Decoder) throws {
        // Acepta cualquier JSON válido, incluyendo null o {}
    }
}

/// Wrapper para respuestas de API que incluyen metadatos.
public struct APIResponse<T: Decodable & Sendable>: Decodable, Sendable {
    /// Datos de la respuesta.
    public let data: T

    /// Mensaje opcional del servidor.
    public let message: String?

    /// Indica si la operación fue exitosa.
    public let success: Bool

    /// Inicializador para testing.
    public init(data: T, message: String? = nil, success: Bool = true) {
        self.data = data
        self.message = message
        self.success = success
    }
}

/// Respuesta paginada del servidor.
public struct PaginatedResponse<T: Decodable & Sendable>: Decodable, Sendable {
    /// Elementos de la página actual.
    public let items: [T]

    /// Número total de elementos.
    public let totalCount: Int

    /// Página actual (1-based).
    public let page: Int

    /// Tamaño de página.
    public let pageSize: Int

    /// Indica si hay más páginas disponibles.
    public var hasNextPage: Bool {
        page * pageSize < totalCount
    }

    /// Número total de páginas.
    public var totalPages: Int {
        guard pageSize > 0 else { return 0 }
        return (totalCount + pageSize - 1) / pageSize
    }

    /// Inicializador para testing.
    public init(items: [T], totalCount: Int, page: Int, pageSize: Int) {
        self.items = items
        self.totalCount = totalCount
        self.page = page
        self.pageSize = pageSize
    }
}
