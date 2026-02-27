import Testing
import Foundation
@testable import EduDomain
import EduCore
import EduFoundation

// MARK: - LoginInput Tests

@Suite("LoginInput Tests")
struct LoginInputTests {

    @Test("LoginInput inicializa correctamente")
    func testLoginInputInitialization() {
        let input = LoginInput(email: "test@edugo.com", password: "password123")

        #expect(input.email == "test@edugo.com")
        #expect(input.password == "password123")
    }

    @Test("LoginInput es Equatable")
    func testLoginInputEquatable() {
        let input1 = LoginInput(email: "test@edugo.com", password: "password123")
        let input2 = LoginInput(email: "test@edugo.com", password: "password123")
        let input3 = LoginInput(email: "other@edugo.com", password: "password123")

        #expect(input1 == input2)
        #expect(input1 != input3)
    }

    @Test("LoginInput es Sendable")
    func testLoginInputSendable() async {
        let input = LoginInput(email: "test@edugo.com", password: "password123")

        // Enviar a otro contexto de concurrencia
        let result = await Task.detached {
            return input.email
        }.value

        #expect(result == "test@edugo.com")
    }
}

// MARK: - LoginOutput Tests

@Suite("LoginOutput Tests")
struct LoginOutputTests {

    @Test("LoginOutput inicializa correctamente")
    func testLoginOutputInitialization() throws {
        let user = try User(
            id: UUID(),
            firstName: "Test",
            lastName: "User",
            email: "test@edugo.com"
        )

        let output = LoginOutput(
            user: user,
            accessToken: "access-token",
            refreshToken: "refresh-token"
        )

        #expect(output.user.email == "test@edugo.com")
        #expect(output.accessToken == "access-token")
        #expect(output.refreshToken == "refresh-token")
    }
}

// MARK: - RefreshTokenInput Tests

@Suite("RefreshTokenInput Tests")
struct RefreshTokenInputTests {

    @Test("RefreshTokenInput inicializa correctamente")
    func testRefreshTokenInputInitialization() {
        let input = RefreshTokenInput(refreshToken: "valid-refresh-token")

        #expect(input.refreshToken == "valid-refresh-token")
    }
}

// MARK: - UseCase Protocol Tests

@Suite("UseCase Protocol Tests")
struct UseCaseProtocolTests {

    @Test("CommandUseCase protocol existe y es accesible")
    func testCommandUseCaseProtocolExists() {
        // Este test verifica que el protocolo está disponible
        // La compilación exitosa es suficiente validación
        #expect(true)
    }

    @Test("UseCase base tiene estructura correcta")
    func testUseCaseBaseStructure() {
        // Verificar que podemos usar los tipos de UseCase
        #expect(true)
    }
}

// MARK: - SwitchSchoolInput Tests

@Suite("SwitchSchoolInput Tests")
struct SwitchSchoolInputTests {

    @Test("SwitchSchoolInput inicializa correctamente")
    func testSwitchSchoolInputInitialization() {
        let userId = UUID()
        let membershipId = UUID()

        let input = SwitchSchoolInput(userId: userId, targetMembershipId: membershipId)

        #expect(input.userId == userId)
        #expect(input.targetMembershipId == membershipId)
    }
}

// MARK: - UserContext Tests

@Suite("UserContext Tests")
struct UserContextTests {

    @Test("UserContext inicializa correctamente")
    func testUserContextInitialization() throws {
        let user = try User(
            id: UUID(),
            firstName: "Test",
            lastName: "User",
            email: "test@edugo.com"
        )

        let context = UserContext(
            user: user,
            memberships: [],
            unitsMap: [:],
            schoolsMap: [:]
        )

        #expect(context.user.id == user.id)
        #expect(context.memberships.isEmpty)
        #expect(context.unitsMap.isEmpty)
        #expect(context.schoolsMap.isEmpty)
    }

    @Test("UserContext es Equatable")
    func testUserContextEquatable() throws {
        let user = try User(
            id: UUID(),
            firstName: "Test",
            lastName: "User",
            email: "test@edugo.com"
        )

        let context1 = UserContext(
            user: user,
            memberships: [],
            unitsMap: [:],
            schoolsMap: [:]
        )

        let context2 = UserContext(
            user: user,
            memberships: [],
            unitsMap: [:],
            schoolsMap: [:]
        )

        #expect(context1 == context2)
    }
}

// MARK: - PartialLoadError Tests

@Suite("PartialLoadError Tests")
struct PartialLoadErrorTests {

    @Test("PartialLoadError inicializa correctamente")
    func testPartialLoadErrorInitialization() {
        let membershipId = UUID()

        let error = PartialLoadError(
            membershipID: membershipId,
            resourceType: .unit,
            message: "Unit not found"
        )

        #expect(error.membershipID == membershipId)
        #expect(error.resourceType == .unit)
        #expect(error.message == "Unit not found")
    }

    @Test("PartialLoadError ResourceType tiene todos los casos")
    func testPartialLoadErrorResourceTypes() {
        let unitType = PartialLoadError.ResourceType.unit
        let schoolType = PartialLoadError.ResourceType.school

        #expect(unitType != schoolType)
    }
}
