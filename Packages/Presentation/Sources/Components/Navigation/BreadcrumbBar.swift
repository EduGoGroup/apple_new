// BreadcrumbBar.swift
// EduPresentation

import SwiftUI

// MARK: - BreadcrumbBarEntry

/// A single entry displayed in the `BreadcrumbBar`.
///
/// This is a lightweight, platform-agnostic value type used by the
/// presentation layer. The domain `BreadcrumbTracker.BreadcrumbEntry`
/// should be mapped to this type before passing to the view.
public struct BreadcrumbBarEntry: Identifiable, Sendable, Hashable {
    public let id: String
    public let title: String
    public let icon: String?

    public init(id: String, title: String, icon: String? = nil) {
        self.id = id
        self.title = title
        self.icon = icon
    }
}

// MARK: - BreadcrumbBar

/// A cross-platform horizontal breadcrumb bar that displays the navigation trail.
///
/// The bar is designed to work on both iOS and macOS without platform guards.
/// It shows a horizontally-scrollable list of breadcrumb chips separated by
/// chevron indicators. Only the last (current) entry gets a filled background;
/// all preceding entries are tappable and navigate back to that level.
///
/// **Visibility rule:** The bar should only be shown when there are 2+ entries.
/// The caller is responsible for this check.
@MainActor
public struct BreadcrumbBar: View {
    public let entries: [BreadcrumbBarEntry]
    public let onNavigate: (String) -> Void

    public init(
        entries: [BreadcrumbBarEntry],
        onNavigate: @escaping (String) -> Void
    ) {
        self.entries = entries
        self.onNavigate = onNavigate
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.small) {
                ForEach(entries) { entry in
                    let isLast = entry.id == entries.last?.id

                    if isLast {
                        BreadcrumbChip(entry: entry, isLast: true)
                    } else {
                        Button {
                            onNavigate(entry.id)
                        } label: {
                            BreadcrumbChip(entry: entry, isLast: false)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text(entry.title))
                        .accessibilityHint(Text("Navigate to \(entry.title)"))
                    }

                    if !isLast {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.medium)
            .padding(.vertical, DesignTokens.Spacing.xs)
        }
    }
}

// MARK: - BreadcrumbChip

/// A single chip in the breadcrumb bar.
///
/// The last chip (current screen) is visually distinct with a filled
/// ultra-thin material background and primary foreground color.
/// Previous chips use secondary foreground to indicate they are navigable.
struct BreadcrumbChip: View {
    let entry: BreadcrumbBarEntry
    let isLast: Bool

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            if let icon = entry.icon {
                Image(systemName: icon)
                    .font(.caption2)
            }
            Text(entry.title)
                .font(.caption)
                .lineLimit(1)
        }
        .padding(.horizontal, DesignTokens.Spacing.small)
        .padding(.vertical, DesignTokens.Spacing.xs)
        .background {
            if isLast {
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                    .fill(.ultraThinMaterial)
            }
        }
        .foregroundStyle(isLast ? .primary : .secondary)
    }
}
