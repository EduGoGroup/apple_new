import Foundation
@testable import EduNetwork

/// Mock del cliente de red para tests unitarios.
///
/// Permite configurar respuestas predefinidas y errores para simular
/// diferentes escenarios de red sin realizar requests reales.
///
/// ## Ejemplo de uso
/// ```swift
/// let mock = MockNetworkClient()
/// mock.mockResponse = MaterialDTO(id: "123", ...)
///
/// let repository = MaterialsRepository(client: mock, baseURL: "https://api.test")
/// let material = try await repository.getMaterial(id: "123")
/// ```
public actor MockNetworkClient: NetworkClientProtocol {
    // MARK: - Configuration

    /// Respuesta mock a retornar en la próxima request.
    public var mockResponse: (any Sendable)?

    /// Error mock a lanzar en la próxima request.
    public var mockError: NetworkError?

    /// Data mock para requests que retornan Data.
    public var mockData: Data?

    /// HTTPURLResponse mock.
    public var mockHTTPResponse: HTTPURLResponse?

    /// URL mock para downloads.
    public var mockDownloadURL: URL?

    /// Historial de requests realizadas para verificación.
    public private(set) var requestHistory: [HTTPRequest] = []

    /// Contador de requests para verificar número de llamadas.
    public var requestCount: Int { requestHistory.count }

    // MARK: - Initialization

    public init() {}

    // MARK: - Configuration Methods

    /// Configura una respuesta exitosa.
    public func setResponse<T: Sendable>(_ response: T) {
        mockResponse = response
        mockError = nil
    }

    /// Configura un error a lanzar.
    public func setError(_ error: NetworkError) {
        mockError = error
        mockResponse = nil
    }

    /// Limpia el historial de requests.
    public func clearHistory() {
        requestHistory.removeAll()
    }

    /// Resetea toda la configuración.
    public func reset() {
        mockResponse = nil
        mockError = nil
        mockData = nil
        mockHTTPResponse = nil
        mockDownloadURL = nil
        requestHistory.removeAll()
    }

    // MARK: - NetworkClientProtocol

    public func request<T: Decodable & Sendable>(
        _ request: HTTPRequest
    ) async throws -> T {
        requestHistory.append(request)

        if let error = mockError {
            throw error
        }

        guard let response = mockResponse as? T else {
            throw NetworkError.noData
        }

        return response
    }

    public func requestData(
        _ request: HTTPRequest
    ) async throws -> (Data, HTTPURLResponse) {
        requestHistory.append(request)

        if let error = mockError {
            throw error
        }

        guard let data = mockData else {
            throw NetworkError.noData
        }

        let response = mockHTTPResponse ?? HTTPURLResponse(
            url: URL(string: request.url)!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        return (data, response)
    }

    public func upload<T: Decodable & Sendable>(
        data: Data,
        request: HTTPRequest
    ) async throws -> T {
        requestHistory.append(request)

        if let error = mockError {
            throw error
        }

        guard let response = mockResponse as? T else {
            throw NetworkError.noData
        }

        return response
    }

    public func upload<T: Decodable & Sendable>(
        fileURL: URL,
        request: HTTPRequest
    ) async throws -> T {
        requestHistory.append(request)

        if let error = mockError {
            throw error
        }

        guard let response = mockResponse as? T else {
            throw NetworkError.noData
        }

        return response
    }

    public func download(
        _ request: HTTPRequest
    ) async throws -> URL {
        requestHistory.append(request)

        if let error = mockError {
            throw error
        }

        guard let url = mockDownloadURL else {
            throw NetworkError.noData
        }

        return url
    }

    public func downloadData(
        _ request: HTTPRequest
    ) async throws -> Data {
        requestHistory.append(request)

        if let error = mockError {
            throw error
        }

        guard let data = mockData else {
            throw NetworkError.noData
        }

        return data
    }
}

// MARK: - Verification Helpers

extension MockNetworkClient {
    /// Verifica que se realizó al menos una request.
    public var wasRequested: Bool {
        !requestHistory.isEmpty
    }

    /// Obtiene la última request realizada.
    public var lastRequest: HTTPRequest? {
        requestHistory.last
    }

    /// Verifica que se llamó con una URL específica.
    public func wasRequestedWith(url: String) -> Bool {
        requestHistory.contains { $0.url.contains(url) }
    }

    /// Verifica que se llamó con un método HTTP específico.
    public func wasRequestedWith(method: HTTPMethod) -> Bool {
        requestHistory.contains { $0.method == method }
    }
}
