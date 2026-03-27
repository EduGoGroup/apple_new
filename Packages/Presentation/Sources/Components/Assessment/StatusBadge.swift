import SwiftUI

/// Capsule-shaped badge displaying a status label with a semantic color.
///
/// Used across assessment views to indicate the current state of an
/// assessment or answer review (e.g. Pending, Completed, In Review).
///
/// ## Predefined Styles
/// - `.pending` -- amber tint
/// - `.completed` -- green tint
/// - `.inReview` -- blue tint
/// - `.failed` -- red tint
///
/// ## Example
/// ```swift
/// StatusBadge(text: "Completado", color: .green)
/// StatusBadge.completed
/// ```
@available(iOS 26.0, macOS 26.0, *)
@MainActor
public struct StatusBadge: View {

    // MARK: - Properties

    private let text: String
    private let color: Color

    // MARK: - Initialization

    /// Creates a status badge with a custom label and color.
    ///
    /// - Parameters:
    ///   - text: The display text inside the badge.
    ///   - color: The semantic tint color for background and text.
    public init(text: String, color: Color) {
        self.text = text
        self.color = color
    }

    // MARK: - Body

    public var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, DesignTokens.Spacing.small)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
            .accessibilityLabel("Estado: \(text)")
    }
}

// MARK: - Predefined Badges

@available(iOS 26.0, macOS 26.0, *)
extension StatusBadge {
    /// Amber badge for pending assessments.
    public static var pending: StatusBadge {
        StatusBadge(text: "Pendiente", color: .orange)
    }

    /// Green badge for completed assessments.
    public static var completed: StatusBadge {
        StatusBadge(text: "Completado", color: .green)
    }

    /// Blue badge for assessments under review.
    public static var inReview: StatusBadge {
        StatusBadge(text: "En revision", color: .blue)
    }

    /// Red badge for failed assessments.
    public static var failed: StatusBadge {
        StatusBadge(text: "Reprobado", color: .red)
    }

    /// Gray badge for expired assessments.
    public static var expired: StatusBadge {
        StatusBadge(text: "Expirado", color: .gray)
    }

    /// Creates a badge from an auto-grading status string.
    ///
    /// - Parameter status: One of `auto_graded`, `pending`, `reviewed`.
    /// - Returns: An appropriate badge for the review status.
    public static func fromReviewStatus(_ status: String) -> StatusBadge {
        switch status {
        case "auto_graded":
            return StatusBadge(text: "Calificado", color: .green)
        case "pending":
            return StatusBadge(text: "Pendiente", color: .orange)
        case "reviewed":
            return StatusBadge(text: "Revisado", color: .blue)
        default:
            return StatusBadge(text: status.capitalized, color: .secondary)
        }
    }
}

// MARK: - Previews

#Preview("Status Badges") {
    VStack(spacing: DesignTokens.Spacing.medium) {
        StatusBadge.pending
        StatusBadge.completed
        StatusBadge.inReview
        StatusBadge.failed
        StatusBadge.expired
        StatusBadge.fromReviewStatus("auto_graded")
    }
    .padding()
}
