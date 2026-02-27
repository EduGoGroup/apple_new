import Testing
import Foundation
@testable import EduFeatures

@Suite("Analytics Tests")
struct AnalyticsTests {
    @Test("AnalyticsManager shared instance is accessible")
    func testSharedInstance() {
        let analytics = AnalyticsManager.shared
        // Analytics should be accessible
    }

    @Test("Track event adds to events list")
    func testTrackEvent() async {
        let analytics = AnalyticsManager.shared
        await analytics.clearEvents()

        await analytics.track(name: "test_event", properties: ["key": "value"])

        let events = await analytics.getAllEvents()
        #expect(events.count == 1)
        #expect(events.first?.name == "test_event")

        await analytics.clearEvents()
    }
}
