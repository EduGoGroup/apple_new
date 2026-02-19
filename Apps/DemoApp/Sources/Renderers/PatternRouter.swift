import SwiftUI
import EduDynamicUI
import EduPresentation
import EduModels

struct PatternRouter: View {
    let screen: ScreenDefinition
    let data: [String: EduModels.JSONValue]?
    let items: [[String: EduModels.JSONValue]]
    let onAction: (ActionDefinition) -> Void

    var body: some View {
        switch screen.pattern {
        case .dashboard:
            DashboardPatternRenderer(
                screen: screen,
                data: data,
                onAction: onAction
            )
        case .list:
            ListPatternRenderer(
                screen: screen,
                items: items,
                onAction: onAction
            )
        default:
            FallbackRenderer(patternName: screen.pattern.rawValue)
        }
    }
}
