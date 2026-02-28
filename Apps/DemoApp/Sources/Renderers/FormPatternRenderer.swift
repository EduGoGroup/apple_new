import SwiftUI
import EduDynamicUI
import EduPresentation
import EduModels

struct FormPatternRenderer: View {
    let screen: ScreenDefinition
    @Bindable var viewModel: DynamicScreenViewModel

    @Environment(\.dismiss) private var dismiss

    private var isEditing: Bool {
        if case .success(let items, _, _) = viewModel.dataState, !items.isEmpty {
            return true
        }
        return false
    }

    private var title: String {
        if isEditing, let editTitle = screen.slotData?["edit_title"] {
            return editTitle.stringRepresentation
        }
        if let pageTitle = screen.slotData?["page_title"] {
            return pageTitle.stringRepresentation
        }
        return screen.template.navigation?.topBar?.title ?? screen.screenName
    }

    var body: some View {
        formContent
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(EduStrings.cancel) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(EduStrings.save) { save() }
                    .fontWeight(.semibold)
            }
        }
        .onAppear { prepopulateFields() }
    }

    @ViewBuilder
    private var formContent: some View {
        switch viewModel.dataState {
        case .loading:
            EduFormSkeleton()
                .padding()
        default:
            Form {
                ForEach(screen.template.zones) { zone in
                    FormZoneSection(
                        zone: zone,
                        screen: screen,
                        viewModel: viewModel
                    )
                }
            }
            .formStyle(.grouped)
        }
    }

    // MARK: - Validation

    private func save() {
        viewModel.fieldErrors = [:]
        var hasErrors = false
        for zone in screen.template.zones {
            FormPatternRenderer.validateZone(zone, viewModel: viewModel, hasErrors: &hasErrors)
        }
        if !hasErrors {
            Task {
                await viewModel.executeEvent(isEditing ? .saveExisting : .saveNew)
            }
        }
    }

    static func validateZone(_ zone: Zone, viewModel: DynamicScreenViewModel, hasErrors: inout Bool) {
        if let slots = zone.slots {
            for slot in slots where isInputControl(slot.controlType) {
                let key = slot.field ?? slot.id
                let value = viewModel.fieldValues[key] ?? ""

                if slot.required == true && value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    viewModel.fieldErrors[key] = EduStrings.fieldRequired
                    hasErrors = true
                }

                if slot.controlType == .emailInput && !value.isEmpty {
                    let emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
                    if value.wholeMatch(of: emailRegex) == nil {
                        viewModel.fieldErrors[key] = EduStrings.invalidEmail
                        hasErrors = true
                    }
                }
            }
        }
        if let childZones = zone.zones {
            for childZone in childZones {
                validateZone(childZone, viewModel: viewModel, hasErrors: &hasErrors)
            }
        }
    }

    // MARK: - Prepopulate

    private func prepopulateFields() {
        guard isEditing,
              case .success(let items, _, _) = viewModel.dataState,
              let item = items.first else { return }

        for zone in screen.template.zones {
            FormPatternRenderer.prepopulateZone(zone, from: item, viewModel: viewModel)
        }
    }

    static func prepopulateZone(
        _ zone: Zone,
        from item: [String: EduModels.JSONValue],
        viewModel: DynamicScreenViewModel
    ) {
        if let slots = zone.slots {
            for slot in slots where isInputControl(slot.controlType) {
                let key = slot.field ?? slot.id
                if let value = item[key] {
                    viewModel.fieldValues[key] = value.stringRepresentation
                }
            }
        }
        if let childZones = zone.zones {
            for childZone in childZones {
                prepopulateZone(childZone, from: item, viewModel: viewModel)
            }
        }
    }

    static func isInputControl(_ type: ControlType) -> Bool {
        switch type {
        case .textInput, .emailInput, .passwordInput, .numberInput, .searchBar,
             .select, .remoteSelect, .checkbox, .switch, .radioGroup, .chip, .rating:
            return true
        default:
            return false
        }
    }
}

// MARK: - Form Zone Section (separate struct to help type checker)

private struct FormZoneSection: View {
    let zone: Zone
    let screen: ScreenDefinition
    let viewModel: DynamicScreenViewModel

    var body: some View {
        Section {
            sectionContent
        } header: {
            sectionHeader
        }
    }

    @ViewBuilder
    private var sectionContent: some View {
        if let slots = zone.slots {
            ForEach(slots) { slot in
                FormSlotRow(
                    slot: slot,
                    screen: screen,
                    viewModel: viewModel
                )
            }
        }
        if let childZones = zone.zones {
            ForEach(childZones) { childZone in
                FormChildZoneContent(
                    zone: childZone,
                    screen: screen,
                    viewModel: viewModel
                )
            }
        }
    }

    @ViewBuilder
    private var sectionHeader: some View {
        if let labelSlot = zone.slots?.first(where: { $0.controlType == .label }),
           let headerText = labelSlot.label {
            Text(headerText)
        }
    }
}

private struct FormChildZoneContent: View {
    let zone: Zone
    let screen: ScreenDefinition
    let viewModel: DynamicScreenViewModel

    var body: some View {
        if let slots = zone.slots {
            ForEach(slots) { slot in
                FormSlotRow(
                    slot: slot,
                    screen: screen,
                    viewModel: viewModel
                )
            }
        }
    }
}

private struct FormSlotRow: View {
    let slot: Slot
    let screen: ScreenDefinition
    @Bindable var viewModel: DynamicScreenViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            SlotRenderer(
                slot: slot,
                data: nil,
                slotData: screen.slotData,
                actions: screen.actions,
                fieldValues: $viewModel.fieldValues,
                onAction: { viewModel.executeAction($0) },
                onEvent: { eventId in
                    Task { await viewModel.executeCustomEvent(eventId) }
                },
                selectOptions: viewModel.selectOptions,
                onLoadSelectOptions: { fieldKey, endpoint, labelField, valueField in
                    await viewModel.loadSelectOptions(
                        fieldKey: fieldKey,
                        endpoint: endpoint,
                        labelField: labelField,
                        valueField: valueField
                    )
                }
            )
            if let error = viewModel.fieldErrors[slot.field ?? slot.id] {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}
