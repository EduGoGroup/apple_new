import Foundation
import EduFoundation
import EduInfrastructure

// MARK: - Attempts Repository

/// Implementacion del repositorio de attempts que conforma `AttemptsRepositoryProtocol`.
///
/// Utiliza `AttemptsNetworkService` del modulo de Infrastructure para obtener DTOs
/// del servidor y los mapea a los tipos del dominio (`AttemptResult`, `AnswerFeedback`).
///
/// ## Thread Safety
/// Como actor de Swift 6.2, todas las operaciones son thread-safe.
///
/// ## Ejemplo de uso
/// ```swift
/// let networkService = AttemptsNetworkService(
///     client: authenticatedClient,
///     baseURL: config.mobileBaseURL
/// )
/// let repository = AttemptsRepository(networkService: networkService)
///
/// let attemptId = try await repository.startAttempt(
///     assessmentId: assessmentId,
///     userId: userId
/// )
/// ```
public actor AttemptsRepository: AttemptsRepositoryProtocol {

    // MARK: - Dependencies

    private let networkService: AttemptsNetworkService

    // MARK: - Initialization

    /// Crea un nuevo repositorio de attempts.
    ///
    /// - Parameter networkService: Servicio de red de attempts (de Infrastructure)
    public init(networkService: AttemptsNetworkService) {
        self.networkService = networkService
    }

    // MARK: - AttemptsRepositoryProtocol

    public func startAttempt(assessmentId: UUID, userId: UUID) async throws -> UUID {
        let dto = try await networkService.startAttempt(
            assessmentId: assessmentId.uuidString
        )
        guard let attemptId = UUID(uuidString: dto.attemptId) else {
            throw UseCaseError.executionFailed(
                reason: "ID de intento invalido recibido del servidor: \(dto.attemptId)"
            )
        }
        return attemptId
    }

    public func submitAttempt(
        attemptId: UUID,
        answers: [UserAnswer],
        timeSpentSeconds: Int,
        idempotencyKey: String
    ) async throws -> AttemptResult {
        let requestDTO = SubmitAttemptRequestDTO(
            answers: answers.map { answer in
                AnswerSubmissionDTO(
                    questionId: answer.questionId.uuidString,
                    selectedOptionId: answer.selectedOptionId.uuidString,
                    timeSpentSeconds: answer.timeSpentSeconds,
                    answeredAt: answer.answeredAt
                )
            },
            timeSpentSeconds: timeSpentSeconds,
            idempotencyKey: idempotencyKey
        )
        let dto = try await networkService.submitAttempt(
            attemptId: attemptId.uuidString,
            request: requestDTO
        )
        return Self.mapToDomain(dto)
    }

    // MARK: - Extended Methods

    /// Obtiene los resultados de un intento completado.
    ///
    /// - Parameter attemptId: ID del intento
    /// - Returns: Resultado del intento con score y feedback
    public func getResults(attemptId: UUID) async throws -> AttemptResult {
        let dto = try await networkService.getResults(
            attemptId: attemptId.uuidString
        )
        return Self.mapToDomain(dto)
    }

    /// Lista los intentos del usuario autenticado con paginacion.
    ///
    /// - Parameters:
    ///   - page: Numero de pagina (1-based)
    ///   - perPage: Tamano de pagina
    /// - Returns: Respuesta paginada de intentos como DTOs
    public func listMyAttempts(
        page: Int,
        perPage: Int
    ) async throws -> PaginatedAttemptsDTO {
        try await networkService.listMyAttempts(page: page, perPage: perPage)
    }

    // MARK: - DTO to Domain Mapping

    /// Mapea un AttemptResultResponseDTO a un AttemptResult del dominio.
    static func mapToDomain(_ dto: AttemptResultResponseDTO) -> AttemptResult {
        AttemptResult(
            attemptId: UUID(uuidString: dto.attemptId) ?? UUID(),
            assessmentId: UUID(uuidString: dto.assessmentId) ?? UUID(),
            userId: UUID(uuidString: dto.userId) ?? UUID(),
            score: dto.score,
            maxScore: dto.maxScore,
            passed: dto.passed,
            correctAnswers: dto.correctAnswers,
            totalQuestions: dto.totalQuestions,
            timeSpentSeconds: dto.timeSpentSeconds,
            feedback: dto.feedback.map { mapFeedbackToDomain($0) },
            startedAt: dto.startedAt,
            completedAt: dto.completedAt,
            canRetake: dto.canRetake
        )
    }

    /// Mapea un AnswerFeedbackDTO a un AnswerFeedback del dominio.
    private static func mapFeedbackToDomain(_ dto: AnswerFeedbackDTO) -> AnswerFeedback {
        AnswerFeedback(
            questionId: UUID(uuidString: dto.questionId) ?? UUID(),
            isCorrect: dto.isCorrect,
            correctOptionId: UUID(uuidString: dto.correctOptionId) ?? UUID(),
            explanation: dto.explanation
        )
    }
}
