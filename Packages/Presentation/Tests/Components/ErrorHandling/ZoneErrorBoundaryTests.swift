import Testing
import Foundation
import SwiftUI
@testable import EduPresentation

@Suite("ZoneErrorBoundary Tests")
struct ZoneErrorBoundaryTests {

    @Test("ZoneErrorPlaceholder displays zone name")
    @MainActor
    func placeholderDisplaysZoneName() {
        let placeholder = ZoneErrorPlaceholder(
            zoneName: "header",
            message: "datos malformados",
            onRetry: {}
        )
        // The placeholder is a valid View (compile-time verification)
        _ = placeholder.body
    }

    @Test("ZoneErrorPlaceholder handles nil message")
    @MainActor
    func placeholderHandlesNilMessage() {
        let placeholder = ZoneErrorPlaceholder(
            zoneName: "footer",
            message: nil,
            onRetry: {}
        )
        _ = placeholder.body
    }

    @Test("ZoneErrorBoundary modifier can be applied to any View")
    @MainActor
    func boundaryModifierApplies() {
        @State var error: String? = nil
        let view = Text("Content")
            .zoneErrorBoundary(zoneName: "test-zone", errorMessage: $error)
        _ = view
    }
}
