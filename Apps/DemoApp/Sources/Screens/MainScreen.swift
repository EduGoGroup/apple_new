import SwiftUI
import EduDynamicUI
import EduPresentation
import EduNetwork
import EduDomain
import EduCore

// MARK: - Main Screen

/// Pantalla principal con navegacion adaptativa basada en menu dinamico.
///
/// Usa `AdaptiveNavigationContainer` que cambia entre TabView (compact)
/// y NavigationSplitView (expanded) segun el tamano de pantalla.
/// El menu se alimenta de `MenuService` que filtra items por permisos.
struct MainScreen: View {
    let container: ServiceContainer

    @State private var menuItems: [MenuItem] = []
    @State private var selectedItemKey: String?
    @State private var showSchoolSelection = false
    @State private var userName: String = ""
    @State private var roleName: String = ""
    @State private var schoolName: String?
    @State private var availableContexts: [UserContextDTO] = []
    @State private var currentSchoolId: String?

    var body: some View {
        AdaptiveNavigationContainer(
            menuItems: menuItems,
            selectedItem: $selectedItemKey,
            sidebarHeader: {
                EduSidebarHeader(
                    userName: userName,
                    roleName: roleName,
                    schoolName: schoolName,
                    showSchoolSwitch: availableContexts.count > 1,
                    onSchoolSwitch: { showSchoolSelection = true }
                )
            },
            sidebarFooter: {
                EduSidebarFooter(
                    onLogout: {
                        Task {
                            await container.authService.logout()
                            await container.syncService.clear()
                            await container.screenLoader.clearCache()
                        }
                    }
                )
            }
        ) { item in
            let screenKey = item.screens["main"] ?? item.key
            DynamicScreenView(
                screenKey: screenKey,
                screenLoader: container.screenLoader,
                dataLoader: container.dataLoader,
                networkClient: container.authenticatedNetworkClient
            )
        }
        .task { await loadInitialData() }
        .task { await observeMenuChanges() }
        .sheet(isPresented: $showSchoolSelection) {
            SchoolSelectionScreen(
                contexts: availableContexts,
                currentSchoolId: currentSchoolId,
                onSelect: { context in
                    showSchoolSelection = false
                    Task { await switchContext(context) }
                }
            )
        }
    }

    // MARK: - Data Loading

    private func loadInitialData() async {
        // Cargar info del usuario
        if let context = await container.authService.activeContext {
            userName = await container.authService.authenticatedUser?.fullName ?? ""
            roleName = context.roleName
            schoolName = context.schoolName
            currentSchoolId = context.schoolId
        }

        // Cargar bundle y construir menu
        if let bundle = await container.syncService.currentBundle {
            let permissions = await container.authService.activeContext?.permissions ?? []
            await container.menuService.updateMenu(from: bundle, permissions: permissions)
            availableContexts = bundle.availableContexts
        }
    }

    private func observeMenuChanges() async {
        for await menu in await container.menuService.menuStream {
            menuItems = menu
            if selectedItemKey == nil, let first = menu.first {
                selectedItemKey = first.key
            }
        }
    }

    // MARK: - Context Switching

    private func switchContext(_ context: UserContextDTO) async {
        do {
            try await container.authService.switchContext(context)
            let bundle = try await container.syncService.fullSync()
            let permissions = context.permissions
            await container.menuService.updateMenu(from: bundle, permissions: permissions)

            // Actualizar UI
            roleName = context.roleName
            schoolName = context.schoolName
            availableContexts = bundle.availableContexts
            selectedItemKey = nil
        } catch {
            // Error silencioso — el usuario permanece en el contexto actual
        }
    }
}
