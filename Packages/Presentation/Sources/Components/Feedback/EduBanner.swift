import SwiftUI

@MainActor
public struct EduBanner: View {
    let message: String
    let style: ToastStyle
    let onDismiss: (() -> Void)?

    public init(message: String, style: ToastStyle = .info, onDismiss: (() -> Void)? = nil) {
        self.message = message
        self.style = style
        self.onDismiss = onDismiss
    }

    public var body: some View {
        HStack(spacing: DesignTokens.Spacing.medium) {
            Image(systemName: style.icon)
                .foregroundStyle(style.color)
            Text(message)
                .font(.body)
            Spacer()
            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss banner")
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(style.color.opacity(0.1))
        // MARK: - Accessibility
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(style.accessibilityPrefix): \(message)")
        .onAppear {
            let priority: AnnouncementPriority = style == .error ? .high : .medium
            AccessibilityAnnouncements.announce("\(style.accessibilityPrefix): \(message)", priority: priority)
        }
        // MARK: - Keyboard Navigation
        .tabPriority(85)
    }
}

// MARK: - Previews

#Preview("Info Banner") {
    EduBanner(
        message: "Esta es una notificación informativa",
        style: .info
    )
}

#Preview("Success Banner") {
    EduBanner(
        message: "Operación completada exitosamente",
        style: .success
    )
}

#Preview("Warning Banner") {
    EduBanner(
        message: "Atención: Tu sesión expira pronto",
        style: .warning
    )
}

#Preview("Error Banner") {
    EduBanner(
        message: "Error al procesar la solicitud",
        style: .error
    )
}

#Preview("Con botón de cerrar") {
    EduBanner(
        message: "Puedes cerrar este banner",
        style: .info
    ) {
        print("Banner cerrado")
    }
}

#Preview("Todos los estilos") {
    VStack(spacing: 0) {
        EduBanner(message: "Info", style: .info)
        EduBanner(message: "Success", style: .success)
        EduBanner(message: "Warning", style: .warning)
        EduBanner(message: "Error", style: .error)
    }
}

#Preview("Dark Mode") {
    VStack(spacing: 0) {
        EduBanner(message: "Info en modo oscuro", style: .info)
        EduBanner(message: "Error en modo oscuro", style: .error)
    }
    .preferredColorScheme(.dark)
}
