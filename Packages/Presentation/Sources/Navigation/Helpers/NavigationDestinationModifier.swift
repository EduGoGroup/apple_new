import SwiftUI

/// ViewModifier que configura los destinos de navegación para NavigationStack.
///
/// Mapea cada Screen a su View correspondiente de forma centralizada,
/// evitando repetir esta configuración en cada pantalla.
///
/// # Uso:
/// ```swift
/// NavigationStack(path: $coordinator.navigationPath) {
///     RootView()
/// }
/// .withNavigationDestinations()
/// ```
///
/// NOTA: Las Views reales deben implementarse en el módulo de UI.
/// Esta implementación usa placeholders para testing del sistema de navegación.
public struct NavigationDestinationModifier: ViewModifier {

    public init() {}

    public func body(content: Content) -> some View {
        content
            .navigationDestination(for: Screen.self) { screen in
                destinationView(for: screen)
            }
    }

    @ViewBuilder
    private func destinationView(for screen: Screen) -> some View {
        switch screen {
        case .login:
            PlaceholderView(title: "Login", screen: screen)
        case .dashboard:
            PlaceholderView(title: "Dashboard", screen: screen)
        case .materialList:
            PlaceholderView(title: "Material List", screen: screen)
        case .materialUpload:
            PlaceholderView(title: "Material Upload", screen: screen)
        case .materialDetail(let id):
            PlaceholderView(title: "Material Detail", screen: screen, id: id)
        case .materialAssignment(let id):
            PlaceholderView(title: "Material Assignment", screen: screen, id: id)
        case .assessment(let assessmentId, let userId):
            PlaceholderView(
                title: "Assessment",
                screen: screen,
                id: assessmentId,
                secondaryId: userId
            )
        case .assessmentResults(let id):
            PlaceholderView(title: "Assessment Results", screen: screen, id: id)
        case .userProfile:
            PlaceholderView(title: "User Profile", screen: screen)
        case .contextSwitch:
            PlaceholderView(title: "Context Switch", screen: screen)
        }
    }
}

/// View placeholder para testing del sistema de navegación.
///
/// Esta view será reemplazada por las views reales en el módulo de UI.
private struct PlaceholderView: View {
    let title: String
    let screen: Screen
    var id: UUID?
    var secondaryId: UUID?

    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Screen: \(screen.id)")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let id {
                Text("ID: \(id.uuidString)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if let secondaryId {
                Text("User ID: \(secondaryId.uuidString)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
    }
}

extension View {
    /// Aplica el modifier de destinos de navegación a la View.
    ///
    /// Debe aplicarse al NavigationStack para que funcione correctamente.
    ///
    /// - Returns: View modificada con destinos de navegación configurados
    public func withNavigationDestinations() -> some View {
        modifier(NavigationDestinationModifier())
    }
}
