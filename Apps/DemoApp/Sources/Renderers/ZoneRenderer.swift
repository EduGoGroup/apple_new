import SwiftUI
import EduDynamicUI
import EduPresentation
import EduModels

struct ZoneRenderer: View {
    let zone: Zone
    let data: [String: EduModels.JSONValue]?
    let slotData: [String: EduModels.JSONValue]?
    let actions: [ActionDefinition]
    var fieldValues: Binding<[String: String]>?
    let onAction: (ActionDefinition) -> Void
    var onEvent: ((String) -> Void)? = nil

    var body: some View {
        zoneContent
    }

    @ViewBuilder
    private var zoneContent: some View {
        switch zone.type {
        case .formSection:
            Section {
                layoutContent
            } header: {
                if let firstLabel = zone.slots?.first(where: { $0.controlType == .label }) {
                    Text(firstLabel.label ?? "")
                        .font(.headline)
                }
            }

        case .actionGroup:
            HStack(spacing: 12) {
                actionGroupChildren
            }

        case .simpleList:
            LazyVStack(spacing: 0) {
                children
            }

        case .metricGrid:
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 12
            ) {
                children
            }

        case .cardList:
            LazyVStack(spacing: 12) {
                children
            }

        case .groupedList:
            List {
                children
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #else
            .listStyle(.inset)
            #endif

        case .container:
            layoutContent
        }
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
                    fieldValues: fieldValues,
                    onAction: onAction,
                    onEvent: onEvent
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
                    fieldValues: fieldValues,
                    onAction: onAction,
                    onEvent: onEvent
                )
            }
        }
    }

    @ViewBuilder
    private var actionGroupChildren: some View {
        if let slots = zone.slots {
            ForEach(slots) { slot in
                SlotRenderer(
                    slot: slot,
                    data: data,
                    slotData: slotData,
                    actions: actions,
                    onAction: onAction,
                    onEvent: onEvent
                )
            }
        }
    }
}
