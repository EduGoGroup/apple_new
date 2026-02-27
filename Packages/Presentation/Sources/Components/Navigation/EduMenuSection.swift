// EduMenuSection.swift
// EduPresentation
//
// Groups menu items into expandable sections.

import SwiftUI
import EduDomain

/// Seccion de menu que agrupa items y soporta secciones expandibles.
public struct EduMenuSection: View {
    private let item: MenuItem
    private let selectedKey: String?
    private let onSelect: (MenuItem) -> Void

    public init(
        item: MenuItem,
        selectedKey: String? = nil,
        onSelect: @escaping (MenuItem) -> Void
    ) {
        self.item = item
        self.selectedKey = selectedKey
        self.onSelect = onSelect
    }

    public var body: some View {
        if item.children.isEmpty {
            Button {
                onSelect(item)
            } label: {
                EduMenuRow(item: item, isSelected: selectedKey == item.key)
            }
            .buttonStyle(.plain)
        } else {
            DisclosureGroup {
                ForEach(item.children) { child in
                    Button {
                        onSelect(child)
                    } label: {
                        EduMenuRow(item: child, isSelected: selectedKey == child.key)
                    }
                    .buttonStyle(.plain)
                }
            } label: {
                EduMenuRow(item: item, isSelected: false)
            }
        }
    }
}
