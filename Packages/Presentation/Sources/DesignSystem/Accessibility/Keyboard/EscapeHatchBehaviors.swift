import SwiftUI

/// Sistema de escape hatch behaviors para manejar teclas de cancelación/escape
/// de forma consistente en toda la aplicación.
///
/// Un "escape hatch" es una forma rápida de cancelar o salir de una operación,
/// típicamente usando la tecla Escape en macOS o gestos en iOS.
///
/// ## Casos de uso comunes
/// - Dismiss modals/sheets con Escape
/// - Cancel editing en text fields
/// - Clear selections
/// - Close popovers
/// - Exit full screen
///
/// ## Ejemplo
/// ```swift
/// Modal {
///     // Contenido
/// }
/// .escapeHatch(.dismissModal) { isPresented = false }
/// ```
@MainActor
public final class EscapeHatchManager {

    // MARK: - Singleton

    public static let shared = EscapeHatchManager()

    // MARK: - Properties

    /// Stack de handlers registrados (puede haber múltiples niveles)
    private var handlerStack: [EscapeHatchHandler] = []

    /// Indica si el escape hatch está globalmente habilitado
    private var isGloballyEnabled: Bool = true

    // MARK: - Initialization

    private init() {}

    // MARK: - Handler Management

    /// Registra un handler de escape hatch
    /// - Parameter handler: Handler a registrar
    public func register(_ handler: EscapeHatchHandler) {
        handlerStack.append(handler)
    }

    /// Desregistra un handler específico
    /// - Parameter id: ID del handler a desregistrar
    public func unregister(id: String) {
        handlerStack.removeAll { $0.id == id }
    }

    /// Desregistra el último handler (LIFO)
    @discardableResult
    public func unregisterLast() -> EscapeHatchHandler? {
        handlerStack.popLast()
    }

    // MARK: - Execution

    /// Ejecuta el handler de escape hatch apropiado
    ///
    /// Los handlers se ejecutan en orden LIFO (último registrado primero),
    /// permitiendo que modals/sheets anidados manejen escape correctamente.
    ///
    /// - Returns: true si un handler manejó el escape, false si no
    @discardableResult
    public func handleEscape() -> Bool {
        guard isGloballyEnabled else { return false }

        // Intentar con el último handler primero (LIFO)
        for handler in handlerStack.reversed() {
            if handler.isEnabled && handler.shouldHandle() {
                handler.action()
                return true
            }
        }

        return false
    }

    // MARK: - Global Control

    /// Habilita o deshabilita todos los escape hatches
    /// - Parameter enabled: Si los escape hatches están habilitados
    public func setGloballyEnabled(_ enabled: Bool) {
        isGloballyEnabled = enabled
    }

    /// Verifica si hay handlers activos
    public var hasActiveHandlers: Bool {
        !handlerStack.isEmpty
    }

    /// Limpia todos los handlers
    public func clear() {
        handlerStack.removeAll()
    }
}

// MARK: - Escape Hatch Handler

/// Representa un handler de escape hatch
public struct EscapeHatchHandler: Identifiable, Sendable {
    public let id: String
    public let behavior: EscapeHatchBehavior
    public let action: @Sendable () -> Void
    public let shouldHandle: @Sendable () -> Bool
    public let isEnabled: Bool

    public init(
        id: String = UUID().uuidString,
        behavior: EscapeHatchBehavior,
        isEnabled: Bool = true,
        shouldHandle: @escaping @Sendable () -> Bool = { true },
        action: @escaping @Sendable () -> Void
    ) {
        self.id = id
        self.behavior = behavior
        self.isEnabled = isEnabled
        self.shouldHandle = shouldHandle
        self.action = action
    }
}

// MARK: - Escape Hatch Behavior Types

/// Tipos de comportamientos de escape hatch predefinidos
public enum EscapeHatchBehavior: Sendable, Hashable, Equatable {
    /// Dismiss un modal/sheet
    case dismissModal

    /// Cancel edición en text field
    case cancelEditing

    /// Clear selección actual
    case clearSelection

    /// Close popover
    case closePopover

    /// Exit full screen
    case exitFullScreen

    /// Cancel operación en progreso
    case cancelOperation

    /// Go back en navegación
    case navigateBack

    /// Clear search
    case clearSearch

    /// Comportamiento custom
    case custom(String)

    /// Descripción human-readable del comportamiento
    public var description: String {
        switch self {
        case .dismissModal:
            return "Dismiss modal"
        case .cancelEditing:
            return "Cancel editing"
        case .clearSelection:
            return "Clear selection"
        case .closePopover:
            return "Close popover"
        case .exitFullScreen:
            return "Exit full screen"
        case .cancelOperation:
            return "Cancel operation"
        case .navigateBack:
            return "Navigate back"
        case .clearSearch:
            return "Clear search"
        case .custom(let name):
            return name
        }
    }
}

// MARK: - View Modifiers

/// Modifier para aplicar escape hatch a un view
private struct EscapeHatchModifier: ViewModifier {
    let handlerID: String
    let behavior: EscapeHatchBehavior
    let isEnabled: Bool
    let shouldHandle: @Sendable () -> Bool
    let action: @Sendable () -> Void

    @State private var isActive: Bool = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                registerHandler()
            }
            .onDisappear {
                unregisterHandler()
            }
            .onChange(of: isActive) { _, active in
                if active {
                    registerHandler()
                } else {
                    unregisterHandler()
                }
            }
            #if os(macOS)
            .onKeyPress(.escape) {
                if shouldHandle() {
                    action()
                    return .handled
                }
                return .ignored
            }
            #endif
    }

    private func registerHandler() {
        let handler = EscapeHatchHandler(
            id: handlerID,
            behavior: behavior,
            isEnabled: isEnabled,
            shouldHandle: shouldHandle,
            action: action
        )
        EscapeHatchManager.shared.register(handler)
    }

    private func unregisterHandler() {
        EscapeHatchManager.shared.unregister(id: handlerID)
    }
}

// MARK: - View Extensions

extension View {
    /// Aplica un escape hatch behavior a este view
    ///
    /// - Parameters:
    ///   - behavior: Tipo de comportamiento
    ///   - isEnabled: Si el escape hatch está habilitado
    ///   - shouldHandle: Closure que determina si este handler debe ejecutarse
    ///   - action: Acción a ejecutar cuando se activa el escape hatch
    /// - Returns: View con escape hatch
    ///
    /// ## Ejemplo
    /// ```swift
    /// Modal {
    ///     // Contenido
    /// }
    /// .escapeHatch(.dismissModal, isEnabled: isDismissible) {
    ///     isPresented = false
    /// }
    /// ```
    public func escapeHatch(
        _ behavior: EscapeHatchBehavior,
        isEnabled: Bool = true,
        shouldHandle: @escaping @Sendable () -> Bool = { true },
        action: @escaping @Sendable () -> Void
    ) -> some View {
        modifier(EscapeHatchModifier(
            handlerID: UUID().uuidString,
            behavior: behavior,
            isEnabled: isEnabled,
            shouldHandle: shouldHandle,
            action: action
        ))
    }

    /// Aplica escape hatch para dismiss modal
    ///
    /// - Parameters:
    ///   - isPresented: Binding que controla la visibilidad
    ///   - isDismissible: Si el modal puede ser dismissed con Escape
    /// - Returns: View con escape hatch para dismiss
    public func dismissOnEscape(
        isPresented: Binding<Bool>,
        isDismissible: Bool = true
    ) -> some View {
        self.escapeHatch(.dismissModal, isEnabled: isDismissible) {
            isPresented.wrappedValue = false
        }
    }

    /// Aplica escape hatch para cancel edición en text field
    ///
    /// - Parameters:
    ///   - text: Binding al texto
    ///   - originalValue: Valor original a restaurar
    ///   - onCancel: Callback adicional al cancelar
    /// - Returns: View con escape hatch para cancel editing
    public func cancelEditingOnEscape(
        text: Binding<String>,
        originalValue: String,
        onCancel: (@Sendable () -> Void)? = nil
    ) -> some View {
        self.escapeHatch(.cancelEditing) {
            text.wrappedValue = originalValue
            onCancel?()
        }
    }

    /// Aplica escape hatch para clear selection
    ///
    /// - Parameters:
    ///   - selection: Binding a la selección
    ///   - onClear: Callback adicional al limpiar
    /// - Returns: View con escape hatch para clear selection
    public func clearSelectionOnEscape<T>(
        selection: Binding<T?>,
        onClear: (@Sendable () -> Void)? = nil
    ) -> some View {
        self.escapeHatch(.clearSelection, shouldHandle: { selection.wrappedValue != nil }) {
            selection.wrappedValue = nil
            onClear?()
        }
    }

    /// Aplica escape hatch para clear search
    ///
    /// - Parameters:
    ///   - searchText: Binding al texto de búsqueda
    ///   - onClear: Callback adicional al limpiar
    /// - Returns: View con escape hatch para clear search
    public func clearSearchOnEscape(
        searchText: Binding<String>,
        onClear: (@Sendable () -> Void)? = nil
    ) -> some View {
        self.escapeHatch(.clearSearch, shouldHandle: { !searchText.wrappedValue.isEmpty }) {
            searchText.wrappedValue = ""
            onClear?()
        }
    }
}

// MARK: - Common Escape Hatch Configurations

/// Configuraciones predefinidas de escape hatches para casos comunes
public struct CommonEscapeHatchConfigurations {

    /// Configuración para modals
    public static func modal(isPresented: Binding<Bool>, isDismissible: Bool = true) -> some ViewModifier {
        EscapeHatchModifier(
            handlerID: "modal-escape",
            behavior: .dismissModal,
            isEnabled: isDismissible,
            shouldHandle: { true },
            action: { isPresented.wrappedValue = false }
        )
    }

    /// Configuración para text fields en formularios
    public static func formField(
        text: Binding<String>,
        originalValue: String,
        onCancel: (@Sendable () -> Void)? = nil
    ) -> some ViewModifier {
        EscapeHatchModifier(
            handlerID: "form-field-escape",
            behavior: .cancelEditing,
            isEnabled: true,
            shouldHandle: { text.wrappedValue != originalValue },
            action: {
                text.wrappedValue = originalValue
                onCancel?()
            }
        )
    }

    /// Configuración para search fields
    public static func searchField(
        searchText: Binding<String>,
        onClear: (@Sendable () -> Void)? = nil
    ) -> some ViewModifier {
        EscapeHatchModifier(
            handlerID: "search-field-escape",
            behavior: .clearSearch,
            isEnabled: true,
            shouldHandle: { !searchText.wrappedValue.isEmpty },
            action: {
                searchText.wrappedValue = ""
                onClear?()
            }
        )
    }
}

// MARK: - Priority Levels

/// Niveles de prioridad para escape hatches
///
/// Cuando hay múltiples handlers registrados, la prioridad determina
/// cuál se ejecuta primero.
public enum EscapeHatchPriority: Int, Sendable, Comparable {
    /// Prioridad baja (ejecuta último)
    case low = 0

    /// Prioridad normal (default)
    case normal = 50

    /// Prioridad alta (ejecuta primero)
    case high = 100

    public static func < (lhs: EscapeHatchPriority, rhs: EscapeHatchPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension EscapeHatchManager {
    /// Genera un reporte del estado actual de escape hatches (solo para debugging)
    public func debugReport() -> String {
        var report = "Escape Hatch Manager Report\n"
        report += "===========================\n\n"

        report += "Globally Enabled: \(isGloballyEnabled)\n"
        report += "Active Handlers: \(handlerStack.count)\n\n"

        for (index, handler) in handlerStack.enumerated() {
            report += "\(index + 1). ID: \(handler.id)\n"
            report += "   Behavior: \(handler.behavior.description)\n"
            report += "   Enabled: \(handler.isEnabled)\n"
            report += "   Should Handle: \(handler.shouldHandle())\n\n"
        }

        return report
    }
}
#endif
