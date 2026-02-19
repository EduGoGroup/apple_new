import SwiftUI
import EduDynamicUI
import EduPresentation
import EduModels

struct FallbackRenderer: View {
    let patternName: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "hammer.fill")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Patrón '\(patternName)' no implementado aún")
                .font(.headline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
