import Testing
import Foundation
@testable import EduNetwork

@Suite("Network Tests")
struct NetworkTests {
    @Test("NetworkClient shared instance is accessible")
    func testSharedInstance() {
        _ = NetworkClient.shared
        // Client should be accessible
    }

    @Test("HTTPMethod raw values")
    func testHTTPMethods() {
        #expect(HTTPMethod.get.rawValue == "GET")
        #expect(HTTPMethod.post.rawValue == "POST")
        #expect(HTTPMethod.put.rawValue == "PUT")
        #expect(HTTPMethod.delete.rawValue == "DELETE")
        #expect(HTTPMethod.patch.rawValue == "PATCH")
    }
}
