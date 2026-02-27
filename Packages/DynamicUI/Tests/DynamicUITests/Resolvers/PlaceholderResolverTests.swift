import Testing
import Foundation
import EduModels
@testable import EduDynamicUI

@Suite("PlaceholderResolver Tests")
struct PlaceholderResolverTests {

    // MARK: - Fixtures

    private func makeResolver() -> PlaceholderResolver {
        let userInfo = UserPlaceholderInfo(
            firstName: "Maria",
            lastName: "Garcia",
            email: "maria@edu.com",
            fullName: "Maria Garcia"
        )
        let contextInfo = ContextPlaceholderInfo(
            roleName: "Docente",
            schoolName: "Escuela Central",
            academicUnitName: "Matematicas"
        )
        return PlaceholderResolver(userInfo: userInfo, contextInfo: contextInfo)
    }

    // MARK: - User Placeholder Tests

    @Test("Resolves user.firstName placeholder")
    func resolveFirstName() {
        let resolver = makeResolver()
        let result = resolver.resolve("Hola {user.firstName}")
        #expect(result == "Hola Maria")
    }

    @Test("Resolves user.lastName placeholder")
    func resolveLastName() {
        let resolver = makeResolver()
        let result = resolver.resolve("Apellido: {user.lastName}")
        #expect(result == "Apellido: Garcia")
    }

    @Test("Resolves user.email placeholder")
    func resolveEmail() {
        let resolver = makeResolver()
        let result = resolver.resolve("Email: {user.email}")
        #expect(result == "Email: maria@edu.com")
    }

    @Test("Resolves user.fullName placeholder")
    func resolveFullName() {
        let resolver = makeResolver()
        let result = resolver.resolve("Bienvenida {user.fullName}")
        #expect(result == "Bienvenida Maria Garcia")
    }

    // MARK: - Context Placeholder Tests

    @Test("Resolves context.roleName placeholder")
    func resolveRoleName() {
        let resolver = makeResolver()
        let result = resolver.resolve("Rol: {context.roleName}")
        #expect(result == "Rol: Docente")
    }

    @Test("Resolves context.schoolName placeholder")
    func resolveSchoolName() {
        let resolver = makeResolver()
        let result = resolver.resolve("{context.schoolName}")
        #expect(result == "Escuela Central")
    }

    @Test("Resolves context.academicUnitName placeholder")
    func resolveAcademicUnitName() {
        let resolver = makeResolver()
        let result = resolver.resolve("Unidad: {context.academicUnitName}")
        #expect(result == "Unidad: Matematicas")
    }

    @Test("Nil context values resolve to empty string")
    func nilContextResolvesToEmpty() {
        let userInfo = UserPlaceholderInfo(
            firstName: "Test", lastName: "User", email: "t@t.com", fullName: "Test User"
        )
        let contextInfo = ContextPlaceholderInfo(roleName: "Admin")
        let resolver = PlaceholderResolver(userInfo: userInfo, contextInfo: contextInfo)

        let result = resolver.resolve("School: {context.schoolName}")
        #expect(result == "School: ")
    }

    // MARK: - Date Placeholder Tests

    @Test("Resolves current_year placeholder")
    func resolveCurrentYear() {
        let resolver = makeResolver()
        let result = resolver.resolve("Anio: {current_year}")
        let expectedYear = String(Calendar.current.component(.year, from: Date()))
        #expect(result == "Anio: \(expectedYear)")
    }

    @Test("Resolves today_date placeholder")
    func resolveTodayDate() {
        let resolver = makeResolver()
        let result = resolver.resolve("Fecha: {today_date}")
        // Just verify it doesn't contain the placeholder anymore
        #expect(!result.contains("{today_date}"))
        #expect(result.hasPrefix("Fecha: "))
    }

    // MARK: - Item Data Placeholder Tests

    @Test("Resolves item data placeholders")
    func resolveItemData() {
        let resolver = makeResolver()
        let itemData: [String: JSONValue] = [
            "title": .string("Algebra"),
            "students": .integer(30)
        ]
        let result = resolver.resolve(
            "Curso: {item.title} ({item.students} alumnos)",
            itemData: itemData
        )
        #expect(result == "Curso: Algebra (30 alumnos)")
    }

    @Test("Item boolean values resolve correctly")
    func resolveItemBooleans() {
        let resolver = makeResolver()
        let itemData: [String: JSONValue] = ["active": .bool(true)]
        let result = resolver.resolve("Activo: {item.active}", itemData: itemData)
        #expect(result == "Activo: true")
    }

    // MARK: - Multiple Placeholders

    @Test("Resolves multiple placeholders in a single string")
    func resolveMultiple() {
        let resolver = makeResolver()
        let result = resolver.resolve(
            "Hola {user.firstName} {user.lastName}, tu rol es {context.roleName}"
        )
        #expect(result == "Hola Maria Garcia, tu rol es Docente")
    }

    @Test("String without placeholders remains unchanged")
    func noPlaceholders() {
        let resolver = makeResolver()
        let result = resolver.resolve("Texto sin placeholders")
        #expect(result == "Texto sin placeholders")
    }
}
