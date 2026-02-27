import SwiftUI
import EduDynamicUI
import EduPresentation
import EduModels

struct DashboardPatternRenderer: View {
    let screen: ScreenDefinition
    let viewModel: DynamicScreenViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(screen.template.zones) { zone in
                    ZoneRenderer(
                        zone: zone,
                        data: slotData,
                        slotData: screen.slotData,
                        actions: screen.actions,
                        onAction: { action in viewModel.executeAction(action) }
                    )
                }
            }
            .padding()
        }
    }

    private var slotData: [String: EduModels.JSONValue]? {
        if case .success(let items, _, _) = viewModel.dataState,
           let first = items.first {
            return first
        }
        return screen.slotData
    }
}
