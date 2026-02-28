import Testing
@testable import EduDomain
import EduFoundation
import EduCore

@Suite
struct DomainTests {

    @Test func domainModuleLoads() {
        #expect(EduDomain.version == "2.0.0")
    }

    @Test func materialTypeAvailable() {
        let videoType = MaterialType.video
        #expect(videoType.rawValue == "video")
    }

    @Test func systemRoleAvailable() {
        let adminRole = SystemRole.admin
        #expect(adminRole == .admin)
    }

    @Test func takeAssessmentFlowStateAvailable() {
        let idle = TakeAssessmentFlowState.idle
        #expect(idle.rawValue == "idle")
    }
}
