// GlossaryProviderTests.swift
// EduDomainTests

import Testing
import Foundation
@testable import EduDomain
import EduCore

@Suite("GlossaryProvider Tests")
struct GlossaryProviderTests {

    @Test @MainActor
    func resolvesKnownKey() {
        let provider = GlossaryProvider()
        let term = provider.term(for: .memberStudent)
        #expect(term == "Estudiante")
    }

    @Test @MainActor
    func returnsFallbackForUnknownKey() {
        let provider = GlossaryProvider()
        let term = provider.term(for: "unknown.key")
        #expect(term == "unknown.key")
    }

    @Test @MainActor
    func updatesFromBundle() {
        let provider = GlossaryProvider()
        let bundle = UserDataBundle(
            menu: [],
            permissions: [],
            screens: [:],
            availableContexts: [],
            hashes: [:],
            glossary: ["member.student": "Alumno"],
            strings: [:]
        )
        provider.updateFromBundle(bundle)
        let term = provider.term(for: .memberStudent)
        #expect(term == "Alumno")
    }

    @Test @MainActor
    func stringKeyResolution() {
        let provider = GlossaryProvider()
        let bundle = UserDataBundle(
            menu: [],
            permissions: [],
            screens: [:],
            availableContexts: [],
            hashes: [:],
            glossary: ["custom.term": "Valor personalizado"],
            strings: [:]
        )
        provider.updateFromBundle(bundle)
        #expect(provider.term(for: "custom.term") == "Valor personalizado")
    }
}
