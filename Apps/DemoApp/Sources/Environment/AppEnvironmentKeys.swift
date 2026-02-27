import SwiftUI
import EduDomain

// MARK: - Network Online Status

private struct IsOnlineKey: EnvironmentKey {
    static let defaultValue: Bool = true
}

extension EnvironmentValues {
    var isOnline: Bool {
        get { self[IsOnlineKey.self] }
        set { self[IsOnlineKey.self] = newValue }
    }
}

// MARK: - EventOrchestrator

private struct EventOrchestratorKey: EnvironmentKey {
    static let defaultValue: EventOrchestrator? = nil
}

extension EnvironmentValues {
    var eventOrchestrator: EventOrchestrator? {
        get { self[EventOrchestratorKey.self] }
        set { self[EventOrchestratorKey.self] = newValue }
    }
}

// Note: ToastManager and GlossaryProvider are @Observable @MainActor classes.
// They are injected via `.environment(object)` in DemoApp.swift and read in
// views with `@Environment(ToastManager.self)` / `@Environment(GlossaryProvider.self)`.
