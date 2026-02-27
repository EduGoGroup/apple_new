import Testing
import Foundation
@testable import EduModels
import EduFoundation

@Suite("Material Entity Tests")
struct MaterialTests {

    // MARK: - Test Data

    private let schoolID = UUID()
    private let academicUnitID = UUID()
    private let teacherID = UUID()
    private let fileURL = URL(string: "https://example.com/materials/test.pdf")!

    // MARK: - Initialization Tests

    @Test("Material creation with valid data")
    func materialCreationWithValidData() throws {
        let material = try Material(
            title: "Introduction to Calculus",
            schoolID: schoolID
        )

        #expect(material.title == "Introduction to Calculus")
        #expect(material.schoolID == schoolID)
        #expect(material.status == .uploaded)
        #expect(material.isPublic == false)
        #expect(material.description == nil)
        #expect(material.fileURL == nil)
    }

    @Test("Material creation with all parameters")
    func materialCreationWithAllParameters() throws {
        let createdAt = Date(timeIntervalSince1970: 1000)
        let updatedAt = Date(timeIntervalSince1970: 2000)
        let processingStartedAt = Date(timeIntervalSince1970: 1500)
        let processingCompletedAt = Date(timeIntervalSince1970: 1800)

        let material = try Material(
            id: UUID(),
            title: "Advanced Physics",
            description: "A comprehensive physics guide",
            status: .ready,
            fileURL: fileURL,
            fileType: "application/pdf",
            fileSizeBytes: 1048576,
            schoolID: schoolID,
            academicUnitID: academicUnitID,
            uploadedByTeacherID: teacherID,
            subject: "Physics",
            grade: "12th Grade",
            isPublic: true,
            processingStartedAt: processingStartedAt,
            processingCompletedAt: processingCompletedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: nil
        )

        #expect(material.title == "Advanced Physics")
        #expect(material.description == "A comprehensive physics guide")
        #expect(material.status == .ready)
        #expect(material.fileURL == fileURL)
        #expect(material.fileType == "application/pdf")
        #expect(material.fileSizeBytes == 1048576)
        #expect(material.schoolID == schoolID)
        #expect(material.academicUnitID == academicUnitID)
        #expect(material.uploadedByTeacherID == teacherID)
        #expect(material.subject == "Physics")
        #expect(material.grade == "12th Grade")
        #expect(material.isPublic == true)
        #expect(material.processingStartedAt == processingStartedAt)
        #expect(material.processingCompletedAt == processingCompletedAt)
    }

    @Test("Material creation fails with empty title")
    func materialCreationFailsWithEmptyTitle() {
        #expect(throws: DomainError.self) {
            _ = try Material(title: "", schoolID: schoolID)
        }
    }

    @Test("Material creation fails with whitespace-only title")
    func materialCreationFailsWithWhitespaceOnlyTitle() {
        #expect(throws: DomainError.self) {
            _ = try Material(title: "   ", schoolID: schoolID)
        }
    }

    @Test("Material creation trims whitespace from title")
    func materialCreationTrimsWhitespaceFromTitle() throws {
        let material = try Material(
            title: "  Introduction to Calculus  ",
            schoolID: schoolID
        )

        #expect(material.title == "Introduction to Calculus")
    }

    @Test("Material creation trims whitespace from description")
    func materialCreationTrimsWhitespaceFromDescription() throws {
        let material = try Material(
            title: "Test Material",
            description: "  A great description  ",
            schoolID: schoolID
        )

        #expect(material.description == "A great description")
    }

    // MARK: - MaterialStatus Tests

    @Test("All MaterialStatus cases are valid")
    func allMaterialStatusCasesAreValid() {
        let allCases: [MaterialStatus] = [.uploaded, .processing, .ready, .failed]
        #expect(allCases.count == 4)
        #expect(MaterialStatus.allCases == allCases)
    }

    @Test("MaterialStatus raw values match backend")
    func materialStatusRawValuesMatchBackend() {
        #expect(MaterialStatus.uploaded.rawValue == "uploaded")
        #expect(MaterialStatus.processing.rawValue == "processing")
        #expect(MaterialStatus.ready.rawValue == "ready")
        #expect(MaterialStatus.failed.rawValue == "failed")
    }

    @Test("MaterialStatus descriptions are human readable")
    func materialStatusDescriptionsAreHumanReadable() {
        #expect(MaterialStatus.uploaded.description == "Uploaded")
        #expect(MaterialStatus.processing.description == "Processing")
        #expect(MaterialStatus.ready.description == "Ready")
        #expect(MaterialStatus.failed.description == "Failed")
    }

    @Test("MaterialStatus encodes and decodes correctly")
    func materialStatusEncodesAndDecodesCorrectly() throws {
        for status in MaterialStatus.allCases {
            let encoded = try JSONEncoder().encode(status)
            let decoded = try JSONDecoder().decode(MaterialStatus.self, from: encoded)
            #expect(decoded == status)
        }
    }

    // MARK: - Computed Properties Tests

    @Test("isReady returns true when status is ready")
    func isReadyReturnsTrueWhenStatusIsReady() throws {
        let material = try Material(
            title: "Test",
            status: .ready,
            schoolID: schoolID
        )

        #expect(material.isReady == true)
    }

    @Test("isReady returns false when status is not ready")
    func isReadyReturnsFalseWhenStatusIsNotReady() throws {
        let material = try Material(
            title: "Test",
            status: .processing,
            schoolID: schoolID
        )

        #expect(material.isReady == false)
    }

    @Test("isProcessing returns true when status is uploaded or processing")
    func isProcessingReturnsTrueWhenProcessing() throws {
        let uploaded = try Material(title: "Test", status: .uploaded, schoolID: schoolID)
        let processing = try Material(title: "Test", status: .processing, schoolID: schoolID)

        #expect(uploaded.isProcessing == true)
        #expect(processing.isProcessing == true)
    }

    @Test("isProcessing returns false when status is ready or failed")
    func isProcessingReturnsFalseWhenNotProcessing() throws {
        let ready = try Material(title: "Test", status: .ready, schoolID: schoolID)
        let failed = try Material(title: "Test", status: .failed, schoolID: schoolID)

        #expect(ready.isProcessing == false)
        #expect(failed.isProcessing == false)
    }

    @Test("isDeleted returns true when deletedAt is set")
    func isDeletedReturnsTrueWhenDeletedAtIsSet() throws {
        let material = try Material(
            title: "Test",
            schoolID: schoolID,
            deletedAt: Date()
        )

        #expect(material.isDeleted == true)
    }

    @Test("isDeleted returns false when deletedAt is nil")
    func isDeletedReturnsFalseWhenDeletedAtIsNil() throws {
        let material = try Material(
            title: "Test",
            schoolID: schoolID,
            deletedAt: nil
        )

        #expect(material.isDeleted == false)
    }

    // MARK: - Copy Method Tests

    @Test("with(title:) creates copy with new title")
    func withTitleCreatesCopyWithNewTitle() throws {
        let original = try Material(
            title: "Original Title",
            schoolID: schoolID
        )

        let updated = try original.with(title: "New Title")

        #expect(updated.title == "New Title")
        #expect(updated.id == original.id)
        #expect(updated.schoolID == original.schoolID)
    }

    @Test("with(title:) throws for empty title")
    func withTitleThrowsForEmptyTitle() throws {
        let material = try Material(title: "Test", schoolID: schoolID)

        #expect(throws: DomainError.self) {
            _ = try material.with(title: "")
        }
    }

    @Test("with(status:) creates copy with new status")
    func withStatusCreatesCopyWithNewStatus() throws {
        let original = try Material(
            title: "Test",
            status: .uploaded,
            schoolID: schoolID
        )

        let updated = original.with(status: .ready)

        #expect(updated.status == .ready)
        #expect(updated.id == original.id)
    }

    @Test("with(description:) creates copy with new description")
    func withDescriptionCreatesCopyWithNewDescription() throws {
        let original = try Material(
            title: "Test",
            description: "Old description",
            schoolID: schoolID
        )

        let updated = original.with(description: "New description")

        #expect(updated.description == "New description")
        #expect(updated.id == original.id)
    }

    @Test("with(isPublic:) creates copy with new public status")
    func withIsPublicCreatesCopyWithNewPublicStatus() throws {
        let original = try Material(
            title: "Test",
            schoolID: schoolID,
            isPublic: false
        )

        let updated = original.with(isPublic: true)

        #expect(updated.isPublic == true)
        #expect(updated.id == original.id)
    }

    @Test("delete(at:) marks material as deleted")
    func deleteMarksAsDeleted() throws {
        let original = try Material(
            title: "Test",
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
        let original = try Material(title: "Test", schoolID: schoolID)
        let deleteDate = Date(timeIntervalSince1970: 5000)

        let deleted = original.delete(at: deleteDate)

        #expect(deleted.deletedAt == deleteDate)
    }

    @Test("copy methods update updatedAt timestamp")
    func copyMethodsUpdateUpdatedAtTimestamp() throws {
        let createdAt = Date(timeIntervalSince1970: 1000)
        let original = try Material(
            title: "Test",
            schoolID: schoolID,
            createdAt: createdAt,
            updatedAt: createdAt
        )

        let updated = original.with(status: .ready)

        #expect(updated.updatedAt > original.updatedAt)
        #expect(updated.createdAt == original.createdAt)
    }

    // MARK: - Protocol Conformance Tests

    @Test("Material conforms to Identifiable")
    func materialConformsToIdentifiable() throws {
        let material = try Material(title: "Test", schoolID: schoolID)
        let _: UUID = material.id
        #expect(true)
    }

    @Test("Material conforms to Equatable")
    func materialConformsToEquatable() throws {
        let id = UUID()
        let material1 = try Material(
            id: id,
            title: "Test",
            schoolID: schoolID,
            createdAt: Date(timeIntervalSince1970: 1000),
            updatedAt: Date(timeIntervalSince1970: 1000)
        )
        let material2 = try Material(
            id: id,
            title: "Test",
            schoolID: schoolID,
            createdAt: Date(timeIntervalSince1970: 1000),
            updatedAt: Date(timeIntervalSince1970: 1000)
        )

        #expect(material1 == material2)
    }

    @Test("Material conforms to Hashable")
    func materialConformsToHashable() throws {
        let material = try Material(title: "Test", schoolID: schoolID)
        var set: Set<Material> = []
        set.insert(material)
        #expect(set.contains(material))
    }

    @Test("Material encodes and decodes correctly")
    func materialEncodesAndDecodesCorrectly() throws {
        let original = try Material(
            title: "Test Material",
            description: "A test",
            status: .ready,
            fileURL: fileURL,
            schoolID: schoolID,
            academicUnitID: academicUnitID,
            subject: "Math",
            isPublic: true
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(Material.self, from: data)

        #expect(decoded == original)
    }
}
