import Foundation
#if canImport(os)
import os
#endif

/// Nivel de logging para el interceptor.
public enum LogLevel: Int, Sendable, Comparable, CaseIterable {
    /// Sin logging.
    case none = 0
    /// Solo errores.
    case error = 1
    /// Errores e información básica.
    case info = 2
    /// Logging detallado para debugging.
    case debug = 3
    /// Logging muy detallado incluyendo headers y body.
    case verbose = 4

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Interceptor que registra requests y responses para debugging.
///
/// Proporciona diferentes niveles de detalle configurables y usa
/// `os.Logger` para integración con Console.app e Instruments.
///
/// ## Uso
/// ```swift
/// let loggingInterceptor = LoggingInterceptor(level: .debug)
/// let client = NetworkClient(interceptors: [loggingInterceptor])
/// ```
public struct LoggingInterceptor: RequestInterceptor {
    /// Nivel de logging actual.
    public let level: LogLevel

    /// Subsistema para os.Logger.
    public let subsystem: String

    /// Categoría para os.Logger.
    public let category: String

    /// Si debe incluir headers en el log.
    public let includeHeaders: Bool

    /// Si debe incluir body en el log (puede contener datos sensibles).
    public let includeBody: Bool

    /// Tamaño máximo del body a loggear (en bytes).
    public let maxBodySize: Int

    #if canImport(os)
    private let logger: Logger
    #endif

    /// Inicializador con configuración personalizada.
    /// - Parameters:
    ///   - level: Nivel de logging (default: .info)
    ///   - subsystem: Subsistema para os.Logger (default: "com.edugo.network")
    ///   - category: Categoría para os.Logger (default: "HTTP")
    ///   - includeHeaders: Si incluir headers (default: false en release, true en debug)
    ///   - includeBody: Si incluir body (default: false)
    ///   - maxBodySize: Tamaño máximo del body a loggear (default: 1024)
    public init(
        level: LogLevel = .info,
        subsystem: String = "com.edugo.network",
        category: String = "HTTP",
        includeHeaders: Bool = false,
        includeBody: Bool = false,
        maxBodySize: Int = 1024
    ) {
        self.level = level
        self.subsystem = subsystem
        self.category = category
        self.includeHeaders = includeHeaders
        self.includeBody = includeBody
        self.maxBodySize = maxBodySize

        #if canImport(os)
        self.logger = Logger(subsystem: subsystem, category: category)
        #endif
    }

    // MARK: - RequestInterceptor

    public func adapt(
        _ request: URLRequest,
        context: RequestContext
    ) async throws -> URLRequest {
        guard level >= .info else { return request }

        logRequest(request, context: context)
        return request
    }

    public func retry(
        _ request: URLRequest,
        dueTo error: NetworkError,
        context: RequestContext
    ) async -> RetryDecision {
        if level >= .error {
            logError(error, for: request, context: context)
        }
        return .doNotRetry
    }

    public func didReceive(
        response: HTTPURLResponse,
        data: Data,
        for request: URLRequest,
        context: RequestContext
    ) async {
        guard level >= .info else { return }
        logResponse(response, data: data, for: request, context: context)
    }

    // MARK: - Private Logging Methods

    private func logRequest(_ request: URLRequest, context: RequestContext) {
        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? "unknown"
        let attempt = context.attemptNumber > 1 ? " (attempt \(context.attemptNumber))" : ""

        let message = "[\(method)] \(url)\(attempt)"

        #if canImport(os)
        if level >= .debug {
            logger.debug("→ \(message)")
        } else {
            logger.info("→ \(message)")
        }
        #else
        print("→ \(message)")
        #endif

        if level >= .verbose {
            logRequestDetails(request)
        }
    }

    private func logRequestDetails(_ request: URLRequest) {
        // Log headers
        if includeHeaders, let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            let headerString = headers
                .map { "  \($0.key): \(sanitizeHeaderValue($0.key, $0.value))" }
                .joined(separator: "\n")

            #if canImport(os)
            logger.debug("  Headers:\n\(headerString)")
            #else
            print("  Headers:\n\(headerString)")
            #endif
        }

        // Log body
        if includeBody, let body = request.httpBody, !body.isEmpty {
            let bodyString = formatBody(body)

            #if canImport(os)
            logger.debug("  Body: \(bodyString)")
            #else
            print("  Body: \(bodyString)")
            #endif
        }
    }

    private func logResponse(
        _ response: HTTPURLResponse,
        data: Data,
        for request: URLRequest,
        context: RequestContext
    ) {
        let statusCode = response.statusCode
        let url = response.url?.absoluteString ?? request.url?.absoluteString ?? "unknown"
        let dataSize = formatByteSize(data.count)
        let duration = String(format: "%.2fs", context.elapsedTime)

        let statusEmoji = statusEmoji(for: statusCode)
        let message = "\(statusEmoji) [\(statusCode)] \(url) (\(dataSize), \(duration))"

        #if canImport(os)
        if NetworkError.isSuccessStatusCode(statusCode) {
            if level >= .debug {
                logger.debug("← \(message)")
            } else {
                logger.info("← \(message)")
            }
        } else {
            logger.warning("← \(message)")
        }
        #else
        print("← \(message)")
        #endif

        if level >= .verbose {
            logResponseDetails(response, data: data)
        }
    }

    private func logResponseDetails(_ response: HTTPURLResponse, data: Data) {
        // Log headers
        if includeHeaders {
            let headers = response.allHeaderFields
            if !headers.isEmpty {
                let headerString = headers
                    .map { "  \($0.key): \($0.value)" }
                    .joined(separator: "\n")

                #if canImport(os)
                logger.debug("  Response Headers:\n\(headerString)")
                #else
                print("  Response Headers:\n\(headerString)")
                #endif
            }
        }

        // Log body
        if includeBody, !data.isEmpty {
            let bodyString = formatBody(data)

            #if canImport(os)
            logger.debug("  Response Body: \(bodyString)")
            #else
            print("  Response Body: \(bodyString)")
            #endif
        }
    }

    private func logError(_ error: NetworkError, for request: URLRequest, context: RequestContext) {
        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? "unknown"
        let attempt = context.attemptNumber

        let message = "[\(method)] \(url) failed (attempt \(attempt)): \(error.localizedDescription)"

        #if canImport(os)
        logger.error("✗ \(message)")
        #else
        print("✗ \(message)")
        #endif
    }

    // MARK: - Formatting Helpers

    private func sanitizeHeaderValue(_ key: String, _ value: String) -> String {
        // Ocultar valores sensibles
        let sensitiveHeaders = ["authorization", "x-api-key", "cookie", "set-cookie"]
        if sensitiveHeaders.contains(key.lowercased()) {
            return "[REDACTED]"
        }
        return value
    }

    private func formatBody(_ data: Data) -> String {
        if data.count > maxBodySize {
            let truncated = data.prefix(maxBodySize)
            if let string = String(data: truncated, encoding: .utf8) {
                return "\(string)... [\(formatByteSize(data.count)) total, truncated]"
            }
        }

        if let string = String(data: data, encoding: .utf8) {
            return string
        }

        return "[\(formatByteSize(data.count)) binary data]"
    }

    private func formatByteSize(_ bytes: Int) -> String {
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024)
        } else {
            return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
        }
    }

    private func statusEmoji(for statusCode: Int) -> String {
        switch statusCode {
        case 200..<300: return ""
        case 300..<400: return ""
        case 400..<500: return ""
        case 500..<600: return ""
        default: return ""
        }
    }
}

// MARK: - Convenience Initializers

extension LoggingInterceptor {
    /// Crea un interceptor para debugging con nivel verbose.
    public static var debug: LoggingInterceptor {
        LoggingInterceptor(
            level: .debug,
            includeHeaders: true,
            includeBody: false
        )
    }

    /// Crea un interceptor para producción con nivel mínimo.
    public static var production: LoggingInterceptor {
        LoggingInterceptor(level: .error)
    }

    /// Crea un interceptor verbose para troubleshooting.
    public static var verbose: LoggingInterceptor {
        LoggingInterceptor(
            level: .verbose,
            includeHeaders: true,
            includeBody: true,
            maxBodySize: 4096
        )
    }
}
