import SwiftUI
import EduDynamicUI
import EduPresentation
import EduModels

struct ButtonControl: View {
    let slot: Slot
    let actions: [ActionDefinition]
    let onAction: (ActionDefinition) -> Void
    let onEvent: ((String) -> Void)?

    var body: some View {
        switch slot.controlType {
        case .filledButton:
            EduButton(
                slot.label ?? "Button",
                icon: slot.icon.map { SlotRenderer.sfSymbolName(for: $0) },
                style: .primary
            ) {
                triggerAction()
            }

        case .outlinedButton:
            EduButton(
                slot.label ?? "Button",
                icon: slot.icon.map { SlotRenderer.sfSymbolName(for: $0) },
                style: .secondary
            ) {
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
                Image(systemName: SlotRenderer.sfSymbolName(for: slot.icon ?? "questionmark"))
                    .font(.title3)
            }

        default:
            EmptyView()
        }
    }

    private func triggerAction() {
        if let action = actions.first(where: { $0.triggerSlotId == slot.id }) {
            onAction(action)
        }
    }
}
