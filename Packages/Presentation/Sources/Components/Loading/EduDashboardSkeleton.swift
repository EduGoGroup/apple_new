// EduDashboardSkeleton.swift
// EduPresentation
//
// Pattern-specific skeleton loader for dashboard screens.

import SwiftUI

/// Skeleton loader that simulates a dashboard with metric cards in an adaptive grid.
///
/// Uses existing `EduSkeletonLoader` and `ShimmerEffect`.
@MainActor
public struct EduDashboardSkeleton: View {
    private let cardCount: Int
    private let columns: Int

    /// - Parameters:
    ///   - cardCount: Number of metric card skeletons to show.
    ///   - columns: Grid columns. Defaults to 2 (iPhone), use 3 for iPad.
    public init(cardCount: Int = 6, columns: Int = 2) {
        self.cardCount = cardCount
        self.columns = columns
    }

    public var body: some View {
        EduSkeletonGroup {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: DesignTokens.Spacing.medium), count: columns),
                spacing: DesignTokens.Spacing.medium
            ) {
                ForEach(0..<cardCount, id: \.self) { _ in
                    metricCardSkeleton
                }
            }
            .padding()
        }
        .accessibilityLabel("Loading dashboard")
        .accessibilityAddTraits(.updatesFrequently)
    }

    // MARK: - Private

    private var metricCardSkeleton: some View {
        VStack(spacing: DesignTokens.Spacing.medium) {
            EduSkeletonLoader(shape: .circle)
                .frame(width: 36, height: 36)

            EduSkeletonLoader(shape: .capsule)
                .frame(height: 10)
                .frame(maxWidth: 80)

            EduSkeletonLoader(shape: .capsule)
                .frame(height: 20)
                .frame(maxWidth: 60)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(white: 0.98))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl))
    }
}

// MARK: - Previews

#Preview("Dashboard Skeleton 2 col") {
    EduDashboardSkeleton()
}

#Preview("Dashboard Skeleton 3 col") {
    EduDashboardSkeleton(cardCount: 6, columns: 3)
}
