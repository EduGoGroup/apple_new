import Foundation
import EduCore
import EduInfrastructure

/// Query para obtener el detalle de un intento para revision.
///
/// ## Uso
/// ```swift
/// let detail = try await mediator.send(
///     GetAttemptDetailQuery(attemptId: "uuid-string")
/// )
/// ```
public struct GetAttemptDetailQuery: Query {
    public typealias Result = AttemptReviewDetailDTO

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

/// Handler que obtiene el detalle de un intento via el servicio de red de revision.
///
/// ## Registro
/// ```swift
/// try await mediator.registerQueryHandler(handler)
/// ```
public actor GetAttemptDetailQueryHandler: QueryHandler {
    public typealias QueryType = GetAttemptDetailQuery

    private let networkService: any AssessmentReviewNetworkServiceProtocol

    public init(networkService: any AssessmentReviewNetworkServiceProtocol) {
        self.networkService = networkService
    }

    public func handle(_ query: GetAttemptDetailQuery) async throws -> AttemptReviewDetailDTO {
        try await networkService.getAttemptForReview(attemptId: query.attemptId)
    }
}
