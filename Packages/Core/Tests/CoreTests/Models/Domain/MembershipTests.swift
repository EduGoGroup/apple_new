import Testing
import Foundation
@testable import EduModels

@Suite("Membership Entity Tests")
struct MembershipTests {

    // MARK: - Test Data

    private let userID = UUID()
    private let unitID = UUID()

    // MARK: - Initialization Tests

    @Test("Membership creation with valid data")
    func testValidMembershipCreation() {
        let membership = Membership(
            userID: userID,
            unitID: unitID,
            role: .student
        )

        #expect(membership.userID == userID)
        #expect(membership.unitID == unitID)
        #expect(membership.role == .student)
        #expect(membership.isActive == true)
        #expect(membership.withdrawnAt == nil)
    }

    @Test("Membership creation with all parameters")
    func testFullMembershipCreation() {
        let id = UUID()
        let enrolledAt = Date(timeIntervalSince1970: 1000)
        let createdAt = Date(timeIntervalSince1970: 1000)
        let updatedAt = Date(timeIntervalSince1970: 2000)

        let membership = Membership(
            id: id,
            userID: userID,
            unitID: unitID,
            role: .teacher,
            isActive: true,
            enrolledAt: enrolledAt,
            withdrawnAt: nil,
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        #expect(membership.id == id)
        #expect(membership.userID == userID)
        #expect(membership.unitID == unitID)
        #expect(membership.role == .teacher)
        #expect(membership.isActive == true)
        #expect(membership.enrolledAt == enrolledAt)
        #expect(membership.withdrawnAt == nil)
        #expect(membership.createdAt == createdAt)
        #expect(membership.updatedAt == updatedAt)
    }

    @Test("Membership with withdrawn date")
    func testMembershipWithWithdrawnDate() {
        let withdrawnAt = Date(timeIntervalSince1970: 3000)

        let membership = Membership(
            userID: userID,
            unitID: unitID,
            role: .student,
            isActive: false,
            withdrawnAt: withdrawnAt
        )

        #expect(membership.isActive == false)
        #expect(membership.withdrawnAt == withdrawnAt)
        #expect(membership.isCurrentlyActive == false)
    }

    // MARK: - MembershipRole Tests

    @Test("All MembershipRole cases are valid")
    func testAllRoleCases() {
        let allRoles: [MembershipRole] = [.owner, .teacher, .assistant, .student, .guardian]

        #expect(allRoles.count == 5)
        #expect(MembershipRole.allCases.count == 5)
    }

    @Test("MembershipRole raw values match backend")
    func testRoleRawValues() {
        #expect(MembershipRole.owner.rawValue == "owner")
        #expect(MembershipRole.teacher.rawValue == "teacher")
        #expect(MembershipRole.assistant.rawValue == "assistant")
        #expect(MembershipRole.student.rawValue == "student")
        #expect(MembershipRole.guardian.rawValue == "guardian")
    }

    @Test("MembershipRole descriptions are human readable")
    func testRoleDescriptions() {
        #expect(MembershipRole.owner.description == "Owner")
        #expect(MembershipRole.teacher.description == "Teacher")
        #expect(MembershipRole.assistant.description == "Assistant")
        #expect(MembershipRole.student.description == "Student")
        #expect(MembershipRole.guardian.description == "Guardian")
    }

    // MARK: - Computed Properties Tests

    @Test("isCurrentlyActive returns true when active and not withdrawn")
    func testIsCurrentlyActiveTrue() {
        let membership = Membership(
            userID: userID,
            unitID: unitID,
            role: .student,
            isActive: true,
            withdrawnAt: nil
        )

        #expect(membership.isCurrentlyActive == true)
    }

    @Test("isCurrentlyActive returns false when not active")
    func testIsCurrentlyActiveFalseWhenNotActive() {
        let membership = Membership(
            userID: userID,
            unitID: unitID,
            role: .student,
            isActive: false,
            withdrawnAt: nil
        )

        #expect(membership.isCurrentlyActive == false)
    }

    @Test("isCurrentlyActive returns false when withdrawn")
    func testIsCurrentlyActiveFalseWhenWithdrawn() {
        let membership = Membership(
            userID: userID,
            unitID: unitID,
            role: .student,
            isActive: true,
            withdrawnAt: Date()
        )

        #expect(membership.isCurrentlyActive == false)
    }

    // MARK: - Copy Method Tests

    @Test("with(role:) creates copy with new role")
    func testWithRole() {
        let membership = Membership(
            userID: userID,
            unitID: unitID,
            role: .student
        )

        let updated = membership.with(role: .teacher)

        #expect(updated.role == .teacher)
        #expect(updated.id == membership.id)
        #expect(updated.userID == membership.userID)
        #expect(updated.unitID == membership.unitID)
    }

    @Test("with(isActive:) creates copy with new active status")
    func testWithIsActive() {
        let membership = Membership(
            userID: userID,
            unitID: unitID,
            role: .student,
            isActive: true
        )

        let deactivated = membership.with(isActive: false)

        #expect(deactivated.isActive == false)
        #expect(deactivated.id == membership.id)
    }

    @Test("withdraw() marks membership as withdrawn")
    func testWithdraw() {
        let membership = Membership(
            userID: userID,
            unitID: unitID,
            role: .student,
            isActive: true
        )

        let withdrawn = membership.withdraw()

        #expect(withdrawn.isActive == false)
        #expect(withdrawn.withdrawnAt != nil)
        #expect(withdrawn.isCurrentlyActive == false)
    }

    @Test("withdraw(at:) uses specified date")
    func testWithdrawAtDate() {
        let withdrawalDate = Date(timeIntervalSince1970: 5000)
        let membership = Membership(
            userID: userID,
            unitID: unitID,
            role: .student
        )

        let withdrawn = membership.withdraw(at: withdrawalDate)

        #expect(withdrawn.withdrawnAt == withdrawalDate)
    }

    @Test("reactivate() restores active membership")
    func testReactivate() {
        let membership = Membership(
            userID: userID,
            unitID: unitID,
            role: .student,
            isActive: false,
            withdrawnAt: Date()
        )

        let reactivated = membership.reactivate()

        #expect(reactivated.isActive == true)
        #expect(reactivated.withdrawnAt == nil)
        #expect(reactivated.isCurrentlyActive == true)
    }

    @Test("copy methods update updatedAt timestamp")
    func testCopyMethodsUpdateTimestamp() {
        let originalDate = Date(timeIntervalSince1970: 1000)
        let membership = Membership(
            userID: userID,
            unitID: unitID,
            role: .student,
            createdAt: originalDate,
            updatedAt: originalDate
        )

        let updated = membership.with(role: .teacher)

        #expect(updated.createdAt == originalDate)
        #expect(updated.updatedAt > originalDate)
    }

    // MARK: - Protocol Conformance Tests

    @Test("Membership conforms to Equatable")
    func testEquatable() {
        let id = UUID()
        let enrolledAt = Date()
        let createdAt = Date()
        let updatedAt = Date()

        let membership1 = Membership(
            id: id,
            userID: userID,
            unitID: unitID,
            role: .student,
            enrolledAt: enrolledAt,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
        let membership2 = Membership(
            id: id,
            userID: userID,
            unitID: unitID,
            role: .student,
            enrolledAt: enrolledAt,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
        let membership3 = Membership(
            userID: userID,
            unitID: unitID,
            role: .teacher
        )

        #expect(membership1 == membership2)
        #expect(membership1 != membership3)
    }

    @Test("Membership conforms to Identifiable")
    func testIdentifiable() {
        let membership = Membership(
            userID: userID,
            unitID: unitID,
            role: .student
        )

        #expect(membership.id == membership.id)
    }

    @Test("Membership conforms to Hashable")
    func testHashable() {
        let membership1 = Membership(userID: UUID(), unitID: UUID(), role: .student)
        let membership2 = Membership(userID: UUID(), unitID: UUID(), role: .teacher)

        var membershipSet: Set<Membership> = []
        membershipSet.insert(membership1)
        membershipSet.insert(membership2)

        #expect(membershipSet.count == 2)
    }

    // MARK: - Codable Tests

    @Test("Membership encodes and decodes correctly")
    func testCodable() throws {
        let membership = Membership(
            userID: userID,
            unitID: unitID,
            role: .teacher,
            isActive: true
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(membership)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Membership.self, from: data)

        #expect(decoded == membership)
    }

    @Test("MembershipRole encodes and decodes correctly")
    func testRoleCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for role in MembershipRole.allCases {
            let data = try encoder.encode(role)
            let decoded = try decoder.decode(MembershipRole.self, from: data)
            #expect(decoded == role)
        }
    }
}
