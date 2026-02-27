import Foundation

/// Métodos HTTP soportados por el cliente de red.
public enum HTTPMethod: String, Sendable, CaseIterable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
    case head = "HEAD"
    case options = "OPTIONS"
}

/// Configuración de una solicitud HTTP usando el patrón Builder.
///
/// Permite construir solicitudes HTTP de forma fluida y segura.
///
/// ## Uso básico
/// ```swift
/// let jsonData = ... // Data previamente serializado (DTO)
/// let request = HTTPRequest(url: "https://api.example.com/users")
///     .method(.post)
///     .header("Authorization", "Bearer token123")
///     .jsonBody(jsonData)
///     .timeout(30)
///     .build()
/// ```
///
/// ## Uso con query parameters
/// ```swift
/// let request = HTTPRequest(url: "https://api.example.com/search")
///     .queryParam("q", "swift")
///     .queryParam("page", "1")
///     .build()
/// ```
public struct HTTPRequest: Sendable {
    /// URL base de la request.
    public let url: String

    /// Método HTTP de la request.
    public private(set) var method: HTTPMethod

    /// Headers HTTP de la request.
    public private(set) var headers: [String: String]

    /// Query parameters de la request.
    public private(set) var queryParameters: [String: String]

    /// Body de la request (datos codificados).
    public private(set) var body: Data?

    /// Timeout de la request en segundos.
    public private(set) var timeoutInterval: TimeInterval

    /// Cache policy para la request.
    public private(set) var cachePolicy: URLRequest.CachePolicy

    // MARK: - Initialization

    /// Crea una nueva HTTPRequest con la URL especificada.
    /// - Parameter url: URL de la request
    public init(url: String) {
        self.url = url
        self.method = .get
        self.headers = [:]
        self.queryParameters = [:]
        self.body = nil
        self.timeoutInterval = 30
        self.cachePolicy = .useProtocolCachePolicy
    }

    // MARK: - Builder Methods

    /// Establece el método HTTP.
    /// - Parameter method: Método HTTP a usar
    /// - Returns: Nueva instancia con el método actualizado
    public func method(_ method: HTTPMethod) -> HTTPRequest {
        var copy = self
        copy.method = method
        return copy
    }

    /// Agrega un header a la request.
    /// - Parameters:
    ///   - name: Nombre del header
    ///   - value: Valor del header
    /// - Returns: Nueva instancia con el header agregado
    public func header(_ name: String, _ value: String) -> HTTPRequest {
        var copy = self
        copy.headers[name] = value
        return copy
    }

    /// Agrega múltiples headers a la request.
    /// - Parameter headers: Diccionario de headers a agregar
    /// - Returns: Nueva instancia con los headers agregados
    public func headers(_ headers: [String: String]) -> HTTPRequest {
        var copy = self
        for (name, value) in headers {
            copy.headers[name] = value
        }
        return copy
    }

    /// Agrega un query parameter a la request.
    /// - Parameters:
    ///   - name: Nombre del parámetro
    ///   - value: Valor del parámetro
    /// - Returns: Nueva instancia con el parámetro agregado
    public func queryParam(_ name: String, _ value: String) -> HTTPRequest {
        var copy = self
        copy.queryParameters[name] = value
        return copy
    }

    /// Agrega múltiples query parameters a la request.
    /// - Parameter params: Diccionario de parámetros a agregar
    /// - Returns: Nueva instancia con los parámetros agregados
    public func queryParams(_ params: [String: String]) -> HTTPRequest {
        var copy = self
        for (name, value) in params {
            copy.queryParameters[name] = value
        }
        return copy
    }

    /// Establece el body de la request como Data.
    /// - Parameter data: Datos del body
    /// - Returns: Nueva instancia con el body establecido
    public func body(_ data: Data) -> HTTPRequest {
        var copy = self
        copy.body = data
        return copy
    }

    /// Establece el body de la request como JSON ya serializado.
    /// - Parameter data: Datos JSON ya serializados
    /// - Returns: Nueva instancia con el body establecido
    public func jsonBody(_ data: Data) -> HTTPRequest {
        var copy = self
        copy.body = data
        if copy.headers["Content-Type"] == nil {
            copy.headers["Content-Type"] = "application/json"
        }
        return copy
    }

    /// Establece el body de la request como JSON desde un diccionario.
    /// - Parameter json: Diccionario a serializar como JSON
    /// - Returns: Nueva instancia con el body establecido
    /// - Throws: Error de serialización si falla
    public func jsonBody(_ json: [String: Any]) throws -> HTTPRequest {
        let copy = self
        let data = try JSONSerialization.data(withJSONObject: json)
        return copy.jsonBody(data)
    }

    /// Establece el timeout de la request.
    /// - Parameter seconds: Timeout en segundos
    /// - Returns: Nueva instancia con el timeout actualizado
    public func timeout(_ seconds: TimeInterval) -> HTTPRequest {
        var copy = self
        copy.timeoutInterval = seconds
        return copy
    }

    /// Establece la cache policy de la request.
    /// - Parameter policy: Policy de cache a usar
    /// - Returns: Nueva instancia con la policy actualizada
    public func cachePolicy(_ policy: URLRequest.CachePolicy) -> HTTPRequest {
        var copy = self
        copy.cachePolicy = policy
        return copy
    }

    /// Agrega el header Accept para JSON.
    /// - Returns: Nueva instancia con el header Accept establecido
    public func acceptJSON() -> HTTPRequest {
        header("Accept", "application/json")
    }

    /// Agrega el header Authorization con Bearer token.
    /// - Parameter token: Token de autorización
    /// - Returns: Nueva instancia con el header de autorización
    public func bearerToken(_ token: String) -> HTTPRequest {
        header("Authorization", "Bearer \(token)")
    }

    /// Agrega el header Authorization con Basic auth.
    /// - Parameters:
    ///   - username: Nombre de usuario
    ///   - password: Contraseña
    /// - Returns: Nueva instancia con el header de autorización
    public func basicAuth(username: String, password: String) -> HTTPRequest {
        let credentials = "\(username):\(password)"
        guard let data = credentials.data(using: .utf8) else {
            return self
        }
        let base64 = data.base64EncodedString()
        return header("Authorization", "Basic \(base64)")
    }

    // MARK: - Build

    /// Construye un URLRequest a partir de la configuración actual.
    /// - Returns: URLRequest configurado o error si la URL es inválida
    /// - Throws: NetworkError.invalidURL si la URL no es válida
    public func build() throws -> URLRequest {
        guard var components = URLComponents(string: url) else {
            throw NetworkError.invalidURL(url)
        }

        // Agregar query parameters
        if !queryParameters.isEmpty {
            var queryItems = components.queryItems ?? []
            for (name, value) in queryParameters {
                queryItems.append(URLQueryItem(name: name, value: value))
            }
            components.queryItems = queryItems
        }

        guard let finalURL = components.url else {
            throw NetworkError.invalidURL(url)
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = method.rawValue
        request.timeoutInterval = timeoutInterval
        request.cachePolicy = cachePolicy
        request.httpBody = body

        // Aplicar headers
        for (name, value) in headers {
            request.setValue(value, forHTTPHeaderField: name)
        }

        return request
    }
}

// MARK: - Convenience Initializers

extension HTTPRequest {
    /// Crea una request GET.
    /// - Parameter url: URL de la request
    /// - Returns: HTTPRequest configurada para GET
    public static func get(_ url: String) -> HTTPRequest {
        HTTPRequest(url: url).method(.get)
    }

    /// Crea una request POST.
    /// - Parameter url: URL de la request
    /// - Returns: HTTPRequest configurada para POST
    public static func post(_ url: String) -> HTTPRequest {
        HTTPRequest(url: url).method(.post)
    }

    /// Crea una request PUT.
    /// - Parameter url: URL de la request
    /// - Returns: HTTPRequest configurada para PUT
    public static func put(_ url: String) -> HTTPRequest {
        HTTPRequest(url: url).method(.put)
    }

    /// Crea una request DELETE.
    /// - Parameter url: URL de la request
    /// - Returns: HTTPRequest configurada para DELETE
    public static func delete(_ url: String) -> HTTPRequest {
        HTTPRequest(url: url).method(.delete)
    }

    /// Crea una request PATCH.
    /// - Parameter url: URL de la request
    /// - Returns: HTTPRequest configurada para PATCH
    public static func patch(_ url: String) -> HTTPRequest {
        HTTPRequest(url: url).method(.patch)
    }
}

// MARK: - CustomStringConvertible

extension HTTPRequest: CustomStringConvertible {
    public var description: String {
        var parts = ["\(method.rawValue) \(url)"]

        if !queryParameters.isEmpty {
            let params = queryParameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
            parts.append("Query: \(params)")
        }

        if !headers.isEmpty {
            let headerList = headers.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            parts.append("Headers: [\(headerList)]")
        }

        if let body, !body.isEmpty {
            parts.append("Body: \(body.count) bytes")
        }

        return parts.joined(separator: " | ")
    }
}

// MARK: - Equatable

extension HTTPRequest: Equatable {
    public static func == (lhs: HTTPRequest, rhs: HTTPRequest) -> Bool {
        lhs.url == rhs.url &&
        lhs.method == rhs.method &&
        lhs.headers == rhs.headers &&
        lhs.queryParameters == rhs.queryParameters &&
        lhs.body == rhs.body &&
        lhs.timeoutInterval == rhs.timeoutInterval &&
        lhs.cachePolicy == rhs.cachePolicy
    }
}
