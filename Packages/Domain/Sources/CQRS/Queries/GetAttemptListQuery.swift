import Foundation
import EduCore
import EduInfrastructure

/// Query para obtener la lista de intentos de un assessment para revision del profesor.
///
/// ## Uso
/// ```swift
/// let attempts = try await mediator.send(
///     GetAttemptListQuery(assessmentId: "uuid-string")
/// )
/// ```
public struct GetAttemptListQuery: Query {
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

/// Handler que obtiene la lista de intentos via el servicio de red de revision.
///
/// ## Registro
/// ```swift
/// try await mediator.registerQueryHandler(handler)
/// ```
public actor GetAttemptListQueryHandler: QueryHandler {
    public typealias QueryType = GetAttemptListQuery

    private let networkService: any AssessmentReviewNetworkServiceProtocol

    public init(networkService: any AssessmentReviewNetworkServiceProtocol) {
        self.networkService = networkService
    }

    public func handle(_ query: GetAttemptListQuery) async throws -> [TeacherAttemptSummaryDTO] {
        try await networkService.listAttempts(assessmentId: query.assessmentId)
    }
}
