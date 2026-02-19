import SwiftUI
import EduDynamicUI
import EduPresentation
import EduNetwork

// MARK: - Main Screen

/// Pantalla principal con navegación por tabs.
/// Cada tab renderiza una pantalla dinámica usando DynamicScreenView.
struct MainScreen: View {
    let screenLoader: ScreenLoader
    let dataLoader: DataLoader
    let networkClient: NetworkClient
    var onLogout: (() -> Void)?

    @State private var selectedTab = "dashboard"

    private let tabItems: [EduTabItem] = [
        EduTabItem(id: "dashboard", title: "Dashboard", icon: "square.grid.2x2", selectedIcon: "square.grid.2x2.fill"),
        EduTabItem(id: "materials", title: "Materiales", icon: "book", selectedIcon: "book.fill"),
        EduTabItem(id: "settings", title: "Ajustes", icon: "gearshape", selectedIcon: "gearshape.fill")
    ]

    private let screenKeys: [String: String] = [
        "dashboard": "dashboard-home",
        "materials": "materials-list",
        "settings": "settings-main"
    ]

    var body: some View {
        EduTabBar(selection: $selectedTab, items: tabItems) { tabId in
            DynamicScreenView(
                screenKey: screenKeys[tabId] ?? tabId,
                screenLoader: screenLoader,
                dataLoader: dataLoader,
                networkClient: networkClient,
                onLogout: onLogout
            )
        }
    }
}
