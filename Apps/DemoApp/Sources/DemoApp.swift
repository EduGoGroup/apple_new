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

func debugLog(_ message: String) {
    let msg = "[\(Date())] \(message)\n"
    print(msg, terminator: "")
    if let data = msg.data(using: .utf8) {
        let url = URL(fileURLWithPath: "/tmp/demoapp_debug.log")
        if let handle = try? FileHandle(forWritingTo: url) {
            handle.seekToEndOfFile()
            handle.write(data)
            handle.closeFile()
        } else {
            try? data.write(to: url)
        }
    }
}

@main
struct DemoApp: App {
    #if canImport(AppKit)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    @State private var container = ServiceContainer()
    @State private var currentRoute: AppRoute = .splash
    @State private var isOnline: Bool = true
    @State private var deepLinkHandler = DeepLinkHandler()

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
                        debugLog("DEBUG [Splash] finished — isAuthenticated: \(isAuthenticated)")
                        currentRoute = isAuthenticated ? .main : .login
                    }

                case .login:
                    LoginScreen(
                        authService: container.authService,
                        onLoginSuccess: {
                            debugLog("DEBUG [Login] success — starting fullSync...")
                            Task {
                                do {
                                    let bundle = try await container.syncService.fullSync()
                                    debugLog("DEBUG [Sync] Bundle loaded — menu: \(bundle.menu.count) items, screens: \(bundle.screens.count), permissions: \(bundle.permissions.count), contexts: \(bundle.availableContexts.count)")
                                    for item in bundle.menu {
                                        debugLog("DEBUG [Menu] item: key=\(item.key), name=\(item.displayName), children=\(item.children?.count ?? 0), perms=\(item.permissions)")
                                    }
                                    await container.screenLoader.seedFromBundle(screens: bundle.screens)
                                } catch {
                                    debugLog("DEBUG [Sync] fullSync FAILED: \(error)")
                                }
                                debugLog("DEBUG [Login] navigating to .main")
                                currentRoute = .main
                            }
                        }
                    )

                case .main:
                    MainScreen(container: container, deepLinkHandler: deepLinkHandler)
                        .task {
                            for await event in await container.authService.sessionStream {
                                debugLog("DEBUG [Session] event: \(event)")
                                if event == .loggedOut || event == .expired {
                                    currentRoute = .login
                                }
                            }
                        }
                }
            }
            .animation(.easeInOut, value: currentRoute)
            .environment(container.toastManager)
            .environment(container.glossaryProvider)
            .environment(\.isOnline, isOnline)
            .environment(\.eventOrchestrator, container.eventOrchestrator)
            .eduOverlays()
            .task { await startConnectivityObserver() }
            .onOpenURL { url in
                debugLog("DEBUG [DeepLink] received URL: \(url)")
                if currentRoute == .main {
                    if let link = deepLinkHandler.handle(url: url) {
                        debugLog("DEBUG [DeepLink] navigating immediately to: \(link.screenKey)")
                        deepLinkHandler.pendingDeepLink = link
                    }
                } else {
                    debugLog("DEBUG [DeepLink] storing pending (not authenticated)")
                    deepLinkHandler.storePending(url: url)
                }
            }
        }
        #if os(macOS)
        .defaultSize(width: 900, height: 600)
        .commands {
            TextEditingCommands()
        }
        #endif
    }

    // MARK: - Connectivity

    private func startConnectivityObserver() async {
        await container.connectivitySyncManager.startObserving()
        for await online in await container.connectivitySyncManager.isOnlineStream {
            isOnline = online
        }
    }
}
