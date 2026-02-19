import SwiftUI
import DesignSystemSDK

// Nota: DesignTokens debe ser parte del módulo EduAccessibility o importado por separado
// Si DesignTokens no está incluido en el target, necesitas agregarlo al proyecto de Xcode

@MainActor
public struct EduEmptyStateView: View {
    private let icon: String
    private let title: String
    private let description: String
    private let actionTitle: String?
    private let action: (() -> Void)?

    public init(
        icon: String = "tray",
        title: String,
        description: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            VStack(spacing: DesignTokens.Spacing.small) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(40)
        // MARK: - Accessibility
        .emptyStateGrouped(title: title, description: description)
        .accessibleIdentifier(.emptyState(module: "ui", screen: "list"))
        // MARK: - Keyboard Navigation
        .tabPriority(actionTitle != nil ? 15 : 100)
        .onAppear {
            AccessibilityAnnouncements.announce("\(title). \(description)", priority: .medium)
        }
    }
}

// MARK: - Previews

#Preview("Estado vacío básico") {
    EduEmptyStateView(
        title: "Sin resultados",
        description: "No hay elementos para mostrar"
    )
}

#Preview("Con icono personalizado") {
    EduEmptyStateView(
        icon: "magnifyingglass",
        title: "Sin resultados de búsqueda",
        description: "Intenta con otros términos de búsqueda"
    )
}

#Preview("Con acción") {
    EduEmptyStateView(
        icon: "plus.circle",
        title: "Sin elementos",
        description: "Comienza agregando tu primer elemento",
        actionTitle: "Agregar elemento"
    ) {
        print("Acción ejecutada")
    }
}

#Preview("Dark Mode") {
    EduEmptyStateView(
        icon: "folder",
        title: "Carpeta vacía",
        description: "Esta carpeta no contiene archivos"
    )
    .preferredColorScheme(.dark)
}
