import SwiftUI
import EduDynamicUI
import EduPresentation
import EduModels
import EduNetwork
import EduDomain

struct DynamicScreenView: View {
    let screenKey: String
    @State private var viewModel: DynamicScreenViewModel
    let onLogout: (() -> Void)?
    let breadcrumbTracker: BreadcrumbTracker?

    init(
        screenKey: String,
        screenLoader: ScreenLoader,
        dataLoader: DataLoader,
        networkClient: NetworkClient,
        orchestrator: EventOrchestrator? = nil,
        userContext: ScreenUserContext = .anonymous,
        onLogout: (() -> Void)? = nil,
        breadcrumbTracker: BreadcrumbTracker? = nil
    ) {
        self.screenKey = screenKey
        self.breadcrumbTracker = breadcrumbTracker
        let vm = DynamicScreenViewModel(
            screenLoader: screenLoader,
            dataLoader: dataLoader,
            orchestrator: orchestrator,
            networkClient: networkClient
        )
        vm.userContext = userContext
        self._viewModel = State(initialValue: vm)
        self.onLogout = onLogout
    }

    private var showAlert: Binding<Bool> {
        Binding(
            get: { viewModel.alertMessage != nil },
            set: { if !$0 { viewModel.alertMessage = nil } }
        )
    }

    var body: some View {
        Group {
            switch viewModel.screenState {
            case .loading:
                EduLoadingStateView()

            case .error(let message):
                EduErrorStateView(message: message) {
                    Task { await viewModel.loadScreen(key: screenKey) }
                }

            case .ready(let screen):
                PatternRouter(
                    screen: screen,
                    viewModel: viewModel
                )
            }
        }
        .onAppear { viewModel.onLogout = onLogout }
        .task(id: screenKey) {
            await viewModel.loadScreen(key: screenKey)
            if case .ready(let screen) = viewModel.screenState {
                await breadcrumbTracker?.push(
                    screenKey: screenKey,
                    title: screen.screenName,
                    icon: Self.iconForPattern(screen.pattern),
                    pattern: screen.pattern.rawValue
                )
            }
        }
        .alert("Acción", isPresented: showAlert) {
            Button("OK") {}
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
    }

    // MARK: - Breadcrumb Helpers

    static func iconForPattern(_ pattern: ScreenPattern) -> String {
        switch pattern {
        case .dashboard: "square.grid.2x2"
        case .list: "list.bullet"
        case .detail: "doc.text"
        case .form: "square.and.pencil"
        case .settings: "gearshape"
        case .search: "magnifyingglass"
        case .profile: "person"
        case .modal: "rectangle.portrait"
        case .notification: "bell"
        case .onboarding: "hand.wave"
        case .emptyState: "tray"
        case .login: "person.badge.key"
        case .unknown: "questionmark.square"
        }
    }
}
