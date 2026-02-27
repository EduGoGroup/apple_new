import SwiftUI
import EduDynamicUI
import EduPresentation
import EduModels

struct MetricCardControl: View {
    let slot: Slot
    let resolvedValue: JSONValue?
    var data: [String: JSONValue]? = nil
    var actions: [ActionDefinition] = []
    var onAction: ((ActionDefinition) -> Void)? = nil

    @State private var appeared = false

    private var displayValue: String {
        resolvedValue?.stringRepresentation ?? "0"
    }

    private var title: String {
        slot.label ?? ""
    }

    private var iconName: String {
        SlotRenderer.sfSymbolName(for: slot.icon ?? "chart.bar.fill")
    }

    private var trend: Double? {
        guard let data else { return nil }
        if let field = slot.field {
            let trendKey = "\(field)_trend"
            if let trendVal = data[trendKey] {
                switch trendVal {
                case .double(let d): return d
                case .integer(let i): return Double(i)
                default: return nil
                }
            }
        }
        return nil
    }

    private var matchingAction: ActionDefinition? {
        actions.first { $0.triggerSlotId == slot.id }
    }

    var body: some View {
        Button {
            if let action = matchingAction {
                onAction?(action)
            }
        } label: {
            cardContent
        }
        .buttonStyle(.plain)
        .disabled(matchingAction == nil)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.92)
        .onAppear {
            withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
                appeared = true
            }
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            HStack {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                Spacer()

                if let trend {
                    trendIndicator(trend)
                }
            }

            Text(displayValue)
                .font(.largeTitle.bold())
                .foregroundStyle(.primary)
                .contentTransition(.numericText())

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.glass))
    }

    @ViewBuilder
    private func trendIndicator(_ value: Double) -> some View {
        HStack(spacing: 4) {
            Image(systemName: value >= 0 ? "arrow.up.right" : "arrow.down.right")
                .font(.caption)
            Text(String(format: "%.1f%%", abs(value)))
                .font(.caption)
        }
        .foregroundStyle(value >= 0 ? .green : .red)
        .padding(.horizontal, DesignTokens.Spacing.small)
        .padding(.vertical, DesignTokens.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                .fill((value >= 0 ? Color.green : Color.red).opacity(0.1))
        )
    }
}
