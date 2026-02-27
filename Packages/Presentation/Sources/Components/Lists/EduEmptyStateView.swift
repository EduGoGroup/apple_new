import SwiftUI

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
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.glassLarge))
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

// MARK: - Factory Initializers

extension EduEmptyStateView {
    /// Empty state for no search results.
    public static func noSearchResults(query: String) -> EduEmptyStateView {
        EduEmptyStateView(
            icon: "magnifyingglass",
            title: "Sin resultados",
            description: "No se encontraron resultados para \"\(query)\". Intenta con otros términos."
        )
    }

    /// Empty state for an empty list with optional create action.
    public static func emptyList(
        resourceName: String,
        canCreate: Bool = false,
        onCreate: (() -> Void)? = nil
    ) -> EduEmptyStateView {
        EduEmptyStateView(
            icon: "tray",
            title: "Sin \(resourceName)",
            description: canCreate
                ? "Comienza agregando tu primer elemento."
                : "No hay \(resourceName) disponibles.",
            actionTitle: canCreate ? "Crear \(resourceName)" : nil,
            action: onCreate
        )
    }

    /// Generic no-data empty state.
    public static func noData() -> EduEmptyStateView {
        EduEmptyStateView(
            icon: "doc.text",
            title: "Sin datos",
            description: "No hay información disponible en este momento."
        )
    }

    /// Network error empty state with retry.
    public static func networkError(onRetry: @escaping () -> Void) -> EduEmptyStateView {
        EduEmptyStateView(
            icon: "wifi.slash",
            title: "Sin conexión",
            description: "Verifica tu conexión a internet e intenta nuevamente.",
            actionTitle: "Reintentar",
            action: onRetry
        )
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

#Preview("No Search Results") {
    EduEmptyStateView.noSearchResults(query: "matemáticas")
}

#Preview("Empty List") {
    EduEmptyStateView.emptyList(resourceName: "cursos", canCreate: true) {
        print("Crear curso")
    }
}

#Preview("No Data") {
    EduEmptyStateView.noData()
}

#Preview("Network Error") {
    EduEmptyStateView.networkError { print("Retry") }
}

#Preview("Dark Mode") {
    EduEmptyStateView(
        icon: "folder",
        title: "Carpeta vacía",
        description: "Esta carpeta no contiene archivos"
    )
    .preferredColorScheme(.dark)
}
