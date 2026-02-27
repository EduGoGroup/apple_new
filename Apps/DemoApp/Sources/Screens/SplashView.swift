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
        let isAuthenticated = await authService.restoreSession()

        guard isAuthenticated else {
            // Sin sesion → Login
            onFinished(false)
            return
        }

        // 2. Restaurar bundle local → pre-popular cache
        if let localBundle = await syncService.restoreFromLocal() {
            await screenLoader.seedFromBundle(screens: localBundle.screens)
        }

        // 3. En paralelo: splash delay + delta sync en background
        await withTaskGroup(of: Void.self) { group in
            // Splash minimo 1.5s
            group.addTask {
                try? await Task.sleep(for: .seconds(1.5))
            }

            // Delta sync en background (best-effort)
            group.addTask {
                if let bundle = await syncService.currentBundle {
                    _ = try? await syncService.deltaSync(currentHashes: bundle.hashes)

                    // Re-seed cache si delta trajo cambios
                    if let updatedBundle = await syncService.currentBundle {
                        await screenLoader.seedFromBundle(screens: updatedBundle.screens)
                    }
                }
            }

            await group.waitForAll()
        }

        // 4. Navegar a Main con todo pre-cargado
        onFinished(true)
    }
}
