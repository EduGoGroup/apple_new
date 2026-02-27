import Foundation

/// Protocolo interno para almacenar handlers de forma type-erased
protocol AnyQueryHandler: Sendable {
    func handle(_ query: Any) async throws -> Any
}

/// Protocolo interno para almacenar command handlers de forma type-erased
protocol AnyCommandHandler: Sendable {
    func handle(_ command: Any) async throws -> Any
}

/// Wrapper type-erased para QueryHandler
struct TypeErasedQueryHandler<H: QueryHandler>: AnyQueryHandler {
    let handler: H

    init(_ handler: H) {
        self.handler = handler
    }

    func handle(_ query: Any) async throws -> Any {
        guard let typedQuery = query as? H.QueryType else {
            throw MediatorError.executionError(
                message: "Type mismatch in query handler",
                underlyingError: nil
            )
        }
        return try await handler.handle(typedQuery)
    }
}

/// Wrapper type-erased para CommandHandler
struct TypeErasedCommandHandler<H: CommandHandler>: AnyCommandHandler {
    let handler: H

    init(_ handler: H) {
        self.handler = handler
    }

    func handle(_ command: Any) async throws -> Any {
        guard let typedCommand = command as? H.CommandType else {
            throw MediatorError.executionError(
                message: "Type mismatch in command handler",
                underlyingError: nil
            )
        }
        return try await handler.handle(typedCommand)
    }
}

/// Registry para almacenar handlers registrados
///
/// Utiliza type-erasure para almacenar handlers de diferentes tipos
/// de forma type-safe y eficiente.
public actor MediatorRegistry {

    // Storage interno usando ObjectIdentifier como key
    private var queryHandlers: [ObjectIdentifier: AnyQueryHandler] = [:]
    private var commandHandlers: [ObjectIdentifier: AnyCommandHandler] = [:]

    // MARK: - Inicialización

    public init() {}

    // MARK: - Registro de Query Handlers

    /// Registra un QueryHandler para un tipo específico de Query
    ///
    /// - Parameter handler: El handler a registrar
    /// - Throws:
    ///   - `MediatorError.registrationError` si ya existe un handler registrado para este tipo de query
    /// - Note: Para APIs de nivel enterprise, todos los casos de error deben estar explícitamente documentados
    public func registerQueryHandler<H: QueryHandler>(_ handler: H) throws {
        let key = ObjectIdentifier(H.QueryType.self)

        guard queryHandlers[key] == nil else {
            throw MediatorError.registrationError(
                message: "Handler already registered for query type: \(H.QueryType.self)"
            )
        }

        queryHandlers[key] = TypeErasedQueryHandler(handler)
    }

    /// Registra un QueryHandler, reemplazando cualquier handler existente
    ///
    /// - Parameter handler: El handler a registrar
    public func registerOrReplaceQueryHandler<H: QueryHandler>(_ handler: H) {
        let key = ObjectIdentifier(H.QueryType.self)
        queryHandlers[key] = TypeErasedQueryHandler(handler)
    }

    /// Obtiene el handler registrado para un tipo de Query
    ///
    /// - Parameter queryType: El tipo de query
    /// - Returns: El handler si existe
    /// - Throws: `MediatorError.handlerNotFound` si no hay handler registrado
    func getQueryHandler<Q: Query>(for queryType: Q.Type) throws -> AnyQueryHandler {
        let key = ObjectIdentifier(queryType)

        guard let handler = queryHandlers[key] else {
            throw MediatorError.handlerNotFound(type: String(describing: queryType))
        }

        return handler
    }

    // MARK: - Registro de Command Handlers

    /// Registra un CommandHandler para un tipo específico de Command
    ///
    /// - Parameter handler: El handler a registrar
    /// - Throws: `MediatorError.registrationError` si ya existe un handler para ese tipo
    public func registerCommandHandler<H: CommandHandler>(_ handler: H) throws {
        let key = ObjectIdentifier(H.CommandType.self)

        guard commandHandlers[key] == nil else {
            throw MediatorError.registrationError(
                message: "Handler already registered for command type: \(H.CommandType.self)"
            )
        }

        commandHandlers[key] = TypeErasedCommandHandler(handler)
    }

    /// Registra un CommandHandler, reemplazando cualquier handler existente
    ///
    /// - Parameter handler: El handler a registrar
    public func registerOrReplaceCommandHandler<H: CommandHandler>(_ handler: H) {
        let key = ObjectIdentifier(H.CommandType.self)
        commandHandlers[key] = TypeErasedCommandHandler(handler)
    }

    /// Obtiene el handler registrado para un tipo de Command
    ///
    /// - Parameter commandType: El tipo de command
    /// - Returns: El handler si existe
    /// - Throws: `MediatorError.handlerNotFound` si no hay handler registrado
    func getCommandHandler<C: Command>(for commandType: C.Type) throws -> AnyCommandHandler {
        let key = ObjectIdentifier(commandType)

        guard let handler = commandHandlers[key] else {
            throw MediatorError.handlerNotFound(type: String(describing: commandType))
        }

        return handler
    }

    // MARK: - Utilidades

    /// Elimina el handler registrado para un tipo de Query
    ///
    /// - Parameter queryType: El tipo de query
    public func unregisterQueryHandler<Q: Query>(for queryType: Q.Type) {
        let key = ObjectIdentifier(queryType)
        queryHandlers.removeValue(forKey: key)
    }

    /// Elimina el handler registrado para un tipo de Command
    ///
    /// - Parameter commandType: El tipo de command
    public func unregisterCommandHandler<C: Command>(for commandType: C.Type) {
        let key = ObjectIdentifier(commandType)
        commandHandlers.removeValue(forKey: key)
    }

    /// Elimina todos los handlers registrados
    public func clear() {
        queryHandlers.removeAll()
        commandHandlers.removeAll()
    }

    /// Retorna el número de query handlers registrados
    ///
    /// Esta propiedad es útil para debugging y monitoreo del estado del mediator.
    /// En producción, úsala para verificar el registro de handlers durante la inicialización de la app.
    public var queryHandlerCount: Int {
        queryHandlers.count
    }

    /// Retorna el número de command handlers registrados
    ///
    /// Esta propiedad es útil para debugging y monitoreo del estado del mediator.
    /// En producción, úsala para verificar el registro de handlers durante la inicialización de la app.
    public var commandHandlerCount: Int {
        commandHandlers.count
    }
}
