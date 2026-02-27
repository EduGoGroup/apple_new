import SwiftUI
import EduPresentation
import EduDynamicUI
import EduNetwork
import EduDomain

#if canImport(AppKit)
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // SPM executables no tienen activation policy por defecto.
        // Sin .regular, macOS no trata la app como GUI y no le da key window.
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        if let window = NSApplication.shared.windows.first, !window.isKeyWindow {
            window.makeKeyAndOrderFront(nil)
        }
    }
}
#endif

@main
struct DemoApp: App {
    #if canImport(AppKit)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    @State private var container = ServiceContainer()
    @State private var currentRoute: AppRoute = .splash

    var body: some Scene {
        WindowGroup {
            Group {
                switch currentRoute {
                case .splash:
                    SplashView(
                        authService: container.authService,
                        syncService: container.syncService,
                        screenLoader: container.screenLoader
                    ) { isAuthenticated in
                        currentRoute = isAuthenticated ? .main : .login
                    }

                case .login:
                    LoginScreen(
                        authService: container.authService,
                        onLoginSuccess: { currentRoute = .main }
                    )

                case .main:
                    MainScreen(container: container)
                        .task {
                            for await event in await container.authService.sessionStream {
                                if event == .loggedOut || event == .expired {
                                    currentRoute = .login
                                }
                            }
                        }
                }
            }
            .animation(.easeInOut, value: currentRoute)
        }
        #if os(macOS)
        .defaultSize(width: 900, height: 600)
        .commands {
            TextEditingCommands()
        }
        #endif
    }
}
