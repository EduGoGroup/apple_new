import SwiftUI
import DesignSystemSDK

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
        toasts.append(toast)

        // VoiceOver announcement based on style
        let priority: AnnouncementPriority = style == .error ? .high : .medium
        AccessibilityAnnouncements.announce("\(style.accessibilityPrefix): \(message)", priority: priority)

        Task {
            try? await Task.sleep(for: .seconds(duration))
            dismiss(toast)
        }
    }

    public func dismiss(_ toast: ToastItem) {
        toasts.removeAll { $0.id == toast.id }
    }
}

public struct ToastItem: Identifiable, Sendable {
    public let id = UUID()
    let message: String
    let style: ToastStyle
    let duration: TimeInterval
}

public struct EduToast: View {
    let item: ToastItem
    let onDismiss: () -> Void

    public var body: some View {
        HStack(spacing: DesignTokens.Spacing.medium) {
            Image(systemName: item.style.icon)
                .foregroundStyle(item.style.color)
            Text(item.message)
                .font(.body)
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss")
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(DesignTokens.CornerRadius.xl)
        .shadow(radius: DesignTokens.Shadow.medium)
        .padding(.horizontal)
        // MARK: - Accessibility
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.style.accessibilityPrefix): \(item.message)")
        .accessibilityAddTraits(.isStaticText)
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
