import Foundation

/// Analytics - Event tracking and analytics module
///
/// Provides event tracking, user behavior analytics, and reporting.
/// TIER-4 Features module.
public struct AnalyticsEvent: Sendable {
    public let name: String
    public let properties: [String: String]
    public let timestamp: Date

    public init(name: String, properties: [String: String] = [:]) {
        self.name = name
        self.properties = properties
        self.timestamp = Date()
    }
}

public actor AnalyticsManager: Sendable {
    public static let shared = AnalyticsManager()

    private var events: [AnalyticsEvent] = []

    private init() {}

    /// Track an analytics event
    public func track(event: AnalyticsEvent) {
        events.append(event)
        // In production, this would send to analytics backend
    }

    /// Track a named event with properties
    public func track(name: String, properties: [String: String] = [:]) {
        let event = AnalyticsEvent(name: name, properties: properties)
        track(event: event)
    }

    /// Get all tracked events (for testing/debugging)
    public func getAllEvents() -> [AnalyticsEvent] {
        events
    }

    /// Clear all events
    public func clearEvents() {
        events.removeAll()
    }
}
