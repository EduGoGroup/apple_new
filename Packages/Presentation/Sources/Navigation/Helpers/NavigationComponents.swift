import SwiftUI
import os.log

/// Logger para diagnóstico de NavigationComponents.
private let componentsLogger = Logger(
    subsystem: "com.edugo.navigation",
    category: "NavigationComponents"
)

// MARK: - NavigationButton

/// Botón que navega a una pantalla específica al presionarse.
///
/// Simplifica la navegación evitando acceder directamente al coordinador.
/// Si el coordinador no está disponible, loggea un warning y no realiza navegación.
///
/// # Ejemplo de uso:
/// ```swift
/// NavigationButton(destination: .materialList) {
///     Label("Ver Materiales", systemImage: "book.fill")
/// }
/// ```
public struct NavigationButton<Label: View>: View {
    let destination: Screen
    let label: Label

    @Environment(\.appCoordinator) private var coordinator

    /// Crea un botón de navegación.
    ///
    /// - Parameters:
    ///   - destination: Pantalla de destino
    ///   - label: Contenido visual del botón
    public init(destination: Screen, @ViewBuilder label: () -> Label) {
        self.destination = destination
        self.label = label()
    }

    public var body: some View {
        Button {
            guard let coordinator else {
                componentsLogger.warning(
                    "NavigationButton: Coordinator not available for navigation to \(destination.id, privacy: .public)"
                )
                return
            }
            coordinator.navigate(to: destination)
        } label: {
            label
        }
    }
}

// MARK: - SheetButton

/// Botón que presenta una pantalla como sheet modal al presionarse.
///
/// Simplifica la presentación de modales evitando acceder directamente al coordinador.
/// Si el coordinador no está disponible, loggea un warning y no presenta el modal.
///
/// # Ejemplo de uso:
/// ```swift
/// SheetButton(screen: .materialUpload) {
///     Label("Subir Material", systemImage: "plus.circle.fill")
/// }
/// ```
public struct SheetButton<Label: View>: View {
    let screen: Screen
    let label: Label

    @Environment(\.appCoordinator) private var coordinator

    /// Crea un botón que presenta un sheet.
    ///
    /// - Parameters:
    ///   - screen: Pantalla a presentar como modal
    ///   - label: Contenido visual del botón
    public init(screen: Screen, @ViewBuilder label: () -> Label) {
        self.screen = screen
        self.label = label()
    }

    public var body: some View {
        Button {
            guard let coordinator else {
                componentsLogger.warning(
                    "SheetButton: Coordinator not available for presenting sheet \(screen.id, privacy: .public)"
                )
                return
            }
            coordinator.presentSheet(screen)
        } label: {
            label
        }
    }
}

// MARK: - FullScreenCoverButton

/// Botón que presenta una pantalla como full screen cover al presionarse.
///
/// Si el coordinador no está disponible, loggea un warning y no presenta el cover.
///
/// # Ejemplo de uso:
/// ```swift
/// FullScreenCoverButton(screen: .assessment(assessmentId: id, userId: userId)) {
///     Text("Iniciar Evaluación")
/// }
/// ```
public struct FullScreenCoverButton<Label: View>: View {
    let screen: Screen
    let label: Label

    @Environment(\.appCoordinator) private var coordinator

    /// Crea un botón que presenta un full screen cover.
    ///
    /// - Parameters:
    ///   - screen: Pantalla a presentar como full screen
    ///   - label: Contenido visual del botón
    public init(screen: Screen, @ViewBuilder label: () -> Label) {
        self.screen = screen
        self.label = label()
    }

    public var body: some View {
        Button {
            guard let coordinator else {
                componentsLogger.warning(
                    "FullScreenCoverButton: Coordinator not available for presenting cover \(screen.id, privacy: .public)"
                )
                return
            }
            coordinator.presentFullScreenCover(screen)
        } label: {
            label
        }
    }
}
