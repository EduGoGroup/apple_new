import Testing
import Foundation
@testable import EduModels
import EduFoundation

@Suite("School Entity Tests")
struct SchoolTests {

    // MARK: - Initialization Tests

    @Test("School creation with valid data")
    func schoolCreationWithValidData() throws {
        let school = try School(
            name: "Springfield Elementary",
            code: "SPR-ELEM-001"
        )

        #expect(school.name == "Springfield Elementary")
        #expect(school.code == "SPR-ELEM-001")
        #expect(school.isActive == true)
        #expect(school.address == nil)
    }

    @Test("School creation with all parameters")
    func schoolCreationWithAllParameters() throws {
        let createdAt = Date(timeIntervalSince1970: 1000)
        let updatedAt = Date(timeIntervalSince1970: 2000)

        let school = try School(
            id: UUID(),
            name: "Advanced Academy",
            code: "ADV-ACA-001",
            isActive: true,
            address: "123 Education Lane",
            city: "Springfield",
            country: "USA",
            contactEmail: "Contact@School.edu",
            contactPhone: "+1-555-1234",
            maxStudents: 500,
            maxTeachers: 50,
            subscriptionTier: "premium",
            metadata: ["region": .string("midwest")],
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        #expect(school.name == "Advanced Academy")
        #expect(school.code == "ADV-ACA-001")
        #expect(school.address == "123 Education Lane")
        #expect(school.city == "Springfield")
        #expect(school.country == "USA")
        #expect(school.contactEmail == "contact@school.edu") // lowercased
        #expect(school.contactPhone == "+1-555-1234")
        #expect(school.maxStudents == 500)
        #expect(school.maxTeachers == 50)
        #expect(school.subscriptionTier == "premium")
        #expect(school.metadata?["region"] == .string("midwest"))
    }

    @Test("School creation fails with empty name")
    func schoolCreationFailsWithEmptyName() {
        #expect(throws: DomainError.self) {
            _ = try School(name: "", code: "CODE")
        }
    }

    @Test("School creation fails with whitespace-only name")
    func schoolCreationFailsWithWhitespaceOnlyName() {
        #expect(throws: DomainError.self) {
            _ = try School(name: "   ", code: "CODE")
        }
    }

    @Test("School creation fails with empty code")
    func schoolCreationFailsWithEmptyCode() {
        #expect(throws: DomainError.self) {
            _ = try School(name: "Test School", code: "")
        }
    }

    @Test("School creation fails with whitespace-only code")
    func schoolCreationFailsWithWhitespaceOnlyCode() {
        #expect(throws: DomainError.self) {
            _ = try School(name: "Test School", code: "   ")
        }
    }

    @Test("School creation trims whitespace from name")
    func schoolCreationTrimsWhitespaceFromName() throws {
        let school = try School(
            name: "  Springfield Elementary  ",
            code: "CODE"
        )

        #expect(school.name == "Springfield Elementary")
    }

    @Test("School creation trims whitespace from code")
    func schoolCreationTrimsWhitespaceFromCode() throws {
        let school = try School(
            name: "Test School",
            code: "  SPR-001  "
        )

        #expect(school.code == "SPR-001")
    }

    @Test("School creation lowercases contact email")
    func schoolCreationLowercasesContactEmail() throws {
        let school = try School(
            name: "Test School",
            code: "CODE",
            contactEmail: "ADMIN@SCHOOL.EDU"
        )

        #expect(school.contactEmail == "admin@school.edu")
    }

    // MARK: - Copy Method Tests

    @Test("with(name:) creates copy with new name")
    func withNameCreatesCopyWithNewName() throws {
        let original = try School(
            name: "Original Name",
            code: "CODE"
        )

        let updated = try original.with(name: "New Name")

        #expect(updated.name == "New Name")
        #expect(updated.id == original.id)
        #expect(updated.code == original.code)
    }

    @Test("with(name:) throws for empty name")
    func withNameThrowsForEmptyName() throws {
        let school = try School(name: "Test", code: "CODE")

        #expect(throws: DomainError.self) {
            _ = try school.with(name: "")
        }
    }

    @Test("with(isActive:) creates copy with new active status")
    func withIsActiveCreatesCopyWithNewStatus() throws {
        let original = try School(
            name: "Test School",
            code: "CODE",
            isActive: true
        )

        let updated = original.with(isActive: false)

        #expect(updated.isActive == false)
        #expect(updated.id == original.id)
    }

    @Test("with(contactEmail:contactPhone:) creates copy with new contact info")
    func withContactInfoCreatesCopyWithNewContactInfo() throws {
        let original = try School(
            name: "Test School",
            code: "CODE",
            contactEmail: "old@school.edu",
            contactPhone: "111-1111"
        )

        let updated = original.with(
            contactEmail: "new@school.edu",
            contactPhone: "222-2222"
        )

        #expect(updated.contactEmail == "new@school.edu")
        #expect(updated.contactPhone == "222-2222")
        #expect(updated.id == original.id)
    }

    @Test("with(subscriptionTier:) creates copy with new tier")
    func withSubscriptionTierCreatesCopyWithNewTier() throws {
        let original = try School(
            name: "Test School",
            code: "CODE",
            subscriptionTier: "free"
        )

        let updated = original.with(subscriptionTier: "premium")

        #expect(updated.subscriptionTier == "premium")
        #expect(updated.id == original.id)
    }

    @Test("copy methods update updatedAt timestamp")
    func copyMethodsUpdateUpdatedAtTimestamp() throws {
        let createdAt = Date(timeIntervalSince1970: 1000)
        let original = try School(
            name: "Test",
            code: "CODE",
            createdAt: createdAt,
            updatedAt: createdAt
        )

        let updated = original.with(isActive: false)

        #expect(updated.updatedAt > original.updatedAt)
        #expect(updated.createdAt == original.createdAt)
    }

    // MARK: - Protocol Conformance Tests

    @Test("School conforms to Identifiable")
    func schoolConformsToIdentifiable() throws {
        let school = try School(name: "Test", code: "CODE")
        let _: UUID = school.id
        #expect(Bool(true))
    }

    @Test("School conforms to Equatable")
    func schoolConformsToEquatable() throws {
        let id = UUID()
        let createdAt = Date(timeIntervalSince1970: 1000)
        let school1 = try School(
            id: id,
            name: "Test",
            code: "CODE",
            createdAt: createdAt,
            updatedAt: createdAt
        )
        let school2 = try School(
            id: id,
            name: "Test",
            code: "CODE",
            createdAt: createdAt,
            updatedAt: createdAt
        )

        #expect(school1 == school2)
    }

    @Test("School conforms to Hashable")
    func schoolConformsToHashable() throws {
        let school = try School(name: "Test", code: "CODE")
        var set: Set<School> = []
        set.insert(school)
        #expect(set.contains(school))
    }

    @Test("School encodes and decodes correctly")
    func schoolEncodesAndDecodesCorrectly() throws {
        let original = try School(
            name: "Test School",
            code: "CODE",
            address: "123 Main St",
            contactEmail: "test@school.edu",
            subscriptionTier: "premium"
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(School.self, from: data)

        #expect(decoded == original)
    }
}
