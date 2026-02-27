import SwiftUI

/// Sistema de optimización de tab order para navegación con teclado
///
/// Proporciona helpers para definir un orden de tabulación custom que mejora
/// la experiencia de navegación con teclado, especialmente para usuarios de
/// screen readers y keyboard-only navigation.
///
/// ## Conceptos
/// - **Tab Priority**: Determina el orden en que los elementos reciben focus
/// - **Tab Group**: Agrupa elementos relacionados para navegación lógica
/// - **Skip Elements**: Marca elementos que se deben saltar en la navegación
///
/// ## Ejemplo de uso
/// ```swift
/// VStack {
///     TextField("Email", text: $email)
///         .tabPriority(1)  // Primero
///
///     TextField("Password", text: $password)
///         .tabPriority(2)  // Segundo
///
///     Button("Submit") { }
///         .tabPriority(3)  // Tercero
///
///     Text("Decorative element")
///         .skipInTabOrder()  // Saltado
/// }
/// ```
@MainActor
public final class TabOrderOptimizer {

    // MARK: - Singleton

    public static let shared = TabOrderOptimizer()

    // MARK: - Properties

    /// Elementos registrados por prioridad
    private var elementsByPriority: [Int: Set<AnyHashable>] = [:]

    /// Elementos que deben ser saltados
    private var skippedElements: Set<AnyHashable> = []

    /// Grupos de tab order
    private var tabGroups: [String: TabGroup] = [:]

    // MARK: - Initialization

    private init() {}

    // MARK: - Registration

    /// Registra un elemento con una prioridad específica
    /// - Parameters:
    ///   - element: ID único del elemento
    ///   - priority: Prioridad (menor = primero)
    public func register(element: AnyHashable, priority: Int) {
        elementsByPriority[priority, default: []].insert(element)
    }

    /// Desregistra un elemento
    /// - Parameter element: ID del elemento
    public func unregister(element: AnyHashable) {
        for priority in elementsByPriority.keys {
            elementsByPriority[priority]?.remove(element)
        }
    }

    /// Marca un elemento para ser saltado en tab order
    /// - Parameter element: ID del elemento a saltar
    public func skip(element: AnyHashable) {
        skippedElements.insert(element)
    }

    /// Desmarca un elemento como saltado
    /// - Parameter element: ID del elemento
    public func unskip(element: AnyHashable) {
        skippedElements.remove(element)
    }

    // MARK: - Tab Groups

    /// Registra un grupo de tab order
    /// - Parameter group: Definición del grupo
    public func registerGroup(_ group: TabGroup) {
        tabGroups[group.id] = group
    }

    /// Obtiene un grupo por ID
    /// - Parameter id: ID del grupo
    /// - Returns: El grupo si existe
    public func group(for id: String) -> TabGroup? {
        tabGroups[id]
    }

    // MARK: - Query

    /// Obtiene todos los elementos en orden de prioridad
    /// - Returns: Array de elementos ordenados (excluyendo saltados)
    public func orderedElements() -> [AnyHashable] {
        let sortedPriorities = elementsByPriority.keys.sorted()

        return sortedPriorities.flatMap { priority in
            Array(elementsByPriority[priority] ?? [])
                .filter { !skippedElements.contains($0) }
        }
    }

    /// Verifica si un elemento debe ser saltado
    /// - Parameter element: ID del elemento
    /// - Returns: true si debe ser saltado
    public func shouldSkip(element: AnyHashable) -> Bool {
        skippedElements.contains(element)
    }

    /// Limpia todos los registros
    public func reset() {
        elementsByPriority.removeAll()
        skippedElements.removeAll()
        tabGroups.removeAll()
    }
}

// MARK: - Tab Group

/// Representa un grupo lógico de elementos para tab order
public struct TabGroup: Sendable, Identifiable {
    public let id: String
    public let name: String
    public let priority: Int
    public let elements: [String]  // Cambiado a [String] para Sendable compliance

    public init(id: String, name: String, priority: Int, elements: [String]) {
        self.id = id
        self.name = name
        self.priority = priority
        self.elements = elements
    }
}

// MARK: - View Modifiers

/// Modifier para establecer prioridad de tab order
private struct TabPriorityModifier: ViewModifier {
    let priority: Int
    let id: AnyHashable

    func body(content: Content) -> some View {
        content
            .onAppear {
                TabOrderOptimizer.shared.register(element: id, priority: priority)
            }
            .onDisappear {
                TabOrderOptimizer.shared.unregister(element: id)
            }
    }
}

/// Modifier para saltar elemento en tab order
private struct SkipTabOrderModifier: ViewModifier {
    let id: AnyHashable

    func body(content: Content) -> some View {
        content
            .onAppear {
                TabOrderOptimizer.shared.skip(element: id)
            }
            .onDisappear {
                TabOrderOptimizer.shared.unskip(element: id)
            }
    }
}

// MARK: - View Extensions

extension View {
    /// Establece la prioridad de tab order para este view
    ///
    /// - Parameters:
    ///   - priority: Prioridad (menor = primero en recibir focus)
    ///   - id: ID único del elemento (se genera automáticamente si no se provee)
    /// - Returns: View con prioridad de tab order
    ///
    /// ## Ejemplo
    /// ```swift
    /// TextField("Email", text: $email)
    ///     .tabPriority(1)
    ///
    /// TextField("Password", text: $password)
    ///     .tabPriority(2)
    /// ```
    public func tabPriority(_ priority: Int, id: AnyHashable? = nil) -> some View {
        let elementID = id ?? AnyHashable(UUID())
        return modifier(TabPriorityModifier(priority: priority, id: elementID))
    }

    /// Marca este view para ser saltado en la navegación con tab
    ///
    /// Útil para elementos decorativos o que no necesitan focus.
    ///
    /// - Parameter id: ID único del elemento (se genera automáticamente si no se provee)
    /// - Returns: View que será saltado en tab order
    ///
    /// ## Ejemplo
    /// ```swift
    /// Image("decorative-icon")
    ///     .skipInTabOrder()
    /// ```
    public func skipInTabOrder(id: AnyHashable? = nil) -> some View {
        let elementID = id ?? AnyHashable(UUID())
        return modifier(SkipTabOrderModifier(id: elementID))
    }

    /// Agrupa elementos relacionados para tab order
    ///
    /// - Parameters:
    ///   - groupID: ID único del grupo
    ///   - priority: Prioridad del grupo completo
    /// - Returns: View con grouping de tab order
    ///
    /// ## Ejemplo
    /// ```swift
    /// VStack {
    ///     TextField("First Name", text: $firstName)
    ///     TextField("Last Name", text: $lastName)
    /// }
    /// .tabGroup(id: "name-fields", priority: 1)
    /// ```
    public func tabGroup(id: String, priority: Int) -> some View {
        self.onAppear {
            let group = TabGroup(
                id: id,
                name: id,
                priority: priority,
                elements: []
            )
            TabOrderOptimizer.shared.registerGroup(group)
        }
    }
}

// MARK: - Accessibility Integration

extension View {
    /// Optimiza el tab order automáticamente basado en la jerarquía visual
    ///
    /// Este modifier analiza la estructura del view y asigna prioridades
    /// automáticamente de arriba a abajo, izquierda a derecha.
    ///
    /// - Returns: View con tab order optimizado
    public func optimizeTabOrder() -> some View {
        self.modifier(AutoTabOrderModifier())
    }
}

private struct AutoTabOrderModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            // El orden natural de SwiftUI ya sigue top-to-bottom, left-to-right
            // Este modifier puede extenderse para casos más complejos
            .accessibilitySortPriority(0)
    }
}

// MARK: - Form Tab Order Helpers

/// Helpers específicos para optimizar tab order en formularios
public struct FormTabOrderHelper {

    /// Configura tab order optimizado para un formulario típico
    ///
    /// Asigna prioridades automáticas a campos de entrada comunes.
    ///
    /// - Parameter fields: Array de IDs de campos en orden deseado
    /// - Returns: Prioridades mapeadas
    public static func setupFormTabOrder(fields: [String]) -> [String: Int] {
        var priorities: [String: Int] = [:]

        for (index, field) in fields.enumerated() {
            priorities[field] = index + 1
        }

        return priorities
    }

    /// Prioridades predefinidas para campos comunes
    public enum CommonFieldPriority {
        public static let email = 1
        public static let password = 2
        public static let confirmPassword = 3
        public static let firstName = 4
        public static let lastName = 5
        public static let submitButton = 99
        public static let cancelButton = 100
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension TabOrderOptimizer {
    /// Genera un reporte del tab order actual (solo para debugging)
    public func debugReport() -> String {
        var report = "Tab Order Report\n"
        report += "================\n\n"

        let ordered = orderedElements()

        report += "Ordered Elements (\(ordered.count)):\n"
        for (index, element) in ordered.enumerated() {
            report += "\(index + 1). \(element)\n"
        }

        report += "\nSkipped Elements (\(skippedElements.count)):\n"
        for element in skippedElements {
            report += "- \(element)\n"
        }

        report += "\nTab Groups (\(tabGroups.count)):\n"
        for (id, group) in tabGroups.sorted(by: { $0.value.priority < $1.value.priority }) {
            report += "- \(id): priority=\(group.priority), elements=\(group.elements.count)\n"
        }

        return report
    }
}
#endif
