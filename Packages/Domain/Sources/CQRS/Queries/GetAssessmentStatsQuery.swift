import Foundation
import EduCore
import EduInfrastructure

/// Query para obtener las estadisticas de un assessment.
///
/// ## Uso
/// ```swift
/// let stats = try await mediator.send(
///     GetAssessmentStatsQuery(assessmentId: "uuid-string")
/// )
/// ```
public struct GetAssessmentStatsQuery: Query {
    public typealias Result = AssessmentStatsDTO

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

/// Handler que obtiene estadisticas via el servicio de red de revision.
///
/// ## Registro
/// ```swift
/// try await mediator.registerQueryHandler(handler)
/// ```
public actor GetAssessmentStatsQueryHandler: QueryHandler {
    public typealias QueryType = GetAssessmentStatsQuery

    private let networkService: any AssessmentReviewNetworkServiceProtocol

    public init(networkService: any AssessmentReviewNetworkServiceProtocol) {
        self.networkService = networkService
    }

    public func handle(_ query: GetAssessmentStatsQuery) async throws -> AssessmentStatsDTO {
        try await networkService.getStats(assessmentId: query.assessmentId)
    }
}
