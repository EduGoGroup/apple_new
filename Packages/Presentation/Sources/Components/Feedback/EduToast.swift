import SwiftUI

public enum ToastStyle: Sendable {
    case success, error, warning, info

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }

    var accessibilityPrefix: String {
        switch self {
        case .success: return "Success"
        case .error: return "Error"
        case .warning: return "Warning"
        case .info: return "Information"
        }
    }
}

@MainActor
@Observable
public final class ToastManager: Sendable {
    public static let shared = ToastManager()
    private(set) var toasts: [ToastItem] = []

    private init() {}

    public func show(_ message: String, style: ToastStyle = .info, duration: TimeInterval = 3.0) {
        let toast = ToastItem(message: message, style: style, duration: duration)
        withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
            toasts.append(toast)
        }

        // VoiceOver announcement based on style
        let priority: AnnouncementPriority = style == .error ? .high : .medium
        AccessibilityAnnouncements.announce("\(style.accessibilityPrefix): \(message)", priority: priority)

        Task {
            try? await Task.sleep(for: .seconds(duration))
            dismiss(toast)
        }
    }

    public func dismiss(_ toast: ToastItem) {
        withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
            toasts.removeAll { $0.id == toast.id }
        }
    }

    // MARK: - Convenience Methods

    public func showSuccess(_ message: String, duration: TimeInterval = 3.0) {
        show(message, style: .success, duration: duration)
    }

    public func showError(_ message: String, duration: TimeInterval = 4.0) {
        show(message, style: .error, duration: duration)
    }

    public func showWarning(_ message: String, duration: TimeInterval = 3.5) {
        show(message, style: .warning, duration: duration)
    }

    public func showInfo(_ message: String, duration: TimeInterval = 3.0) {
        show(message, style: .info, duration: duration)
    }

    /// Shows a toast with an undo action button.
    ///
    /// The toast auto-dismisses after `duration` seconds. If the user taps
    /// the action button, the `onUndo` closure is called and the toast is dismissed.
    ///
    /// - Parameters:
    ///   - message: The message to display.
    ///   - actionLabel: Label for the action button (default: "Deshacer").
    ///   - onUndo: Closure called when the user taps the undo button.
    ///   - duration: Auto-dismiss delay in seconds (default: 5).
    public func showUndoable(
        message: String,
        actionLabel: String = EduStrings.undo,
        onUndo: @escaping @Sendable @MainActor () -> Void,
        duration: TimeInterval = 5.0
    ) {
        let action = ToastAction(label: actionLabel, handler: onUndo)
        let toast = ToastItem(message: message, style: .info, duration: duration, action: action)
        withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
            toasts.append(toast)
        }

        AccessibilityAnnouncements.announce("Information: \(message)", priority: .medium)

        Task {
            try? await Task.sleep(for: .seconds(duration))
            dismiss(toast)
        }
    }
}

/// An optional action button displayed alongside a toast message.
public struct ToastAction: Sendable {
    public let label: String
    public let handler: @Sendable @MainActor () -> Void

    public init(label: String, handler: @escaping @Sendable @MainActor () -> Void) {
        self.label = label
        self.handler = handler
    }
}

public struct ToastItem: Identifiable, Sendable {
    public let id = UUID()
    public let message: String
    public let style: ToastStyle
    public let duration: TimeInterval
    public let action: ToastAction?

    public init(message: String, style: ToastStyle, duration: TimeInterval, action: ToastAction? = nil) {
        self.message = message
        self.style = style
        self.duration = duration
        self.action = action
    }
}

public struct EduToast: View {
    let item: ToastItem
    let onDismiss: () -> Void
    @State private var dragOffset: CGFloat = 0

    public init(item: ToastItem, onDismiss: @escaping () -> Void) {
        self.item = item
        self.onDismiss = onDismiss
    }

    public var body: some View {
        HStack(spacing: DesignTokens.Spacing.medium) {
            Image(systemName: item.style.icon)
                .foregroundStyle(item.style.color)
            Text(item.message)
                .font(.body)
            Spacer()
            if let action = item.action {
                Button {
                    action.handler()
                    onDismiss()
                } label: {
                    Text(action.label)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(item.style.color)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(action.label)
            }
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss")
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl))
        .shadow(radius: DesignTokens.Shadow.medium)
        .padding(.horizontal)
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height < 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height < -50 {
                        onDismiss()
                    } else {
                        withAnimation(.spring(duration: 0.3)) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .transition(.move(edge: .top).combined(with: .opacity))
        // MARK: - Accessibility
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.style.accessibilityPrefix): \(item.message)")
        .accessibilityAddTraits(.isStaticText)
        .accessibilityAction(named: "Dismiss") { onDismiss() }
        // MARK: - Keyboard Navigation
        .skipInTabOrder()
    }
}

// MARK: - Previews

#Preview("Toast Info") {
    EduToast(
        item: ToastItem(message: "Información actualizada", style: .info, duration: 3),
        onDismiss: {}
    )
    .padding(.top, 50)
}

#Preview("Toast Success") {
    EduToast(
        item: ToastItem(message: "Guardado exitosamente", style: .success, duration: 3),
        onDismiss: {}
    )
    .padding(.top, 50)
}

#Preview("Toast Warning") {
    EduToast(
        item: ToastItem(message: "Conexión inestable", style: .warning, duration: 3),
        onDismiss: {}
    )
    .padding(.top, 50)
}

#Preview("Toast Error") {
    EduToast(
        item: ToastItem(message: "Error al guardar", style: .error, duration: 3),
        onDismiss: {}
    )
    .padding(.top, 50)
}

#Preview("Todos los estilos") {
    VStack(spacing: 16) {
        EduToast(item: ToastItem(message: "Info", style: .info, duration: 3), onDismiss: {})
        EduToast(item: ToastItem(message: "Success", style: .success, duration: 3), onDismiss: {})
        EduToast(item: ToastItem(message: "Warning", style: .warning, duration: 3), onDismiss: {})
        EduToast(item: ToastItem(message: "Error", style: .error, duration: 3), onDismiss: {})
    }
    .padding(.top, 50)
}

#Preview("Dark Mode") {
    VStack(spacing: 16) {
        EduToast(item: ToastItem(message: "Toast en modo oscuro", style: .info, duration: 3), onDismiss: {})
        EduToast(item: ToastItem(message: "Error en modo oscuro", style: .error, duration: 3), onDismiss: {})
    }
    .padding(.top, 50)
    .preferredColorScheme(.dark)
}
