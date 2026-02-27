// EduStaleDataIndicator.swift
// EduPresentation
//
// Indicator for stale/cached data with relative time and refresh action.

import SwiftUI

/// Indicator that shows when displayed data may be stale.
///
/// Displays relative time since last update with a tap-to-refresh action
/// and a dismiss button. Uses an amber translucent background.
@MainActor
public struct EduStaleDataIndicator: View {
    private let lastUpdated: Date
    private let onRefresh: () -> Void
    @State private var isDismissed = false

    public init(lastUpdated: Date, onRefresh: @escaping () -> Void) {
        self.lastUpdated = lastUpdated
        self.onRefresh = onRefresh
    }

    public var body: some View {
        if !isDismissed {
            HStack(spacing: DesignTokens.Spacing.small) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)

                Text(relativeTimeString)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    onRefresh()
                } label: {
                    Label("Actualizar", systemImage: "arrow.clockwise")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation(.easeOut(duration: 0.25)) {
                        isDismissed = true
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss")
            }
            .padding(.horizontal, DesignTokens.Spacing.large)
            .padding(.vertical, DesignTokens.Spacing.small)
            .background(.orange.opacity(0.12), in: .capsule)
            .padding(.horizontal)
            .transition(.opacity.combined(with: .move(edge: .top)))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Data last updated \(relativeTimeString). Tap refresh to update.")
            .accessibilityAddTraits(.isButton)
        }
    }

    // MARK: - Private

    private var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastUpdated, relativeTo: Date.now)
    }
}

// MARK: - View Extension

extension View {
    /// Shows a stale data indicator above the content when data is older than the threshold.
    public func staleDataIndicator(
        lastUpdated: Date?,
        threshold: TimeInterval = 300,
        onRefresh: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 0) {
            if let lastUpdated, Date.now.timeIntervalSince(lastUpdated) > threshold {
                EduStaleDataIndicator(lastUpdated: lastUpdated, onRefresh: onRefresh)
                    .padding(.bottom, DesignTokens.Spacing.small)
            }
            self
        }
        .animation(.easeInOut(duration: 0.3), value: lastUpdated)
    }
}

// MARK: - Previews

#Preview("Stale 5 min") {
    EduStaleDataIndicator(
        lastUpdated: Date.now.addingTimeInterval(-300),
        onRefresh: { print("Refresh") }
    )
    .padding()
}

#Preview("Stale 1 hour") {
    EduStaleDataIndicator(
        lastUpdated: Date.now.addingTimeInterval(-3600),
        onRefresh: { print("Refresh") }
    )
    .padding()
}

#Preview("In context") {
    NavigationStack {
        List {
            Text("Item 1")
            Text("Item 2")
            Text("Item 3")
        }
        .staleDataIndicator(
            lastUpdated: Date.now.addingTimeInterval(-600),
            onRefresh: { print("Refresh") }
        )
        .navigationTitle("Items")
    }
}
