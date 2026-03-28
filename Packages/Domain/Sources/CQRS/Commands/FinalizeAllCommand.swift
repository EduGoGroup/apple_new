import Foundation
import EduCore
import EduInfrastructure

/// Command para finalizar todos los intentos de un assessment.
///
/// ## Uso
/// ```swift
/// let result = try await mediator.execute(
///     FinalizeAllCommand(assessmentId: "uuid-string")
/// )
/// ```
public struct FinalizeAllCommand: Command {
    public typealias Result = [TeacherAttemptSummaryDTO]

    public let assessmentId: String
    public let metadata: [String: String]?

    public init(
        assessmentId: String,
        metadata: [String: String]? = nil
    ) {
        self.assessmentId = assessmentId
        self.metadata = metadata
    }
}

/// Handler que finaliza todos los intentos y recarga la lista actualizada.
///
/// ## Registro
/// ```swift
/// try await mediator.registerCommandHandler(handler)
/// ```
public actor FinalizeAllCommandHandler: CommandHandler {
    public typealias CommandType = FinalizeAllCommand

    private let networkService: any AssessmentReviewNetworkServiceProtocol

    public init(networkService: any AssessmentReviewNetworkServiceProtocol) {
        self.networkService = networkService
    }

    public func handle(_ command: FinalizeAllCommand) async throws -> CommandResult<[TeacherAttemptSummaryDTO]> {
        do {
            try await networkService.finalizeAll(assessmentId: command.assessmentId)

            // Recargar la lista de intentos
            let updated = try await networkService.listAttempts(assessmentId: command.assessmentId)

            return .success(
                updated,
                events: ["AllAttemptsFinalizedEvent"],
                metadata: ["assessmentId": command.assessmentId]
            )
        } catch {
            return .failure(error, metadata: ["assessmentId": command.assessmentId])
        }
    }
}
