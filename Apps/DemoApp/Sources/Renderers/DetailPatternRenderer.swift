import SwiftUI
import EduDynamicUI
import EduPresentation
import EduModels

struct DetailPatternRenderer: View {
    let screen: ScreenDefinition
    let viewModel: DynamicScreenViewModel

    @State private var showDeleteConfirmation = false

    private var item: [String: EduModels.JSONValue]? {
        if case .success(let items, _, _) = viewModel.dataState {
            return items.first
        }
        return nil
    }

    private var title: String {
        if let pageTitle = screen.slotData?["page_title"] {
            return pageTitle.stringRepresentation
        }
        if let item, let name = item["name"] ?? item["title"] {
            return name.stringRepresentation
        }
        return screen.template.navigation?.topBar?.title ?? screen.screenName
    }

    var body: some View {
        Group {
            switch viewModel.dataState {
            case .idle, .loading:
                EduDetailSkeleton()
                    .padding()
            case .error(let message):
                EduErrorStateView(message: message) {
                    Task { await viewModel.refresh() }
                }
            case .success:
                detailContent
            }
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                editButton
                deleteButton
            }
        }
        .confirmationDialog(
            "Eliminar",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Eliminar", role: .destructive) {
                Task { await viewModel.executeEvent(.delete, selectedItem: item) }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("¿Estás seguro de que deseas eliminar este elemento?")
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(screen.template.zones) { zone in
                    DetailZoneCard(
                        zone: zone,
                        item: item,
                        screen: screen
                    )
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private var editButton: some View {
        let hasEditAction = screen.actions.contains { $0.type == .navigate }
        if hasEditAction {
            Button {
                if let action = screen.actions.first(where: { $0.type == .navigate }) {
                    viewModel.executeAction(action)
                }
            } label: {
                Image(systemName: "pencil")
            }
        }
    }

    @ViewBuilder
    private var deleteButton: some View {
        let hasDeleteAction = screen.actions.contains {
            $0.type == .apiCall && $0.id.contains("delete")
        }
        if hasDeleteAction {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Image(systemName: "trash")
            }
        }
    }
}

// MARK: - Detail Zone Card (separate struct to avoid recursive opaque type)

private struct DetailZoneCard: View {
    let zone: Zone
    let item: [String: EduModels.JSONValue]?
    let screen: ScreenDefinition

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                if let slots = zone.slots {
                    ForEach(slots) { slot in
                        DetailFieldRow(
                            slot: slot,
                            item: item,
                            slotData: screen.slotData
                        )
                    }
                }
                if let childZones = zone.zones {
                    ForEach(childZones) { childZone in
                        DetailChildContent(
                            zone: childZone,
                            item: item,
                            slotData: screen.slotData
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct DetailChildContent: View {
    let zone: Zone
    let item: [String: EduModels.JSONValue]?
    let slotData: [String: EduModels.JSONValue]?

    var body: some View {
        if let slots = zone.slots {
            ForEach(slots) { slot in
                DetailFieldRow(slot: slot, item: item, slotData: slotData)
            }
        }
    }
}

private struct DetailFieldRow: View {
    let slot: Slot
    let item: [String: EduModels.JSONValue]?
    let slotData: [String: EduModels.JSONValue]?

    private var resolved: EduModels.JSONValue? {
        SlotBindingResolver().resolve(slot: slot, data: item, slotData: slotData)
    }

    var body: some View {
        switch slot.controlType {
        case .label:
            LabelControl(slot: slot, resolvedValue: resolved)
        case .divider:
            Divider()
        case .image:
            ImageControl(slot: slot, resolvedValue: resolved)
        case .avatar:
            AvatarControl(slot: slot, resolvedValue: resolved)
        case .rating:
            HStack {
                if let label = slot.label {
                    Text(label)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                RatingDisplayControl(slot: slot, resolvedValue: resolved)
            }
        default:
            if let label = slot.label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(resolved?.stringRepresentation ?? "—")
                        .font(.body)
                }
            } else {
                Text(resolved?.stringRepresentation ?? "")
            }
        }
    }
}
