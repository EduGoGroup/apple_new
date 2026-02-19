import SwiftUI
import EduPresentation
import EduDynamicUI
import EduNetwork

@main
struct DemoApp: App {
    @State private var container = ServiceContainer()
    @State private var currentRoute: AppRoute = .splash

    var body: some Scene {
        WindowGroup {
            Group {
                switch currentRoute {
                case .splash:
                    SplashView(authService: container.authService) { isAuthenticated in
                        currentRoute = isAuthenticated ? .main : .login
                    }

                case .login:
                    LoginScreen(
                        authService: container.authService,
                        onLoginSuccess: { currentRoute = .main }
                    )

                case .main:
                    MainScreen(
                        screenLoader: container.screenLoader,
                        dataLoader: container.dataLoader,
                        networkClient: container.networkClient,
                        onLogout: {
                            Task { await container.authService.logout() }
                            currentRoute = .login
                        }
                    )
                }
            }
            .animation(.easeInOut, value: currentRoute)
        }
    }
}
