import SwiftUI
import EduDynamicUI
import EduPresentation
import EduModels

struct SettingsPatternRenderer: View {
    let screen: ScreenDefinition
    @Bindable var viewModel: DynamicScreenViewModel

    private var title: String {
        if let pageTitle = screen.slotData?["page_title"] {
            return pageTitle.stringRepresentation
        }
        return screen.template.navigation?.topBar?.title ?? screen.screenName
    }

    var body: some View {
        Form {
            ForEach(screen.template.zones) { zone in
                settingsZone(zone)
            }

            Section {
                Button(role: .destructive) {
                    viewModel.onLogout?()
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Cerrar sesión")
                    }
                }
            }

            Section {
                HStack {
                    Text("Versión")
                    Spacer()
                    Text(appVersion)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(title)
    }

    @ViewBuilder
    private func settingsZone(_ zone: Zone) -> some View {
        Section {
            if let childZones = zone.zones {
                ForEach(childZones) { childZone in
                    settingsZoneContent(childZone)
                }
            }
            if let slots = zone.slots {
                ForEach(slots) { slot in
                    settingsSlot(slot)
                }
            }
        } header: {
            if let labelSlot = zone.slots?.first(where: { $0.controlType == .label }),
               let headerText = labelSlot.label {
                Text(headerText)
            }
        }
    }

    @ViewBuilder
    private func settingsZoneContent(_ zone: Zone) -> some View {
        if let slots = zone.slots {
            ForEach(slots) { slot in
                settingsSlot(slot)
            }
        }
    }

    @ViewBuilder
    private func settingsSlot(_ slot: Slot) -> some View {
        switch slot.controlType {
        case .switch, .checkbox:
            SlotRenderer(
                slot: slot,
                data: nil,
                slotData: screen.slotData,
                actions: screen.actions,
                fieldValues: $viewModel.fieldValues,
                onAction: { viewModel.executeAction($0) },
                onEvent: { eventId in
                    Task { await viewModel.executeCustomEvent(eventId) }
                }
            )

        case .listItemNavigation:
            let resolver = SlotBindingResolver()
            let resolved = resolver.resolve(slot: slot, data: nil, slotData: screen.slotData)
            ListItemNavigationControl(
                slot: slot,
                resolvedValue: resolved,
                actions: screen.actions,
                onAction: { viewModel.executeAction($0) }
            )

        case .select:
            SlotRenderer(
                slot: slot,
                data: nil,
                slotData: screen.slotData,
                actions: screen.actions,
                fieldValues: $viewModel.fieldValues,
                onAction: { viewModel.executeAction($0) }
            )

        case .label:
            if slot.style != "headline" && slot.style != "title" {
                let resolver = SlotBindingResolver()
                let resolved = resolver.resolve(slot: slot, data: nil, slotData: screen.slotData)
                LabelControl(slot: slot, resolvedValue: resolved)
            }

        case .filledButton, .outlinedButton, .textButton:
            ButtonControl(
                slot: slot,
                actions: screen.actions,
                onAction: { viewModel.executeAction($0) },
                onEvent: { eventId in
                    Task { await viewModel.executeCustomEvent(eventId) }
                }
            )

        default:
            SlotRenderer(
                slot: slot,
                data: nil,
                slotData: screen.slotData,
                actions: screen.actions,
                onAction: { viewModel.executeAction($0) }
            )
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}
