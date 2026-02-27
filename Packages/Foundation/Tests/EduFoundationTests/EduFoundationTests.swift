import Testing
@testable import EduFoundation

@Suite("EduFoundation Tests")
struct EduFoundationTests {
    @Test("Module version is defined")
    func testModuleVersion() {
        #expect(EduFoundation.version == "1.0.0")
    }
}
