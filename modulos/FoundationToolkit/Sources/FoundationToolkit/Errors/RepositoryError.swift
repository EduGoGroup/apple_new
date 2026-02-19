import Foundation

/// Errores relacionados con la capa de persistencia y acceso a datos.
///
/// Estos errores representan fallos en operaciones de lectura, escritura, eliminación
/// y sincronización de datos con las fuentes de persistencia (API, base de datos local, etc.).
public enum RepositoryError: Error, LocalizedError, Sendable {
    /// Falló la operación de recuperación de datos.
    case fetchFailed(reason: String)

    /// Falló la operación de guardado de datos.
    case saveFailed(reason: String)

    /// Falló la operación de eliminación de datos.
    case deleteFailed(reason: String)

    /// Error de conexión con la fuente de datos.
    ///
    /// Usa `String` en lugar de `Error` porque el protocolo `Error`
    /// no es `Sendable`, lo que violaría strict concurrency en Swift 6.
    case connectionError(reason: String)

    /// Error de serialización o deserialización de datos.
    case serializationError(type: String)

    /// Inconsistencia detectada en los datos almacenados.
    case dataInconsistency(description: String)

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .fetchFailed(let reason):
            return "Error al recuperar datos: \(reason)"
        case .saveFailed(let reason):
            return "Error al guardar datos: \(reason)"
        case .deleteFailed(let reason):
            return "Error al eliminar datos: \(reason)"
        case .connectionError(let reason):
            return "Error de conexión: \(reason)"
        case .serializationError(let type):
            return "Error de serialización para el tipo '\(type)'"
        case .dataInconsistency(let description):
            return "Inconsistencia en los datos: \(description)"
        }
    }

    public var failureReason: String? {
        switch self {
        case .fetchFailed:
            return "No se pudo completar la operación de lectura desde la fuente de datos."
        case .saveFailed:
            return "No se pudo completar la operación de escritura en la fuente de datos."
        case .deleteFailed:
            return "No se pudo completar la operación de eliminación en la fuente de datos."
        case .connectionError:
            return "No se pudo establecer o mantener la conexión con la fuente de datos."
        case .serializationError(let type):
            return "Los datos recibidos no pudieron ser convertidos al tipo '\(type)' esperado."
        case .dataInconsistency:
            return "Los datos almacenados no cumplen con las restricciones de integridad esperadas."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .fetchFailed:
            return "Verifique su conexión a internet y vuelva a intentar. Si el problema persiste, contacte al soporte técnico."
        case .saveFailed:
            return "Asegúrese de tener conexión a internet y permisos suficientes. Intente guardar nuevamente."
        case .deleteFailed:
            return "Verifique que el recurso no esté siendo utilizado por otras entidades y vuelva a intentar."
        case .connectionError:
            return "Revise su conexión a internet y asegúrese de que el servicio esté disponible."
        case .serializationError:
            return "Los datos recibidos pueden estar en un formato incorrecto. Actualice la aplicación o contacte al soporte."
        case .dataInconsistency:
            return "Intente sincronizar los datos nuevamente o contacte al soporte técnico para resolver la inconsistencia."
        }
    }
}

// MARK: - Equatable

extension RepositoryError: Equatable {
    public static func == (lhs: RepositoryError, rhs: RepositoryError) -> Bool {
        switch (lhs, rhs) {
        case (.fetchFailed(let lReason), .fetchFailed(let rReason)):
            return lReason == rReason
        case (.saveFailed(let lReason), .saveFailed(let rReason)):
            return lReason == rReason
        case (.deleteFailed(let lReason), .deleteFailed(let rReason)):
            return lReason == rReason
        case (.connectionError(let lReason), .connectionError(let rReason)):
            return lReason == rReason
        case (.serializationError(let lType), .serializationError(let rType)):
            return lType == rType
        case (.dataInconsistency(let lDesc), .dataInconsistency(let rDesc)):
            return lDesc == rDesc
        default:
            return false
        }
    }
}
