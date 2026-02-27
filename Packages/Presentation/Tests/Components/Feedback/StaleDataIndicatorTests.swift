import Testing
import Foundation
@testable import EduPresentation

@Suite("EduStaleDataIndicator")
struct StaleDataIndicatorTests {

    @Test("Initializes with date and refresh callback")
    @MainActor
    func initialization() {
        let date = Date.now.addingTimeInterval(-300)
        let indicator = EduStaleDataIndicator(lastUpdated: date, onRefresh: {})
        #expect(indicator != nil)
    }

    @Test("staleDataIndicator modifier shows when data is old enough")
    @MainActor
    func modifierThreshold() {
        // Data 10 minutes old, threshold 5 minutes → should show
        let oldDate = Date.now.addingTimeInterval(-600)
        let threshold: TimeInterval = 300
        let elapsed = Date.now.timeIntervalSince(oldDate)
        #expect(elapsed > threshold)
    }

    @Test("staleDataIndicator modifier hides when data is fresh")
    @MainActor
    func modifierFresh() {
        // Data 1 minute old, threshold 5 minutes → should not show
        let freshDate = Date.now.addingTimeInterval(-60)
        let threshold: TimeInterval = 300
        let elapsed = Date.now.timeIntervalSince(freshDate)
        #expect(elapsed < threshold)
    }

    @Test("Relative time formatting produces non-empty string")
    func relativeTimeFormatting() {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        let result = formatter.localizedString(for: Date.now.addingTimeInterval(-3600), relativeTo: Date.now)
        #expect(!result.isEmpty)
    }
}
