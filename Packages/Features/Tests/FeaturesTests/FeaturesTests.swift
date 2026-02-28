import Foundation
import Testing
@testable import EduFeatures

@Suite
struct FeaturesTests {
    @Test func featuresModuleLoads() {
        #expect(EduFeatures.version == "2.0.0")
    }

    @Test func aiPromptCreation() {
        let prompt = AIPrompt(text: "Explain photosynthesis", context: ["level": "beginner"])
        #expect(prompt.text == "Explain photosynthesis")
        #expect(prompt.context["level"] == "beginner")
    }

    @Test func analyticsEventHasTimestamp() {
        let event = AnalyticsEvent(name: "lesson_started", properties: ["subject": "math"])
        #expect(event.name == "lesson_started")
        #expect(event.properties["subject"] == "math")
        #expect(event.timestamp <= Date())
    }
}
