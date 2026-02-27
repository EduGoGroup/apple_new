import Testing
import Foundation
import SwiftData
import EduCore
import EduFoundation
@testable import EduPersistence

@Suite("MembershipPersistenceMapper Tests")
struct MembershipPersistenceMapperTests {

    // MARK: - Roundtrip Tests

    @Test("Domain to Model to Domain roundtrip produces identical membership")
    func testRoundtrip() throws {
        let userID = UUID()
        let unitID = UUID()
        let enrolledAt = Date()
        let createdAt = Date()
        let updatedAt = Date()
        let original = TestDataFactory.makeMembership(
            userID: userID,
            unitID: unitID,
            role: .teacher,
            isActive: true,
            enrolledAt: enrolledAt,
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        // Domain -> Model
        let model = MembershipPersistenceMapper.toModel(original, existing: nil)

        // Model -> Domain
        let restored = try MembershipPersistenceMapper.toDomain(model)

        #expect(restored.id == original.id)
        #expect(restored.userID == original.userID)
        #expect(restored.unitID == original.unitID)
        #expect(restored.role == original.role)
        #expect(restored.isActive == original.isActive)
        #expect(restored.enrolledAt == original.enrolledAt)
        #expect(restored.createdAt == original.createdAt)
        #expect(restored.updatedAt == original.updatedAt)
    }

    @Test("Roundtrip preserves all roles")
    func testRoundtripPreservesRoles() throws {
        let roles: [MembershipRole] = [.owner, .teacher, .assistant, .student, .guardian]

        for role in roles {
            let original = TestDataFactory.makeMembership(role: role)
            let model = MembershipPersistenceMapper.toModel(original, existing: nil)
            let restored = try MembershipPersistenceMapper.toDomain(model)

            #expect(restored.role == role)
        }
    }

    @Test("Roundtrip with withdrawnAt date")
    func testRoundtripWithWithdrawnAt() throws {
        let withdrawnAt = Date()
        let original = TestDataFactory.makeMembership(
            isActive: false,
            withdrawnAt: withdrawnAt
        )

        let model = MembershipPersistenceMapper.toModel(original, existing: nil)
        let restored = try MembershipPersistenceMapper.toDomain(model)

        #expect(restored.withdrawnAt == withdrawnAt)
        #expect(restored.isActive == false)
    }

    @Test("Roundtrip preserves timestamps")
    func testRoundtripPreservesTimestamps() throws {
        let createdAt = Date(timeIntervalSince1970: 1000000)
        let updatedAt = Date(timeIntervalSince1970: 2000000)
        let enrolledAt = Date(timeIntervalSince1970: 500000)
        let original = TestDataFactory.makeMembership(
            enrolledAt: enrolledAt,
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        let model = MembershipPersistenceMapper.toModel(original, existing: nil)
        let restored = try MembershipPersistenceMapper.toDomain(model)

        #expect(restored.enrolledAt == enrolledAt)
        #expect(restored.createdAt == createdAt)
        #expect(restored.updatedAt == updatedAt)
    }

    // MARK: - toModel Tests

    @Test("toModel creates new model when existing is nil")
    func testToModelCreatesNew() {
        let membership = TestDataFactory.makeMembership()

        let model = MembershipPersistenceMapper.toModel(membership, existing: nil)

        #expect(model.id == membership.id)
        #expect(model.userID == membership.userID)
        #expect(model.unitID == membership.unitID)
        #expect(model.role == membership.role.rawValue)
    }

    @Test("toModel updates existing model in place")
    func testToModelUpdatesExisting() {
        let membership1 = TestDataFactory.makeMembership(role: .student)
        let existingModel = MembershipPersistenceMapper.toModel(membership1, existing: nil)

        let newUpdatedAt = Date()
        let membership2 = Membership(
            id: membership1.id,
            userID: membership1.userID,
            unitID: membership1.unitID,
            role: .teacher,
            isActive: false,
            enrolledAt: membership1.enrolledAt,
            withdrawnAt: Date(),
            createdAt: membership1.createdAt,
            updatedAt: newUpdatedAt
        )

        let updatedModel = MembershipPersistenceMapper.toModel(membership2, existing: existingModel)

        // Should be the same instance
        #expect(updatedModel === existingModel)
        #expect(updatedModel.role == "teacher")
        #expect(updatedModel.isActive == false)
        #expect(updatedModel.withdrawnAt != nil)
        #expect(updatedModel.updatedAt == newUpdatedAt)
    }

    @Test("toModel converts role enum to string")
    func testToModelConvertsRoleToString() {
        let membership = TestDataFactory.makeMembership(role: .owner)

        let model = MembershipPersistenceMapper.toModel(membership, existing: nil)

        #expect(model.role == "owner")
    }

    // MARK: - toDomain Tests

    @Test("toDomain creates valid domain membership")
    func testToDomainCreatesValidMembership() throws {
        let userID = UUID()
        let unitID = UUID()
        let model = MembershipModel(
            id: UUID(),
            userID: userID,
            unitID: unitID,
            role: "teacher",
            isActive: true,
            enrolledAt: Date()
        )

        let membership = try MembershipPersistenceMapper.toDomain(model)

        #expect(membership.id == model.id)
        #expect(membership.userID == userID)
        #expect(membership.unitID == unitID)
        #expect(membership.role == .teacher)
        #expect(membership.isActive == true)
    }

    @Test("toDomain throws for unknown role")
    func testToDomainThrowsForUnknownRole() {
        let model = MembershipModel(
            id: UUID(),
            userID: UUID(),
            unitID: UUID(),
            role: "unknown_role",
            isActive: true,
            enrolledAt: Date()
        )

        #expect(throws: DomainError.self) {
            _ = try MembershipPersistenceMapper.toDomain(model)
        }
    }

    @Test("toDomain converts all known role strings")
    func testToDomainConvertsAllKnownRoles() throws {
        let roleMapping: [(String, MembershipRole)] = [
            ("owner", .owner),
            ("teacher", .teacher),
            ("assistant", .assistant),
            ("student", .student),
            ("guardian", .guardian)
        ]

        for (roleString, expectedRole) in roleMapping {
            let model = MembershipModel(
                id: UUID(),
                userID: UUID(),
                unitID: UUID(),
                role: roleString,
                isActive: true,
                enrolledAt: Date()
            )

            let membership = try MembershipPersistenceMapper.toDomain(model)

            #expect(membership.role == expectedRole)
        }
    }

    @Test("toDomain handles nil withdrawnAt")
    func testToDomainHandlesNilWithdrawnAt() throws {
        let model = MembershipModel(
            id: UUID(),
            userID: UUID(),
            unitID: UUID(),
            role: "student",
            isActive: true,
            enrolledAt: Date(),
            withdrawnAt: nil
        )

        let membership = try MembershipPersistenceMapper.toDomain(model)

        #expect(membership.withdrawnAt == nil)
    }

    // MARK: - Extended Persistence Tests

    @Test("Roundtrip with withdrawn membership")
    func testRoundtripWithdrawnMembership() throws {
        let original = TestDataFactory.makeWithdrawnMembership()

        let model = MembershipPersistenceMapper.toModel(original, existing: nil)
        let restored = try MembershipPersistenceMapper.toDomain(model)

        #expect(restored.isActive == false)
        #expect(restored.withdrawnAt != nil)
        #expect(restored.withdrawnAt == original.withdrawnAt)
    }

    @Test("Multiple roundtrips produce consistent results")
    func testMultipleRoundtrips() throws {
        let original = TestDataFactory.makeMembership(role: .teacher)

        var current = original
        for _ in 0..<5 {
            let model = MembershipPersistenceMapper.toModel(current, existing: nil)
            current = try MembershipPersistenceMapper.toDomain(model)
        }

        #expect(current.id == original.id)
        #expect(current.userID == original.userID)
        #expect(current.unitID == original.unitID)
        #expect(current.role == original.role)
    }

    @Test("Batch membership mapping maintains data integrity")
    func testBatchMembershipMapping() throws {
        let memberships = TestDataFactory.makeMemberships(count: 50)

        let models = memberships.map { MembershipPersistenceMapper.toModel($0, existing: nil) }
        let restored = try models.map { try MembershipPersistenceMapper.toDomain($0) }

        #expect(restored.count == memberships.count)
        for (original, mapped) in zip(memberships, restored) {
            #expect(mapped.id == original.id)
            #expect(mapped.userID == original.userID)
            #expect(mapped.unitID == original.unitID)
            #expect(mapped.role == original.role)
        }
    }

    @Test("Roundtrip preserves all roles with all cases")
    func testRoundtripAllRolesCases() throws {
        let memberships = TestDataFactory.makeMembershipsWithAllRoles()

        for original in memberships {
            let model = MembershipPersistenceMapper.toModel(original, existing: nil)
            let restored = try MembershipPersistenceMapper.toDomain(model)

            #expect(restored.role == original.role)
        }
    }

    @Test("toModel preserves instance across updates")
    func testToModelPreservesInstance() {
        let membership1 = TestDataFactory.makeMembership(role: .student, isActive: true)
        let existingModel = MembershipPersistenceMapper.toModel(membership1, existing: nil)
        let originalModelID = ObjectIdentifier(existingModel)

        let membership2 = Membership(
            id: membership1.id,
            userID: membership1.userID,
            unitID: membership1.unitID,
            role: .teacher,
            isActive: false,
            enrolledAt: membership1.enrolledAt,
            withdrawnAt: Date(),
            createdAt: membership1.createdAt,
            updatedAt: Date()
        )

        let updatedModel = MembershipPersistenceMapper.toModel(membership2, existing: existingModel)

        #expect(ObjectIdentifier(updatedModel) == originalModelID)
        #expect(updatedModel.role == "teacher")
        #expect(updatedModel.isActive == false)
    }

    @Test("Roundtrip preserves exact timestamp precision")
    func testRoundtripPreservesTimestampPrecision() throws {
        let preciseEnrolledAt = Date(timeIntervalSince1970: 1704067200.123456)
        let preciseCreatedAt = Date(timeIntervalSince1970: 1704153600.789012)
        let preciseUpdatedAt = Date(timeIntervalSince1970: 1704240000.456789)

        let original = TestDataFactory.makeMembership(
            enrolledAt: preciseEnrolledAt,
            createdAt: preciseCreatedAt,
            updatedAt: preciseUpdatedAt
        )

        let model = MembershipPersistenceMapper.toModel(original, existing: nil)
        let restored = try MembershipPersistenceMapper.toDomain(model)

        #expect(restored.enrolledAt.timeIntervalSince1970 == preciseEnrolledAt.timeIntervalSince1970)
        #expect(restored.createdAt.timeIntervalSince1970 == preciseCreatedAt.timeIntervalSince1970)
        #expect(restored.updatedAt.timeIntervalSince1970 == preciseUpdatedAt.timeIntervalSince1970)
    }

    @Test("toDomain with case-insensitive role strings")
    func testToDomainCaseInsensitiveRoles() {
        // Test that roles must match exactly (case-sensitive)
        let model = MembershipModel(
            id: UUID(),
            userID: UUID(),
            unitID: UUID(),
            role: "TEACHER",
            isActive: true,
            enrolledAt: Date()
        )

        #expect(throws: DomainError.self) {
            _ = try MembershipPersistenceMapper.toDomain(model)
        }
    }
}
