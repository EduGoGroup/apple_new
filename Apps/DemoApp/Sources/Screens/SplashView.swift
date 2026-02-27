import SwiftUI
import EduDomain
import EduDynamicUI

struct SplashView: View {
    let authService: AuthService
    let syncService: SyncService
    let screenLoader: ScreenLoader
    let onFinished: (Bool) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 80))
                .foregroundStyle(.tint)

            Text("EduGo")
                .font(.largeTitle.bold())

            ProgressView()
                .padding(.top, 8)
        }
        .task {
            await performStartup()
        }
    }

    private func performStartup() async {
        // 1. Restaurar sesion
        debugLog("DEBUG [Splash] restoring session...")
        let isAuthenticated = await authService.restoreSession()
        debugLog("DEBUG [Splash] restoreSession result: \(isAuthenticated)")

        guard isAuthenticated else {
            // Sin sesion → Login
            debugLog("DEBUG [Splash] not authenticated → login")
            onFinished(false)
            return
        }

        // 2. Restaurar bundle local → pre-popular cache
        let localBundle = await syncService.restoreFromLocal()
        debugLog("DEBUG [Splash] local bundle: \(localBundle != nil ? "found (menu: \(localBundle!.menu.count))" : "nil")")

        if let localBundle {
            await screenLoader.seedFromBundle(screens: localBundle.screens)
        }

        // 3. Sync: fullSync if no bundle, deltaSync if we have one
        await withTaskGroup(of: Void.self) { group in
            // Splash minimo 1.5s
            group.addTask {
                try? await Task.sleep(for: .seconds(1.5))
            }

            group.addTask {
                if localBundle != nil {
                    // Delta sync — ya tenemos bundle
                    debugLog("DEBUG [Splash] doing deltaSync...")
                    if let bundle = await syncService.currentBundle {
                        _ = try? await syncService.deltaSync(currentHashes: bundle.hashes)
                        if let updatedBundle = await syncService.currentBundle {
                            await screenLoader.seedFromBundle(screens: updatedBundle.screens)
                        }
                    }
                } else {
                    // Full sync — no tenemos bundle local
                    debugLog("DEBUG [Splash] no local bundle → doing fullSync...")
                    do {
                        let bundle = try await syncService.fullSync()
                        debugLog("DEBUG [Splash] fullSync OK — menu: \(bundle.menu.count), screens: \(bundle.screens.count)")
                        await screenLoader.seedFromBundle(screens: bundle.screens)
                    } catch {
                        debugLog("DEBUG [Splash] fullSync FAILED: \(error)")
                    }
                }
            }

            await group.waitForAll()
        }

        // 4. Navegar a Main con todo pre-cargado
        debugLog("DEBUG [Splash] navigating to main")
        onFinished(true)
    }
}
