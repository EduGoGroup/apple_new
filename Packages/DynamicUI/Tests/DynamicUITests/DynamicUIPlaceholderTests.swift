import Testing
@testable import EduDynamicUI

@Test func dynamicUIModuleLoads() {
    // Placeholder test to verify module compiles
    let pattern = ScreenPattern.login
    #expect(pattern.rawValue == "login")
}
