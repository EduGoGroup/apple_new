import Foundation
import EduCore
import EduInfrastructure

/// Command para finalizar la revision de un intento individual.
///
/// ## Uso
/// ```swift
/// let result = try await mediator.execute(
///     FinalizeAttemptCommand(attemptId: "uuid-string")
/// )
/// ```
public struct FinalizeAttemptCommand: Command {
    public typealias Result = Void

    public let attemptId: String
    public let metadata: [String: String]?

    public init(
        attemptId: String,
        metadata: [String: String]? = nil
    ) {
        self.attemptId = attemptId
        self.metadata = metadata
    }
}

/// Handler que finaliza la revision de un intento individual.
///
/// ## Registro
/// ```swift
/// try await mediator.registerCommandHandler(handler)
/// ```
public actor FinalizeAttemptCommandHandler: CommandHandler {
    public typealias CommandType = FinalizeAttemptCommand

    private let networkService: any AssessmentReviewNetworkServiceProtocol

    public init(networkService: any AssessmentReviewNetworkServiceProtocol) {
        self.networkService = networkService
    }

    public func handle(_ command: FinalizeAttemptCommand) async throws -> CommandResult<Void> {
        do {
            try await networkService.finalizeAttempt(attemptId: command.attemptId)

            return .success(
                (),
                events: ["AttemptFinalizedEvent"],
                metadata: ["attemptId": command.attemptId]
            )
        } catch {
            return .failure(error, metadata: ["attemptId": command.attemptId])
        }
    }
}
