import SwiftUI
import EduDynamicUI
import EduPresentation
import EduModels

struct SlotRenderer: View {
    let slot: Slot
    let data: [String: EduModels.JSONValue]?
    let slotData: [String: EduModels.JSONValue]?
    let actions: [ActionDefinition]
    let onAction: (ActionDefinition) -> Void

    private let resolver = SlotBindingResolver()

    private var resolvedValue: EduModels.JSONValue? {
        resolver.resolve(slot: slot, data: data, slotData: slotData)
    }

    var body: some View {
        switch slot.controlType {
        case .label:
            labelView

        case .filledButton:
            EduButton(slot.label ?? "Button", icon: slot.icon, style: .primary) {
                triggerAction()
            }

        case .outlinedButton:
            EduButton(slot.label ?? "Button", icon: slot.icon, style: .secondary) {
                triggerAction()
            }

        case .textButton:
            EduButton.link(slot.label ?? "Button") {
                triggerAction()
            }

        case .iconButton:
            Button {
                triggerAction()
            } label: {
                Image(systemName: slot.icon ?? "questionmark")
            }

        case .metricCard:
            EduMetricCard(
                title: slot.label ?? "",
                value: resolvedValue?.stringRepresentation ?? "0",
                icon: slot.icon ?? "chart.bar.fill"
            )

        case .icon:
            Image(systemName: slot.icon ?? "questionmark")

        case .divider:
            Divider()

        case .listItem:
            listItemView

        case .listItemNavigation:
            listItemNavigationView

        default:
            EmptyView()
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var labelView: some View {
        let text = resolvedValue?.stringRepresentation ?? slot.label ?? ""
        switch slot.style {
        case "title":
            Text(text).font(.title)
        case "headline":
            Text(text).font(.headline)
        case "caption":
            Text(text).font(.caption).foregroundStyle(.secondary)
        case "subheadline":
            Text(text).font(.subheadline).foregroundStyle(.secondary)
        default:
            Text(text)
        }
    }

    private var listItemView: some View {
        HStack {
            if let icon = slot.icon {
                Image(systemName: icon)
            }
            VStack(alignment: .leading) {
                Text(resolvedValue?.stringRepresentation ?? "")
                if let label = slot.label {
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }

    private var listItemNavigationView: some View {
        HStack {
            if let icon = slot.icon {
                Image(systemName: icon)
            }
            VStack(alignment: .leading) {
                Text(resolvedValue?.stringRepresentation ?? "")
                if let label = slot.label {
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            triggerAction()
        }
    }

    // MARK: - Actions

    private func triggerAction() {
        if let action = actions.first(where: { $0.triggerSlotId == slot.id }) {
            onAction(action)
        }
    }
}
