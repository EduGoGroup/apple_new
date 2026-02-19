import SwiftUI
import EduDynamicUI
import EduPresentation
import EduModels

struct ZoneRenderer: View {
    let zone: Zone
    let data: [String: EduModels.JSONValue]?
    let slotData: [String: EduModels.JSONValue]?
    let actions: [ActionDefinition]
    let onAction: (ActionDefinition) -> Void

    var body: some View {
        layoutContent
    }

    @ViewBuilder
    private var layoutContent: some View {
        switch zone.distribution ?? .stacked {
        case .stacked:
            VStack(spacing: 12) { children }
        case .sideBySide:
            HStack(spacing: 12) { children }
        case .grid:
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 12
            ) { children }
        case .flowRow:
            HStack(spacing: 8) { children }
        }
    }

    @ViewBuilder
    private var children: some View {
        if let childZones = zone.zones {
            ForEach(childZones) { childZone in
                ZoneRenderer(
                    zone: childZone,
                    data: data,
                    slotData: slotData,
                    actions: actions,
                    onAction: onAction
                )
            }
        }

        if let slots = zone.slots {
            ForEach(slots) { slot in
                SlotRenderer(
                    slot: slot,
                    data: data,
                    slotData: slotData,
                    actions: actions,
                    onAction: onAction
                )
            }
        }
    }
}
