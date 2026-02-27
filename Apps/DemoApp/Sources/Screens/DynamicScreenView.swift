import SwiftUI
import EduDynamicUI
import EduPresentation
import EduModels
import EduNetwork

struct DynamicScreenView: View {
    let screenKey: String
    @State private var viewModel: DynamicScreenViewModel
    let onLogout: (() -> Void)?

    init(
        screenKey: String,
        screenLoader: ScreenLoader,
        dataLoader: DataLoader,
        networkClient: NetworkClient,
        onLogout: (() -> Void)? = nil
    ) {
        self.screenKey = screenKey
        self._viewModel = State(
            initialValue: DynamicScreenViewModel(
                screenLoader: screenLoader,
                dataLoader: dataLoader
            )
        )
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
        .task(id: screenKey) { await viewModel.loadScreen(key: screenKey) }
        .alert("Acción", isPresented: showAlert) {
            Button("OK") {}
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
    }
}
