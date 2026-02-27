import SwiftUI
import EduCore
import EduPresentation

// MARK: - Observable Error Handler

/// Dedicated error handler that ViewModels can use to trigger the ErrorBoundary.
@MainActor
@Observable
final class ScreenErrorHandler {
    private(set) var currentError: (any Error)?
    var hasError: Bool { currentError != nil }

    func report(_ error: any Error) {
        Task {
            await Logger.shared.error("[ErrorBoundary] \(error.localizedDescription)")
        }
        currentError = error
        ToastManager.shared.showError(error.localizedDescription)
    }

    func clear() {
        currentError = nil
    }
}

// MARK: - Error Boundary ViewModifier

/// ViewModifier that shows a fallback view when an error is reported.
struct ErrorBoundary: ViewModifier {
    @Bindable var errorHandler: ScreenErrorHandler
    let onNavigateHome: (() -> Void)?

    func body(content: Content) -> some View {
        if let error = errorHandler.currentError {
            ErrorFallbackView(
                error: error,
                onRetry: { errorHandler.clear() },
                onNavigateHome: onNavigateHome
            )
        } else {
            content
        }
    }
}

// MARK: - Error Fallback View

private struct ErrorFallbackView: View {
    let error: any Error
    let onRetry: () -> Void
    let onNavigateHome: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label("Algo salió mal", systemImage: "exclamationmark.triangle.fill")
        } description: {
            Text(error.localizedDescription)
                .multilineTextAlignment(.center)
        } actions: {
            VStack(spacing: DesignTokens.Spacing.medium) {
                Button {
                    onRetry()
                } label: {
                    Label("Reintentar", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)

                if let onNavigateHome {
                    Button {
                        onNavigateHome()
                    } label: {
                        Label("Volver al inicio", systemImage: "house")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
}

// MARK: - View Extension

extension View {
    /// Wraps a screen in an error boundary with retry + optional home navigation.
    func errorBoundary(
        handler: ScreenErrorHandler,
        onNavigateHome: (() -> Void)? = nil
    ) -> some View {
        modifier(ErrorBoundary(errorHandler: handler, onNavigateHome: onNavigateHome))
    }
}
