// EduFormSkeleton.swift
// EduPresentation
//
// Pattern-specific skeleton loader for form screens.

import SwiftUI

/// Skeleton loader that simulates a form with label + input field pairs.
///
/// Uses existing `EduSkeletonLoader` and `ShimmerEffect`.
@MainActor
public struct EduFormSkeleton: View {
    private let fieldCount: Int

    public init(fieldCount: Int = 5) {
        self.fieldCount = fieldCount
    }

    public var body: some View {
        EduSkeletonGroup {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                ForEach(0..<fieldCount, id: \.self) { index in
                    formFieldSkeleton(widthFraction: labelWidth(for: index))
                }

                // Save button
                EduSkeletonLoader(shape: .roundedRectangle(DesignTokens.CornerRadius.medium))
                    .frame(height: 44)
                    .frame(maxWidth: .infinity)
                    .padding(.top, DesignTokens.Spacing.medium)
            }
            .padding()
        }
        .accessibilityLabel("Loading form")
        .accessibilityAddTraits(.updatesFrequently)
    }

    // MARK: - Private

    @ViewBuilder
    private func formFieldSkeleton(widthFraction: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            // Label
            EduSkeletonLoader(shape: .capsule)
                .frame(height: 12)
                .frame(maxWidth: 120 * widthFraction)

            // Input field
            EduSkeletonLoader(shape: .roundedRectangle(DesignTokens.CornerRadius.medium))
                .frame(height: 40)
        }
    }

    private func labelWidth(for index: Int) -> CGFloat {
        let widths: [CGFloat] = [0.8, 1.0, 0.6, 0.9, 0.7, 0.85]
        return widths[index % widths.count]
    }
}

// MARK: - Previews

#Preview("Form Skeleton") {
    EduFormSkeleton()
}

#Preview("Form Skeleton 3 fields") {
    EduFormSkeleton(fieldCount: 3)
}
