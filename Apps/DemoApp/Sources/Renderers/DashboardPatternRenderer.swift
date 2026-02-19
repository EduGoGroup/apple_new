import SwiftUI
import EduDynamicUI
import EduPresentation
import EduModels

struct DashboardPatternRenderer: View {
    let screen: ScreenDefinition
    let data: [String: EduModels.JSONValue]?
    let onAction: (ActionDefinition) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(screen.template.zones) { zone in
                    ZoneRenderer(
                        zone: zone,
                        data: data,
                        slotData: screen.slotData,
                        actions: screen.actions,
                        onAction: onAction
                    )
                }
            }
            .padding()
        }
    }
}
