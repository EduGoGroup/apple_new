import Testing
import Foundation
@testable import EduFeatures

@Suite("AI Tests")
struct AITests {
    @Test("AIService shared instance is accessible")
    func testSharedInstance() {
        let ai = AIService.shared
        // AI should be accessible
    }

    @Test("Generate AI response")
    func testGenerate() async throws {
        let ai = AIService.shared
        let prompt = AIPrompt(text: "What is Swift?", context: [:])

        let response = try await ai.generate(prompt: prompt)

        #expect(response.confidence > 0.0)
        #expect(response.confidence <= 1.0)
        #expect(!response.text.isEmpty)
    }

    @Test("Get recommendations")
    func testRecommendations() async throws {
        let ai = AIService.shared

        let recommendations = try await ai.getRecommendations(
            userId: "test_user",
            category: "courses"
        )

        #expect(recommendations.count > 0)
    }
}
