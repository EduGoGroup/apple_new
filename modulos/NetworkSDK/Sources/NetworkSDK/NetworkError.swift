import Foundation

/// Errores tipados para operaciones de networking.
///
/// Proporciona errores específicos y descriptivos para el manejo de fallos
/// en la capa de red, siguiendo las mejores prácticas de Swift 6.2.
///
/// ## Uso
/// ```swift
/// do {
///     let data = try await networkClient.request(url)
/// } catch let error as NetworkError {
///     switch error {
///     case .invalidURL(let url):
///         print("URL inválida: \(url)")
///     case .serverError(let code, let message):
///         print("Error del servidor (\(code)): \(message ?? "Sin mensaje")")
///     default:
///         print("Error de red: \(error.localizedDescription)")
///     }
/// }
/// ```
public enum NetworkError: Error, Sendable, Equatable {
    /// La URL proporcionada no es válida o no se puede construir.
    case invalidURL(String)

    /// No se recibieron datos en la respuesta del servidor.
    case noData

    /// Error al decodificar la respuesta JSON.
    /// - Parameter type: Nombre del tipo que se intentó decodificar
    /// - Parameter underlyingError: Descripción del error de decodificación
    case decodingError(type: String, underlyingError: String)

    /// Error del servidor HTTP.
    /// - Parameter statusCode: Código de estado HTTP
    /// - Parameter message: Mensaje opcional del servidor
    case serverError(statusCode: Int, message: String?)

    /// Fallo de conexión de red.
    /// - Parameter underlyingError: Descripción del error subyacente
    case networkFailure(underlyingError: String)

    /// La request fue cancelada.
    case cancelled

    /// Timeout de la request.
    case timeout

    /// Error de certificado SSL/TLS.
    case sslError(underlyingError: String)

    /// Error de autenticación (401).
    case unauthorized

    /// Error de autorización (403).
    case forbidden

    /// Recurso no encontrado (404).
    case notFound

    /// Rate limit excedido (429).
    case rateLimited(retryAfter: TimeInterval?)
}

// MARK: - LocalizedError

extension NetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "URL inválida: \(url)"
        case .noData:
            return "No se recibieron datos del servidor"
        case .decodingError(let type, let underlyingError):
            return "Error al decodificar \(type): \(underlyingError)"
        case .serverError(let statusCode, let message):
            if let message {
                return "Error del servidor (\(statusCode)): \(message)"
            }
            return "Error del servidor: HTTP \(statusCode)"
        case .networkFailure(let underlyingError):
            return "Fallo de conexión: \(underlyingError)"
        case .cancelled:
            return "La solicitud fue cancelada"
        case .timeout:
            return "La solicitud excedió el tiempo de espera"
        case .sslError(let underlyingError):
            return "Error de seguridad SSL: \(underlyingError)"
        case .unauthorized:
            return "No autorizado. Por favor, inicie sesión nuevamente"
        case .forbidden:
            return "No tiene permisos para acceder a este recurso"
        case .notFound:
            return "El recurso solicitado no fue encontrado"
        case .rateLimited(let retryAfter):
            if let retryAfter {
                return "Demasiadas solicitudes. Intente de nuevo en \(Int(retryAfter)) segundos"
            }
            return "Demasiadas solicitudes. Intente de nuevo más tarde"
        }
    }
}

// MARK: - CustomDebugStringConvertible

extension NetworkError: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .invalidURL(let url):
            return "NetworkError.invalidURL(\(url))"
        case .noData:
            return "NetworkError.noData"
        case .decodingError(let type, let error):
            return "NetworkError.decodingError(type: \(type), error: \(error))"
        case .serverError(let code, let message):
            return "NetworkError.serverError(statusCode: \(code), message: \(message ?? "nil"))"
        case .networkFailure(let error):
            return "NetworkError.networkFailure(\(error))"
        case .cancelled:
            return "NetworkError.cancelled"
        case .timeout:
            return "NetworkError.timeout"
        case .sslError(let error):
            return "NetworkError.sslError(\(error))"
        case .unauthorized:
            return "NetworkError.unauthorized"
        case .forbidden:
            return "NetworkError.forbidden"
        case .notFound:
            return "NetworkError.notFound"
        case .rateLimited(let retryAfter):
            return "NetworkError.rateLimited(retryAfter: \(retryAfter ?? 0))"
        }
    }
}

// MARK: - Factory Methods

extension NetworkError {
    /// Crea un NetworkError a partir de un código de estado HTTP.
    /// - Parameters:
    ///   - statusCode: Código de estado HTTP
    ///   - message: Mensaje opcional del servidor
    ///   - retryAfter: Tiempo de espera para retry (solo para 429)
    /// - Returns: NetworkError correspondiente al código de estado
    public static func from(
        statusCode: Int,
        message: String? = nil,
        retryAfter: TimeInterval? = nil
    ) -> NetworkError {
        switch statusCode {
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 429:
            return .rateLimited(retryAfter: retryAfter)
        default:
            return .serverError(statusCode: statusCode, message: message)
        }
    }

    /// Crea un NetworkError a partir de un URLError.
    /// - Parameter urlError: El URLError original
    /// - Returns: NetworkError correspondiente
    public static func from(urlError: URLError) -> NetworkError {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
            return .networkFailure(underlyingError: urlError.localizedDescription)
        case .timedOut:
            return .timeout
        case .cancelled:
            return .cancelled
        case .secureConnectionFailed, .serverCertificateUntrusted,
             .serverCertificateHasBadDate, .serverCertificateNotYetValid,
             .serverCertificateHasUnknownRoot, .clientCertificateRejected:
            return .sslError(underlyingError: urlError.localizedDescription)
        default:
            return .networkFailure(underlyingError: urlError.localizedDescription)
        }
    }
}

// MARK: - HTTP Status Code Validation

extension NetworkError {
    /// Verifica si un código de estado HTTP indica éxito (200-299).
    /// - Parameter statusCode: Código de estado HTTP
    /// - Returns: true si el código indica éxito
    public static func isSuccessStatusCode(_ statusCode: Int) -> Bool {
        (200...299).contains(statusCode)
    }

    /// Verifica si un código de estado HTTP indica error del cliente (400-499).
    /// - Parameter statusCode: Código de estado HTTP
    /// - Returns: true si el código indica error del cliente
    public static func isClientError(_ statusCode: Int) -> Bool {
        (400...499).contains(statusCode)
    }

    /// Verifica si un código de estado HTTP indica error del servidor (500-599).
    /// - Parameter statusCode: Código de estado HTTP
    /// - Returns: true si el código indica error del servidor
    public static func isServerError(_ statusCode: Int) -> Bool {
        (500...599).contains(statusCode)
    }
}
