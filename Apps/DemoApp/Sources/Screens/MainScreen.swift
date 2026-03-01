import SwiftUI
import EduDynamicUI
import EduPresentation
import EduNetwork
import EduDomain
import EduCore
import EduModels

// MARK: - Main Screen

/// Pantalla principal con navegacion adaptativa basada en menu dinamico.
///
/// Usa `AdaptiveNavigationContainer` que cambia entre TabView (compact)
/// y NavigationSplitView (expanded) segun el tamano de pantalla.
/// El menu se alimenta de `MenuService` que filtra items por permisos.
struct MainScreen: View {
    let container: ServiceContainer
    var deepLinkHandler: DeepLinkHandler? = nil

    @State private var menuItems: [MenuItem] = []
    @State private var selectedItemKey: String?
    @State private var showSchoolSelection = false
    @State private var userName: String = ""
    @State private var roleName: String = ""
    @State private var schoolName: String?
    @State private var availableContexts: [UserContextDTO] = []
    @State private var currentSchoolId: String?
    @State private var activeUserContext: ScreenUserContext = .anonymous
    @State private var allSchools: [[String: JSONValue]] = []
    @State private var deepLinkScreen: DeepLink?

    // MARK: - Breadcrumb State

    @State private var breadcrumbTracker = BreadcrumbTracker()
    @State private var breadcrumbEntries: [BreadcrumbBarEntry] = []

    var body: some View {
        AdaptiveNavigationContainer(
            menuItems: menuItems,
            selectedItem: $selectedItemKey,
            sidebarHeader: {
                EduSidebarHeader(
                    userName: userName,
                    roleName: roleName,
                    schoolName: schoolName,
                    showSchoolSwitch: roleName == "super_admin" || availableContexts.count > 1,
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
            let screenKey = item.screens["default"]
                ?? item.screens["list"]
                ?? item.screens["dashboard"]
                ?? item.screens.values.first
                ?? item.key
            DynamicScreenView(
                screenKey: screenKey,
                screenLoader: container.screenLoader,
                dataLoader: container.dataLoader,
                networkClient: container.authenticatedNetworkClient,
                orchestrator: container.eventOrchestrator,
                userContext: activeUserContext,
                breadcrumbTracker: breadcrumbTracker
            )
        }
        .safeAreaInset(edge: .top) {
            if breadcrumbEntries.count > 1 {
                BreadcrumbBar(entries: breadcrumbEntries) { entryId in
                    Task {
                        if let entry = await breadcrumbTracker.navigateTo(entryId: entryId) {
                            // Navigate to the breadcrumb's screen by finding its menu item
                            if let itemKey = findMenuItemKey(for: entry.screenKey) {
                                selectedItemKey = itemKey
                            }
                        }
                    }
                }
            }
        }
        .task { await loadInitialData() }
        .task { await observeMenuChanges() }
        .task { await observeBreadcrumbChanges() }
        .onChange(of: selectedItemKey) { _, _ in
            Task { await breadcrumbTracker.clear() }
        }
        .onChange(of: deepLinkHandler?.pendingDeepLink) { _, newLink in
            if let link = newLink {
                navigateToDeepLink(link)
            }
        }
        .sheet(isPresented: $showSchoolSelection) {
            SchoolSelectionScreen(
                contexts: availableContexts,
                currentSchoolId: currentSchoolId,
                schools: allSchools,
                onSelect: { context in
                    showSchoolSelection = false
                    Task { await switchContext(context) }
                }
            )
        }
        .sheet(item: $deepLinkScreen) { link in
            NavigationStack {
                DynamicScreenView(
                    screenKey: link.screenKey,
                    screenLoader: container.screenLoader,
                    dataLoader: container.dataLoader,
                    networkClient: container.authenticatedNetworkClient,
                    orchestrator: container.eventOrchestrator,
                    userContext: activeUserContext
                )
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(EduStrings.close) { deepLinkScreen = nil }
                    }
                }
            }
        }
    }

    // MARK: - Data Loading

    private func loadInitialData() async {
        debugLog("DEBUG [MainScreen] loadInitialData started")

        // Cargar info del usuario
        if let context = await container.authService.activeContext {
            userName = await container.authService.authenticatedUser?.fullName ?? ""
            roleName = context.roleName
            schoolName = context.schoolName
            currentSchoolId = context.schoolId
            activeUserContext = ScreenUserContext(auth: context)
            debugLog("DEBUG [MainScreen] user: \(userName), role: \(roleName), school: \(schoolName ?? "none")")
        } else {
            debugLog("DEBUG [MainScreen] NO activeContext found!")
        }

        // Cargar bundle y construir menu
        if let bundle = await container.syncService.currentBundle {
            debugLog("DEBUG [MainScreen] bundle found — menu DTOs: \(bundle.menu.count), permissions: \(bundle.permissions.count)")
            let permissions = await container.authService.activeContext?.permissions ?? []
            debugLog("DEBUG [MainScreen] user permissions count: \(permissions.count)")
            await container.menuService.updateMenu(from: bundle, permissions: permissions)
            availableContexts = bundle.availableContexts

            // Also set menuItems directly to avoid race with stream listener
            let filtered = await container.menuService.currentMenu
            debugLog("DEBUG [MainScreen] filtered menu items: \(filtered.count)")
            for item in filtered {
                debugLog("DEBUG [MainScreen] menuItem: key=\(item.key), name=\(item.displayName), children=\(item.children.count)")
            }
            menuItems = filtered
            if selectedItemKey == nil, let first = filtered.first {
                selectedItemKey = first.key
            }

            // super_admin sin escuela seleccionada → cargar escuelas del API
            if roleName == "super_admin" && currentSchoolId == nil {
                debugLog("DEBUG [MainScreen] super_admin without school — loading schools from API")
                await loadSchoolsForSuperAdmin()
                if !allSchools.isEmpty {
                    showSchoolSelection = true
                }
            }
        } else {
            debugLog("DEBUG [MainScreen] NO bundle found! syncService.currentBundle is nil")
        }
    }

    private func loadSchoolsForSuperAdmin() async {
        do {
            let raw = try await container.dataLoader.loadData(
                endpoint: "admin:/api/v1/schools",
                config: nil
            )
            var schools: [[String: JSONValue]] = []
            for key in ["items", "data", "results"] {
                if case .array(let array) = raw[key] {
                    schools = array.compactMap { element in
                        if case .object(let dict) = element { return dict }
                        return nil
                    }
                    break
                }
            }
            if schools.isEmpty {
                schools = [raw]
            }
            allSchools = schools
            debugLog("DEBUG [MainScreen] loaded \(schools.count) schools for super_admin")
        } catch {
            debugLog("DEBUG [MainScreen] failed to load schools: \(error)")
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

    private func observeBreadcrumbChanges() async {
        for await trail in breadcrumbTracker.trailStream {
            breadcrumbEntries = trail.map { entry in
                BreadcrumbBarEntry(
                    id: entry.id,
                    title: entry.title,
                    icon: entry.icon
                )
            }
        }
    }

    // MARK: - Deep Link Navigation

    private func navigateToDeepLink(_ link: DeepLink) {
        deepLinkHandler?.pendingDeepLink = nil

        // Try to find a menu item that matches the deep link screenKey
        if let itemKey = findMenuItemKey(for: link.screenKey) {
            debugLog("DEBUG [DeepLink] matched menu item: \(itemKey) for screenKey: \(link.screenKey)")
            selectedItemKey = itemKey
        } else {
            debugLog("DEBUG [DeepLink] no menu match — opening sheet for: \(link.screenKey)")
            deepLinkScreen = link
        }
    }

    private func findMenuItemKey(for screenKey: String) -> String? {
        for item in menuItems {
            if item.key == screenKey { return item.key }
            if item.screens.values.contains(screenKey) { return item.key }
            for child in item.children {
                if child.key == screenKey { return child.key }
                if child.screens.values.contains(screenKey) { return child.key }
            }
        }
        return nil
    }

    // MARK: - Context Switching

    private func switchContext(_ context: UserContextDTO) async {
        do {
            try await container.authService.switchContext(context)
            await container.screenLoader.clearCache()
            await container.dataLoader.clearCache()

            // Fase 1: Carga rapida de metadata (menu, permissions, contexts)
            let metadataBundle = try await container.syncService.syncBuckets([
                .menu, .permissions, .availableContexts
            ])
            let permissions = context.permissions
            await container.menuService.updateMenu(from: metadataBundle, permissions: permissions)

            // Actualizar UI inmediatamente con metadata
            roleName = context.roleName
            schoolName = context.schoolName
            currentSchoolId = context.schoolId
            availableContexts = metadataBundle.availableContexts
            activeUserContext = ScreenUserContext(dto: context)
            selectedItemKey = nil

            // Fase 2: Cargar screens en background y poblar cache
            Task {
                if let bundle = try? await container.syncService.syncBuckets([.screens]) {
                    await container.screenLoader.seedFromBundle(screens: bundle.screens)
                }
            }
        } catch {
            // Error silencioso — el usuario permanece en el contexto actual
        }
    }
}
