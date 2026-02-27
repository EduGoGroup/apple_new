import Foundation
import Synchronization
@testable import EduNetwork

// MARK: - Mock Storage

/// Almacenamiento thread-safe para el estado del mock usando Mutex.
///
/// Encapsula todo el estado mutable del URLProtocolMock de forma segura
/// para concurrencia en Swift 6.2.
final class URLProtocolMockStorage: Sendable {
    /// Estructura que contiene el estado mutable del mock.
    struct State: Sendable {
        var requestHandler: (@Sendable (URLRequest) throws -> (Data, HTTPURLResponse))?
        var mockResponse: MockResponse?
        var requestHistory: [URLRequest] = []
        var artificialDelay: TimeInterval = 0
    }

    /// Respuesta mock thread-safe.
    struct MockResponse: Sendable {
        let data: Data?
        let response: HTTPURLResponse?
        let error: (any Error)?

        init(data: Data?, response: HTTPURLResponse?, error: (any Error)?) {
            self.data = data
            self.response = response
            self.error = error
        }
    }

    private let state = Mutex(State())

    /// Acceso thread-safe al estado del mock.
    func withState<T>(_ operation: (inout State) throws -> T) rethrows -> T {
        try state.withLock { state in
            try operation(&state)
        }
    }
}

// MARK: - URLProtocolMock

/// Mock de URLProtocol para interceptar requests HTTP en tests de integración.
///
/// Permite configurar respuestas predefinidas a nivel de URLSession,
/// útil para tests que necesitan verificar el comportamiento real del cliente.
///
/// ## Thread Safety
/// Esta implementación usa `Mutex` de Swift 6 para garantizar acceso
/// thread-safe al estado compartido, cumpliendo con Strict Concurrency.
///
/// ## Ejemplo de uso
/// ```swift
/// // Configurar respuesta
/// URLProtocolMock.setMockResponse(
///     data: jsonData,
///     response: HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!,
///     error: nil
/// )
///
/// // Configurar URLSession con el mock
/// let session = URLProtocolMock.createMockSession()
///
/// // Realizar request...
///
/// // Verificar
/// XCTAssertTrue(URLProtocolMock.wasRequested)
/// XCTAssertEqual(URLProtocolMock.requestCount, 1)
///
/// // Limpiar después del test
/// URLProtocolMock.reset()
/// ```
final class URLProtocolMock: URLProtocol, @unchecked Sendable {
    // MARK: - Storage

    /// Almacenamiento compartido thread-safe.
    private static let storage = URLProtocolMockStorage()

    // MARK: - URLProtocol Override

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        // Obtener configuración actual de forma thread-safe
        let config = Self.storage.withState { state -> (
            handler: (@Sendable (URLRequest) throws -> (Data, HTTPURLResponse))?,
            response: URLProtocolMockStorage.MockResponse?,
            delay: TimeInterval
        ) in
            state.requestHistory.append(request)
            return (state.requestHandler, state.mockResponse, state.artificialDelay)
        }

        // Simular latencia si está configurada
        if config.delay > 0 {
            Thread.sleep(forTimeInterval: config.delay)
        }

        // Usar handler personalizado si está configurado
        if let handler = config.handler {
            do {
                let (data, response) = try handler(request)
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
            return
        }

        // Usar respuesta estática
        if let mockResponse = config.response {
            if let error = mockResponse.error {
                client?.urlProtocol(self, didFailWithError: error)
                return
            }

            if let response = mockResponse.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }

            if let data = mockResponse.data {
                client?.urlProtocol(self, didLoad: data)
            }

            client?.urlProtocolDidFinishLoading(self)
            return
        }

        // Sin configuración, retornar error
        let error = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorUnknown,
            userInfo: [NSLocalizedDescriptionKey: "URLProtocolMock not configured"]
        )
        client?.urlProtocol(self, didFailWithError: error)
    }

    override func stopLoading() {
        // No-op
    }

    // MARK: - Configuration Methods

    /// Resetea toda la configuración del mock.
    ///
    /// Debe llamarse en el `tearDown` de cada test para evitar
    /// contaminación entre tests.
    static func reset() {
        storage.withState { state in
            state.requestHandler = nil
            state.mockResponse = nil
            state.requestHistory.removeAll()
            state.artificialDelay = 0
        }
    }

    /// Configura un handler personalizado para procesar requests.
    /// - Parameter handler: Closure que recibe la request y retorna data y response.
    static func setRequestHandler(
        _ handler: (@Sendable (URLRequest) throws -> (Data, HTTPURLResponse))?
    ) {
        storage.withState { state in
            state.requestHandler = handler
        }
    }

    /// Configura una respuesta mock estática.
    /// - Parameters:
    ///   - data: Datos a retornar.
    ///   - response: Respuesta HTTP.
    ///   - error: Error a lanzar (si se proporciona, data y response se ignoran).
    static func setMockResponse(
        data: Data?,
        response: HTTPURLResponse?,
        error: (any Error)?
    ) {
        storage.withState { state in
            state.mockResponse = URLProtocolMockStorage.MockResponse(
                data: data,
                response: response,
                error: error
            )
        }
    }

    /// Configura una respuesta JSON exitosa.
    /// - Parameters:
    ///   - object: Objeto a codificar como JSON.
    ///   - statusCode: Código de estado HTTP (default: 200).
    ///   - url: URL para la respuesta (default: https://api.test.com).
    static func setJSONResponse<T: Encodable>(
        _ object: T,
        statusCode: Int = 200,
        url: URL = URL(string: "https://api.test.com")!
    ) throws {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(object)
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!

        setMockResponse(data: data, response: response, error: nil)
    }

    /// Configura un error de red.
    /// - Parameter code: Código de error URLError (default: notConnectedToInternet).
    static func setNetworkError(_ code: URLError.Code = .notConnectedToInternet) {
        let error = URLError(code)
        setMockResponse(data: nil, response: nil, error: error)
    }

    /// Configura una respuesta HTTP con código de error.
    /// - Parameters:
    ///   - statusCode: Código de estado HTTP.
    ///   - message: Mensaje de error opcional para incluir en el body.
    ///   - url: URL para la respuesta.
    static func setHTTPError(
        statusCode: Int,
        message: String? = nil,
        url: URL = URL(string: "https://api.test.com")!
    ) {
        var data: Data?
        if let message {
            data = "{\"error\": \"\(message)\"}".data(using: .utf8)
        }

        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!

        setMockResponse(data: data, response: response, error: nil)
    }

    /// Configura un delay artificial para simular latencia.
    /// - Parameter delay: Tiempo de espera en segundos.
    static func setArtificialDelay(_ delay: TimeInterval) {
        storage.withState { state in
            state.artificialDelay = delay
        }
    }

    /// Crea una URLSession configurada con este mock.
    /// - Returns: URLSession que usará URLProtocolMock para todas las requests.
    static func createMockSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolMock.self]
        return URLSession(configuration: config)
    }
}

// MARK: - Verification Helpers

extension URLProtocolMock {
    /// Verifica que se realizó al menos una request.
    static var wasRequested: Bool {
        storage.withState { !$0.requestHistory.isEmpty }
    }

    /// Obtiene la última request realizada.
    static var lastRequest: URLRequest? {
        storage.withState { $0.requestHistory.last }
    }

    /// Obtiene el historial completo de requests.
    static var requestHistory: [URLRequest] {
        storage.withState { $0.requestHistory }
    }

    /// Número total de requests interceptadas.
    static var requestCount: Int {
        storage.withState { $0.requestHistory.count }
    }

    /// Verifica que se llamó con una URL específica.
    /// - Parameter url: Substring de la URL a buscar.
    /// - Returns: `true` si alguna request contiene la URL.
    static func wasRequestedWith(url: String) -> Bool {
        storage.withState { state in
            state.requestHistory.contains { $0.url?.absoluteString.contains(url) == true }
        }
    }

    /// Verifica que se llamó con un método HTTP específico.
    /// - Parameter method: Método HTTP a buscar (GET, POST, etc.).
    /// - Returns: `true` si alguna request usó el método.
    static func wasRequestedWith(method: String) -> Bool {
        storage.withState { state in
            state.requestHistory.contains { $0.httpMethod == method }
        }
    }
}
