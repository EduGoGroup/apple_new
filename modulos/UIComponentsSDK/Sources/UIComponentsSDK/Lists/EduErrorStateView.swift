import SwiftUI
import DesignSystemSDK

public struct EduErrorStateView: View {
    private let title: String
    private let message: String
    private let retryTitle: String
    private let onRetry: () -> Void

    public init(
        title: String = "Error",
        message: String,
        retryTitle: String = "Reintentar",
        onRetry: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.retryTitle = retryTitle
        self.onRetry = onRetry
    }

    public var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundStyle(.red)

            VStack(spacing: DesignTokens.Spacing.small) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(retryTitle, action: onRetry)
                .buttonStyle(.borderedProminent)
                .accessibilityHint("Double tap to retry")
        }
        .padding(40)
        // MARK: - Accessibility
        .accessibilityElement(children: .contain)
        .accessibleIdentifier(.errorState(module: "ui", screen: "list"))
        // MARK: - Keyboard Navigation
        .tabPriority(5)
        .onAppear {
            AccessibilityAnnouncements.announceError("\(title). \(message)")
        }
    }
}

// MARK: - Previews

#Preview("Error básico") {
    EduErrorStateView(
        message: "No se pudo cargar la información"
    ) {
        print("Reintentando...")
    }
}

#Preview("Error de red") {
    EduErrorStateView(
        title: "Sin conexión",
        message: "Verifica tu conexión a internet e intenta nuevamente",
        retryTitle: "Reintentar conexión"
    ) {
        print("Reintentando conexión...")
    }
}

#Preview("Error personalizado") {
    EduErrorStateView(
        title: "Sesión expirada",
        message: "Tu sesión ha expirado. Por favor, inicia sesión nuevamente.",
        retryTitle: "Iniciar sesión"
    ) {
        print("Iniciando sesión...")
    }
}

#Preview("Dark Mode") {
    EduErrorStateView(
        message: "Ocurrió un error inesperado"
    ) {
        print("Reintentando...")
    }
    .preferredColorScheme(.dark)
}
