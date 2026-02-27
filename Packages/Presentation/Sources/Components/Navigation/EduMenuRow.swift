// EduMenuRow.swift
// EduPresentation
//
// Single menu row with icon, label, and selection state.

import SwiftUI
import EduDomain

/// Fila de menu con icono SF Symbol mapeado, label y estado seleccionado.
public struct EduMenuRow: View {
    private let item: MenuItem
    private let isSelected: Bool

    public init(item: MenuItem, isSelected: Bool = false) {
        self.item = item
        self.isSelected = isSelected
    }

    public var body: some View {
        HStack(spacing: DesignTokens.Spacing.medium) {
            Image(systemName: IconMapper.sfSymbol(from: item.icon ?? ""))
                .font(.body)
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                .frame(width: DesignTokens.IconSize.medium)

            Text(item.displayName)
                .font(.body)
                .foregroundStyle(isSelected ? Color.primary : .secondary)

            Spacer()

            if !item.children.isEmpty {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, DesignTokens.Spacing.small)
        .padding(.horizontal, DesignTokens.Spacing.medium)
        .contentShape(Rectangle())
        .accessibilityLabel(item.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
