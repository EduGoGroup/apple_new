// EduDetailSkeleton.swift
// EduPresentation
//
// Pattern-specific skeleton loader for detail screens.

import SwiftUI

/// Skeleton loader that simulates a detail view with header and key-value rows.
///
/// Uses existing `EduSkeletonLoader` and `ShimmerEffect`.
@MainActor
public struct EduDetailSkeleton: View {
    private let rowCount: Int

    public init(rowCount: Int = 5) {
        self.rowCount = rowCount
    }

    public var body: some View {
        EduSkeletonGroup {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                // Header: avatar + name
                HStack(spacing: DesignTokens.Spacing.medium) {
                    EduSkeletonLoader(shape: .circle)
                        .frame(width: 56, height: 56)

                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                        EduSkeletonLoader(shape: .capsule)
                            .frame(height: 18)
                            .frame(maxWidth: 160)

                        EduSkeletonLoader(shape: .capsule)
                            .frame(height: 12)
                            .frame(maxWidth: 100)
                    }
                }

                // Divider
                EduSkeletonLoader(shape: .rectangle)
                    .frame(height: 1)
                    .opacity(0.3)

                // Key-value rows
                ForEach(0..<rowCount, id: \.self) { index in
                    detailRowSkeleton(labelFraction: labelWidth(for: index))
                }
            }
            .padding()
        }
        .accessibilityLabel("Loading detail")
        .accessibilityAddTraits(.updatesFrequently)
    }

    // MARK: - Private

    @ViewBuilder
    private func detailRowSkeleton(labelFraction: CGFloat) -> some View {
        HStack {
            EduSkeletonLoader(shape: .capsule)
                .frame(height: 12)
                .frame(maxWidth: 90 * labelFraction)

            Spacer()

            EduSkeletonLoader(shape: .capsule)
                .frame(height: 12)
                .frame(maxWidth: 120)
        }
    }

    private func labelWidth(for index: Int) -> CGFloat {
        let widths: [CGFloat] = [0.8, 1.0, 0.7, 0.9, 0.6, 0.85]
        return widths[index % widths.count]
    }
}

// MARK: - Previews

#Preview("Detail Skeleton") {
    EduDetailSkeleton()
}

#Preview("Detail Skeleton 3 rows") {
    EduDetailSkeleton(rowCount: 3)
}
