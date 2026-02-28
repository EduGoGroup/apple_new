import SwiftUI

/// Compact inline placeholder displayed when a zone fails to render.
///
/// Shows a warning icon, zone name, optional error message, and a retry button.
/// Uses Liquid Glass styling for a subtle, non-intrusive appearance.
public struct ZoneErrorPlaceholder: View {
    let zoneName: String
    let message: String?
    let onRetry: () -> Void

    public init(zoneName: String, message: String? = nil, onRetry: @escaping () -> Void) {
        self.zoneName = zoneName
        self.message = message
        self.onRetry = onRetry
    }

    public var body: some View {
        HStack(spacing: DesignTokens.Spacing.small) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.callout)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text("Error en zona \(zoneName)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                if let message {
                    Text(message)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Button {
                onRetry()
            } label: {
                Label("Reintentar", systemImage: "arrow.clockwise")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(DesignTokens.Spacing.medium)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
    }
}
