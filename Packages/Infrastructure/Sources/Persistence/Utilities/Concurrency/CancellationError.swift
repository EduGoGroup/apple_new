import Foundation

/// Errores específicos de cancelación para operaciones concurrentes.
///
/// Proporciona una clasificación detallada de las razones de cancelación,
/// permitiendo al código llamador distinguir entre diferentes escenarios
/// y tomar acciones apropiadas.
///
/// ## Casos de Uso
///
/// ```swift
/// do {
///     let result = try await handler.withTimeout(.seconds(30)) {
///         try await longRunningOperation()
///     }
/// } catch let error as CancellationReason {
///     switch error {
///     case .timeout(let duration):
///         print("Operación excedió \(duration)s")
///     case .userCancelled:
///         print("Cancelado por el usuario")
///     case .systemCancelled(let reason):
///         print("Sistema canceló: \(reason ?? "desconocido")")
///     case .parentTaskCancelled:
///         print("Tarea padre fue cancelada")
///     }
/// }
/// ```
///
/// ## Best Practices para Cancelación Cooperativa
///
/// 1. **Verificar frecuentemente**: Usa `Task.checkCancellation()` en loops largos
/// 2. **Propagar cancelación**: No captures errores de cancelación silenciosamente
/// 3. **Cleanup recursos**: Usa `defer` para garantizar cleanup
/// 4. **Distinguir errores**: Usa este enum para clasificar la razón de cancelación
public enum CancellationReason: Error, Sendable, Equatable {
    /// La operación excedió el tiempo límite configurado.
    ///
    /// - Parameter duration: Duración del timeout en segundos.
    ///
    /// ## Ejemplo
    /// ```swift
    /// throw CancellationReason.timeout(duration: 30.0)
    /// ```
    case timeout(duration: TimeInterval)

    /// La operación fue cancelada explícitamente por el usuario.
    ///
    /// Típicamente ocurre cuando el usuario presiona un botón de cancelar
    /// o navega fuera de la pantalla.
    case userCancelled

    /// La operación fue cancelada por el sistema.
    ///
    /// - Parameter reason: Descripción opcional del motivo del sistema.
    ///
    /// Puede ocurrir por:
    /// - Presión de memoria
    /// - App entrando en background
    /// - Sistema operativo terminando la app
    case systemCancelled(reason: String?)

    /// La tarea padre fue cancelada, propagando la cancelación a esta operación.
    ///
    /// En Swift Concurrency, cuando una tarea padre se cancela, todas las
    /// child tasks reciben una señal de cancelación cooperativa.
    case parentTaskCancelled

    /// Múltiples operaciones en un batch fueron canceladas.
    ///
    /// - Parameters:
    ///   - completed: Número de operaciones que completaron antes de la cancelación.
    ///   - total: Número total de operaciones en el batch.
    case batchCancelled(completed: Int, total: Int)

    /// Recurso necesario no disponible, operación cancelada.
    ///
    /// - Parameter resource: Nombre o descripción del recurso.
    case resourceUnavailable(resource: String)
}

// MARK: - LocalizedError

extension CancellationReason: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .timeout(let duration):
            return "La operación excedió el tiempo límite de \(Int(duration)) segundos"

        case .userCancelled:
            return "Operación cancelada por el usuario"

        case .systemCancelled(let reason):
            if let reason {
                return "Operación cancelada por el sistema: \(reason)"
            }
            return "Operación cancelada por el sistema"

        case .parentTaskCancelled:
            return "Operación cancelada porque la tarea padre fue cancelada"

        case .batchCancelled(let completed, let total):
            return "Batch cancelado después de completar \(completed) de \(total) operaciones"

        case .resourceUnavailable(let resource):
            return "Operación cancelada: recurso '\(resource)' no disponible"
        }
    }

    public var failureReason: String? {
        switch self {
        case .timeout:
            return "El tiempo de ejecución superó el límite configurado"
        case .userCancelled:
            return "El usuario solicitó cancelar la operación"
        case .systemCancelled:
            return "El sistema operativo solicitó cancelar la operación"
        case .parentTaskCancelled:
            return "La tarea que inició esta operación fue cancelada"
        case .batchCancelled:
            return "El batch de operaciones fue interrumpido"
        case .resourceUnavailable:
            return "Un recurso requerido no está disponible"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .timeout:
            return "Intente la operación nuevamente o aumente el tiempo límite"
        case .userCancelled:
            return "Reinicie la operación si lo desea"
        case .systemCancelled:
            return "Espere a que el sistema esté menos ocupado e intente de nuevo"
        case .parentTaskCancelled:
            return "Reinicie la operación desde el contexto padre"
        case .batchCancelled:
            return "Reinicie el batch o procese las operaciones pendientes individualmente"
        case .resourceUnavailable:
            return "Verifique que el recurso esté disponible e intente de nuevo"
        }
    }
}

// MARK: - CustomDebugStringConvertible

extension CancellationReason: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .timeout(let duration):
            return "CancellationReason.timeout(duration: \(duration)s)"
        case .userCancelled:
            return "CancellationReason.userCancelled"
        case .systemCancelled(let reason):
            return "CancellationReason.systemCancelled(reason: \(reason ?? "nil"))"
        case .parentTaskCancelled:
            return "CancellationReason.parentTaskCancelled"
        case .batchCancelled(let completed, let total):
            return "CancellationReason.batchCancelled(completed: \(completed), total: \(total))"
        case .resourceUnavailable(let resource):
            return "CancellationReason.resourceUnavailable(resource: \(resource))"
        }
    }
}

// MARK: - Convenience Properties

extension CancellationReason {
    /// Indica si la cancelación fue iniciada por el usuario.
    public var isUserInitiated: Bool {
        if case .userCancelled = self { return true }
        return false
    }

    /// Indica si la cancelación fue por timeout.
    public var isTimeout: Bool {
        if case .timeout = self { return true }
        return false
    }

    /// Indica si la cancelación fue por el sistema.
    public var isSystemInitiated: Bool {
        switch self {
        case .systemCancelled, .parentTaskCancelled, .resourceUnavailable:
            return true
        default:
            return false
        }
    }

    /// Indica si la operación puede ser reintentada de forma segura.
    public var isRetriable: Bool {
        switch self {
        case .timeout, .systemCancelled, .resourceUnavailable:
            return true
        case .userCancelled, .parentTaskCancelled, .batchCancelled:
            return false
        }
    }
}

// MARK: - Factory Methods

extension CancellationReason {
    /// Crea un CancellationReason desde un CancellationError estándar de Swift.
    ///
    /// - Returns: `.parentTaskCancelled` ya que CancellationError indica
    ///   cancelación cooperativa desde la tarea padre.
    public static func from(_ error: CancellationError) -> CancellationReason {
        .parentTaskCancelled
    }

    /// Crea un CancellationReason verificando si la tarea actual está cancelada.
    ///
    /// - Returns: `.parentTaskCancelled` si `Task.isCancelled` es true, nil si no.
    public static func checkCurrentTask() -> CancellationReason? {
        Task.isCancelled ? .parentTaskCancelled : nil
    }
}
