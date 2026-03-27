import Foundation
import EduFoundation
import EduInfrastructure

// MARK: - Assessments Repository

/// Implementacion del repositorio de assessments que conforma `AssessmentsRepositoryProtocol`.
///
/// Utiliza `AssessmentsNetworkService` del modulo de Infrastructure para obtener DTOs
/// del servidor y los mapea a los tipos del dominio (`Assessment`, `AssessmentQuestion`,
/// `QuestionOption`).
///
/// ## Thread Safety
/// Como actor de Swift 6.2, todas las operaciones son thread-safe.
///
/// ## Ejemplo de uso
/// ```swift
/// let networkService = AssessmentsNetworkService(
///     client: authenticatedClient,
///     baseURL: config.mobileBaseURL
/// )
/// let repository = AssessmentsRepository(networkService: networkService)
///
/// let assessment = try await repository.get(id: assessmentId)
/// ```
public actor AssessmentsRepository: AssessmentsRepositoryProtocol {

    // MARK: - Dependencies

    private let networkService: AssessmentsNetworkService

    /// Cache in-memory simple para getCached/cache.
    private var localCache: [UUID: Assessment] = [:]

    // MARK: - Initialization

    /// Crea un nuevo repositorio de assessments.
    ///
    /// - Parameter networkService: Servicio de red de assessments (de Infrastructure)
    public init(networkService: AssessmentsNetworkService) {
        self.networkService = networkService
    }

    // MARK: - AssessmentsRepositoryProtocol

    public func get(id: UUID) async throws -> Assessment {
        let dto = try await networkService.getAssessment(id: id.uuidString)
        return Self.mapToDomain(dto)
    }

    public func getCached(id: UUID) async -> Assessment? {
        localCache[id]
    }

    public func cache(_ assessment: Assessment) async {
        localCache[assessment.id] = assessment
    }

    // MARK: - DTO to Domain Mapping

    /// Mapea un AssessmentDTO a un Assessment del dominio.
    static func mapToDomain(_ dto: AssessmentDTO) -> Assessment {
        Assessment(
            id: UUID(uuidString: dto.id) ?? UUID(),
            materialId: UUID(uuidString: dto.materialId) ?? UUID(),
            title: dto.title,
            description: dto.description,
            questions: dto.questions.map { mapQuestionToDomain($0) },
            timeLimitSeconds: dto.timeLimitSeconds,
            maxAttempts: dto.maxAttempts,
            passThreshold: dto.passThreshold,
            attemptsUsed: dto.attemptsUsed,
            expiresAt: dto.expiresAt
        )
    }

    /// Mapea un AssessmentQuestionDTO a un AssessmentQuestion del dominio.
    private static func mapQuestionToDomain(_ dto: AssessmentQuestionDTO) -> AssessmentQuestion {
        AssessmentQuestion(
            id: UUID(uuidString: dto.id) ?? UUID(),
            text: dto.text,
            options: dto.options.map { mapOptionToDomain($0) },
            isRequired: dto.isRequired,
            orderIndex: dto.orderIndex
        )
    }

    /// Mapea un AssessmentQuestionOptionDTO a un QuestionOption del dominio.
    private static func mapOptionToDomain(_ dto: AssessmentQuestionOptionDTO) -> QuestionOption {
        QuestionOption(
            id: UUID(uuidString: dto.id) ?? UUID(),
            text: dto.text,
            orderIndex: dto.orderIndex
        )
    }
}
