import SwiftUI
import DesignSystemSDK

public struct EduLoadingStateView: View {
    @State private var isAnimating = false

    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { _ in
                SkeletonRow()
            }
        }
        .padding()
        // MARK: - Accessibility
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading content")
        .accessibleIdentifier(.loading(module: "ui", screen: "list"))
        .onAppear {
            AccessibilityAnnouncements.announce("Loading content", priority: .low)
        }
    }
}

private struct SkeletonRow: View {
    @State private var opacity: Double = 0.3

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(opacity))
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(opacity))
                    .frame(height: 16)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(opacity))
                    .frame(width: 200, height: 12)
            }

            Spacer()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                opacity = 0.6
            }
        }
    }
}

// MARK: - Previews

#Preview("Estado de carga") {
    EduLoadingStateView()
}

#Preview("En contenedor") {
    VStack {
        Text("Cargando datos...")
            .font(.headline)
            .padding(.bottom)
        EduLoadingStateView()
    }
    .padding()
}

#Preview("Dark Mode") {
    EduLoadingStateView()
        .preferredColorScheme(.dark)
}
