import Foundation
import EduCore
import EduInfrastructure

/// Command para calificar una respuesta individual de un intento.
///
/// ## Uso
/// ```swift
/// let result = try await mediator.execute(
///     ReviewAnswerCommand(attemptId: "...", answerId: "...", points: 8.0, feedback: "Buen trabajo")
/// )
/// ```
public struct ReviewAnswerCommand: Command {
    public typealias Result = AttemptReviewDetailDTO

    public let attemptId: String
    public let answerId: String
    public let points: Double
    public let feedback: String
    public let metadata: [String: String]?

    public init(
        attemptId: String,
        answerId: String,
        points: Double,
        feedback: String,
        metadata: [String: String]? = nil
    ) {
        self.attemptId = attemptId
        self.answerId = answerId
        self.points = points
        self.feedback = feedback
        self.metadata = metadata
    }

    public func validate() throws {
        guard points >= 0 else {
            throw ValidationError.outOfRange(
                fieldName: "points",
                min: 0,
                max: nil,
                actual: Int(points)
            )
        }
    }
}

/// Handler que califica una respuesta y recarga el detalle del intento.
///
/// ## Registro
/// ```swift
/// try await mediator.registerCommandHandler(handler)
/// ```
public actor ReviewAnswerCommandHandler: CommandHandler {
    public typealias CommandType = ReviewAnswerCommand

    private let networkService: any AssessmentReviewNetworkServiceProtocol

    public init(networkService: any AssessmentReviewNetworkServiceProtocol) {
        self.networkService = networkService
    }

    public func handle(_ command: ReviewAnswerCommand) async throws -> CommandResult<AttemptReviewDetailDTO> {
        do {
            let request = ReviewAnswerRequestDTO(
                pointsAwarded: command.points,
                feedback: command.feedback
            )
            try await networkService.reviewAnswer(
                attemptId: command.attemptId,
                answerId: command.answerId,
                request: request
            )

            // Recargar el detalle del intento para reflejar cambios
            let updated = try await networkService.getAttemptForReview(attemptId: command.attemptId)

            return .success(
                updated,
                events: ["AnswerReviewedEvent"],
                metadata: [
                    "attemptId": command.attemptId,
                    "answerId": command.answerId,
                    "pointsAwarded": "\(command.points)"
                ]
            )
        } catch {
            return .failure(error, metadata: [
                "attemptId": command.attemptId,
                "answerId": command.answerId
            ])
        }
    }
}
