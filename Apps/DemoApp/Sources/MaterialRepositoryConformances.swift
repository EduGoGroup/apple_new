import Foundation
import EduCore
import EduNetwork
import EduDomain

// MARK: - MaterialUploadRepository + MaterialUploadRepositoryProtocol

/// Bridges the Infrastructure-level MaterialUploadRepository to the
/// Domain-level MaterialUploadRepositoryProtocol.
///
/// This conformance lives in the app layer (DemoApp) because:
/// - MaterialUploadRepository is in EduNetwork (no dependency on EduDomain)
/// - MaterialUploadRepositoryProtocol is in EduDomain
/// - EduNetwork cannot depend on EduDomain (would cause circular dependency)
///
/// The adapter converts between Infrastructure DTOs (String IDs) and
/// Domain types (UUID IDs, Material entities).
extension MaterialUploadRepository: MaterialUploadRepositoryProtocol {

    public func createMaterial(
        title: String,
        description: String?,
        subject: String?,
        grade: String?
    ) async throws -> EduCore.Material {
        let dto = try await createMaterialDTO(
            title: title,
            description: description,
            subject: subject,
            grade: grade
        )
        return try mapDTOToMaterial(dto)
    }

    public func getMaterial(id: UUID) async throws -> EduCore.Material {
        let dto = try await getMaterialDTO(id: id)
        return try mapDTOToMaterial(dto)
    }

    /// Maps the EduNetwork MaterialDTO (String-based) to an EduCore Material entity.
    private func mapDTOToMaterial(_ dto: EduNetwork.MaterialDTO) throws -> EduCore.Material {
        guard let status = EduCore.MaterialStatus(rawValue: dto.status.rawValue) else {
            throw DomainError.validationFailed(field: "status", reason: "Unknown status: \(dto.status.rawValue)")
        }

        guard let id = UUID(uuidString: dto.id) else {
            throw DomainError.validationFailed(field: "id", reason: "Invalid UUID: \(dto.id)")
        }

        guard let schoolID = UUID(uuidString: dto.schoolId) else {
            throw DomainError.validationFailed(field: "schoolId", reason: "Invalid UUID: \(dto.schoolId)")
        }

        let fileURL = URL(string: dto.fileUrl)
        let academicUnitID = UUID(uuidString: dto.academicUnitId)
        let uploadedByTeacherID = UUID(uuidString: dto.uploadedByTeacherId)

        return try EduCore.Material(
            id: id,
            title: dto.title,
            description: dto.description.isEmpty ? nil : dto.description,
            status: status,
            fileURL: fileURL,
            fileType: dto.fileType,
            fileSizeBytes: dto.fileSizeBytes,
            schoolID: schoolID,
            academicUnitID: academicUnitID,
            uploadedByTeacherID: uploadedByTeacherID,
            subject: dto.subject,
            grade: dto.grade,
            isPublic: dto.isPublic,
            processingStartedAt: dto.processingStartedAt,
            processingCompletedAt: dto.processingCompletedAt,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt,
            deletedAt: dto.deletedAt
        )
    }
}

// MARK: - MaterialListRepository + ListMaterialsRepositoryProtocol

/// Bridges the Infrastructure-level MaterialListRepository to the
/// Domain-level ListMaterialsRepositoryProtocol.
extension MaterialListRepository: ListMaterialsRepositoryProtocol {

    public func list(query: MaterialsQuery) async throws -> MaterialsRepositoryResponse {
        // Convert Domain query type to Infrastructure query type
        let params = MaterialListQueryParams(
            subjectId: query.subjectId,
            unitId: query.unitId,
            type: query.type,
            status: query.status,
            searchQuery: query.searchQuery,
            cursor: query.cursor,
            limit: query.limit,
            sortBy: query.sortBy,
            sortOrder: query.sortOrder
        )

        let response = try await list(params: params)

        // Convert EduNetwork DTOs to EduCore domain models
        let materials: [EduCore.Material] = try response.items.compactMap { dto in
            guard let status = EduCore.MaterialStatus(rawValue: dto.status.rawValue) else { return nil }
            guard let id = UUID(uuidString: dto.id) else { return nil }
            guard let schoolID = UUID(uuidString: dto.schoolId) else { return nil }

            let fileURL = URL(string: dto.fileUrl)
            let academicUnitID = UUID(uuidString: dto.academicUnitId)
            let uploadedByTeacherID = UUID(uuidString: dto.uploadedByTeacherId)

            return try EduCore.Material(
                id: id,
                title: dto.title,
                description: dto.description.isEmpty ? nil : dto.description,
                status: status,
                fileURL: fileURL,
                fileType: dto.fileType,
                fileSizeBytes: dto.fileSizeBytes,
                schoolID: schoolID,
                academicUnitID: academicUnitID,
                uploadedByTeacherID: uploadedByTeacherID,
                subject: dto.subject,
                grade: dto.grade,
                isPublic: dto.isPublic,
                processingStartedAt: dto.processingStartedAt,
                processingCompletedAt: dto.processingCompletedAt,
                createdAt: dto.createdAt,
                updatedAt: dto.updatedAt,
                deletedAt: dto.deletedAt
            )
        }

        return MaterialsRepositoryResponse(
            materials: materials,
            nextCursor: response.nextCursor,
            totalCount: response.totalCount
        )
    }
}
