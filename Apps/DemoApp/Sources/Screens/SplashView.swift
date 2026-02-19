import SwiftUI

struct SplashView: View {
    let onFinished: (Bool) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 80))
                .foregroundStyle(.tint)

            Text("EduGo")
                .font(.largeTitle.bold())
        }
        .task {
            try? await Task.sleep(for: .seconds(1.5))
            onFinished(false)
        }
    }
}
