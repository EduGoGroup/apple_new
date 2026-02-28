import Testing
@testable import EduPresentation

@Suite
struct PresentationTests {
    @Test func presentationModuleLoads() {
        #expect(EduPresentation.version == "2.0.0")
    }
}
