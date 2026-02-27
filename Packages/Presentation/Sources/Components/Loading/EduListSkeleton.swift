// EduListSkeleton.swift
// EduPresentation
//
// Pattern-specific skeleton loader for list screens.

import SwiftUI

/// Skeleton loader that simulates a list with avatar and text rows.
///
/// Uses existing `EduSkeletonListRow` and `ShimmerEffect` as building blocks.
@MainActor
public struct EduListSkeleton: View {
    private let rowCount: Int

    public init(rowCount: Int = 6) {
        self.rowCount = rowCount
    }

    public var body: some View {
        EduSkeletonGroup {
            VStack(spacing: DesignTokens.Spacing.medium) {
                ForEach(0..<rowCount, id: \.self) { _ in
                    EduSkeletonListRow()
                }
            }
        }
        .padding(.horizontal)
        .accessibilityLabel("Loading list")
        .accessibilityAddTraits(.updatesFrequently)
    }
}

// MARK: - Previews

#Preview("List Skeleton") {
    EduListSkeleton()
}

#Preview("List Skeleton 3 rows") {
    EduListSkeleton(rowCount: 3)
}
