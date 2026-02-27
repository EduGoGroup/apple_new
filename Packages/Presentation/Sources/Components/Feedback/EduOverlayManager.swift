import SwiftUI

// MARK: - Unified Overlay Manager

/// Manager unificado que coordina todos los overlays de feedback (Toasts, Alerts, Modals, Banners, ActionSheets)
@MainActor
@Observable
public final class EduOverlayManager: Sendable {
    public static let shared = EduOverlayManager()

    // Toast Manager
    public let toastManager = ToastManager.shared

    // Alert Manager
    public let alertManager = EduAlertManager.shared

    // Modal Manager
    public let modalManager = EduModalManager.shared

    // Action Sheet Manager
    public let actionSheetManager = EduActionSheetManager.shared

    // Banner Manager
    private(set) var currentBanner: BannerItem?

    private init() {}

    // MARK: - Banner Methods

    /// Muestra un banner persistente
    public func showBanner(_ message: String, style: ToastStyle = .info, onDismiss: (@Sendable () -> Void)? = nil) {
        currentBanner = BannerItem(message: message, style: style, onDismiss: onDismiss)
    }

    /// Oculta el banner actual
    public func dismissBanner() {
        currentBanner = nil
    }

    // MARK: - Convenience Methods

    /// Muestra un toast rápido
    public func toast(_ message: String, style: ToastStyle = .info, duration: TimeInterval = 3.0) {
        toastManager.show(message, style: style, duration: duration)
    }

    /// Muestra una alerta de confirmación
    public func confirm(
        title: String,
        message: String? = nil,
        confirmTitle: String = "Confirmar",
        cancelTitle: String = "Cancelar",
        onConfirm: @escaping @Sendable () -> Void
    ) {
        alertManager.showConfirmation(
            title: title,
            message: message,
            confirmTitle: confirmTitle,
            cancelTitle: cancelTitle,
            onConfirm: onConfirm
        )
    }

    /// Muestra una alerta destructiva
    public func confirmDestruct(
        title: String,
        message: String? = nil,
        destructiveTitle: String = "Eliminar",
        cancelTitle: String = "Cancelar",
        onDestroy: @escaping @Sendable () -> Void
    ) {
        alertManager.showDestructive(
            title: title,
            message: message,
            destructiveTitle: destructiveTitle,
            cancelTitle: cancelTitle,
            onDestroy: onDestroy
        )
    }

    /// Muestra un modal
    public func showModal<Content: View>(@ViewBuilder content: @escaping () -> Content) {
        modalManager.show(content: content)
    }

    /// Muestra un action sheet con opciones
    public func showOptions(
        title: String? = nil,
        message: String? = nil,
        options: [(title: String, icon: String?, action: @Sendable () -> Void)],
        includeCancel: Bool = true
    ) {
        actionSheetManager.showOptions(
            title: title,
            message: message,
            options: options,
            includeCancel: includeCancel
        )
    }

    /// Oculta todos los overlays activos
    public func dismissAll() {
        // Dismiss all toasts individually
        for toast in toastManager.toasts {
            toastManager.dismiss(toast)
        }
        alertManager.dismiss()
        modalManager.dismiss()
        actionSheetManager.dismiss()
        currentBanner = nil
    }
}

// MARK: - Banner Item

public struct BannerItem: Identifiable, Sendable {
    public let id = UUID()
    let message: String
    let style: ToastStyle
    let onDismiss: (@Sendable () -> Void)?
}

// MARK: - Unified Overlay Modifier

/// Modifier que integra TODOS los overlays de feedback en una sola vista
public struct EduOverlayModifier: ViewModifier {
    @State private var manager = EduOverlayManager.shared

    public func body(content: Content) -> some View {
        content
            // Banner overlay (top, persistent)
            .overlay(alignment: .top) {
                if let banner = manager.currentBanner {
                    EduBanner(
                        message: banner.message,
                        style: banner.style,
                        onDismiss: {
                            banner.onDismiss?()
                            manager.dismissBanner()
                        }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(), value: manager.currentBanner?.id)
                    .zIndex(100)
                }
            }
            // Toast overlay (top, auto-dismiss)
            .overlay(alignment: .top) {
                VStack(spacing: 8) {
                    ForEach(manager.toastManager.toasts) { toast in
                        EduToast(item: toast) {
                            manager.toastManager.dismiss(toast)
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(.top, manager.currentBanner != nil ? 80 : 8)
                .animation(.spring(), value: manager.toastManager.toasts.count)
                .zIndex(99)
            }
            // Alert overlay (uses native alerts)
            .alert(
                manager.alertManager.currentAlert?.title ?? "",
                isPresented: Binding(
                    get: { manager.alertManager.isPresented },
                    set: { if !$0 { manager.alertManager.dismiss() } }
                )
            ) {
                if let currentAlert = manager.alertManager.currentAlert {
                    ForEach(0..<currentAlert.actions.count, id: \.self) { index in
                        Button(currentAlert.actions[index].title, role: currentAlert.actions[index].role) {
                            currentAlert.actions[index].action()
                        }
                    }
                }
            } message: {
                if let message = manager.alertManager.currentAlert?.message {
                    Text(message)
                }
            }
            // Modal overlay (uses native sheets)
            .sheet(isPresented: Binding(
                get: { manager.modalManager.isPresented },
                set: { if !$0 { manager.modalManager.dismiss() } }
            )) {
                if let modalView = manager.modalManager.modalView {
                    modalView
                }
            }
            // Action Sheet overlay (uses native sheets/popovers)
            .sheet(isPresented: Binding(
                get: { manager.actionSheetManager.isPresented },
                set: { if !$0 { manager.actionSheetManager.dismiss() } }
            )) {
                if let currentActionSheet = manager.actionSheetManager.currentActionSheet {
                    EduActionSheetView(
                        isPresented: Binding(
                            get: { manager.actionSheetManager.isPresented },
                            set: { if !$0 { manager.actionSheetManager.dismiss() } }
                        ),
                        content: currentActionSheet
                    )
                }
            }
    }
}

// MARK: - View Extension

extension View {
    /// Agrega TODOS los overlays de feedback a la vista raíz
    /// Incluye: Toasts, Alerts, Modals, Banners y ActionSheets
    public func eduOverlays() -> some View {
        modifier(EduOverlayModifier())
    }

    /// Alias para mantener compatibilidad con código existente
    public func withToasts() -> some View {
        modifier(EduOverlayModifier())
    }
}

// MARK: - Legacy Toast Overlay Modifier (deprecated)

@available(*, deprecated, message: "Use eduOverlays() instead for full feedback support")
public struct ToastOverlayModifier: ViewModifier {
    @State private var toastManager = ToastManager.shared

    public func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            VStack(spacing: 8) {
                ForEach(toastManager.toasts) { toast in
                    EduToast(item: toast) {
                        toastManager.dismiss(toast)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.top, 8)
            .animation(.spring(), value: toastManager.toasts.count)
        }
    }
}
