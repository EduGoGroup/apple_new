import SwiftUI

// MARK: - Navigation Bar Configuration

/// Configuración para la barra de navegación
@MainActor
public struct EduNavigationBarConfiguration: Sendable {
    public let displayMode: DisplayMode
    public let showsBackButton: Bool
    public let showsLeadingButton: Bool
    public let showsTrailingButton: Bool

    /// Modo de visualización del título de navegación
    ///
    /// **Nota importante sobre compatibilidad de plataforma:**
    /// - `.automatic`: Soportado en todas las plataformas (iOS, macOS, visionOS)
    /// - `.inline`: Soportado en todas las plataformas
    /// - `.large`: **Solo iOS/visionOS**. En macOS se fallback automático a `.inline`
    ///
    /// El sistema realiza fallback graceful en plataformas que no soportan `.large`.
    public enum DisplayMode: Sendable {
        case automatic
        case inline
        case large  // iOS/visionOS only - graceful fallback on other platforms
    }

    public init(
        displayMode: DisplayMode = .automatic,
        showsBackButton: Bool = true,
        showsLeadingButton: Bool = false,
        showsTrailingButton: Bool = false
    ) {
        self.displayMode = displayMode
        self.showsBackButton = showsBackButton
        self.showsLeadingButton = showsLeadingButton
        self.showsTrailingButton = showsTrailingButton
    }
}

// MARK: - Navigation Bar Item

/// Item personalizado para la barra de navegación
@MainActor
public struct EduNavigationBarItem: Sendable {
    public let title: String?
    public let icon: String?
    public let action: @Sendable () -> Void

    public init(
        title: String? = nil,
        icon: String? = nil,
        action: @escaping @Sendable () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.action = action
    }
}

// MARK: - Custom Navigation Bar

/// Barra de navegación personalizada
@MainActor
public struct EduNavigationBar<Content: View>: View {
    private let title: String
    private let leadingItem: EduNavigationBarItem?
    private let trailingItem: EduNavigationBarItem?
    private let content: () -> Content

    public init(
        title: String,
        leadingItem: EduNavigationBarItem? = nil,
        trailingItem: EduNavigationBarItem? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.leadingItem = leadingItem
        self.trailingItem = trailingItem
        self.content = content
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Custom Navigation Bar
            HStack {
                // Leading button
                if let leading = leadingItem {
                    Button(action: leading.action) {
                        HStack(spacing: DesignTokens.Spacing.xs) {
                            if let icon = leading.icon {
                                Image(systemName: icon)
                            }
                            if let leadingTitle = leading.title {
                                Text(leadingTitle)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(leading.title ?? "Back")
                } else {
                    Spacer()
                        .frame(width: 44)
                }

                Spacer()

                // Title
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                // Trailing button
                if let trailing = trailingItem {
                    Button(action: trailing.action) {
                        HStack(spacing: DesignTokens.Spacing.xs) {
                            if let trailingTitle = trailing.title {
                                Text(trailingTitle)
                            }
                            if let icon = trailing.icon {
                                Image(systemName: icon)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(trailing.title ?? "Options")
                } else {
                    Spacer()
                        .frame(width: 44)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, DesignTokens.Spacing.medium)
            .background(Color(white: 0.98))
            // MARK: - Accessibility
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Navigation bar, \(title)")
            // MARK: - Keyboard Navigation
            .tabGroup(id: "navigation-bar", priority: 5)

            Divider()

            // Content
            content()
        }
    }
}

// MARK: - Native Navigation Bar Modifier

extension View {
    /// Configura la barra de navegación nativa
    public func eduNavigationBar(
        title: String,
        displayMode: EduNavigationBarConfiguration.DisplayMode = .automatic
    ) -> some View {
        #if os(iOS) || os(visionOS)
        self
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(displayMode.toNative)
        #else
        self.navigationTitle(title)
        #endif
    }

    /// Configura los botones de la barra de navegación
    ///
    /// **Límites recomendados:**
    /// - iOS/visionOS: Máximo 1 item leading + 3 items trailing
    /// - macOS: Más flexible, pero se recomienda máximo 4 items totales
    ///
    /// Para múltiples acciones, considere usar un menú o action sheet.
    public func eduNavigationBarItems(
        leading: EduNavigationBarItem? = nil,
        trailing: EduNavigationBarItem? = nil
    ) -> some View {
        self.toolbar {
            #if os(iOS) || os(visionOS)
            if let leading {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: leading.action) {
                        HStack(spacing: 4) {
                            if let icon = leading.icon {
                                Image(systemName: icon)
                            }
                            if let title = leading.title {
                                Text(title)
                            }
                        }
                    }
                }
            }

            if let trailing {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: trailing.action) {
                        HStack(spacing: 4) {
                            if let title = trailing.title {
                                Text(title)
                            }
                            if let icon = trailing.icon {
                                Image(systemName: icon)
                            }
                        }
                    }
                }
            }
            #elseif os(macOS)
            if let leading {
                ToolbarItem(placement: .navigation) {
                    Button(action: leading.action) {
                        HStack(spacing: 4) {
                            if let icon = leading.icon {
                                Image(systemName: icon)
                            }
                            if let title = leading.title {
                                Text(title)
                            }
                        }
                    }
                }
            }

            if let trailing {
                ToolbarItem(placement: .automatic) {
                    Button(action: trailing.action) {
                        HStack(spacing: 4) {
                            if let title = trailing.title {
                                Text(title)
                            }
                            if let icon = trailing.icon {
                                Image(systemName: icon)
                            }
                        }
                    }
                }
            }
            #endif
        }
    }
}

// MARK: - Display Mode Conversion

extension EduNavigationBarConfiguration.DisplayMode {
    #if os(iOS) || os(visionOS)
    var toNative: NavigationBarItem.TitleDisplayMode {
        switch self {
        case .automatic: return .automatic
        case .inline: return .inline
        case .large: return .large
        }
    }
    #endif
}

// MARK: - Navigation Stack Helper

#if os(iOS) || os(visionOS)
/// Wrapper para NavigationStack con configuración
@MainActor
public struct EduNavigationStack<Content: View>: View {
    private let content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        NavigationStack {
            content()
        }
    }
}
#endif

// MARK: - Navigation Coordinator

/// Coordinador para gestionar la navegación
@MainActor
@Observable
public final class EduNavigationCoordinator: Sendable {
    public private(set) var path: [String] = []
    public private(set) var currentTitle: String = ""

    public init() {}

    /// Navega a una nueva pantalla
    public func push(_ destination: String, title: String) {
        path.append(destination)
        currentTitle = title
    }

    /// Vuelve a la pantalla anterior
    public func pop() {
        if !path.isEmpty {
            path.removeLast()
            currentTitle = path.last ?? ""
        }
    }

    /// Vuelve a la raíz
    public func popToRoot() {
        path.removeAll()
        currentTitle = ""
    }

    /// Navega a una ruta específica
    public func navigate(to route: [String]) {
        path = route
        currentTitle = route.last ?? ""
    }
}

// MARK: - Previews

#Preview("Navigation Bar personalizada") {
    EduNavigationBar(
        title: "Configuración",
        leadingItem: EduNavigationBarItem(icon: "chevron.left") { print("Atrás") },
        trailingItem: EduNavigationBarItem(icon: "gear") { print("Opciones") }
    ) {
        Text("Contenido de la pantalla")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Navigation Bar con texto") {
    EduNavigationBar(
        title: "Perfil",
        leadingItem: EduNavigationBarItem(title: "Cancelar") { print("Cancelar") },
        trailingItem: EduNavigationBarItem(title: "Guardar") { print("Guardar") }
    ) {
        VStack(spacing: 16) {
            Text("Nombre: Juan Pérez")
            Text("Email: juan@email.com")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Native Navigation Bar") {
    NavigationStack {
        Text("Contenido")
            .eduNavigationBar(title: "Título", displayMode: .large)
            .eduNavigationBarItems(
                leading: EduNavigationBarItem(icon: "chevron.left") { print("Atrás") },
                trailing: EduNavigationBarItem(icon: "plus") { print("Añadir") }
            )
    }
}

#Preview("Dark Mode") {
    EduNavigationBar(
        title: "Dashboard",
        trailingItem: EduNavigationBarItem(icon: "bell") { print("Notificaciones") }
    ) {
        Text("Contenido en modo oscuro")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .preferredColorScheme(.dark)
}
