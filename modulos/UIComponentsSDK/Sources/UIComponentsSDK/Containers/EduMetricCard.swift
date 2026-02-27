// EduMetricCard.swift
// UI
//
// Metric card for dashboards - iOS 26+ and macOS 26+

import SwiftUI

/// Metric card for dashboards
///
/// Displays a metric with title, value, optional change indicator,
/// and glass background optimized for iOS 26+.
@available(iOS 26.0, macOS 26.0, *)
public struct EduMetricCard: View {
    public let title: String
    public let value: String
    public let change: Double?
    public let icon: String
    public let action: (() -> Void)?

    /// Creates a Metric Card
    ///
    /// - Parameters:
    ///   - title: Metric title
    ///   - value: Metric value
    ///   - change: Percentage change (optional)
    ///   - icon: SF Symbol icon
    ///   - action: Action on tap (optional)
    public init(
        title: String,
        value: String,
        change: Double? = nil,
        icon: String = "chart.bar.fill",
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.value = value
        self.change = change
        self.icon = icon
        self.action = action
    }

    public var body: some View {
        Button(action: { action?() }) {
            cardContent
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }

    @ViewBuilder
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            // Header: Icon and Change
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                Spacer()

                if let change = change {
                    changeIndicator(change)
                }
            }

            // Value
            Text(value)
                .font(.largeTitle.bold())
                .foregroundStyle(.primary)

            // Title
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: DesignTokens.CornerRadius.glass))
    }

    @ViewBuilder
    private func changeIndicator(_ change: Double) -> some View {
        HStack(spacing: 4) {
            Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                .font(.caption)

            Text(String(format: "%.1f%%", abs(change)))
                .font(.caption)
        }
        .foregroundStyle(change >= 0 ? .green : .red)
        .padding(.horizontal, DesignTokens.Spacing.small)
        .padding(.vertical, DesignTokens.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                .fill((change >= 0 ? Color.green : Color.red).opacity(0.1))
        )
    }

}

// MARK: - Convenience Initializers

@available(iOS 26.0, macOS 26.0, *)
public extension EduMetricCard {
    /// Creates a metric card for user count
    static func users(_ value: String, change: Double? = nil) -> EduMetricCard {
        EduMetricCard(
            title: "Users",
            value: value,
            change: change,
            icon: "person.2.fill"
        )
    }

    /// Creates a metric card for revenue
    static func revenue(_ value: String, change: Double? = nil) -> EduMetricCard {
        EduMetricCard(
            title: "Revenue",
            value: value,
            change: change,
            icon: "dollarsign.circle.fill"
        )
    }

    /// Creates a metric card for conversion rate
    static func conversion(_ value: String, change: Double? = nil) -> EduMetricCard {
        EduMetricCard(
            title: "Conversion",
            value: value,
            change: change,
            icon: "arrow.up.right.circle.fill"
        )
    }
}

// MARK: - Compatibility Alias

@available(iOS 26.0, macOS 26.0, *)
@available(*, deprecated, renamed: "EduMetricCard")
public typealias DSMetricCard = EduMetricCard
