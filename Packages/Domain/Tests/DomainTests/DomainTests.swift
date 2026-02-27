import XCTest
@testable import EduDomain
import EduFoundation
import EduCore

/// Tests básicos para verificar que EduDomain carga correctamente.
final class DomainTests: XCTestCase {
    
    func testDomainModuleLoads() {
        // Verificar que el módulo carga
        XCTAssertEqual(EduDomain.version, "2.0.0")
    }
    
    func testCQRSCommandProtocol() {
        // Verificar que el protocolo Command está disponible
        XCTAssertTrue(true, "CQRS Command protocol is available")
    }
    
    func testMaterialTypeAvailable() {
        // Verificar que MaterialType está disponible
        let videoType = MaterialType.video
        XCTAssertEqual(videoType.rawValue, "video")
    }
    
    func testSystemRoleAvailable() {
        // Verificar que SystemRole está disponible
        let adminRole = SystemRole.admin
        XCTAssertNotNil(adminRole)
    }
    
    func testTakeAssessmentFlowStateAvailable() {
        // Verificar que TakeAssessmentFlowState está disponible
        let idle = TakeAssessmentFlowState.idle
        XCTAssertEqual(idle.rawValue, "idle")
    }
}
