// PlaceholderGlossaryTests.swift
// DynamicUITests

import Testing
import Foundation
@testable import EduDynamicUI
import EduModels

@Suite("PlaceholderResolver Glossary Tests")
struct PlaceholderGlossaryTests {

    private func makeResolver(glossary: [String: String] = [:]) -> PlaceholderResolver {
        PlaceholderResolver(
            userInfo: UserPlaceholderInfo(
                firstName: "Juan",
                lastName: "Pérez",
                email: "juan@test.com",
                fullName: "Juan Pérez"
            ),
            contextInfo: ContextPlaceholderInfo(roleName: "Docente"),
            glossaryData: glossary
        )
    }

    @Test
    func resolvesGlossaryPlaceholder() {
        let resolver = makeResolver(glossary: ["member.student": "Alumno"])
        let result = resolver.resolve("Listado de {glossary.member.student}")
        #expect(result == "Listado de Alumno")
    }

    @Test
    func handlesUnknownGlossaryKey() {
        let resolver = makeResolver(glossary: [:])
        let result = resolver.resolve("Ver {glossary.unknown.key}")
        #expect(result == "Ver {glossary.unknown.key}")
    }

    @Test
    func resolvesMultipleGlossaryPlaceholders() {
        let resolver = makeResolver(glossary: [
            "member.student": "Alumno",
            "org.name_singular": "Colegio"
        ])
        let result = resolver.resolve("{glossary.member.student} de {glossary.org.name_singular}")
        #expect(result == "Alumno de Colegio")
    }

    @Test
    func backwardCompatibleWithoutGlossary() {
        let resolver = PlaceholderResolver(
            userInfo: UserPlaceholderInfo(
                firstName: "Ana",
                lastName: "López",
                email: "ana@test.com",
                fullName: "Ana López"
            ),
            contextInfo: ContextPlaceholderInfo(roleName: "Admin")
        )
        let result = resolver.resolve("Hola {user.firstName}")
        #expect(result == "Hola Ana")
    }
}
