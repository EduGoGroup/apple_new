// EduListSkeleton.swift
// EduPresentation
//
// Pattern-specific skeleton loader for list screens.
// Fase B: 5 rows with circle avatar + 2 text lines + chevron placeholder.

import SwiftUI

/// Skeleton loader that simulates a list with avatar, text lines, and chevron.
///
/// Layout per row: circle (48pt) + 2 text lines (80% and 60% width) + chevron placeholder.
/// No internal padding - the parent container handles padding (PR #19 fix).
@MainActor
public struct EduListSkeleton: View {
    private let rowCount: Int

    public init(rowCount: Int = 5) {
        self.rowCount = rowCount
    }

    public var body: some View {
        EduSkeletonGroup {
            VStack(spacing: 0) {
                ForEach(0..<rowCount, id: \.self) { index in
                    listRowSkeleton
                    if index < rowCount - 1 {
                        Divider()
                    }
                }
            }
        }
        .accessibilityLabel("Loading list")
        .accessibilityAddTraits(.updatesFrequently)
    }

    // MARK: - Private

    private var listRowSkeleton: some View {
        HStack(spacing: DesignTokens.Spacing.medium) {
            // Avatar circle
            EduSkeletonLoader(shape: .circle)
                .frame(width: 48, height: 48)

            // Two text lines
            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geo in
                    EduSkeletonLoader(shape: .capsule)
                        .frame(width: geo.size.width * 0.8, height: 14)
                }
                .frame(height: 14)

                GeometryReader { geo in
                    EduSkeletonLoader(shape: .capsule)
                        .frame(width: geo.size.width * 0.6, height: 10)
                }
                .frame(height: 10)
            }

            Spacer()

            // Chevron placeholder
            EduSkeletonLoader(shape: .roundedRectangle(2))
                .frame(width: 8, height: 14)
        }
        .padding(.vertical, DesignTokens.Spacing.medium)
    }
}

// MARK: - Previews

#Preview("List Skeleton") {
    EduListSkeleton()
        .padding()
}

#Preview("List Skeleton 3 rows") {
    EduListSkeleton(rowCount: 3)
        .padding()
}
