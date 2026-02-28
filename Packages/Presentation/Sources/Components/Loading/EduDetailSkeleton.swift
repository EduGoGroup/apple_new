// EduDetailSkeleton.swift
// EduPresentation
//
// Pattern-specific skeleton loader for detail screens.
// Fase B: Header (title 80% + subtitle 60%) + divider + 3 detail rows (label + value).

import SwiftUI

/// Skeleton loader that simulates a detail view with header and key-value rows.
///
/// Layout: title (80% width, 20pt) + subtitle (60% width, 14pt) + divider + detail rows.
/// No internal padding - the parent container handles padding (PR #19 fix).
@MainActor
public struct EduDetailSkeleton: View {
    private let rowCount: Int

    public init(rowCount: Int = 3) {
        self.rowCount = rowCount
    }

    public var body: some View {
        EduSkeletonGroup {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                // Header: title + subtitle
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                    GeometryReader { geo in
                        EduSkeletonLoader(shape: .capsule)
                            .frame(width: geo.size.width * 0.8, height: 20)
                    }
                    .frame(height: 20)

                    GeometryReader { geo in
                        EduSkeletonLoader(shape: .capsule)
                            .frame(width: geo.size.width * 0.6, height: 14)
                    }
                    .frame(height: 14)
                }

                // Divider
                Divider()

                // Detail rows (label + value)
                ForEach(0..<rowCount, id: \.self) { _ in
                    detailRowSkeleton
                }
            }
        }
        .accessibilityLabel("Loading detail")
        .accessibilityAddTraits(.updatesFrequently)
    }

    // MARK: - Private

    private var detailRowSkeleton: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            // Label (short)
            EduSkeletonLoader(shape: .capsule)
                .frame(width: 80, height: 12)

            // Value (full width)
            EduSkeletonLoader(shape: .capsule)
                .frame(height: 14)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Previews

#Preview("Detail Skeleton") {
    EduDetailSkeleton()
        .padding()
}

#Preview("Detail Skeleton 5 rows") {
    EduDetailSkeleton(rowCount: 5)
        .padding()
}
