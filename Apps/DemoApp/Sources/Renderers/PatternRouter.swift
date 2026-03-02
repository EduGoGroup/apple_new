import SwiftUI
import EduDynamicUI
import EduPresentation
import EduModels

struct PatternRouter: View {
    let screen: ScreenDefinition
    let viewModel: DynamicScreenViewModel

    var body: some View {
        switch screen.pattern {
        case .login:
            FallbackRenderer(patternName: "login")

        case .list:
            ListPatternRenderer(
                screen: screen,
                viewModel: viewModel
            )

        case .form:
            FormPatternRenderer(
                screen: screen,
                viewModel: viewModel
            )

        case .detail:
            DetailPatternRenderer(
                screen: screen,
                viewModel: viewModel
            )

        case .dashboard:
            DashboardPatternRenderer(
                screen: screen,
                viewModel: viewModel
            )

        case .settings:
            SettingsPatternRenderer(
                screen: screen,
                viewModel: viewModel
            )

        case .search:
            ListPatternRenderer(
                screen: screen,
                viewModel: viewModel
            )

        case .profile:
            DetailPatternRenderer(
                screen: screen,
                viewModel: viewModel
            )

        case .modal:
            FallbackRenderer(patternName: "modal")

        case .notification:
            FallbackRenderer(patternName: "notification")

        case .onboarding:
            FallbackRenderer(patternName: "onboarding")

        case .emptyState:
            EduEmptyStateView(
                icon: "tray",
                title: screen.slotData?["title"]?.stringRepresentation ?? "Sin contenido",
                description: screen.slotData?["description"]?.stringRepresentation ?? ""
            )
        
        case .unknown(let rawValue):
            FallbackRenderer(patternName: rawValue)
        }
    }
}
