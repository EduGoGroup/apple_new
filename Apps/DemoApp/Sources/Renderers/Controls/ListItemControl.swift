import SwiftUI
import EduDynamicUI
import EduPresentation
import EduModels

// MARK: - ListItem

struct ListItemControl: View {
    let slot: Slot
    let resolvedValue: JSONValue?

    var body: some View {
        HStack {
            if let icon = slot.icon {
                Image(systemName: SlotRenderer.sfSymbolName(for: icon))
                    .foregroundStyle(Color.accentColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(resolvedValue?.stringRepresentation ?? "")
                    .font(.body)
                if let label = slot.label {
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }
}

// MARK: - ListItemNavigation

struct ListItemNavigationControl: View {
    let slot: Slot
    let resolvedValue: JSONValue?
    let actions: [ActionDefinition]
    let onAction: (ActionDefinition) -> Void

    var body: some View {
        HStack {
            if let icon = slot.icon {
                Image(systemName: SlotRenderer.sfSymbolName(for: icon))
                    .foregroundStyle(Color.accentColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(resolvedValue?.stringRepresentation ?? "")
                    .font(.body)
                if let label = slot.label {
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if let action = actions.first(where: { $0.triggerSlotId == slot.id }) {
                onAction(action)
            }
        }
    }
}

// MARK: - MetricCard

struct MetricCardControl: View {
    let slot: Slot
    let resolvedValue: JSONValue?

    var body: some View {
        EduMetricCard(
            title: slot.label ?? "",
            value: resolvedValue?.stringRepresentation ?? "0",
            icon: SlotRenderer.sfSymbolName(for: slot.icon ?? "chart.bar.fill")
        )
    }
}
