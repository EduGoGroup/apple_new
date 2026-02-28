import Foundation
import EduCore
#if canImport(os)
import os
#endif

/// Network - HTTP networking module
///
/// Provides HTTP client, request/response handling, and network utilities.
/// TIER-2 Infrastructure module.
///
/// ## Overview
/// `NetworkClient` es un actor thread-safe que proporciona funcionalidades
/// de networking usando `URLSession` con soporte completo para async/await.
///
/// ## Uso básico
/// ```swift
/// let client = NetworkClient.shared
///
/// // Request GET simple
/// let users: [User] = try await client.request(
///     HTTPRequest.get("https://api.example.com/users")
/// )
///
/// // Request POST con body
/// let newUser: UserDTO = try await client.post(
///     "https://api.example.com/users",
///     body: CreateUserRequest(name: "John")
/// )
/// ```
///
/// ## Thread Safety
/// Como actor de Swift 6.2, todas las operaciones son automáticamente
/// thread-safe sin necesidad de locks o dispatch queues.
public actor NetworkClient: NetworkClientProtocol {

    // MARK: - Singleton

    /// Instancia compartida del cliente de red.
    public static let shared = NetworkClient(
        interceptors: [],
        retryPolicy: ExponentialBackoffRetryPolicy(maxRetryCount: 3)
    )

    // MARK: - Properties

    /// Sesión URL para realizar requests.
    private let urlSession: URLSession

    /// Serializer thread-safe para encoding/decoding JSON (DTOs con CodingKeys explícitos).
    private let serializer: CodableSerializer

    /// Headers globales aplicados a todas las requests.
    private var globalHeaders: [String: String] = [
        "Accept": "application/json",
        "Content-Type": "application/json"
    ]

    /// Cadena de interceptors (puede estar vacía).
    private let interceptorChain: InterceptorChain

    /// Timeout máximo total para reintentos.
    private let maxRetryTimeout: TimeInterval

    #if canImport(os)
    /// Logger para debugging.
    private let logger = Logger(subsystem: "com.edugo.network", category: "NetworkClient")
    #endif

    #if DEBUG
    /// Flag para habilitar logging detallado.
    public var isLoggingEnabled: Bool = true
    #else
    public let isLoggingEnabled: Bool = false
    #endif

    // MARK: - Initialization

    /// Inicializa el cliente con la configuración por defecto.
    public init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = true
        configuration.httpAdditionalHeaders = [
            "User-Agent": "EduGo-iOS/1.0"
        ]

        self.urlSession = URLSession(configuration: configuration)
        self.serializer = CodableSerializer.dtoSerializer
        self.interceptorChain = InterceptorChain([])
        self.maxRetryTimeout = 120
    }

    /// Inicializa el cliente con interceptors usando la configuración por defecto.
    public init(
        interceptors: [any RequestInterceptor] = [],
        retryPolicy: (any RetryPolicy)? = nil,
        maxRetryTimeout: TimeInterval = 120
    ) {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = true
        configuration.httpAdditionalHeaders = [
            "User-Agent": "EduGo-iOS/1.0"
        ]

        var configuredInterceptors = interceptors
        if let retryPolicy,
           !configuredInterceptors.contains(where: { $0 is RetryInterceptor }) {
            configuredInterceptors.append(RetryInterceptor(policy: retryPolicy))
        }

        self.interceptorChain = InterceptorChain(configuredInterceptors)
        self.maxRetryTimeout = maxRetryTimeout
        self.urlSession = URLSession(configuration: configuration)
        self.serializer = CodableSerializer.dtoSerializer
    }

    /// Inicializa el cliente con una configuración personalizada.
    /// - Parameters:
    ///   - configuration: Configuración de URLSession
    ///   - serializer: Serializer JSON personalizado (opcional, usa shared por defecto)
    ///   - interceptors: Lista de interceptors
    ///   - maxRetryTimeout: Timeout máximo para reintentos
    ///   - retryPolicy: Política de reintentos
    public init(
        configuration: URLSessionConfiguration,
        serializer: CodableSerializer? = nil,
        interceptors: [any RequestInterceptor] = [],
        maxRetryTimeout: TimeInterval = 120,
        retryPolicy: (any RetryPolicy)? = nil
    ) {
        var configuredInterceptors = interceptors
        if let retryPolicy,
           !configuredInterceptors.contains(where: { $0 is RetryInterceptor }) {
            configuredInterceptors.append(RetryInterceptor(policy: retryPolicy))
        }

        self.interceptorChain = InterceptorChain(configuredInterceptors)
        self.maxRetryTimeout = maxRetryTimeout
        self.urlSession = URLSession(configuration: configuration)
        self.serializer = serializer ?? CodableSerializer.dtoSerializer
    }

    // MARK: - Header Management

    /// Establece un header global que se aplicará a todas las requests.
    /// - Parameters:
    ///   - value: Valor del header
    ///   - key: Nombre del header
    public func setGlobalHeader(_ value: String, forKey key: String) {
        globalHeaders[key] = value
    }

    /// Remueve un header global.
    /// - Parameter key: Nombre del header a remover
    public func removeGlobalHeader(forKey key: String) {
        globalHeaders.removeValue(forKey: key)
    }

    /// Establece el token de autorización Bearer.
    /// - Parameter token: Token de autorización
    public func setAuthorizationToken(_ token: String) {
        globalHeaders["Authorization"] = "Bearer \(token)"
    }

    /// Remueve el token de autorización.
    public func clearAuthorizationToken() {
        globalHeaders.removeValue(forKey: "Authorization")
    }

    // MARK: - NetworkClientProtocol Implementation

    /// Ejecuta una request HTTP y decodifica la respuesta.
    /// - Parameter request: Configuración de la request
    /// - Returns: Respuesta decodificada del tipo especificado
    /// - Throws: `NetworkError` si la request falla
    public func request<T: Decodable & Sendable>(
        _ request: HTTPRequest
    ) async throws -> T {
        let (data, _) = try await requestData(request)

        // Manejar respuesta vacía para EmptyResponse
        if T.self == EmptyResponse.self {
            // swiftlint:disable:next force_cast
            return EmptyResponse() as! T
        }

        do {
            let decoded: T = try await serializer.decode(T.self, from: data)
            return decoded
        } catch let serializationError as SerializationError {
            logError("Decoding error for \(T.self): \(serializationError.localizedDescription)")
            throw NetworkError.decodingError(
                type: String(describing: T.self),
                underlyingError: serializationError.localizedDescription
            )
        } catch {
            throw NetworkError.decodingError(
                type: String(describing: T.self),
                underlyingError: error.localizedDescription
            )
        }
    }

    /// Ejecuta una request HTTP y retorna los datos crudos.
    /// - Parameter request: Configuración de la request
    /// - Returns: Tupla con los datos y la respuesta HTTP
    /// - Throws: `NetworkError` si la request falla
    public func requestData(
        _ request: HTTPRequest
    ) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await performWithRetry(
            originalRequest: request,
            dataForInterceptors: { $0 },
            execute: { request in
                try await urlSession.data(for: request)
            }
        )

        return (data, response)
    }

    /// Sube datos al servidor.
    /// - Parameters:
    ///   - data: Datos a subir
    ///   - request: Configuración de la request
    /// - Returns: Respuesta decodificada
    /// - Throws: `NetworkError` si la subida falla
    public func upload<T: Decodable & Sendable>(
        data: Data,
        request: HTTPRequest
    ) async throws -> T {
        let (responseData, _) = try await performWithRetry(
            originalRequest: request,
            prepare: { urlRequest in
                urlRequest.httpBody = data
            },
            dataForInterceptors: { $0 },
            execute: { urlRequest in
                try await urlSession.upload(for: urlRequest, from: data)
            }
        )

        do {
            return try await serializer.decode(T.self, from: responseData)
        } catch let serializationError as SerializationError {
            throw NetworkError.decodingError(
                type: String(describing: T.self),
                underlyingError: serializationError.localizedDescription
            )
        } catch {
            throw NetworkError.decodingError(
                type: String(describing: T.self),
                underlyingError: error.localizedDescription
            )
        }
    }

    /// Sube un archivo al servidor.
    /// - Parameters:
    ///   - fileURL: URL local del archivo
    ///   - request: Configuración de la request
    /// - Returns: Respuesta decodificada
    /// - Throws: `NetworkError` si la subida falla
    public func upload<T: Decodable & Sendable>(
        fileURL: URL,
        request: HTTPRequest
    ) async throws -> T {
        let (responseData, _) = try await performWithRetry(
            originalRequest: request,
            dataForInterceptors: { $0 },
            execute: { urlRequest in
                try await urlSession.upload(for: urlRequest, fromFile: fileURL)
            }
        )

        do {
            return try await serializer.decode(T.self, from: responseData)
        } catch let serializationError as SerializationError {
            throw NetworkError.decodingError(
                type: String(describing: T.self),
                underlyingError: serializationError.localizedDescription
            )
        } catch {
            throw NetworkError.decodingError(
                type: String(describing: T.self),
                underlyingError: error.localizedDescription
            )
        }
    }

    /// Descarga un archivo del servidor.
    /// - Parameter request: Configuración de la request
    /// - Returns: URL del archivo descargado
    /// - Throws: `NetworkError` si la descarga falla
    public func download(_ request: HTTPRequest) async throws -> URL {
        let (fileURL, _) = try await performWithRetry(
            originalRequest: request,
            dataForInterceptors: { _ in Data() },
            execute: { urlRequest in
                try await urlSession.download(for: urlRequest)
            }
        )

        return fileURL
    }

    /// Descarga datos del servidor.
    /// - Parameter request: Configuración de la request
    /// - Returns: Datos descargados
    /// - Throws: `NetworkError` si la descarga falla
    public func downloadData(_ request: HTTPRequest) async throws -> Data {
        let (data, _) = try await requestData(request)
        return data
    }

    // MARK: - Legacy Support

    /// Ejecuta una request simple por URL (compatibilidad hacia atrás).
    /// - Parameters:
    ///   - url: URL de la request
    ///   - method: Método HTTP
    /// - Returns: Respuesta decodificada
    /// - Throws: Error si la request falla
    public func request<T: Decodable & Sendable>(
        _ url: URL,
        method: HTTPMethod = .get
    ) async throws -> T {
        let httpRequest = HTTPRequest(url: url.absoluteString).method(method)
        return try await request(httpRequest)
    }

    // MARK: - Private Helpers

    private func performWithRetry<Response>(
        originalRequest: HTTPRequest,
        prepare: @Sendable (inout URLRequest) -> Void = { _ in },
        dataForInterceptors: @Sendable (Response) -> Data?,
        execute: @Sendable (URLRequest) async throws -> (Response, URLResponse)
    ) async throws -> (Response, HTTPURLResponse) {
        let startTime = Date()
        var context = RequestContext(originalRequest: originalRequest)

        var baseRequest = try buildURLRequest(from: originalRequest)
        prepare(&baseRequest)

        var lastRequest = baseRequest

        while true {
            do {
                lastRequest = try await interceptorChain.adapt(baseRequest, context: context)
                logRequest(lastRequest)

                let (result, response) = try await execute(lastRequest)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.networkFailure(underlyingError: "Invalid response type")
                }

                let responseData = dataForInterceptors(result)
                logResponse(httpResponse, data: responseData)

                try validateResponse(httpResponse, data: responseData)

                await interceptorChain.didReceive(
                    response: httpResponse,
                    data: responseData ?? Data(),
                    for: lastRequest,
                    context: context
                )

                return (result, httpResponse)
            } catch {
                let networkError = mapNetworkError(error)
                logError("Request failed: \(networkError.localizedDescription)")

                let elapsed = Date().timeIntervalSince(startTime)
                if elapsed >= maxRetryTimeout {
                    throw networkError
                }

                let decision = await interceptorChain.retry(
                    lastRequest,
                    dueTo: networkError,
                    context: context
                )

                switch decision {
                case .doNotRetry:
                    throw networkError
                case .retryImmediately:
                    context = context.nextAttempt(elapsedTime: elapsed)
                    baseRequest = try buildURLRequest(from: originalRequest)
                    prepare(&baseRequest)
                case .retryAfter(let delay):
                    try await Task.sleep(for: .seconds(delay))
                    context = context.nextAttempt(elapsedTime: Date().timeIntervalSince(startTime))
                    baseRequest = try buildURLRequest(from: originalRequest)
                    prepare(&baseRequest)
                case .retryWithRequest(let newRequest):
                    baseRequest = newRequest
                    context = context.nextAttempt(elapsedTime: elapsed)
                }
            }
        }
    }

    private func mapNetworkError(_ error: Error) -> NetworkError {
        if let networkError = error as? NetworkError {
            return networkError
        }

        if let urlError = error as? URLError {
            return NetworkError.from(urlError: urlError)
        }

        if error is CancellationError {
            return .cancelled
        }

        return NetworkError.networkFailure(underlyingError: error.localizedDescription)
    }

    /// Construye un URLRequest a partir de HTTPRequest aplicando headers globales.
    private func buildURLRequest(from request: HTTPRequest) throws -> URLRequest {
        var urlRequest = try request.build()

        // Aplicar headers globales (los headers específicos tienen prioridad)
        for (key, value) in globalHeaders {
            if urlRequest.value(forHTTPHeaderField: key) == nil {
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
        }

        return urlRequest
    }

    /// Valida la respuesta HTTP y lanza error si es necesario.
    private func validateResponse(_ response: HTTPURLResponse, data: Data?) throws {
        let statusCode = response.statusCode

        guard NetworkError.isSuccessStatusCode(statusCode) else {
            // Intentar extraer mensaje de error del servidor
            var serverMessage: String?
            if let data {
                serverMessage = extractErrorMessage(from: data)
            }

            // Extraer Retry-After para rate limiting
            var retryAfter: TimeInterval?
            if statusCode == 429,
               let retryAfterString = response.value(forHTTPHeaderField: "Retry-After"),
               let seconds = TimeInterval(retryAfterString) {
                retryAfter = seconds
            }

            throw NetworkError.from(
                statusCode: statusCode,
                message: serverMessage,
                retryAfter: retryAfter
            )
        }
    }

    /// Extrae el mensaje de error del body de la respuesta.
    private func extractErrorMessage(from data: Data) -> String? {
        // Intentar decodificar como JSON con campo "message" o "error"
        // Usa un decoder simple ya que los mensajes de error no requieren estrategias especiales
        struct ErrorResponse: Decodable {
            let message: String?
            let error: String?
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        guard let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) else {
            return nil
        }

        return errorResponse.message ?? errorResponse.error
    }

    // MARK: - Logging

    private func logRequest(_ request: URLRequest) {
        #if DEBUG
        guard isLoggingEnabled else { return }

        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? "unknown"

        #if canImport(os)
        logger.debug("→ \(method) \(url)")
        #else
        print("→ \(method) \(url)")
        #endif
        #endif
    }

    private func logResponse(_ response: HTTPURLResponse, data: Data?) {
        #if DEBUG
        guard isLoggingEnabled else { return }

        let statusCode = response.statusCode
        let url = response.url?.absoluteString ?? "unknown"
        let dataSize = data?.count ?? 0

        #if canImport(os)
        logger.debug("← \(statusCode) \(url) (\(dataSize) bytes)")
        #else
        print("← \(statusCode) \(url) (\(dataSize) bytes)")
        #endif
        #endif
    }

    private func logError(_ message: String) {
        #if DEBUG
        guard isLoggingEnabled else { return }

        #if canImport(os)
        logger.error("✗ \(message)")
        #else
        print("✗ \(message)")
        #endif
        #endif
    }
}
