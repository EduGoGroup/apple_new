import SwiftUI
import Observation

/// Actor observable que gestiona el estado de focus global de la aplicación.
/// Thread-safe con actor isolation, puede ser accedido desde cualquier contexto.
@MainActor
@Observable
public final class FocusManager {

    // MARK: - Singleton

    /// Instancia compartida del FocusManager
    public static let shared = FocusManager()

    // MARK: - Properties

    /// ID del elemento que actualmente tiene focus
    public private(set) var currentFocusID: AnyHashable?

    /// Stack de contextos de focus (para modals, sheets, etc.)
    private var focusContextStack: [FocusContext] = []

    /// Historial de focus (para restaurar focus previo)
    private var focusHistory: [AnyHashable] = []

    /// Máximo número de elementos en el historial
    private let maxHistorySize: Int = 10

    // MARK: - Initialization

    private init() {}

    // MARK: - Focus Management

    /// Establece el focus en un elemento específico
    /// - Parameter id: ID del elemento que debe recibir focus
    public func setFocus(_ id: AnyHashable?) {
        // Guardar focus anterior en el historial si existe
        if let currentFocusID = currentFocusID {
            addToHistory(currentFocusID)
        }

        currentFocusID = id
    }

    /// Limpia el focus actual
    public func clearFocus() {
        if let currentFocusID = currentFocusID {
            addToHistory(currentFocusID)
        }
        currentFocusID = nil
    }

    /// Restaura el focus al elemento anterior en el historial
    /// - Returns: true si se pudo restaurar, false si no hay historial
    @discardableResult
    public func restorePreviousFocus() -> Bool {
        guard let previousFocus = focusHistory.popLast() else {
            return false
        }
        currentFocusID = previousFocus
        return true
    }

    // MARK: - Focus Context Stack

    /// Añade un nuevo contexto de focus (usado cuando se abre un modal o sheet)
    /// - Parameter context: Contexto de focus a añadir
    public func pushFocusContext(_ context: FocusContext) {
        // Guardar focus actual antes de cambiar de contexto
        if let currentFocusID = currentFocusID {
            addToHistory(currentFocusID)
        }

        focusContextStack.append(context)

        // Si el contexto tiene un focus inicial, establecerlo
        if let initialFocus = context.initialFocusID {
            currentFocusID = initialFocus
        }
    }

    /// Remueve el contexto de focus actual (usado cuando se cierra un modal o sheet)
    /// - Returns: El contexto removido, o nil si el stack está vacío
    @discardableResult
    public func popFocusContext() -> FocusContext? {
        guard let context = focusContextStack.popLast() else {
            return nil
        }

        // Restaurar focus al contexto anterior
        if let previousContext = focusContextStack.last,
           let restorationFocus = previousContext.restorationFocusID {
            currentFocusID = restorationFocus
        } else {
            // No hay contexto anterior, intentar restaurar del historial
            restorePreviousFocus()
        }

        return context
    }

    /// Obtiene el contexto de focus actual
    public var currentContext: FocusContext? {
        focusContextStack.last
    }

    /// Indica si hay contextos de focus activos (por ejemplo, un modal abierto)
    public var hasActiveContext: Bool {
        !focusContextStack.isEmpty
    }

    // MARK: - History Management

    private func addToHistory(_ focusID: AnyHashable) {
        // Evitar duplicados consecutivos
        if focusHistory.last != focusID {
            focusHistory.append(focusID)

            // Mantener el tamaño del historial limitado
            if focusHistory.count > maxHistorySize {
                focusHistory.removeFirst()
            }
        }
    }

    /// Limpia el historial de focus
    public func clearHistory() {
        focusHistory.removeAll()
    }

    // MARK: - Debug

    /// Información de debug sobre el estado actual del FocusManager
    public var debugInfo: String {
        var info = "FocusManager Debug Info:\n"
        info += "Current Focus: \(currentFocusID.map(String.init(describing:)) ?? "nil")\n"
        info += "Context Stack Depth: \(focusContextStack.count)\n"
        info += "History Size: \(focusHistory.count)\n"
        if let currentContext = currentContext {
            info += "Current Context: \(currentContext.name)\n"
        }
        return info
    }
}

// MARK: - Focus Context

/// Representa un contexto de focus (modal, sheet, popover, etc.)
public struct FocusContext: Sendable {
    /// Nombre descriptivo del contexto
    public let name: String

    /// ID del elemento que debe recibir focus inicialmente
    public let initialFocusID: String?

    /// ID del elemento al que debe volver el focus al cerrar este contexto
    public let restorationFocusID: String?

    /// Indica si este contexto atrapa el focus (focus trap)
    public let trapsFocus: Bool

    /// IDs de elementos permitidos dentro de este contexto (para focus trap)
    public let allowedFocusIDs: Set<String>?

    public init(
        name: String,
        initialFocusID: String? = nil,
        restorationFocusID: String? = nil,
        trapsFocus: Bool = false,
        allowedFocusIDs: Set<String>? = nil
    ) {
        self.name = name
        self.initialFocusID = initialFocusID
        self.restorationFocusID = restorationFocusID
        self.trapsFocus = trapsFocus
        self.allowedFocusIDs = allowedFocusIDs
    }

    /// Verifica si un ID de focus está permitido en este contexto
    public func isAllowed(_ focusID: String) -> Bool {
        guard trapsFocus else { return true }
        guard let allowedFocusIDs = allowedFocusIDs else { return true }
        return allowedFocusIDs.contains(focusID)
    }
}

// MARK: - Environment Integration

/// Environment key para el FocusManager
extension FocusManagerKey: @preconcurrency EnvironmentKey {}
public struct FocusManagerKey {
    @MainActor
    public static var defaultValue: FocusManager {
        .shared
    }
}

extension EnvironmentValues {
    /// Acceso al FocusManager desde el environment
    public var focusManager: FocusManager {
        get { self[FocusManagerKey.self] }
        set { self[FocusManagerKey.self] = newValue }
    }
}

// MARK: - View Extensions

extension View {
    /// Inyecta el FocusManager en el environment
    /// - Parameter manager: FocusManager a inyectar (por defecto usa .shared)
    /// - Returns: Vista con el FocusManager en el environment
    public func focusManager(_ manager: FocusManager = .shared) -> some View {
        environment(\.focusManager, manager)
    }
}
