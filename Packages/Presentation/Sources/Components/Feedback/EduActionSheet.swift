import SwiftUI

// MARK: - Action Sheet Action

/// Acción para un action sheet
@MainActor
public struct EduActionSheetAction: Identifiable, Sendable {
    public let id = UUID()
    public let title: String
    public let role: ButtonRole?
    public let icon: String?
    public let action: @Sendable () -> Void

    public init(
        title: String,
        icon: String? = nil,
        role: ButtonRole? = nil,
        action: @escaping @Sendable () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.role = role
        self.action = action
    }
}

// MARK: - Action Sheet Content

/// Contenido configurado para un action sheet
@MainActor
public struct EduActionSheetContent: Sendable {
    public let title: String?
    public let message: String?
    public let actions: [EduActionSheetAction]

    public init(
        title: String? = nil,
        message: String? = nil,
        actions: [EduActionSheetAction]
    ) {
        self.title = title
        self.message = message
        self.actions = actions
    }
}

// MARK: - iOS/visionOS Action Sheet

#if os(iOS) || os(visionOS)
@MainActor
public struct EduActionSheetView: View {
    @Binding private var isPresented: Bool
    private let content: EduActionSheetContent

    public init(isPresented: Binding<Bool>, content: EduActionSheetContent) {
        self._isPresented = isPresented
        self.content = content
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header (opcional)
            if content.title != nil || content.message != nil {
                VStack(spacing: 8) {
                    if let title = content.title {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                    if let message = content.message {
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(white: 0.98))
            }

            Divider()

            // Actions
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(content.actions) { action in
                        Button {
                            action.action()
                            isPresented = false
                        } label: {
                            HStack {
                                if let icon = action.icon {
                                    Image(systemName: icon)
                                }
                                Text(action.title)
                                Spacer()
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(
                            action.role == .destructive ? Color.red :
                            action.role == .cancel ? Color.blue : Color.primary
                        )

                        if action.id != content.actions.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 20)
        .padding()
        .presentationDetents([.height(CGFloat(content.actions.count * 50 + 100))])
        .presentationDragIndicator(.visible)
    }
}
#endif

// MARK: - macOS Action Sheet (implementado como popover)

#if os(macOS)
@MainActor
public struct EduActionSheetView: View {
    @Binding private var isPresented: Bool
    private let content: EduActionSheetContent

    public init(isPresented: Binding<Bool>, content: EduActionSheetContent) {
        self._isPresented = isPresented
        self.content = content
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            if content.title != nil || content.message != nil {
                VStack(spacing: 8) {
                    if let title = content.title {
                        Text(title)
                            .font(.headline)
                    }
                    if let message = content.message {
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
            }

            // Actions
            VStack(spacing: 1) {
                ForEach(content.actions) { action in
                    Button {
                        action.action()
                        isPresented = false
                    } label: {
                        HStack {
                            if let icon = action.icon {
                                Image(systemName: icon)
                            }
                            Text(action.title)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(
                        action.role == .destructive ? Color.red : Color.primary
                    )
                    .background(
                        Color.clear
                            .onHover { hovering in
                                // Efecto hover nativo
                            }
                    )
                }
            }
            .padding(.vertical, 8)
        }
        .frame(width: 250)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}
#endif

// MARK: - View Extension

extension View {
    /// Presenta un action sheet educativo
    public func eduActionSheet(
        isPresented: Binding<Bool>,
        content: EduActionSheetContent
    ) -> some View {
        #if os(iOS) || os(visionOS)
        self.sheet(isPresented: isPresented) {
            EduActionSheetView(isPresented: isPresented, content: content)
        }
        #elseif os(macOS)
        self.popover(isPresented: isPresented) {
            EduActionSheetView(isPresented: isPresented, content: content)
        }
        #endif
    }

    /// Presenta un action sheet con confirmDialog nativo (iOS/visionOS)
    #if os(iOS) || os(visionOS)
    public func eduConfirmationDialog(
        isPresented: Binding<Bool>,
        content: EduActionSheetContent
    ) -> some View {
        self.confirmationDialog(
            content.title ?? "",
            isPresented: isPresented,
            titleVisibility: content.title != nil ? .visible : .hidden
        ) {
            ForEach(content.actions) { action in
                Button(action.title, role: action.role) {
                    action.action()
                }
            }
        } message: {
            if let message = content.message {
                Text(message)
            }
        }
    }
    #endif
}

// MARK: - Action Sheet Manager

/// Manager centralizado para mostrar action sheets en toda la aplicación
@MainActor
@Observable
public final class EduActionSheetManager: Sendable {
    public static let shared = EduActionSheetManager()

    private(set) var isPresented: Bool = false
    private(set) var currentActionSheet: EduActionSheetContent?

    private init() {}

    /// Muestra un action sheet
    public func show(actionSheet: EduActionSheetContent) {
        currentActionSheet = actionSheet
        isPresented = true

        // VoiceOver announcement
        let optionsCount = actionSheet.actions.count
        let title = actionSheet.title ?? "Options"
        AccessibilityAnnouncements.announce("\(title). \(optionsCount) options available", priority: .medium)
    }

    /// Muestra un action sheet simple con opciones
    public func showOptions(
        title: String? = nil,
        message: String? = nil,
        options: [(title: String, icon: String?, action: @Sendable () -> Void)],
        includeCancel: Bool = true
    ) {
        var actions = options.map { option in
            EduActionSheetAction(
                title: option.title,
                icon: option.icon,
                action: option.action
            )
        }

        if includeCancel {
            actions.append(
                EduActionSheetAction(
                    title: "Cancelar",
                    role: .cancel,
                    action: {}
                )
            )
        }

        let actionSheet = EduActionSheetContent(
            title: title,
            message: message,
            actions: actions
        )
        show(actionSheet: actionSheet)
    }

    /// Oculta el action sheet actual
    public func dismiss() {
        isPresented = false
        currentActionSheet = nil
    }
}

// MARK: - Action Sheet Overlay Modifier

public struct EduActionSheetOverlayModifier: ViewModifier {
    @State private var actionSheetManager = EduActionSheetManager.shared

    public func body(content: Content) -> some View {
        content
            .sheet(isPresented: Binding(
                get: { actionSheetManager.isPresented },
                set: { if !$0 { actionSheetManager.dismiss() } }
            )) {
                if let currentActionSheet = actionSheetManager.currentActionSheet {
                    EduActionSheetView(
                        isPresented: Binding(
                            get: { actionSheetManager.isPresented },
                            set: { if !$0 { actionSheetManager.dismiss() } }
                        ),
                        content: currentActionSheet
                    )
                }
            }
    }
}

extension View {
    /// Agrega el overlay de action sheets globales a la vista
    public func eduActionSheetOverlay() -> some View {
        modifier(EduActionSheetOverlayModifier())
    }
}

// MARK: - Previews

#Preview("Action Sheet básico") {
    @Previewable @State var showActionSheet = false

    Button("Mostrar opciones") {
        showActionSheet = true
    }
    .eduActionSheet(
        isPresented: $showActionSheet,
        content: EduActionSheetContent(
            title: "Opciones",
            message: "Selecciona una accion",
            actions: [
                EduActionSheetAction(title: "Editar", icon: "pencil") { print("Editar") },
                EduActionSheetAction(title: "Compartir", icon: "square.and.arrow.up") { print("Compartir") },
                EduActionSheetAction(title: "Cancelar", role: .cancel) {}
            ]
        )
    )
}

#Preview("Action Sheet destructivo") {
    @Previewable @State var showActionSheet = false

    Button("Eliminar elemento") {
        showActionSheet = true
    }
    .eduActionSheet(
        isPresented: $showActionSheet,
        content: EduActionSheetContent(
            title: "Eliminar",
            message: "Estas seguro de eliminar este elemento?",
            actions: [
                EduActionSheetAction(title: "Eliminar", icon: "trash", role: .destructive) { print("Eliminado") },
                EduActionSheetAction(title: "Cancelar", role: .cancel) {}
            ]
        )
    )
}

#Preview("Action Sheet con multiples opciones") {
    @Previewable @State var showActionSheet = false

    Button("Mas opciones") {
        showActionSheet = true
    }
    .eduActionSheet(
        isPresented: $showActionSheet,
        content: EduActionSheetContent(
            title: "Acciones",
            actions: [
                EduActionSheetAction(title: "Copiar", icon: "doc.on.doc") { print("Copiar") },
                EduActionSheetAction(title: "Mover", icon: "folder") { print("Mover") },
                EduActionSheetAction(title: "Renombrar", icon: "pencil") { print("Renombrar") },
                EduActionSheetAction(title: "Duplicar", icon: "plus.square.on.square") { print("Duplicar") },
                EduActionSheetAction(title: "Eliminar", icon: "trash", role: .destructive) { print("Eliminar") },
                EduActionSheetAction(title: "Cancelar", role: .cancel) {}
            ]
        )
    )
}
