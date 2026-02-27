import Testing
import Foundation
@testable import EduModels
import EduFoundation

@Suite("AcademicUnit Entity Tests")
struct AcademicUnitTests {

    // MARK: - Test Data

    private let schoolID = UUID()

    // MARK: - Initialization Tests

    @Test("AcademicUnit creation with valid data")
    func academicUnitCreationWithValidData() throws {
        let unit = try AcademicUnit(
            displayName: "10th Grade",
            type: .grade,
            schoolID: schoolID
        )

        #expect(unit.displayName == "10th Grade")
        #expect(unit.type == .grade)
        #expect(unit.schoolID == schoolID)
        #expect(unit.isTopLevel == true)
        #expect(unit.parentUnitID == nil)
    }

    @Test("AcademicUnit creation with all parameters")
    func academicUnitCreationWithAllParameters() throws {
        let parentID = UUID()
        let createdAt = Date(timeIntervalSince1970: 1000)
        let updatedAt = Date(timeIntervalSince1970: 2000)

        let unit = try AcademicUnit(
            id: UUID(),
            displayName: "Section A",
            code: "G10-A",
            description: "First section of 10th grade",
            type: .section,
            parentUnitID: parentID,
            schoolID: schoolID,
            metadata: ["capacity": .string("30")],
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: nil
        )

        #expect(unit.displayName == "Section A")
        #expect(unit.code == "G10-A")
        #expect(unit.description == "First section of 10th grade")
        #expect(unit.type == .section)
        #expect(unit.parentUnitID == parentID)
        #expect(unit.schoolID == schoolID)
        #expect(unit.metadata?["capacity"] == .string("30"))
        #expect(unit.isTopLevel == false)
    }

    @Test("AcademicUnit creation fails with empty displayName")
    func academicUnitCreationFailsWithEmptyDisplayName() {
        #expect(throws: DomainError.self) {
            _ = try AcademicUnit(
                displayName: "",
                type: .grade,
                schoolID: schoolID
            )
        }
    }

    @Test("AcademicUnit creation fails with whitespace-only displayName")
    func academicUnitCreationFailsWithWhitespaceOnlyDisplayName() {
        #expect(throws: DomainError.self) {
            _ = try AcademicUnit(
                displayName: "   ",
                type: .grade,
                schoolID: schoolID
            )
        }
    }

    @Test("AcademicUnit creation trims whitespace from displayName")
    func academicUnitCreationTrimsWhitespaceFromDisplayName() throws {
        let unit = try AcademicUnit(
            displayName: "  10th Grade  ",
            type: .grade,
            schoolID: schoolID
        )

        #expect(unit.displayName == "10th Grade")
    }

    // MARK: - AcademicUnitType Tests

    @Test("All AcademicUnitType cases are valid")
    func allAcademicUnitTypeCasesAreValid() {
        let allCases: [AcademicUnitType] = [.grade, .section, .club, .department, .course]
        #expect(allCases.count == 5)
        #expect(AcademicUnitType.allCases == allCases)
    }

    @Test("AcademicUnitType raw values match backend")
    func academicUnitTypeRawValuesMatchBackend() {
        #expect(AcademicUnitType.grade.rawValue == "grade")
        #expect(AcademicUnitType.section.rawValue == "section")
        #expect(AcademicUnitType.club.rawValue == "club")
        #expect(AcademicUnitType.department.rawValue == "department")
        #expect(AcademicUnitType.course.rawValue == "course")
    }

    @Test("AcademicUnitType descriptions are human readable")
    func academicUnitTypeDescriptionsAreHumanReadable() {
        #expect(AcademicUnitType.grade.description == "Grade")
        #expect(AcademicUnitType.section.description == "Section")
        #expect(AcademicUnitType.club.description == "Club")
        #expect(AcademicUnitType.department.description == "Department")
        #expect(AcademicUnitType.course.description == "Course")
    }

    @Test("AcademicUnitType encodes and decodes correctly")
    func academicUnitTypeEncodesAndDecodesCorrectly() throws {
        for unitType in AcademicUnitType.allCases {
            let encoded = try JSONEncoder().encode(unitType)
            let decoded = try JSONDecoder().decode(AcademicUnitType.self, from: encoded)
            #expect(decoded == unitType)
        }
    }

    // MARK: - Computed Properties Tests

    @Test("isTopLevel returns true when parentUnitID is nil")
    func isTopLevelReturnsTrueWhenParentIsNil() throws {
        let unit = try AcademicUnit(
            displayName: "10th Grade",
            type: .grade,
            parentUnitID: nil,
            schoolID: schoolID
        )

        #expect(unit.isTopLevel == true)
    }

    @Test("isTopLevel returns false when parentUnitID is set")
    func isTopLevelReturnsFalseWhenParentIsSet() throws {
        let unit = try AcademicUnit(
            displayName: "Section A",
            type: .section,
            parentUnitID: UUID(),
            schoolID: schoolID
        )

        #expect(unit.isTopLevel == false)
    }

    @Test("isDeleted returns true when deletedAt is set")
    func isDeletedReturnsTrueWhenDeletedAtIsSet() throws {
        let unit = try AcademicUnit(
            displayName: "Old Unit",
            type: .grade,
            schoolID: schoolID,
            deletedAt: Date()
        )

        #expect(unit.isDeleted == true)
    }

    @Test("isDeleted returns false when deletedAt is nil")
    func isDeletedReturnsFalseWhenDeletedAtIsNil() throws {
        let unit = try AcademicUnit(
            displayName: "Active Unit",
            type: .grade,
            schoolID: schoolID,
            deletedAt: nil
        )

        #expect(unit.isDeleted == false)
    }

    // MARK: - Copy Method Tests

    @Test("with(displayName:) creates copy with new name")
    func withDisplayNameCreatesCopyWithNewName() throws {
        let original = try AcademicUnit(
            displayName: "Original Name",
            type: .grade,
            schoolID: schoolID
        )

        let updated = try original.with(displayName: "New Name")

        #expect(updated.displayName == "New Name")
        #expect(updated.id == original.id)
        #expect(updated.type == original.type)
    }

    @Test("with(displayName:) throws for empty name")
    func withDisplayNameThrowsForEmptyName() throws {
        let unit = try AcademicUnit(
            displayName: "Test",
            type: .grade,
            schoolID: schoolID
        )

        #expect(throws: DomainError.self) {
            _ = try unit.with(displayName: "")
        }
    }

    @Test("with(type:) creates copy with new type")
    func withTypeCreatesCopyWithNewType() throws {
        let original = try AcademicUnit(
            displayName: "Test Unit",
            type: .grade,
            schoolID: schoolID
        )

        let updated = original.with(type: .section)

        #expect(updated.type == .section)
        #expect(updated.id == original.id)
    }

    @Test("with(parentUnitID:) creates copy with new parent")
    func withParentUnitIDCreatesCopyWithNewParent() throws {
        let original = try AcademicUnit(
            displayName: "Test Unit",
            type: .section,
            parentUnitID: nil,
            schoolID: schoolID
        )
        let newParentID = UUID()

        let updated = original.with(parentUnitID: newParentID)

        #expect(updated.parentUnitID == newParentID)
        #expect(updated.isTopLevel == false)
        #expect(updated.id == original.id)
    }

    @Test("with(parentUnitID:) can make unit top-level")
    func withParentUnitIDCanMakeUnitTopLevel() throws {
        let original = try AcademicUnit(
            displayName: "Test Unit",
            type: .section,
            parentUnitID: UUID(),
            schoolID: schoolID
        )

        let updated = original.with(parentUnitID: nil)

        #expect(updated.parentUnitID == nil)
        #expect(updated.isTopLevel == true)
    }

    @Test("with(description:) creates copy with new description")
    func withDescriptionCreatesCopyWithNewDescription() throws {
        let original = try AcademicUnit(
            displayName: "Test Unit",
            description: "Old description",
            type: .grade,
            schoolID: schoolID
        )

        let updated = original.with(description: "New description")

        #expect(updated.description == "New description")
        #expect(updated.id == original.id)
    }

    @Test("delete(at:) marks unit as deleted")
    func deleteMarksUnitAsDeleted() throws {
        let original = try AcademicUnit(
            displayName: "Test Unit",
            type: .grade,
            schoolID: schoolID,
            deletedAt: nil
        )

        let deleted = original.delete()

        #expect(deleted.isDeleted == true)
        #expect(deleted.deletedAt != nil)
        #expect(deleted.id == original.id)
    }

    @Test("delete(at:) uses specified date")
    func deleteUsesSpecifiedDate() throws {
        let original = try AcademicUnit(
            displayName: "Test Unit",
            type: .grade,
            schoolID: schoolID
        )
        let deleteDate = Date(timeIntervalSince1970: 5000)

        let deleted = original.delete(at: deleteDate)

        #expect(deleted.deletedAt == deleteDate)
    }

    @Test("copy methods update updatedAt timestamp")
    func copyMethodsUpdateUpdatedAtTimestamp() throws {
        let createdAt = Date(timeIntervalSince1970: 1000)
        let original = try AcademicUnit(
            displayName: "Test",
            type: .grade,
            schoolID: schoolID,
            createdAt: createdAt,
            updatedAt: createdAt
        )

        let updated = original.with(type: .section)

        #expect(updated.updatedAt > original.updatedAt)
        #expect(updated.createdAt == original.createdAt)
    }

    // MARK: - Hierarchical Structure Tests

    @Test("Grade can have Section as child")
    func gradeCanHaveSectionAsChild() throws {
        let grade = try AcademicUnit(
            displayName: "10th Grade",
            type: .grade,
            schoolID: schoolID
        )

        let section = try AcademicUnit(
            displayName: "Section A",
            type: .section,
            parentUnitID: grade.id,
            schoolID: schoolID
        )

        #expect(section.parentUnitID == grade.id)
        #expect(grade.isTopLevel == true)
        #expect(section.isTopLevel == false)
    }

    @Test("Department can have Course as child")
    func departmentCanHaveCourseAsChild() throws {
        let department = try AcademicUnit(
            displayName: "Mathematics Department",
            type: .department,
            schoolID: schoolID
        )

        let course = try AcademicUnit(
            displayName: "Calculus 101",
            type: .course,
            parentUnitID: department.id,
            schoolID: schoolID
        )

        #expect(course.parentUnitID == department.id)
        #expect(department.isTopLevel == true)
        #expect(course.isTopLevel == false)
    }

    @Test("Club is typically top-level")
    func clubIsTypicallyTopLevel() throws {
        let club = try AcademicUnit(
            displayName: "Chess Club",
            type: .club,
            parentUnitID: nil,
            schoolID: schoolID
        )

        #expect(club.isTopLevel == true)
        #expect(club.type == .club)
    }

    @Test("Multiple sections can share same parent grade")
    func multipleSectionsCanShareSameParentGrade() throws {
        let grade = try AcademicUnit(
            displayName: "10th Grade",
            type: .grade,
            schoolID: schoolID
        )

        let sectionA = try AcademicUnit(
            displayName: "Section A",
            type: .section,
            parentUnitID: grade.id,
            schoolID: schoolID
        )

        let sectionB = try AcademicUnit(
            displayName: "Section B",
            type: .section,
            parentUnitID: grade.id,
            schoolID: schoolID
        )

        #expect(sectionA.parentUnitID == grade.id)
        #expect(sectionB.parentUnitID == grade.id)
        #expect(sectionA.parentUnitID == sectionB.parentUnitID)
    }

    // MARK: - Protocol Conformance Tests

    @Test("AcademicUnit conforms to Identifiable")
    func academicUnitConformsToIdentifiable() throws {
        let unit = try AcademicUnit(
            displayName: "Test",
            type: .grade,
            schoolID: schoolID
        )
        let _: UUID = unit.id
        #expect(Bool(true))
    }

    @Test("AcademicUnit conforms to Equatable")
    func academicUnitConformsToEquatable() throws {
        let id = UUID()
        let createdAt = Date(timeIntervalSince1970: 1000)
        let unit1 = try AcademicUnit(
            id: id,
            displayName: "Test",
            type: .grade,
            schoolID: schoolID,
            createdAt: createdAt,
            updatedAt: createdAt
        )
        let unit2 = try AcademicUnit(
            id: id,
            displayName: "Test",
            type: .grade,
            schoolID: schoolID,
            createdAt: createdAt,
            updatedAt: createdAt
        )

        #expect(unit1 == unit2)
    }

    @Test("AcademicUnit conforms to Hashable")
    func academicUnitConformsToHashable() throws {
        let unit = try AcademicUnit(
            displayName: "Test",
            type: .grade,
            schoolID: schoolID
        )
        var set: Set<AcademicUnit> = []
        set.insert(unit)
        #expect(set.contains(unit))
    }

    @Test("AcademicUnit encodes and decodes correctly")
    func academicUnitEncodesAndDecodesCorrectly() throws {
        let original = try AcademicUnit(
            displayName: "Test Unit",
            code: "TEST-001",
            description: "A test unit",
            type: .section,
            parentUnitID: UUID(),
            schoolID: schoolID
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(AcademicUnit.self, from: data)

        #expect(decoded == original)
    }
}
