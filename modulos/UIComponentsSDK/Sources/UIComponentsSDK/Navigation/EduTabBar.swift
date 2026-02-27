import SwiftUI
import DesignSystemSDK

// MARK: - Tab Item

/// Representa un item del TabBar
@MainActor
public struct EduTabItem: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let icon: String
    public let selectedIcon: String?
    public let badge: String?

    public init(
        id: String,
        title: String,
        icon: String,
        selectedIcon: String? = nil,
        badge: String? = nil
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.selectedIcon = selectedIcon
        self.badge = badge
    }
}

// MARK: - Tab Bar

/// TabBar customizado multi-plataforma
///
/// Implementa un TabBar adaptativo que se comporta de manera nativa en cada plataforma:
///
/// **iOS/visionOS:**
/// - Utiliza `TabView` nativo con `tabItem` modifier
/// - Soporta badges y selección de iconos
/// - Aparece en la parte inferior de la pantalla (iOS HIG)
/// - Requiere entre 2 y 5 tabs para óptima experiencia de usuario
///
/// **macOS:**
/// - Utiliza `NavigationSplitView` con sidebar
/// - Lista de items en la columna lateral izquierda
/// - Contenido mostrado en el panel detail
/// - Badges mostrados como capsulas en la lista
/// - Mejor experiencia para navegación en escritorio
///
/// **Nota:** El comportamiento es automáticamente adaptado según la plataforma en compilación.
public struct EduTabBar<Content: View>: View {
    @Binding private var selection: String
    private let items: [EduTabItem]
    private let content: (String) -> Content

    public init(
        selection: Binding<String>,
        items: [EduTabItem],
        @ViewBuilder content: @escaping (String) -> Content
    ) {
        // Validación de cantidad de tabs según iOS Human Interface Guidelines
        precondition(items.count >= 2 && items.count <= 5,
                     "TabBar requires between 2 and 5 tabs. Received \(items.count) tabs. iOS HIG recommends a maximum of 5 tabs for optimal UX.")

        self._selection = selection
        self.items = items
        self.content = content
    }

    public var body: some View {
        #if os(iOS) || os(visionOS)
        TabView(selection: $selection) {
            ForEach(items) { item in
                content(item.id)
                    .tabItem {
                        Label(item.title, systemImage: selection == item.id ? (item.selectedIcon ?? item.icon) : item.icon)
                    }
                    .badge(item.badge)
                    .tag(item.id)
            }
        }
        // MARK: - Keyboard Navigation
        .tabGroup(id: "main-tab-bar", priority: 1)
        #elseif os(macOS)
        NavigationSplitView {
            List(items, selection: $selection) { item in
                HStack {
                    Image(systemName: selection == item.id ? (item.selectedIcon ?? item.icon) : item.icon)
                        .foregroundStyle(selection == item.id ? Color.accentColor : Color.secondary)
                    Text(item.title)
                        .foregroundStyle(selection == item.id ? Color.primary : Color.secondary)
                    Spacer()
                    if let badge = item.badge {
                        Text(badge)
                            .font(.caption2)
                            .padding(.horizontal, DesignTokens.Spacing.small)
                            .padding(.vertical, DesignTokens.Spacing.xs)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
                .contentShape(Rectangle())
                .tag(item.id)
            }
            .listStyle(.sidebar)
            .navigationTitle("Navegación")
        } detail: {
            content(selection)
        }
        #endif
    }
}

// MARK: - Custom Tab Bar Style

#if os(iOS) || os(visionOS)
/// Estilo personalizable para el TabBar
public enum EduTabBarStyle: Sendable {
    case automatic
    case transparent
    case opaque
}

extension View {
    /// Aplica un estilo personalizado al TabBar
    public func eduTabBarStyle(_ style: EduTabBarStyle) -> some View {
        self.onAppear {
            let appearance = UITabBarAppearance()

            switch style {
            case .automatic:
                appearance.configureWithDefaultBackground()
            case .transparent:
                appearance.configureWithTransparentBackground()
            case .opaque:
                appearance.configureWithOpaqueBackground()
            }

            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
#endif

// MARK: - Tab Bar Coordinator

/// Coordinador para gestionar la navegación del TabBar
@MainActor
@Observable
public final class EduTabBarCoordinator: Sendable {
    public private(set) var selectedTab: String
    public private(set) var previousTab: String?

    public init(initialTab: String) {
        self.selectedTab = initialTab
    }

    /// Selecciona un tab específico
    public func select(tab: String) {
        previousTab = selectedTab
        selectedTab = tab

        // VoiceOver announcement
        AccessibilityAnnouncements.announce("Selected \(tab) tab", priority: .medium)
    }

    /// Vuelve al tab anterior si existe
    public func goBackToPreviousTab() {
        if let previous = previousTab {
            let temp = selectedTab
            selectedTab = previous
            previousTab = temp
        }
    }
}

// MARK: - Tab Bar with Coordinator

/// TabBar con coordinador integrado
public struct EduCoordinatedTabBar<Content: View>: View {
    @State private var coordinator: EduTabBarCoordinator
    private let items: [EduTabItem]
    private let content: (String, EduTabBarCoordinator) -> Content

    public init(
        initialTab: String,
        items: [EduTabItem],
        @ViewBuilder content: @escaping (String, EduTabBarCoordinator) -> Content
    ) {
        // Validación de cantidad de tabs según iOS Human Interface Guidelines
        precondition(items.count >= 2 && items.count <= 5,
                     "TabBar requires between 2 and 5 tabs. Received \(items.count) tabs. iOS HIG recommends a maximum of 5 tabs for optimal UX.")

        self._coordinator = State(initialValue: EduTabBarCoordinator(initialTab: initialTab))
        self.items = items
        self.content = content
    }

    public var body: some View {
        EduTabBar(
            selection: Binding(
                get: { coordinator.selectedTab },
                set: { coordinator.select(tab: $0) }
            ),
            items: items
        ) { tabId in
            content(tabId, coordinator)
        }
    }
}

// MARK: - Previews

#Preview("TabBar básico") {
    @Previewable @State var selection = "home"

    let items = [
        EduTabItem(id: "home", title: "Inicio", icon: "house"),
        EduTabItem(id: "search", title: "Buscar", icon: "magnifyingglass"),
        EduTabItem(id: "profile", title: "Perfil", icon: "person")
    ]

    EduTabBar(selection: $selection, items: items) { tabId in
        Text("Contenido de \(tabId)")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("TabBar con iconos seleccionados") {
    @Previewable @State var selection = "home"

    let items = [
        EduTabItem(id: "home", title: "Inicio", icon: "house", selectedIcon: "house.fill"),
        EduTabItem(id: "explore", title: "Explorar", icon: "safari", selectedIcon: "safari.fill"),
        EduTabItem(id: "favorites", title: "Favoritos", icon: "heart", selectedIcon: "heart.fill"),
        EduTabItem(id: "profile", title: "Perfil", icon: "person", selectedIcon: "person.fill")
    ]

    EduTabBar(selection: $selection, items: items) { tabId in
        VStack {
            Image(systemName: items.first { $0.id == tabId }?.icon ?? "questionmark")
                .font(.largeTitle)
            Text("Vista: \(tabId)")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("TabBar con badges") {
    @Previewable @State var selection = "inbox"

    let items = [
        EduTabItem(id: "inbox", title: "Bandeja", icon: "tray", badge: "5"),
        EduTabItem(id: "sent", title: "Enviados", icon: "paperplane"),
        EduTabItem(id: "trash", title: "Papelera", icon: "trash")
    ]

    EduTabBar(selection: $selection, items: items) { tabId in
        Text("Contenido de \(tabId)")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Dark Mode") {
    @Previewable @State var selection = "home"

    let items = [
        EduTabItem(id: "home", title: "Inicio", icon: "house", selectedIcon: "house.fill"),
        EduTabItem(id: "search", title: "Buscar", icon: "magnifyingglass"),
        EduTabItem(id: "profile", title: "Perfil", icon: "person", selectedIcon: "person.fill")
    ]

    EduTabBar(selection: $selection, items: items) { tabId in
        Text("Modo oscuro: \(tabId)")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .preferredColorScheme(.dark)
}
