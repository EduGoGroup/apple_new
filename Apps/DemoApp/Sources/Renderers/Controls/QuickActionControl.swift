import SwiftUI
import EduDynamicUI
import EduPresentation
import EduModels

struct QuickActionControl: View {
    let slot: Slot
    let actions: [ActionDefinition]
    let onAction: (ActionDefinition) -> Void

    @State private var appeared = false

    private var iconName: String {
        SlotRenderer.sfSymbolName(for: slot.icon ?? "arrow.right.circle.fill")
    }

    private var title: String {
        slot.label ?? ""
    }

    private var matchingAction: ActionDefinition? {
        actions.first { $0.triggerSlotId == slot.id }
    }

    var body: some View {
        Button {
            if let action = matchingAction {
                onAction(action)
            }
        } label: {
            cardContent
        }
        .buttonStyle(.plain)
        .disabled(matchingAction == nil)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.9)
        .onAppear {
            withAnimation(.spring(duration: 0.35, bounce: 0.25)) {
                appeared = true
            }
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        VStack(spacing: DesignTokens.Spacing.small) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 40, height: 40)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(Circle())

            Text(title)
                .font(.caption)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.Spacing.medium)
        .padding(.horizontal, DesignTokens.Spacing.small)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.glass))
    }
}
