import SwiftUI

struct SplashView: View {
    let authService: AuthService
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
            let isAuthenticated = await authService.restoreSession()
            try? await Task.sleep(for: .seconds(0.5))
            onFinished(isAuthenticated)
        }
    }
}
