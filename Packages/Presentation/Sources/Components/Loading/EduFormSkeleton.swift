// EduFormSkeleton.swift
// EduPresentation
//
// Pattern-specific skeleton loader for form screens.
// Fase B: 3 field groups with label (30% width, 14pt) + input (100% width, 44pt).

import SwiftUI

/// Skeleton loader that simulates a form with label + input field pairs.
///
/// Each group: label skeleton (30% width, 14pt) + input skeleton (100% width, 44pt).
/// No internal padding - the parent container handles padding (PR #19 fix).
@MainActor
public struct EduFormSkeleton: View {
    private let fieldCount: Int

    public init(fieldCount: Int = 3) {
        self.fieldCount = fieldCount
    }

    public var body: some View {
        EduSkeletonGroup {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                ForEach(0..<fieldCount, id: \.self) { _ in
                    formFieldSkeleton
                }
            }
        }
        .accessibilityLabel("Loading form")
        .accessibilityAddTraits(.updatesFrequently)
    }

    // MARK: - Private

    private var formFieldSkeleton: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            // Label skeleton (30% width, 14pt height)
            GeometryReader { geo in
                EduSkeletonLoader(shape: .capsule)
                    .frame(width: geo.size.width * 0.3, height: 14)
            }
            .frame(height: 14)

            // Input skeleton (100% width, 44pt height)
            EduSkeletonLoader(shape: .roundedRectangle(DesignTokens.CornerRadius.medium))
                .frame(height: 44)
                .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Previews

#Preview("Form Skeleton") {
    EduFormSkeleton()
        .padding()
}

#Preview("Form Skeleton 5 fields") {
    EduFormSkeleton(fieldCount: 5)
        .padding()
}
