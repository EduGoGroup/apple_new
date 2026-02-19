import Testing
@testable import FoundationToolkit

@Suite("FoundationToolkit Tests")
struct FoundationToolkitTests {
    @Test("Module version is defined")
    func testModuleVersion() {
        #expect(FoundationToolkit.version == "1.0.0")
    }
}
