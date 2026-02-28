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
    var selectOptions: [String: SelectOptionsState]? = nil
    var onLoadSelectOptions: ((String, String, String, String) async -> Void)? = nil

    @State private var zoneError: String?

    var body: some View {
        zoneContent
            .zoneErrorBoundary(zoneName: zone.id, errorMessage: $zoneError)
            .onAppear {
                zoneError = Self.validateZone(zone, data: data)
            }
    }

    /// Pre-validates zone data integrity before rendering.
    /// Returns nil if valid, or an error message describing the issue.
    static func validateZone(_ zone: Zone, data: [String: EduModels.JSONValue]?) -> String? {
        // Zone must have either slots or child zones
        let hasSlots = zone.slots != nil && !(zone.slots!.isEmpty)
        let hasChildZones = zone.zones != nil && !(zone.zones!.isEmpty)
        let hasItemLayout = zone.itemLayout != nil

        if !hasSlots && !hasChildZones && !hasItemLayout {
            return "Zona sin contenido (sin slots ni zonas hijas)"
        }

        // Validate slots have known control types (already enforced by Codable, but check for empty IDs)
        if let slots = zone.slots {
            for slot in slots {
                if slot.id.isEmpty {
                    return "Slot con ID vacío detectado"
                }
            }
        }

        return nil
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
                    onEvent: onEvent,
                    selectOptions: selectOptions,
                    onLoadSelectOptions: onLoadSelectOptions
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
                    onEvent: onEvent,
                    selectOptions: selectOptions,
                    onLoadSelectOptions: onLoadSelectOptions
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
                    onEvent: onEvent,
                    selectOptions: selectOptions,
                    onLoadSelectOptions: onLoadSelectOptions
                )
            }
        }
    }
}
