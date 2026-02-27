import SwiftUI

// MARK: - Lazy Navigation Link

/// NavigationLink mejorado con lazy loading y soporte de disabled state
///
/// Soporta desactivación del link mediante el parámetro `isEnabled`.
/// Cuando está disabled:
/// - El link no permite navegación
/// - Se aplica opacidad reducida (0.6)
/// - Se aplica el modifier `.disabled(true)` según Apple HIG
public struct EduNavigationLink<Label: View, Destination: View>: View {
    private let destination: () -> Destination
    private let label: () -> Label
    private let isEnabled: Bool

    /// Inicializa un NavigationLink con lazy loading
    /// - Parameters:
    ///   - isEnabled: Si `false`, el link se muestra pero no permite navegación (default: `true`)
    ///   - destination: Vista de destino cargada lazily
    ///   - label: Vista del label del link
    public init(
        isEnabled: Bool = true,
        @ViewBuilder destination: @escaping () -> Destination,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.isEnabled = isEnabled
        self.destination = destination
        self.label = label
    }

    public var body: some View {
        NavigationLink {
            LazyView(destination)
        } label: {
            label()
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.6)
        // MARK: - Accessibility
        .accessibilityAddTraits(.isLink)
        .accessibilityHint(isEnabled ? "Double tap to navigate" : "Navigation disabled")
        // MARK: - Keyboard Navigation
        .tabPriority(30)
    }
}

// MARK: - Lazy View Wrapper

/// Wrapper para lazy loading de vistas
private struct LazyView<Content: View>: View {
    private let build: () -> Content

    init(_ build: @escaping () -> Content) {
        self.build = build
    }

    var body: Content {
        build()
    }
}

// MARK: - String-Based Navigation Link

/// NavigationLink que navega usando strings (útil con coordinadores)
public struct EduNavigationLinkValue<Label: View>: View {
    private let value: String
    private let label: () -> Label

    public init(
        value: String,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.value = value
        self.label = label
    }

    public var body: some View {
        NavigationLink(value: value) {
            label()
        }
    }
}

// MARK: - Navigation Link with Analytics

/// NavigationLink con tracking de navegación
public struct EduTrackedNavigationLink<Label: View, Destination: View>: View {
    private let destination: () -> Destination
    private let label: () -> Label
    private let trackingId: String
    private let onNavigate: (@Sendable (String) -> Void)?

    public init(
        trackingId: String,
        onNavigate: (@Sendable (String) -> Void)? = nil,
        @ViewBuilder destination: @escaping () -> Destination,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.trackingId = trackingId
        self.onNavigate = onNavigate
        self.destination = destination
        self.label = label
    }

    public var body: some View {
        NavigationLink {
            LazyView(destination)
                .onAppear {
                    onNavigate?(trackingId)
                }
        } label: {
            label()
        }
    }
}

// MARK: - Styled Navigation Link

/// NavigationLink con estilos predefinidos y soporte de disabled state
public struct EduStyledNavigationLink<Destination: View>: View {
    private let title: String
    private let subtitle: String?
    private let icon: String?
    private let badge: String?
    private let destination: () -> Destination
    private let style: Style
    private let isEnabled: Bool

    public enum Style: Sendable {
        case plain
        case card
        case row
    }

    public init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        badge: String? = nil,
        style: Style = .row,
        isEnabled: Bool = true,
        @ViewBuilder destination: @escaping () -> Destination
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.badge = badge
        self.style = style
        self.isEnabled = isEnabled
        self.destination = destination
    }

    public var body: some View {
        NavigationLink {
            LazyView(destination)
        } label: {
            switch style {
            case .plain:
                plainView
            case .card:
                cardView
            case .row:
                rowView
            }
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.6)
        // MARK: - Accessibility
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityAddTraits(.isLink)
        .accessibilityHint(isEnabled ? "Double tap to navigate" : "Navigation disabled")
        // MARK: - Keyboard Navigation
        .tabPriority(30)
    }

    private var accessibilityLabelText: String {
        var label = title
        if let subtitle = subtitle {
            label += ", \(subtitle)"
        }
        if let badge = badge {
            label += ", \(badge) new"
        }
        if !isEnabled {
            label += ", disabled"
        }
        return label
    }

    @ViewBuilder
    private var plainView: some View {
        HStack {
            if let icon {
                Image(systemName: icon)
            }
            Text(title)
            Spacer()
            if let badge {
                Text(badge)
                    .font(.caption)
                    .padding(.horizontal, DesignTokens.Spacing.small)
                    .padding(.vertical, DesignTokens.Spacing.xs)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
    }

    @ViewBuilder
    private var cardView: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            HStack {
                if let icon {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                }

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(title)
                        .font(.headline)

                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if let badge {
                    Text(badge)
                        .font(.caption)
                        .padding(.horizontal, DesignTokens.Spacing.small)
                        .padding(.vertical, DesignTokens.Spacing.xs)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(white: 0.98))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl))
    }

    @ViewBuilder
    private var rowView: some View {
        HStack {
            if let icon {
                Image(systemName: icon)
                    .frame(width: DesignTokens.IconSize.medium)
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let badge {
                Text(badge)
                    .font(.caption2)
                    .padding(.horizontal, DesignTokens.Spacing.small)
                    .padding(.vertical, DesignTokens.Spacing.xs)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, DesignTokens.Spacing.small)
    }
}

// MARK: - Navigation Router

/// Router para gestionar navegación basada en destinos
@MainActor
@Observable
public final class EduNavigationRouter: Sendable {
    public enum Destination: Hashable, Sendable {
        case detail(id: String)
        case settings
        case profile
        case custom(String)
    }

    public private(set) var path: [Destination] = []

    public init() {}

    /// Navega a un destino
    public func navigate(to destination: Destination) {
        path.append(destination)
    }

    /// Vuelve atrás
    public func goBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    /// Vuelve a la raíz
    public func goToRoot() {
        path.removeAll()
    }

    /// Navega a una ruta específica
    public func navigate(to route: [Destination]) {
        path = route
    }
}

// MARK: - Previews

#Preview("NavigationLink básico") {
    NavigationStack {
        VStack(spacing: 16) {
            EduNavigationLink {
                Text("Vista de destino")
            } label: {
                Text("Ir a destino")
            }
        }
        .padding()
        .navigationTitle("Inicio")
    }
}

#Preview("NavigationLink deshabilitado") {
    NavigationStack {
        VStack(spacing: 16) {
            EduNavigationLink(isEnabled: true) {
                Text("Destino habilitado")
            } label: {
                Text("Link habilitado")
            }

            EduNavigationLink(isEnabled: false) {
                Text("Destino deshabilitado")
            } label: {
                Text("Link deshabilitado")
            }
        }
        .padding()
        .navigationTitle("Estados")
    }
}

#Preview("Styled NavigationLink - Row") {
    NavigationStack {
        VStack(spacing: 8) {
            EduStyledNavigationLink(
                title: "Configuración",
                subtitle: "Ajustes de la aplicación",
                icon: "gear",
                style: .row
            ) {
                Text("Vista de configuración")
            }

            EduStyledNavigationLink(
                title: "Notificaciones",
                subtitle: "3 nuevas",
                icon: "bell",
                badge: "3",
                style: .row
            ) {
                Text("Vista de notificaciones")
            }

            EduStyledNavigationLink(
                title: "Deshabilitado",
                icon: "lock",
                style: .row,
                isEnabled: false
            ) {
                Text("No accesible")
            }
        }
        .padding()
        .navigationTitle("Ajustes")
    }
}

#Preview("Styled NavigationLink - Card") {
    NavigationStack {
        VStack(spacing: 16) {
            EduStyledNavigationLink(
                title: "Nuevo Proyecto",
                subtitle: "Crea un proyecto desde cero",
                icon: "plus.rectangle",
                style: .card
            ) {
                Text("Crear proyecto")
            }

            EduStyledNavigationLink(
                title: "Cursos",
                subtitle: "12 cursos disponibles",
                icon: "book",
                badge: "12",
                style: .card
            ) {
                Text("Lista de cursos")
            }
        }
        .padding()
        .navigationTitle("Dashboard")
    }
}

#Preview("Dark Mode") {
    NavigationStack {
        VStack(spacing: 16) {
            EduStyledNavigationLink(
                title: "Perfil",
                subtitle: "Ver mi perfil",
                icon: "person.circle",
                style: .card
            ) {
                Text("Perfil")
            }

            EduStyledNavigationLink(
                title: "Ayuda",
                icon: "questionmark.circle",
                style: .row
            ) {
                Text("Ayuda")
            }
        }
        .padding()
        .navigationTitle("Menú")
    }
    .preferredColorScheme(.dark)
}
