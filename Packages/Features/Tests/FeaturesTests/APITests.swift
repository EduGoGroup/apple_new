import Testing
import Foundation
@testable import EduFeatures

@Suite("API Tests")
struct APITests {
    @Test("APIClient shared instance is accessible")
    func testSharedInstance() {
        let api = APIClient.shared
        // API should be accessible
    }
}
