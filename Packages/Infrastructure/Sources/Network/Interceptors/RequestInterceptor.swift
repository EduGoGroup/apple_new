import Foundation

/// Resultado de la decisión de retry de un interceptor.
public enum RetryDecision: Sendable, Equatable {
    /// No reintentar, propagar el error.
    case doNotRetry

    /// Reintentar la request después del delay especificado.
    case retryAfter(TimeInterval)

    /// Reintentar inmediatamente.
    case retryImmediately

    /// Reintentar con una request modificada.
    case retryWithRequest(URLRequest)
}

/// Contexto de ejecución de una request para los interceptors.
public struct RequestContext: Sendable {
    /// Request original antes de cualquier modificación.
    public let originalRequest: HTTPRequest

    /// Número de intento actual (1-based).
    public let attemptNumber: Int

    /// Tiempo transcurrido desde el primer intento.
    public let elapsedTime: TimeInterval

    /// Metadata adicional del contexto.
    public let metadata: [String: String]

    /// Inicializador.
    public init(
        originalRequest: HTTPRequest,
        attemptNumber: Int = 1,
        elapsedTime: TimeInterval = 0,
        metadata: [String: String] = [:]
    ) {
        self.originalRequest = originalRequest
        self.attemptNumber = attemptNumber
        self.elapsedTime = elapsedTime
        self.metadata = metadata
    }

    /// Crea un nuevo contexto incrementando el intento.
    public func nextAttempt(elapsedTime: TimeInterval) -> RequestContext {
        RequestContext(
            originalRequest: originalRequest,
            attemptNumber: attemptNumber + 1,
            elapsedTime: elapsedTime,
            metadata: metadata
        )
    }
}

/// Protocolo que define un interceptor de requests HTTP.
///
/// Los interceptors permiten modificar requests antes de enviarlas y
/// decidir si reintentar en caso de error, siguiendo el patrón
/// Chain of Responsibility.
///
/// ## Conformidad con Swift 6.2
/// - Hereda de `Sendable` para thread-safety
/// - Métodos `async` para operaciones asíncronas
///
/// ## Ejemplo de implementación
/// ```swift
/// struct CustomHeaderInterceptor: RequestInterceptor {
///     func adapt(_ request: URLRequest, context: RequestContext) async throws -> URLRequest {
///         var modified = request
///         modified.setValue("custom-value", forHTTPHeaderField: "X-Custom-Header")
///         return modified
///     }
///
///     func retry(
///         _ request: URLRequest,
///         dueTo error: NetworkError,
///         context: RequestContext
///     ) async -> RetryDecision {
///         return .doNotRetry
///     }
/// }
/// ```
public protocol RequestInterceptor: Sendable {
    /// Adapta una request antes de ser enviada.
    ///
    /// Este método permite modificar headers, body, o cualquier otro
    /// aspecto de la request antes de que sea ejecutada.
    ///
    /// - Parameters:
    ///   - request: Request original a modificar
    ///   - context: Contexto de ejecución
    /// - Returns: Request modificada
    /// - Throws: Error si la adaptación falla
    func adapt(
        _ request: URLRequest,
        context: RequestContext
    ) async throws -> URLRequest

    /// Decide si reintentar una request fallida.
    ///
    /// Este método es llamado cuando una request falla, permitiendo
    /// al interceptor decidir si debe reintentarse.
    ///
    /// - Parameters:
    ///   - request: Request que falló
    ///   - error: Error que causó el fallo
    ///   - context: Contexto de ejecución
    /// - Returns: Decisión de retry
    func retry(
        _ request: URLRequest,
        dueTo error: NetworkError,
        context: RequestContext
    ) async -> RetryDecision

    /// Callback opcional cuando una request se completa exitosamente.
    ///
    /// - Parameters:
    ///   - request: Request completada
    ///   - response: Respuesta HTTP
    ///   - data: Datos de la respuesta
    ///   - context: Contexto de ejecución
    func didReceive(
        response: HTTPURLResponse,
        data: Data,
        for request: URLRequest,
        context: RequestContext
    ) async
}

// MARK: - Default Implementations

extension RequestInterceptor {
    /// Implementación por defecto que no modifica la request.
    public func adapt(
        _ request: URLRequest,
        context: RequestContext
    ) async throws -> URLRequest {
        request
    }

    /// Implementación por defecto que no reintenta.
    public func retry(
        _ request: URLRequest,
        dueTo error: NetworkError,
        context: RequestContext
    ) async -> RetryDecision {
        .doNotRetry
    }

    /// Implementación por defecto que no hace nada.
    public func didReceive(
        response: HTTPURLResponse,
        data: Data,
        for request: URLRequest,
        context: RequestContext
    ) async {
        // No-op por defecto
    }
}

/// Compone múltiples interceptors en una cadena.
///
/// Los interceptors se ejecutan en orden para `adapt` y en orden inverso
/// para `retry`, siguiendo el patrón Chain of Responsibility.
public struct InterceptorChain: RequestInterceptor {
    /// Interceptors en la cadena.
    public let interceptors: [any RequestInterceptor]

    /// Inicializador con array de interceptors.
    public init(_ interceptors: [any RequestInterceptor]) {
        self.interceptors = interceptors
    }

    /// Inicializador variádico.
    public init(_ interceptors: any RequestInterceptor...) {
        self.interceptors = interceptors
    }

    /// Aplica todos los interceptors en orden.
    public func adapt(
        _ request: URLRequest,
        context: RequestContext
    ) async throws -> URLRequest {
        var currentRequest = request
        for interceptor in interceptors {
            currentRequest = try await interceptor.adapt(currentRequest, context: context)
        }
        return currentRequest
    }

    /// Consulta los interceptors en orden inverso hasta que uno decida reintentar.
    public func retry(
        _ request: URLRequest,
        dueTo error: NetworkError,
        context: RequestContext
    ) async -> RetryDecision {
        // Los interceptors de retry se evalúan en orden inverso
        for interceptor in interceptors.reversed() {
            let decision = await interceptor.retry(request, dueTo: error, context: context)
            if decision != .doNotRetry {
                return decision
            }
        }
        return .doNotRetry
    }

    /// Notifica a todos los interceptors de la respuesta.
    public func didReceive(
        response: HTTPURLResponse,
        data: Data,
        for request: URLRequest,
        context: RequestContext
    ) async {
        for interceptor in interceptors {
            await interceptor.didReceive(
                response: response,
                data: data,
                for: request,
                context: context
            )
        }
    }
}

// MARK: - Type-erased Interceptor

/// Wrapper type-erased para cualquier RequestInterceptor.
public struct AnyInterceptor: RequestInterceptor {
    private let _adapt: @Sendable (URLRequest, RequestContext) async throws -> URLRequest
    private let _retry: @Sendable (URLRequest, NetworkError, RequestContext) async -> RetryDecision
    private let _didReceive: @Sendable (HTTPURLResponse, Data, URLRequest, RequestContext) async -> Void

    /// Crea un AnyInterceptor a partir de cualquier RequestInterceptor.
    public init<I: RequestInterceptor>(_ interceptor: I) {
        _adapt = { request, context in
            try await interceptor.adapt(request, context: context)
        }
        _retry = { request, error, context in
            await interceptor.retry(request, dueTo: error, context: context)
        }
        _didReceive = { response, data, request, context in
            await interceptor.didReceive(
                response: response,
                data: data,
                for: request,
                context: context
            )
        }
    }

    public func adapt(
        _ request: URLRequest,
        context: RequestContext
    ) async throws -> URLRequest {
        try await _adapt(request, context)
    }

    public func retry(
        _ request: URLRequest,
        dueTo error: NetworkError,
        context: RequestContext
    ) async -> RetryDecision {
        await _retry(request, error, context)
    }

    public func didReceive(
        response: HTTPURLResponse,
        data: Data,
        for request: URLRequest,
        context: RequestContext
    ) async {
        await _didReceive(response, data, request, context)
    }
}
