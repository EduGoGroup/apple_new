// DemoAppPhase7Integration.swift
// DemoApp
//
// Phase 7 UX integration helpers.
// The renderers (ListPatternRenderer, FormPatternRenderer, etc.)
// should use these helpers after Phase 4 integration is merged.

import SwiftUI
import EduPresentation

// MARK: - Skeleton for Pattern

/// Returns the appropriate skeleton loader based on screen pattern string.
///
/// Usage in renderers:
/// ```swift
/// case .loading:
///     SkeletonForPattern(pattern: screenDefinition.pattern)
/// ```
struct SkeletonForPattern: View {
    let pattern: String

    var body: some View {
        switch pattern {
        case "list", "search":
            EduListSkeleton()
        case "form", "login", "settings", "profile":
            EduFormSkeleton()
        case "dashboard":
            EduDashboardSkeleton()
        case "detail":
            EduDetailSkeleton()
        default:
            EduSkeletonList(count: 5)
        }
    }
}

// MARK: - Refreshable with Haptic

/// Adds pull-to-refresh with haptic feedback.
///
/// Usage in renderers:
/// ```swift
/// listContent
///     .modifier(RefreshableWithHaptic { await viewModel.refresh() })
/// ```
struct RefreshableWithHaptic: ViewModifier {
    let action: @Sendable () async -> Void

    func body(content: Content) -> some View {
        content
            .refreshable {
                #if os(iOS)
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                #endif
                await action()
            }
    }
}

// MARK: - Delete Confirmation

/// Adds a delete confirmation dialog.
///
/// Usage in renderers:
/// ```swift
/// row.modifier(DeleteConfirmation(
///     isPresented: $showDelete,
///     itemName: "Curso",
///     onDelete: { viewModel.delete(id) }
/// ))
/// ```
struct DeleteConfirmation: ViewModifier {
    @Binding var isPresented: Bool
    let itemName: String
    let onDelete: () -> Void

    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                "Eliminar \(itemName)",
                isPresented: $isPresented,
                titleVisibility: .visible
            ) {
                Button("Eliminar", role: .destructive) {
                    onDelete()
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Esta acción no se puede deshacer.")
            }
    }
}

// MARK: - Empty State for Pattern

/// Returns the appropriate empty state based on screen pattern and context.
///
/// Usage in renderers:
/// ```swift
/// case .success(let items, _, _) where items.isEmpty:
///     EmptyStateForPattern(pattern: "list", resourceName: "cursos")
/// ```
struct EmptyStateForPattern: View {
    let pattern: String
    let resourceName: String
    var searchQuery: String = ""
    var canCreate: Bool = false
    var onCreate: (() -> Void)? = nil
    var onRetry: (() -> Void)? = nil

    var body: some View {
        if !searchQuery.isEmpty {
            EduEmptyStateView.noSearchResults(query: searchQuery)
        } else if let onRetry {
            EduEmptyStateView.networkError(onRetry: onRetry)
        } else {
            EduEmptyStateView.emptyList(
                resourceName: resourceName,
                canCreate: canCreate,
                onCreate: onCreate
            )
        }
    }
}
