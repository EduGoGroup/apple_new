import Foundation
import OSLog

/// Actor central que despacha queries y commands a sus handlers respectivos.
///
/// El Mediator implementa el patrón Mediator para desacoplar las capas de la aplicación
/// de los handlers específicos. Proporciona un punto central de dispatch type-safe
/// con logging estructurado y manejo de errores robusto.
///
/// # Ejemplo de uso:
/// ```swift
/// // Configurar el mediator
/// let mediator = Mediator()
/// try await mediator.registerQueryHandler(GetUserQueryHandler())
/// try await mediator.registerCommandHandler(CreateUserCommandHandler())
///
/// // Ejecutar una query
/// let user = try await mediator.send(GetUserQuery(userId: "123"))
///
/// // Ejecutar un command
/// let result = try await mediator.execute(CreateUserCommand(
///     username: "john",
///     email: "john@example.com"
/// ))
/// ```
public actor Mediator {

    // MARK: - Properties

    /// Registry interno que almacena todos los handlers registrados
    private let registry: MediatorRegistry

    /// Logger para debugging y structured logging
    private let logger: Logger

    /// Indica si el logging está habilitado
    private let loggingEnabled: Bool

    /// Indica si las métricas están habilitadas
    private let metricsEnabled: Bool

    /// Instancia de métricas (inyectable para testing)
    private let metrics: CQRSMetrics

    // MARK: - Inicialización

    /// Crea una nueva instancia del Mediator
    ///
    /// - Parameters:
    ///   - loggingEnabled: Habilita o deshabilita el logging (default: true)
    ///   - metricsEnabled: Habilita o deshabilita las métricas (default: true)
    ///   - metrics: Instancia de CQRSMetrics a usar (default: shared)
    ///   - subsystem: Subsystem para el logger OSLog
    ///   - category: Categoría para el logger OSLog
    public init(
        loggingEnabled: Bool = true,
        metricsEnabled: Bool = true,
        metrics: CQRSMetrics = CQRSMetrics.shared,
        subsystem: String = "com.edugo.cqrs",
        category: String = "Mediator"
    ) {
        self.registry = MediatorRegistry()
        self.loggingEnabled = loggingEnabled
        self.metricsEnabled = metricsEnabled
        self.metrics = metrics
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    // MARK: - Query Dispatch

    /// Despacha una Query a su handler registrado y retorna el resultado.
    ///
    /// Este método es type-safe: el tipo de retorno se infiere automáticamente
    /// del tipo asociado de la Query.
    ///
    /// - Parameter query: La query a ejecutar
    /// - Returns: El resultado de tipo `Q.Result`
    /// - Throws: `MediatorError` si no hay handler registrado o si falla la ejecución
    ///
    /// # Ejemplo:
    /// ```swift
    /// let user = try await mediator.send(GetUserQuery(userId: "123"))
    /// ```
    public func send<Q: Query>(_ query: Q) async throws -> Q.Result {
        let queryType = String(describing: type(of: query))
        let startTime = ContinuousClock.now

        if loggingEnabled {
            logger.debug("Dispatching query: \(queryType, privacy: .public)")
        }

        do {
            // Obtener el handler del registry
            let handler = try await registry.getQueryHandler(for: Q.self)

            // Ejecutar el handler
            let result = try await handler.handle(query)

            // Type-cast del resultado
            guard let typedResult = result as? Q.Result else {
                throw MediatorError.executionError(
                    message: "Result type mismatch for query: \(queryType)",
                    underlyingError: nil
                )
            }

            // Registrar métricas de latencia
            if metricsEnabled {
                let duration = ContinuousClock.now - startTime
                await metrics.recordQueryLatency(
                    queryType: queryType,
                    duration: duration
                )
            }

            if loggingEnabled {
                logger.debug("Query executed successfully: \(queryType)")
            }

            return typedResult

        } catch let error as MediatorError {
            // Registrar error en métricas
            if metricsEnabled {
                await metrics.recordError(handlerType: queryType, error: error)
            }

            if loggingEnabled {
                logger.error("Query failed: \(queryType, privacy: .public). Error: \(error.description, privacy: .public)")
            }
            throw error
        } catch {
            // Registrar error en métricas
            if metricsEnabled {
                await metrics.recordError(handlerType: queryType, error: error)
            }

            if loggingEnabled {
                logger.error("Query failed: \(queryType, privacy: .public). Error: \(error.localizedDescription, privacy: .public)")
            }
            throw MediatorError.executionError(
                message: "Failed to execute query: \(queryType)",
                underlyingError: error
            )
        }
    }

    // MARK: - Command Dispatch

    /// Ejecuta un Command con validación pre-ejecución y retorna el resultado.
    ///
    /// Este método valida el command antes de ejecutarlo y envuelve el resultado
    /// en un `CommandResult` type-safe.
    ///
    /// - Parameter command: El command a ejecutar
    /// - Returns: `CommandResult<C.Result>` con el resultado de la operación
    /// - Throws: `MediatorError` si falla la validación, no hay handler, o falla la ejecución
    ///
    /// # Ejemplo:
    /// ```swift
    /// let result = try await mediator.execute(CreateUserCommand(
    ///     username: "john",
    ///     email: "john@example.com"
    /// ))
    /// ```
    public func execute<C: Command>(_ command: C) async throws -> CommandResult<C.Result> {
        let commandType = String(describing: type(of: command))
        let startTime = ContinuousClock.now

        if loggingEnabled {
            logger.debug("Executing command: \(commandType, privacy: .public)")
        }

        // Validar el command antes de ejecutarlo
        do {
            try command.validate()
        } catch {
            if loggingEnabled {
                logger.error("Command validation failed: \(commandType). Error: \(error.localizedDescription)")
            }
            throw MediatorError.validationError(
                message: "Validation failed for command: \(commandType)",
                underlyingError: error
            )
        }

        do {
            // Obtener el handler del registry
            let handler = try await registry.getCommandHandler(for: C.self)

            // Ejecutar el handler
            let result = try await handler.handle(command)

            // Type-cast del resultado
            guard let typedResult = result as? CommandResult<C.Result> else {
                throw MediatorError.executionError(
                    message: "Result type mismatch for command: \(commandType)",
                    underlyingError: nil
                )
            }

            // Registrar métricas de latencia
            if metricsEnabled {
                let duration = ContinuousClock.now - startTime
                await metrics.recordCommandLatency(
                    commandType: commandType,
                    duration: duration
                )

                // Registrar eventos publicados
                for event in typedResult.events {
                    await metrics.recordEventPublished(eventType: event)
                }
            }

            if loggingEnabled {
                if typedResult.isSuccess {
                    logger.debug("Command executed successfully: \(commandType). Events: \(typedResult.events)")
                } else {
                    logger.warning("Command execution failed: \(commandType)")
                }
            }

            return typedResult

        } catch let error as MediatorError {
            // Registrar error en métricas
            if metricsEnabled {
                await metrics.recordError(handlerType: commandType, error: error)
            }

            if loggingEnabled {
                logger.error("Command failed: \(commandType, privacy: .public). Error: \(error.description, privacy: .public)")
            }
            throw error
        } catch {
            // Registrar error en métricas
            if metricsEnabled {
                await metrics.recordError(handlerType: commandType, error: error)
            }

            if loggingEnabled {
                logger.error("Command failed: \(commandType, privacy: .public). Error: \(error.localizedDescription, privacy: .public)")
            }
            throw MediatorError.executionError(
                message: "Failed to execute command: \(commandType)",
                underlyingError: error
            )
        }
    }

    // MARK: - Handler Registration

    /// Registra un QueryHandler en el registry
    ///
    /// - Parameter handler: El handler a registrar
    /// - Throws: `MediatorError.registrationError` si ya existe un handler para ese tipo
    public func registerQueryHandler<H: QueryHandler>(_ handler: H) async throws {
        try await registry.registerQueryHandler(handler)

        if loggingEnabled {
            logger.info("Registered query handler: \(String(describing: H.QueryType.self))")
        }
    }

    /// Registra un QueryHandler, reemplazando cualquier handler existente
    ///
    /// - Parameter handler: El handler a registrar
    public func registerOrReplaceQueryHandler<H: QueryHandler>(_ handler: H) async {
        await registry.registerOrReplaceQueryHandler(handler)

        if loggingEnabled {
            logger.info("Registered/replaced query handler: \(String(describing: H.QueryType.self))")
        }
    }

    /// Registra un CommandHandler en el registry
    ///
    /// - Parameter handler: El handler a registrar
    /// - Throws: `MediatorError.registrationError` si ya existe un handler para ese tipo
    public func registerCommandHandler<H: CommandHandler>(_ handler: H) async throws {
        try await registry.registerCommandHandler(handler)

        if loggingEnabled {
            logger.info("Registered command handler: \(String(describing: H.CommandType.self))")
        }
    }

    /// Registra un CommandHandler, reemplazando cualquier handler existente
    ///
    /// - Parameter handler: El handler a registrar
    public func registerOrReplaceCommandHandler<H: CommandHandler>(_ handler: H) async {
        await registry.registerOrReplaceCommandHandler(handler)

        if loggingEnabled {
            logger.info("Registered/replaced command handler: \(String(describing: H.CommandType.self))")
        }
    }

    // MARK: - Utilidades

    /// Elimina el handler registrado para un tipo de Query
    ///
    /// - Parameter queryType: El tipo de query
    public func unregisterQueryHandler<Q: Query>(for queryType: Q.Type) async {
        await registry.unregisterQueryHandler(for: queryType)

        if loggingEnabled {
            logger.info("Unregistered query handler: \(String(describing: queryType))")
        }
    }

    /// Elimina el handler registrado para un tipo de Command
    ///
    /// - Parameter commandType: El tipo de command
    public func unregisterCommandHandler<C: Command>(for commandType: C.Type) async {
        await registry.unregisterCommandHandler(for: commandType)

        if loggingEnabled {
            logger.info("Unregistered command handler: \(String(describing: commandType))")
        }
    }

    /// Elimina todos los handlers registrados
    public func clearAllHandlers() async {
        await registry.clear()

        if loggingEnabled {
            logger.warning("Cleared all handlers from registry")
        }
    }

    /// Retorna el número de query handlers registrados
    ///
    /// Esta propiedad asíncrona delega al registry interno para obtener el conteo.
    /// Úsala para monitoreo y debugging del estado del mediator en producción.
    public var queryHandlerCount: Int {
        get async {
            await registry.queryHandlerCount
        }
    }

    /// Retorna el número de command handlers registrados
    ///
    /// Esta propiedad asíncrona delega al registry interno para obtener el conteo.
    /// Úsala para monitoreo y debugging del estado del mediator en producción.
    public var commandHandlerCount: Int {
        get async {
            await registry.commandHandlerCount
        }
    }
}
