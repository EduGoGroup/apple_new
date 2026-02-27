import SwiftUI

/// Sistema de focus trap para modals, sheets y otros contenedores que requieren
/// mantener el focus dentro de un contexto específico.
///
/// Un focus trap previene que el usuario navegue fuera de un modal/sheet usando Tab,
/// creando un ciclo de navegación dentro del contenedor. Esto es esencial para
/// accesibilidad y cumplimiento de WCAG 2.1.
///
/// ## Ejemplo de uso
/// ```swift
/// Modal {
///     VStack {
///         TextField("Name", text: $name)
///         TextField("Email", text: $email)
///         Button("Submit") { }
///         Button("Cancel") { }
///     }
/// }
/// .focusTrap(isActive: isModalPresented)
/// ```
@MainActor
public final class FocusTrapManager {

    // MARK: - Singleton

    public static let shared = FocusTrapManager()

    // MARK: - Properties

    /// Stack de focus traps activos (puede haber anidados)
    private var trapStack: [FocusTrapContext] = []

    /// IDs de elementos focusables registrados en el trap actual
    private var focusableElements: [String] = []

    /// Índice del elemento actualmente enfocado
    private var currentFocusIndex: Int = 0

    // MARK: - Initialization

    private init() {}

    // MARK: - Trap Management

    /// Activa un focus trap
    /// - Parameter context: Contexto del focus trap
    public func activate(trap context: FocusTrapContext) {
        trapStack.append(context)
        focusableElements = context.focusableElements
        currentFocusIndex = 0

        // Establecer focus en el primer elemento
        if let firstElement = focusableElements.first {
            FocusManager.shared.setFocus(firstElement)
        }
    }

    /// Desactiva el focus trap actual
    /// - Returns: El contexto del trap desactivado
    @discardableResult
    public func deactivate() -> FocusTrapContext? {
        guard let context = trapStack.popLast() else {
            return nil
        }

        // Restaurar focus al contexto anterior
        if let previousContext = trapStack.last {
            focusableElements = previousContext.focusableElements
            currentFocusIndex = previousContext.lastFocusedIndex ?? 0
        } else {
            focusableElements.removeAll()
            currentFocusIndex = 0
        }

        return context
    }

    /// Verifica si hay un trap activo
    public var isActive: Bool {
        !trapStack.isEmpty
    }

    /// Contexto del trap actual
    public var currentTrap: FocusTrapContext? {
        trapStack.last
    }

    // MARK: - Navigation

    /// Mueve el focus al siguiente elemento en el trap
    public func focusNext() {
        guard !focusableElements.isEmpty else { return }

        currentFocusIndex = (currentFocusIndex + 1) % focusableElements.count
        let nextElement = focusableElements[currentFocusIndex]
        FocusManager.shared.setFocus(nextElement)

        // Actualizar índice en el contexto
        trapStack[trapStack.count - 1].lastFocusedIndex = currentFocusIndex
    }

    /// Mueve el focus al elemento anterior en el trap
    public func focusPrevious() {
        guard !focusableElements.isEmpty else { return }

        currentFocusIndex = (currentFocusIndex - 1 + focusableElements.count) % focusableElements.count
        let previousElement = focusableElements[currentFocusIndex]
        FocusManager.shared.setFocus(previousElement)

        // Actualizar índice en el contexto
        trapStack[trapStack.count - 1].lastFocusedIndex = currentFocusIndex
    }

    /// Mueve el focus al primer elemento
    public func focusFirst() {
        guard !focusableElements.isEmpty else { return }

        currentFocusIndex = 0
        let firstElement = focusableElements[0]
        FocusManager.shared.setFocus(firstElement)

        trapStack[trapStack.count - 1].lastFocusedIndex = currentFocusIndex
    }

    /// Mueve el focus al último elemento
    public func focusLast() {
        guard !focusableElements.isEmpty else { return }

        currentFocusIndex = focusableElements.count - 1
        let lastElement = focusableElements[currentFocusIndex]
        FocusManager.shared.setFocus(lastElement)

        trapStack[trapStack.count - 1].lastFocusedIndex = currentFocusIndex
    }

    // MARK: - Element Registration

    /// Registra un elemento focusable en el trap actual
    /// - Parameter element: ID del elemento
    public func registerFocusableElement(_ element: String) {
        guard isActive else { return }

        if !focusableElements.contains(element) {
            focusableElements.append(element)
            // Actualizar en el contexto también
            trapStack[trapStack.count - 1].focusableElements = focusableElements
        }
    }

    /// Desregistra un elemento focusable
    /// - Parameter element: ID del elemento
    public func unregisterFocusableElement(_ element: String) {
        guard isActive else { return }

        if let index = focusableElements.firstIndex(of: element) {
            focusableElements.remove(at: index)

            // Ajustar índice actual si es necesario
            if currentFocusIndex >= focusableElements.count {
                currentFocusIndex = max(0, focusableElements.count - 1)
            }

            trapStack[trapStack.count - 1].focusableElements = focusableElements
        }
    }
}

// MARK: - Focus Trap Context

/// Contexto de un focus trap activo
public struct FocusTrapContext: Sendable {
    public let id: String
    public let name: String
    public var focusableElements: [String]  // Cambiado a [String] para Sendable
    public var lastFocusedIndex: Int?
    public let restoreFocusOnExit: Bool
    public let allowEscape: Bool

    public init(
        id: String,
        name: String,
        focusableElements: [String],
        restoreFocusOnExit: Bool = true,
        allowEscape: Bool = true
    ) {
        self.id = id
        self.name = name
        self.focusableElements = focusableElements
        self.lastFocusedIndex = nil
        self.restoreFocusOnExit = restoreFocusOnExit
        self.allowEscape = allowEscape
    }
}

// MARK: - View Modifiers

/// Modifier para aplicar focus trap a un view
private struct FocusTrapModifier: ViewModifier {
    let trapID: String
    let isActive: Bool
    let focusableElements: [String]
    let restoreFocusOnExit: Bool
    let allowEscape: Bool
    let onEscape: (() -> Void)?

    @FocusState private var isFocused: Bool

    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .onChange(of: isActive) { _, active in
                if active {
                    activateTrap()
                } else {
                    deactivateTrap()
                }
            }
            .onAppear {
                if isActive {
                    activateTrap()
                }
            }
            .onDisappear {
                if isActive {
                    deactivateTrap()
                }
            }
            #if os(macOS)
            .onKeyPress(.tab) {
                handleTabPress(shiftPressed: false)
                return .handled
            }
            .onKeyPress(.escape) {
                handleEscapePress()
                return .handled
            }
            #endif
    }

    private func activateTrap() {
        let context = FocusTrapContext(
            id: trapID,
            name: trapID,
            focusableElements: focusableElements,
            restoreFocusOnExit: restoreFocusOnExit,
            allowEscape: allowEscape
        )
        FocusTrapManager.shared.activate(trap: context)
        isFocused = true
    }

    private func deactivateTrap() {
        FocusTrapManager.shared.deactivate()
        isFocused = false
    }

    private func handleTabPress(shiftPressed: Bool) {
        if shiftPressed {
            FocusTrapManager.shared.focusPrevious()
        } else {
            FocusTrapManager.shared.focusNext()
        }
    }

    private func handleEscapePress() {
        guard allowEscape else { return }
        onEscape?()
    }
}

// MARK: - View Extensions

extension View {
    /// Aplica un focus trap a este view
    ///
    /// El focus trap previene que el usuario navegue fuera del contenedor usando Tab,
    /// creando un ciclo de navegación entre los elementos focusables.
    ///
    /// - Parameters:
    ///   - id: ID único del focus trap
    ///   - isActive: Si el trap está activo
    ///   - focusableElements: Array de IDs de elementos focusables (en orden)
    ///   - restoreFocusOnExit: Si restaurar focus al elemento anterior al salir
    ///   - allowEscape: Si permitir escape con Esc key
    ///   - onEscape: Callback cuando se presiona Escape
    /// - Returns: View con focus trap
    ///
    /// ## Ejemplo
    /// ```swift
    /// Modal {
    ///     VStack {
    ///         TextField("Name", text: $name).id("name-field")
    ///         TextField("Email", text: $email).id("email-field")
    ///         Button("Submit") { }.id("submit-btn")
    ///     }
    /// }
    /// .focusTrap(
    ///     id: "modal-trap",
    ///     isActive: isModalPresented,
    ///     focusableElements: ["name-field", "email-field", "submit-btn"],
    ///     onEscape: { isModalPresented = false }
    /// )
    /// ```
    public func focusTrap(
        id: String,
        isActive: Bool,
        focusableElements: [String],
        restoreFocusOnExit: Bool = true,
        allowEscape: Bool = true,
        onEscape: (() -> Void)? = nil
    ) -> some View {
        modifier(FocusTrapModifier(
            trapID: id,
            isActive: isActive,
            focusableElements: focusableElements,
            restoreFocusOnExit: restoreFocusOnExit,
            allowEscape: allowEscape,
            onEscape: onEscape
        ))
    }

    /// Variante simplificada de focus trap que descubre elementos automáticamente
    ///
    /// - Parameters:
    ///   - isActive: Si el trap está activo
    ///   - onEscape: Callback cuando se presiona Escape
    /// - Returns: View con focus trap automático
    ///
    /// ## Ejemplo
    /// ```swift
    /// Modal {
    ///     // Contenido
    /// }
    /// .focusTrap(isActive: isModalPresented) {
    ///     isModalPresented = false
    /// }
    /// ```
    public func focusTrap(
        isActive: Bool,
        onEscape: (() -> Void)? = nil
    ) -> some View {
        // Esta versión usa auto-discovery de elementos focusables
        // Los elementos se registran automáticamente vía accessibilityElement
        modifier(FocusTrapModifier(
            trapID: UUID().uuidString,
            isActive: isActive,
            focusableElements: [],  // Auto-discover
            restoreFocusOnExit: true,
            allowEscape: true,
            onEscape: onEscape
        ))
    }
}

// MARK: - Modal Integration Helpers

extension View {
    /// Aplica focus trap optimizado para modals
    ///
    /// - Parameters:
    ///   - isPresented: Binding que controla la visibilidad del modal
    ///   - focusableElements: Array de IDs de elementos focusables
    /// - Returns: View con focus trap configurado para modal
    public func modalFocusTrap(
        isPresented: Binding<Bool>,
        focusableElements: [String]
    ) -> some View {
        self.focusTrap(
            id: "modal-\(UUID().uuidString)",
            isActive: isPresented.wrappedValue,
            focusableElements: focusableElements,
            restoreFocusOnExit: true,
            allowEscape: true,
            onEscape: { isPresented.wrappedValue = false }
        )
    }

    /// Aplica focus trap optimizado para sheets
    ///
    /// - Parameters:
    ///   - isPresented: Binding que controla la visibilidad del sheet
    ///   - focusableElements: Array de IDs de elementos focusables
    /// - Returns: View con focus trap configurado para sheet
    public func sheetFocusTrap(
        isPresented: Binding<Bool>,
        focusableElements: [String]
    ) -> some View {
        self.focusTrap(
            id: "sheet-\(UUID().uuidString)",
            isActive: isPresented.wrappedValue,
            focusableElements: focusableElements,
            restoreFocusOnExit: true,
            allowEscape: true,
            onEscape: { isPresented.wrappedValue = false }
        )
    }
}

// MARK: - Focusable Element Marker

/// Modifier para marcar un elemento como focusable dentro de un trap
private struct FocusableInTrapModifier: ViewModifier {
    let elementID: String

    func body(content: Content) -> some View {
        content
            .onAppear {
                FocusTrapManager.shared.registerFocusableElement(elementID)
            }
            .onDisappear {
                FocusTrapManager.shared.unregisterFocusableElement(elementID)
            }
    }
}

extension View {
    /// Marca este view como focusable dentro de un focus trap
    ///
    /// - Parameter id: ID único del elemento
    /// - Returns: View marcado como focusable
    public func focusableInTrap(id: String) -> some View {
        modifier(FocusableInTrapModifier(elementID: id))
    }
}
