import SwiftUI
import EduPresentation
import EduFeatures

@main
struct DemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("EduGo Demo App")
                    .font(.largeTitle)

                Text("Migration Complete!")
                    .font(.headline)

                Text("All modules loaded successfully")
                    .foregroundStyle(.secondary)

                Divider()
                    .padding(.vertical)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Loaded Modules:")
                        .font(.headline)

                    Text("- EduFoundation")
                    Text("- EduCore")
                    Text("- EduInfrastructure")
                    Text("- EduDomain")
                    Text("- EduPresentation")
                    Text("- EduFeatures (AI, API, Analytics)")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }
            .padding()
            .navigationTitle("EduGo")
        }
    }
}

#Preview {
    ContentView()
}
