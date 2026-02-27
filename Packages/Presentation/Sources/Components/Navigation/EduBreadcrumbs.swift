import SwiftUI

// MARK: - Breadcrumb Item

/// Representa un elemento del breadcrumb
@MainActor
public struct EduBreadcrumbItem: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let icon: String?
    public let destination: String?

    public init(id: String, title: String, icon: String? = nil, destination: String? = nil) {
        self.id = id
        self.title = title
        self.icon = icon
        self.destination = destination
    }
}

// MARK: - Breadcrumbs (macOS specific)

#if os(macOS)
/// Breadcrumbs para navegación en macOS
///
/// **Límites recomendados:**
/// - Mínimo: 1 item (item actual)
/// - Máximo: 5 niveles de profundidad para óptima legibilidad
/// - UX típico: 3-4 niveles visibles
@MainActor
public struct EduBreadcrumbs: View {
    private let items: [EduBreadcrumbItem]
    private let onNavigate: (@Sendable (String) -> Void)?

    public init(
        items: [EduBreadcrumbItem],
        onNavigate: (@Sendable (String) -> Void)? = nil
    ) {
        precondition(!items.isEmpty, "Breadcrumbs requires at least 1 item")
        precondition(items.count <= 7, "Breadcrumbs supports maximum 7 levels. Consider using a different navigation pattern for deeper hierarchies. Received \(items.count) items.")

        self.items = items
        self.onNavigate = onNavigate
    }

    public var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                // Item
                Group {
                    if let destination = item.destination, let onNavigate = onNavigate {
                        Button {
                            onNavigate(destination)
                        } label: {
                            breadcrumbItemView(item: item)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Color.accentColor)
                    } else {
                        breadcrumbItemView(item: item)
                            .foregroundStyle(index == items.count - 1 ? Color.primary : Color.secondary)
                    }
                }

                // Separator
                if index < items.count - 1 {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.medium)
        .padding(.vertical, DesignTokens.Spacing.small)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
        // MARK: - Accessibility
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Breadcrumb navigation, \(items.count) levels")
        // MARK: - Keyboard Navigation
        .tabGroup(id: "breadcrumbs", priority: 90)
    }

    @ViewBuilder
    private func breadcrumbItemView(item: EduBreadcrumbItem) -> some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            if let icon = item.icon {
                Image(systemName: icon)
                    .font(.caption)
            }
            Text(item.title)
                .font(.subheadline)
        }
    }
}
#endif

// MARK: - Breadcrumb Builder

/// Constructor para crear breadcrumbs dinámicamente
@MainActor
public struct EduBreadcrumbBuilder: Sendable {
    private var items: [EduBreadcrumbItem] = []

    public init() {}

    /// Agrega un item al breadcrumb
    public mutating func add(
        id: String,
        title: String,
        icon: String? = nil,
        destination: String? = nil
    ) {
        items.append(EduBreadcrumbItem(
            id: id,
            title: title,
            icon: icon,
            destination: destination
        ))
    }

    /// Construye el array de items
    public func build() -> [EduBreadcrumbItem] {
        return items
    }

    /// Crea breadcrumbs desde un path
    public static func fromPath(
        _ path: [String],
        titles: [String: String],
        icons: [String: String]? = nil
    ) -> [EduBreadcrumbItem] {
        path.enumerated().map { index, destination in
            EduBreadcrumbItem(
                id: destination,
                title: titles[destination] ?? destination,
                icon: icons?[destination],
                destination: index < path.count - 1 ? destination : nil
            )
        }
    }
}

// MARK: - Breadcrumb Coordinator

/// Coordinador para gestionar breadcrumbs
@MainActor
@Observable
public final class EduBreadcrumbCoordinator: Sendable {
    public private(set) var items: [EduBreadcrumbItem] = []

    public init() {}

    /// Actualiza los breadcrumbs basado en el path actual
    public func update(path: [String], titles: [String: String]) {
        items = path.enumerated().map { index, destination in
            EduBreadcrumbItem(
                id: destination,
                title: titles[destination] ?? destination,
                destination: index < path.count - 1 ? destination : nil
            )
        }
    }

    /// Agrega un breadcrumb
    public func push(id: String, title: String, destination: String?) {
        items.append(EduBreadcrumbItem(
            id: id,
            title: title,
            destination: destination
        ))
    }

    /// Elimina el último breadcrumb
    public func pop() {
        if !items.isEmpty {
            items.removeLast()
        }
    }

    /// Limpia todos los breadcrumbs
    public func clear() {
        items.removeAll()
    }
}

// MARK: - Previews

#if os(macOS)
#Preview("Breadcrumbs básico") {
    EduBreadcrumbs(
        items: [
            EduBreadcrumbItem(id: "home", title: "Inicio", icon: "house", destination: "home"),
            EduBreadcrumbItem(id: "docs", title: "Documentos", icon: "folder", destination: "docs"),
            EduBreadcrumbItem(id: "file", title: "Archivo.pdf", icon: "doc")
        ]
    ) { destination in
        print("Navegar a: \(destination)")
    }
    .padding()
}

#Preview("Breadcrumbs largo") {
    EduBreadcrumbs(
        items: [
            EduBreadcrumbItem(id: "1", title: "Raíz", destination: "1"),
            EduBreadcrumbItem(id: "2", title: "Carpeta A", destination: "2"),
            EduBreadcrumbItem(id: "3", title: "Subcarpeta", destination: "3"),
            EduBreadcrumbItem(id: "4", title: "Proyecto", destination: "4"),
            EduBreadcrumbItem(id: "5", title: "Archivo actual")
        ]
    ) { destination in
        print("Navegar a: \(destination)")
    }
    .padding()
}

#Preview("Dark Mode") {
    EduBreadcrumbs(
        items: [
            EduBreadcrumbItem(id: "home", title: "Inicio", icon: "house", destination: "home"),
            EduBreadcrumbItem(id: "settings", title: "Configuración", icon: "gear")
        ]
    )
    .padding()
    .preferredColorScheme(.dark)
}
#endif

#Preview("Platform Breadcrumbs") {
    EduPlatformBreadcrumbs(
        items: [
            EduBreadcrumbItem(id: "home", title: "Inicio"),
            EduBreadcrumbItem(id: "section", title: "Sección"),
            EduBreadcrumbItem(id: "current", title: "Página actual")
        ]
    )
    .padding()
}

// MARK: - Platform Independent Breadcrumb

/// Breadcrumb que se adapta a la plataforma
@MainActor
public struct EduPlatformBreadcrumbs: View {
    private let items: [EduBreadcrumbItem]
    private let onNavigate: (@Sendable (String) -> Void)?

    public init(
        items: [EduBreadcrumbItem],
        onNavigate: (@Sendable (String) -> Void)? = nil
    ) {
        self.items = items
        self.onNavigate = onNavigate
    }

    public var body: some View {
        #if os(macOS)
        EduBreadcrumbs(items: items, onNavigate: onNavigate)
        #else
        // En iOS/visionOS podemos mostrar una versión simplificada
        HStack {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                if index == items.count - 1 {
                    Text(item.title)
                        .font(.headline)
                }
            }
        }
        #endif
    }
}
