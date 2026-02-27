import Foundation
import EduCore
#if canImport(os)
import os
#endif

/// Cliente de red con soporte para interceptors y retry automático.
///
/// Extiende las capacidades de `NetworkClient` agregando:
/// - Chain of interceptors para modificar requests/responses
/// - Retry automático con políticas configurables
/// - Logging integrado con interceptors
///
/// ## Uso básico
/// ```swift
/// let client = InterceptableNetworkClient(
///     interceptors: [
///         LoggingInterceptor.debug,
///         AuthenticationInterceptor(tokenProvider: myTokenProvider),
///         RetryInterceptor(policy: .standard)
///     ]
/// )
///
/// let users: [User] = try await client.request(
///     HTTPRequest.get("https://api.example.com/users")
/// )
/// ```
public actor InterceptableNetworkClient: NetworkClientProtocol {

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

    /// Cadena de interceptors.
    private let interceptorChain: InterceptorChain

    /// Política de retry por defecto.
    private let defaultRetryPolicy: (any RetryPolicy)?

    /// Timeout máximo para reintentos.
    private let maxRetryTimeout: TimeInterval

    #if canImport(os)
    private let logger = Logger(subsystem: "com.edugo.network", category: "InterceptableNetworkClient")
    #endif

    // MARK: - Initialization

    /// Inicializa el cliente con interceptors.
    /// - Parameters:
    ///   - interceptors: Array de interceptors a aplicar
    ///   - defaultRetryPolicy: Política de retry por defecto (nil = sin retry automático)
    ///   - maxRetryTimeout: Timeout máximo total para reintentos (default: 120s)
    ///   - configuration: Configuración de URLSession (default: .default)
    public init(
        interceptors: [any RequestInterceptor] = [],
        defaultRetryPolicy: (any RetryPolicy)? = nil,
        maxRetryTimeout: TimeInterval = 120,
        configuration: URLSessionConfiguration = .default
    ) {
        var configuredInterceptors = interceptors
        if let defaultRetryPolicy,
           !configuredInterceptors.contains(where: { $0 is RetryInterceptor }) {
            configuredInterceptors.append(RetryInterceptor(policy: defaultRetryPolicy))
        }

        self.interceptorChain = InterceptorChain(configuredInterceptors)
        self.defaultRetryPolicy = defaultRetryPolicy
        self.maxRetryTimeout = maxRetryTimeout

        // Configurar URLSession
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = true
        configuration.httpAdditionalHeaders = [
            "User-Agent": "EduGo-iOS/1.0"
        ]
        self.urlSession = URLSession(configuration: configuration)

        self.serializer = CodableSerializer.dtoSerializer
    }

    /// Inicializa con configuración estándar incluyendo logging y retry.
    public static func standard(
        tokenProvider: (any TokenProvider)? = nil,
        retryPolicy: any RetryPolicy = ExponentialBackoffRetryPolicy.standard
    ) -> InterceptableNetworkClient {
        var interceptors: [any RequestInterceptor] = [
            LoggingInterceptor(level: .info)
        ]

        if let tokenProvider {
            interceptors.append(AuthenticationInterceptor.standard(tokenProvider: tokenProvider))
        }

        interceptors.append(RetryInterceptor(policy: retryPolicy))

        return InterceptableNetworkClient(
            interceptors: interceptors,
            defaultRetryPolicy: retryPolicy
        )
    }

    // MARK: - Header Management

    /// Establece un header global.
    public func setGlobalHeader(_ value: String, forKey key: String) {
        globalHeaders[key] = value
    }

    /// Remueve un header global.
    public func removeGlobalHeader(forKey key: String) {
        globalHeaders.removeValue(forKey: key)
    }

    /// Establece el token de autorización Bearer.
    public func setAuthorizationToken(_ token: String) {
        globalHeaders["Authorization"] = "Bearer \(token)"
    }

    /// Remueve el token de autorización.
    public func clearAuthorizationToken() {
        globalHeaders.removeValue(forKey: "Authorization")
    }

    // MARK: - NetworkClientProtocol Implementation

    public func request<T: Decodable & Sendable>(
        _ request: HTTPRequest
    ) async throws -> T {
        let (data, _) = try await requestData(request)

        if T.self == EmptyResponse.self {
            // swiftlint:disable:next force_cast
            return EmptyResponse() as! T
        }

        do {
            return try await serializer.decode(T.self, from: data)
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

    public func requestData(
        _ request: HTTPRequest
    ) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await performWithRetry(
            originalRequest: request,
            dataForInterceptors: { $0 },
            execute: { urlRequest in
                try await executeRequest(urlRequest)
            }
        )

        return (data, response)
    }

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

    public func downloadData(_ request: HTTPRequest) async throws -> Data {
        let (data, _) = try await requestData(request)
        return data
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

                let (result, response) = try await execute(lastRequest)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.networkFailure(underlyingError: "Invalid response type")
                }

                let responseData = dataForInterceptors(result)
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

    private func executeRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await urlSession.data(for: request)
        } catch let error as URLError {
            throw NetworkError.from(urlError: error)
        } catch {
            throw NetworkError.networkFailure(underlyingError: error.localizedDescription)
        }
    }

    private func buildURLRequest(from request: HTTPRequest) throws -> URLRequest {
        var urlRequest = try request.build()

        for (key, value) in globalHeaders {
            if urlRequest.value(forHTTPHeaderField: key) == nil {
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
        }

        return urlRequest
    }

    private func validateResponse(_ response: HTTPURLResponse, data: Data?) throws {
        let statusCode = response.statusCode

        guard NetworkError.isSuccessStatusCode(statusCode) else {
            var serverMessage: String?
            if let data {
                serverMessage = extractErrorMessage(from: data)
            }

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

    private func extractErrorMessage(from data: Data) -> String? {
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

}

// MARK: - Builder Pattern

/// Builder para crear InterceptableNetworkClient de forma fluida.
public final class NetworkClientBuilder: @unchecked Sendable {
    private var interceptors: [any RequestInterceptor] = []
    private var retryPolicy: (any RetryPolicy)?
    private var maxRetryTimeout: TimeInterval = 120
    private var configuration: URLSessionConfiguration = .default

    public init() {}

    /// Agrega un interceptor.
    @discardableResult
    public func addInterceptor(_ interceptor: any RequestInterceptor) -> Self {
        interceptors.append(interceptor)
        return self
    }

    /// Agrega logging con nivel especificado.
    @discardableResult
    public func withLogging(level: LogLevel = .info) -> Self {
        interceptors.append(LoggingInterceptor(level: level))
        return self
    }

    /// Agrega autenticación con el token provider especificado.
    @discardableResult
    public func withAuthentication(tokenProvider: any TokenProvider) -> Self {
        interceptors.append(AuthenticationInterceptor.standard(tokenProvider: tokenProvider))
        return self
    }

    /// Agrega retry con la política especificada.
    @discardableResult
    public func withRetry(policy: any RetryPolicy = ExponentialBackoffRetryPolicy.standard) -> Self {
        interceptors.append(RetryInterceptor(policy: policy))
        self.retryPolicy = policy
        return self
    }

    /// Establece el timeout máximo para reintentos.
    @discardableResult
    public func maxRetryTimeout(_ timeout: TimeInterval) -> Self {
        self.maxRetryTimeout = timeout
        return self
    }

    /// Establece la configuración de URLSession.
    @discardableResult
    public func configuration(_ config: URLSessionConfiguration) -> Self {
        self.configuration = config
        return self
    }

    /// Construye el cliente.
    public func build() -> InterceptableNetworkClient {
        InterceptableNetworkClient(
            interceptors: interceptors,
            defaultRetryPolicy: retryPolicy,
            maxRetryTimeout: maxRetryTimeout,
            configuration: configuration
        )
    }
}

// MARK: - Convenience Extensions

extension InterceptableNetworkClient {
    /// Crea un builder para configurar el cliente.
    public static func builder() -> NetworkClientBuilder {
        NetworkClientBuilder()
    }
}
