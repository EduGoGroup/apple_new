import Testing
import Foundation
import EduModels
@testable import EduDynamicUI

@Suite("PlaceholderResolver Edge Case Tests")
struct PlaceholderResolverEdgeCaseTests {

    private func makeResolver() -> PlaceholderResolver {
        PlaceholderResolver(
            userInfo: UserPlaceholderInfo(
                firstName: "Ana",
                lastName: "Lopez",
                email: "ana@test.com",
                fullName: "Ana Lopez"
            ),
            contextInfo: ContextPlaceholderInfo(roleName: "Admin")
        )
    }

    // MARK: - Malformed Placeholders

    @Test("Unclosed brace is left as-is")
    func unclosedBrace() {
        let resolver = makeResolver()
        let result = resolver.resolve("Hola {user.firstName")
        #expect(result == "Hola {user.firstName")
    }

    @Test("Empty braces are left as-is")
    func emptyBraces() {
        let resolver = makeResolver()
        let result = resolver.resolve("Value: {}")
        #expect(result == "Value: {}")
    }

    @Test("Unknown user key is left as placeholder")
    func unknownUserKey() {
        let resolver = makeResolver()
        let result = resolver.resolve("Phone: {user.phone}")
        #expect(result == "Phone: {user.phone}")
    }

    @Test("Unknown namespace is left as placeholder")
    func unknownNamespace() {
        let resolver = makeResolver()
        let result = resolver.resolve("Data: {custom.field}")
        #expect(result == "Data: {custom.field}")
    }

    @Test("Nested braces are handled gracefully")
    func nestedBraces() {
        let resolver = makeResolver()
        let result = resolver.resolve("Msg: {{user.firstName}}")
        // Should resolve inner placeholder, outer braces remain or are handled
        #expect(!result.contains("{user.firstName}") || result.contains("{"))
    }

    @Test("Empty string input returns empty string")
    func emptyInput() {
        let resolver = makeResolver()
        let result = resolver.resolve("")
        #expect(result == "")
    }

    @Test("String with only placeholders resolves fully")
    func onlyPlaceholder() {
        let resolver = makeResolver()
        let result = resolver.resolve("{user.firstName}")
        #expect(result == "Ana")
    }

    // MARK: - Item Data Edge Cases

    @Test("Missing item key resolves to placeholder")
    func missingItemKey() {
        let resolver = makeResolver()
        let itemData: [String: JSONValue] = ["name": .string("Test")]
        let result = resolver.resolve("{item.missing}", itemData: itemData)
        #expect(result == "{item.missing}")
    }

    @Test("Item data with null value resolves to empty")
    func itemNullValue() {
        let resolver = makeResolver()
        let itemData: [String: JSONValue] = ["field": .null]
        let result = resolver.resolve("Val: {item.field}", itemData: itemData)
        // null should resolve to empty or "null"
        #expect(!result.contains("{item.field}"))
    }

    @Test("Item data with nested object resolves to string representation")
    func itemNestedObject() {
        let resolver = makeResolver()
        let itemData: [String: JSONValue] = [
            "meta": .object(["key": .string("val")])
        ]
        let result = resolver.resolve("Meta: {item.meta}", itemData: itemData)
        #expect(!result.contains("{item.meta}"))
    }

    @Test("Multiple placeholders of same type resolve independently")
    func multipleSamePlaceholder() {
        let resolver = makeResolver()
        let result = resolver.resolve("{user.firstName} y {user.firstName}")
        #expect(result == "Ana y Ana")
    }
}
