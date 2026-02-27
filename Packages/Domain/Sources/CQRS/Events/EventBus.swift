import Foundation
import OSLog

/// Protocolo para subscribers que reaccionan a eventos de dominio.
///
/// Los EventSubscriber son componentes que se suscriben a tipos específicos
/// de eventos y ejecutan lógica de negocio cuando esos eventos ocurren.
/// Los subscribers son asíncronos y no bloquean el publish del evento.
///
/// # Ejemplo de implementación:
/// ```swift
/// actor EmailNotificationSubscriber: EventSubscriber {
///     typealias EventType = UserCreatedEvent
///
///     func handle(_ event: UserCreatedEvent) async {
///         await emailService.sendWelcomeEmail(to: event.userId)
///     }
/// }
/// ```
public protocol EventSubscriber: Sendable {
    /// Tipo de evento que este subscriber puede procesar
    associatedtype EventType: DomainEvent

    /// Procesa el evento de forma asíncrona.
    ///
    /// Este método no debe lanzar errores. Si ocurre un error,
    /// el subscriber debe manejarlo internamente (logging, retry, etc.)
    ///
    /// - Parameter event: El evento a procesar
    func handle(_ event: EventType) async
}

/// Actor central que implementa el patrón pub/sub para eventos de dominio.
///
/// EventBus permite a los componentes publicar eventos sin conocer
/// quién los consume, y a los subscribers reaccionar a eventos sin
/// conocer quién los produce. Esto promueve un bajo acoplamiento.
///
/// # Características
/// - Thread-safe mediante actor isolation
/// - Múltiples subscribers por tipo de evento
/// - Ejecución asíncrona no-bloqueante de subscribers
/// - Integración con CQRSMetrics para observabilidad
/// - Logging estructurado con OSLog
///
/// # Ejemplo de uso:
/// ```swift
/// let eventBus = EventBus()
///
/// // Registrar subscribers
/// await eventBus.subscribe(CacheInvalidationSubscriber())
/// await eventBus.subscribe(AuditLogSubscriber())
///
/// // Publicar eventos
/// await eventBus.publish(MaterialUploadedEvent(materialId: id, title: title))
///
/// // Los subscribers procesan el evento de forma asíncrona
/// ```
public actor EventBus {

    // MARK: - Types

    /// Wrapper type-erased para almacenar subscribers heterogéneos
    private struct SubscriberEntry: Sendable {
        let id: UUID
        let eventTypeName: String
        let handler: @Sendable (any DomainEvent) async -> Void
    }

    // MARK: - Properties

    /// Subscribers registrados, indexados por tipo de evento
    private var subscribers: [String: [SubscriberEntry]] = [:]

    /// Logger para debugging
    private let logger: Logger

    /// Indica si el logging está habilitado
    private let loggingEnabled: Bool

    /// Instancia de métricas para observabilidad
    private let metrics: CQRSMetrics

    /// Indica si las métricas están habilitadas
    private let metricsEnabled: Bool

    // MARK: - Initialization

    /// Crea una nueva instancia de EventBus.
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
        category: String = "EventBus"
    ) {
        self.loggingEnabled = loggingEnabled
        self.metricsEnabled = metricsEnabled
        self.metrics = metrics
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    // MARK: - Subscription

    /// Suscribe un subscriber a su tipo de evento asociado.
    ///
    /// El subscriber será invocado cada vez que se publique un evento
    /// del tipo que maneja. Múltiples subscribers pueden escuchar
    /// el mismo tipo de evento.
    ///
    /// - Parameter subscriber: El subscriber a registrar
    /// - Returns: ID de suscripción para poder cancelarla
    @discardableResult
    public func subscribe<S: EventSubscriber>(_ subscriber: S) -> UUID {
        let eventTypeName = String(describing: S.EventType.self)
        let subscriptionId = UUID()

        let entry = SubscriberEntry(
            id: subscriptionId,
            eventTypeName: eventTypeName,
            handler: { @Sendable event in
                if let typedEvent = event as? S.EventType {
                    await subscriber.handle(typedEvent)
                }
            }
        )

        subscribers[eventTypeName, default: []].append(entry)

        if loggingEnabled {
            logger.info("Subscribed to \(eventTypeName, privacy: .public). Subscription ID: \(subscriptionId)")
        }

        return subscriptionId
    }

    /// Suscribe un closure como handler para un tipo de evento específico.
    ///
    /// Esta variante es útil para casos simples donde no se necesita
    /// crear un tipo separado de subscriber.
    ///
    /// - Parameters:
    ///   - eventType: Tipo de evento a escuchar
    ///   - handler: Closure que procesa el evento
    /// - Returns: ID de suscripción para poder cancelarla
    @discardableResult
    public func subscribe<E: DomainEvent>(
        to eventType: E.Type,
        handler: @escaping @Sendable (E) async -> Void
    ) -> UUID {
        let eventTypeName = String(describing: E.self)
        let subscriptionId = UUID()

        let entry = SubscriberEntry(
            id: subscriptionId,
            eventTypeName: eventTypeName,
            handler: { @Sendable event in
                if let typedEvent = event as? E {
                    await handler(typedEvent)
                }
            }
        )

        subscribers[eventTypeName, default: []].append(entry)

        if loggingEnabled {
            logger.info("Subscribed closure to \(eventTypeName, privacy: .public). Subscription ID: \(subscriptionId)")
        }

        return subscriptionId
    }

    /// Cancela una suscripción por su ID.
    ///
    /// - Parameter subscriptionId: ID de la suscripción a cancelar
    /// - Returns: true si se encontró y canceló la suscripción
    @discardableResult
    public func unsubscribe(_ subscriptionId: UUID) -> Bool {
        for (eventType, entries) in subscribers {
            if let index = entries.firstIndex(where: { $0.id == subscriptionId }) {
                subscribers[eventType]?.remove(at: index)

                // Limpiar arrays vacíos
                if subscribers[eventType]?.isEmpty == true {
                    subscribers.removeValue(forKey: eventType)
                }

                if loggingEnabled {
                    logger.info("Unsubscribed: \(subscriptionId) from \(eventType, privacy: .public)")
                }

                return true
            }
        }
        return false
    }

    /// Elimina todos los subscribers de un tipo de evento específico.
    ///
    /// - Parameter eventType: Tipo de evento
    public func unsubscribeAll<E: DomainEvent>(from eventType: E.Type) {
        let eventTypeName = String(describing: E.self)
        let count = subscribers[eventTypeName]?.count ?? 0
        subscribers.removeValue(forKey: eventTypeName)

        if loggingEnabled {
            logger.info("Unsubscribed all (\(count)) from \(eventTypeName, privacy: .public)")
        }
    }

    // MARK: - Publishing

    /// Publica un evento a todos los subscribers registrados.
    ///
    /// Los subscribers son invocados de forma asíncrona y no bloquean
    /// la operación de publish. Cada subscriber se ejecuta en su propio
    /// contexto de concurrencia.
    ///
    /// - Parameter event: El evento a publicar
    public func publish<E: DomainEvent>(_ event: E) async {
        let eventTypeName = String(describing: E.self)

        if loggingEnabled {
            logger.debug("Publishing event: \(eventTypeName, privacy: .public) [ID: \(event.eventId)]")
        }

        // Registrar métrica de evento publicado
        if metricsEnabled {
            await metrics.recordEventPublished(eventType: eventTypeName)
        }

        // Obtener subscribers para este tipo de evento
        guard let eventSubscribers = subscribers[eventTypeName], !eventSubscribers.isEmpty else {
            if loggingEnabled {
                logger.debug("No subscribers for event: \(eventTypeName, privacy: .public)")
            }
            return
        }

        if loggingEnabled {
            logger.debug("Dispatching to \(eventSubscribers.count) subscribers")
        }

        // Ejecutar todos los subscribers en paralelo (no bloqueante)
        await withTaskGroup(of: Void.self) { group in
            for subscriber in eventSubscribers {
                group.addTask {
                    await subscriber.handler(event)

                    // Registrar métrica de evento procesado
                    if self.metricsEnabled {
                        await self.metrics.recordEventProcessed(eventType: eventTypeName)
                    }
                }
            }
        }

        if loggingEnabled {
            logger.debug("Event dispatched: \(eventTypeName, privacy: .public)")
        }
    }

    /// Publica múltiples eventos en secuencia.
    ///
    /// - Parameter events: Array de eventos a publicar
    public func publishAll(_ events: [any DomainEvent]) async {
        for event in events {
            await publishAny(event)
        }
    }

    /// Publica un evento type-erased.
    ///
    /// - Parameter event: El evento a publicar
    public func publishAny(_ event: any DomainEvent) async {
        let eventTypeName = event.eventType

        if loggingEnabled {
            logger.debug("Publishing type-erased event: \(eventTypeName, privacy: .public) [ID: \(event.eventId)]")
        }

        // Registrar métrica de evento publicado
        if metricsEnabled {
            await metrics.recordEventPublished(eventType: eventTypeName)
        }

        // Obtener subscribers para este tipo de evento
        guard let eventSubscribers = subscribers[eventTypeName], !eventSubscribers.isEmpty else {
            if loggingEnabled {
                logger.debug("No subscribers for event: \(eventTypeName, privacy: .public)")
            }
            return
        }

        // Ejecutar todos los subscribers en paralelo
        await withTaskGroup(of: Void.self) { group in
            for subscriber in eventSubscribers {
                group.addTask {
                    await subscriber.handler(event)

                    if self.metricsEnabled {
                        await self.metrics.recordEventProcessed(eventType: eventTypeName)
                    }
                }
            }
        }
    }

    // MARK: - Inspection

    /// Retorna el número de subscribers para un tipo de evento.
    ///
    /// - Parameter eventType: Tipo de evento
    /// - Returns: Número de subscribers registrados
    public func subscriberCount<E: DomainEvent>(for eventType: E.Type) -> Int {
        let eventTypeName = String(describing: E.self)
        return subscribers[eventTypeName]?.count ?? 0
    }

    /// Retorna el número total de suscripciones.
    public var totalSubscriptions: Int {
        subscribers.values.reduce(0) { $0 + $1.count }
    }

    /// Retorna los tipos de eventos que tienen subscribers.
    public var subscribedEventTypes: [String] {
        Array(subscribers.keys)
    }

    /// Elimina todos los subscribers.
    public func clearAllSubscriptions() {
        let count = totalSubscriptions
        subscribers.removeAll()

        if loggingEnabled {
            logger.warning("Cleared all subscriptions (\(count))")
        }
    }
}
