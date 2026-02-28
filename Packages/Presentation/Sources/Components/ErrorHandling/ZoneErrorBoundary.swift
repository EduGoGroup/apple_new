import SwiftUI

/// ViewModifier that wraps zone content with validation-driven error handling.
///
/// **Note**: This is NOT a crash/exception barrier like React error boundaries.
/// SwiftUI does not support catching exceptions thrown from `body` computations.
/// Instead, this modifier uses pre-validation: when a non-nil `errorMessage`
/// binding is provided (populated by `ZoneRenderer.validateZone`), it displays
/// a `ZoneErrorPlaceholder` inline instead of the zone content.
/// Supports retry via `retryCount` which forces SwiftUI to re-create
/// the content view.
public struct ZoneErrorBoundary: ViewModifier {
    let zoneName: String
    @Binding var errorMessage: String?
    @State private var retryCount = 0

    public init(zoneName: String, errorMessage: Binding<String?>) {
        self.zoneName = zoneName
        self._errorMessage = errorMessage
    }

    public func body(content: Content) -> some View {
        if let message = errorMessage {
            ZoneErrorPlaceholder(
                zoneName: zoneName,
                message: message,
                onRetry: {
                    retryCount += 1
                    errorMessage = nil
                }
            )
        } else {
            content
                .id(retryCount)
        }
    }
}

extension View {
    /// Wraps a zone in an error boundary that shows a placeholder on validation failure.
    public func zoneErrorBoundary(
        zoneName: String,
        errorMessage: Binding<String?>
    ) -> some View {
        modifier(ZoneErrorBoundary(zoneName: zoneName, errorMessage: errorMessage))
    }
}
