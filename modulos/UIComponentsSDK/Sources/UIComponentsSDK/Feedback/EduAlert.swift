import SwiftUI
import DesignSystemSDK

// MARK: - EduAlert

/// Alerta adaptativa que usa los diálogos nativos de cada plataforma
@MainActor
public struct EduAlertAction: Sendable {
    public let title: String
    public let role: ButtonRole?
    public let action: @Sendable () -> Void

    public init(title: String, role: ButtonRole? = nil, action: @escaping @Sendable () -> Void) {
        self.title = title
        self.role = role
        self.action = action
    }
}

@MainActor
public struct EduAlertContent: Sendable {
    public let title: String
    public let message: String?
    public let actions: [EduAlertAction]

    public init(title: String, message: String? = nil, actions: [EduAlertAction]) {
        self.title = title
        self.message = message
        self.actions = actions
    }
}

// MARK: - View Extension

extension View {
    /// Presenta una alerta usando el sistema nativo de alertas
    /// - Parameters:
    ///   - isPresented: Binding que controla la visibilidad
    ///   - content: El contenido de la alerta
    public func eduAlert(isPresented: Binding<Bool>, content: EduAlertContent) -> some View {
        self.alert(content.title, isPresented: isPresented) {
            ForEach(0..<content.actions.count, id: \.self) { index in
                Button(content.actions[index].title, role: content.actions[index].role) {
                    content.actions[index].action()
                }
            }
        } message: {
            if let message = content.message {
                Text(message)
            }
        }
    }
}

// MARK: - Alert Manager

/// Manager centralizado para mostrar alertas en toda la aplicación
@MainActor
@Observable
public final class EduAlertManager: Sendable {
    public static let shared = EduAlertManager()

    private(set) var isPresented: Bool = false
    private(set) var currentAlert: EduAlertContent?

    private init() {}

    /// Muestra una alerta
    public func show(alert: EduAlertContent) {
        currentAlert = alert
        isPresented = true

        // VoiceOver announcement
        let message = alert.message != nil ? "\(alert.title). \(alert.message!)" : alert.title
        AccessibilityAnnouncements.announce("Alert: \(message)", priority: .high)
    }

    /// Muestra una alerta de confirmación simple
    public func showConfirmation(
        title: String,
        message: String? = nil,
        confirmTitle: String = "Confirmar",
        cancelTitle: String = "Cancelar",
        onConfirm: @escaping @Sendable () -> Void
    ) {
        let alert = EduAlertContent(
            title: title,
            message: message,
            actions: [
                EduAlertAction(title: cancelTitle, role: .cancel, action: {}),
                EduAlertAction(title: confirmTitle, action: onConfirm)
            ]
        )
        show(alert: alert)
    }

    /// Muestra una alerta destructiva
    public func showDestructive(
        title: String,
        message: String? = nil,
        destructiveTitle: String = "Eliminar",
        cancelTitle: String = "Cancelar",
        onDestroy: @escaping @Sendable () -> Void
    ) {
        let alert = EduAlertContent(
            title: title,
            message: message,
            actions: [
                EduAlertAction(title: cancelTitle, role: .cancel, action: {}),
                EduAlertAction(title: destructiveTitle, role: .destructive, action: onDestroy)
            ]
        )
        show(alert: alert)
    }

    /// Oculta la alerta actual
    public func dismiss() {
        isPresented = false
        currentAlert = nil
    }
}

// MARK: - Alert Overlay Modifier

public struct EduAlertOverlayModifier: ViewModifier {
    @State private var alertManager = EduAlertManager.shared

    public func body(content: Content) -> some View {
        content
            .alert(
                alertManager.currentAlert?.title ?? "",
                isPresented: Binding(
                    get: { alertManager.isPresented },
                    set: { if !$0 { alertManager.dismiss() } }
                )
            ) {
                if let currentAlert = alertManager.currentAlert {
                    ForEach(0..<currentAlert.actions.count, id: \.self) { index in
                        Button(currentAlert.actions[index].title, role: currentAlert.actions[index].role) {
                            currentAlert.actions[index].action()
                        }
                    }
                }
            } message: {
                if let message = alertManager.currentAlert?.message {
                    Text(message)
                }
            }
    }
}

extension View {
    /// Agrega el overlay de alertas globales a la vista
    public func eduAlertOverlay() -> some View {
        modifier(EduAlertOverlayModifier())
    }
}

// MARK: - Previews

#Preview("Alerta simple") {
    @Previewable @State var showAlert = true

    Button("Mostrar alerta") {
        showAlert = true
    }
    .eduAlert(
        isPresented: $showAlert,
        content: EduAlertContent(
            title: "Confirmar acción",
            message: "¿Estás seguro de que deseas continuar?",
            actions: [
                EduAlertAction(title: "Cancelar", role: .cancel) {},
                EduAlertAction(title: "Confirmar") { print("Confirmado") }
            ]
        )
    )
}

#Preview("Alerta destructiva") {
    @Previewable @State var showAlert = true

    Button("Mostrar alerta") {
        showAlert = true
    }
    .eduAlert(
        isPresented: $showAlert,
        content: EduAlertContent(
            title: "Eliminar elemento",
            message: "Esta acción no se puede deshacer. ¿Deseas continuar?",
            actions: [
                EduAlertAction(title: "Cancelar", role: .cancel) {},
                EduAlertAction(title: "Eliminar", role: .destructive) { print("Eliminado") }
            ]
        )
    )
}

#Preview("Alerta informativa") {
    @Previewable @State var showAlert = true

    Button("Mostrar alerta") {
        showAlert = true
    }
    .eduAlert(
        isPresented: $showAlert,
        content: EduAlertContent(
            title: "Actualización disponible",
            message: "Hay una nueva versión de la aplicación disponible.",
            actions: [
                EduAlertAction(title: "Más tarde", role: .cancel) {},
                EduAlertAction(title: "Actualizar") { print("Actualizando") }
            ]
        )
    )
}
