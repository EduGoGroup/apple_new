// ServerStringResolverTests.swift
// EduDomainTests

import Testing
import Foundation
@testable import EduDomain
import EduCore

@Suite("ServerStringResolver Tests")
struct ServerStringResolverTests {

    @Test @MainActor
    func resolvesServerString() {
        let resolver = ServerStringResolver()
        let bundle = UserDataBundle(
            menu: [],
            permissions: [],
            screens: [:],
            availableContexts: [],
            hashes: [:],
            glossary: [:],
            strings: ["welcome.title": "Bienvenido"]
        )
        resolver.updateFromBundle(bundle)
        #expect(resolver.resolve(key: "welcome.title", fallback: "Welcome") == "Bienvenido")
    }

    @Test @MainActor
    func returnsFallbackWhenMissing() {
        let resolver = ServerStringResolver()
        #expect(resolver.resolve(key: "missing.key", fallback: "Default") == "Default")
    }

    @Test @MainActor
    func updatesFromBundle() {
        let resolver = ServerStringResolver()

        let bundle1 = UserDataBundle(
            menu: [],
            permissions: [],
            screens: [:],
            availableContexts: [],
            hashes: [:],
            glossary: [:],
            strings: ["key1": "Value1"]
        )
        resolver.updateFromBundle(bundle1)
        #expect(resolver.resolve(key: "key1", fallback: "fallback") == "Value1")

        let bundle2 = UserDataBundle(
            menu: [],
            permissions: [],
            screens: [:],
            availableContexts: [],
            hashes: [:],
            glossary: [:],
            strings: ["key2": "Value2"]
        )
        resolver.updateFromBundle(bundle2)
        #expect(resolver.resolve(key: "key1", fallback: "fallback") == "fallback")
        #expect(resolver.resolve(key: "key2", fallback: "fallback") == "Value2")
    }
}
