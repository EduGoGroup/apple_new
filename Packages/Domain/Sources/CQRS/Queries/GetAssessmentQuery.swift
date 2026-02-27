import Foundation

// MARK: - AssessmentProjection

/// Campos específicos que se pueden solicitar de una evaluación.
///
/// Las proyecciones permiten optimizar el payload retornado, especialmente
/// útil cuando solo se necesita metadata sin las preguntas completas.
public struct AssessmentProjection: Sendable, Equatable, Hashable {

    /// Incluir metadata básica (id, título, descripción)
    public let includeMetadata: Bool

    /// Incluir preguntas completas
    public let includeQuestions: Bool

    /// Incluir configuración (timeLimit, maxAttempts, etc.)
    public let includeConfiguration: Bool

    /// Incluir información de elegibilidad
    public let includeEligibility: Bool

    // MARK: - Initialization

    public init(
        includeMetadata: Bool = true,
        includeQuestions: Bool = true,
        includeConfiguration: Bool = true,
        includeEligibility: Bool = true
    ) {
        self.includeMetadata = includeMetadata
        self.includeQuestions = includeQuestions
        self.includeConfiguration = includeConfiguration
        self.includeEligibility = includeEligibility
    }

    // MARK: - Presets

    /// Proyección completa (todos los campos)
    public static let full = AssessmentProjection(
        includeMetadata: true,
        includeQuestions: true,
        includeConfiguration: true,
        includeEligibility: true
    )

    /// Solo metadata (sin preguntas)
    public static let metadataOnly = AssessmentProjection(
        includeMetadata: true,
        includeQuestions: false,
        includeConfiguration: true,
        includeEligibility: false
    )

    /// Metadata con elegibilidad (para cards de vista previa)
    public static let preview = AssessmentProjection(
        includeMetadata: true,
        includeQuestions: false,
        includeConfiguration: true,
        includeEligibility: true
    )
}

// MARK: - GetAssessmentQuery

/// Query para obtener una evaluación con proyecciones específicas.
///
/// Esta query permite solicitar solo los campos necesarios de una evaluación,
/// optimizando el payload y el rendimiento. Soporta proyecciones para casos
/// como vista previa (sin preguntas) o solo metadata.
///
/// ## Ejemplo de Uso
/// ```swift
/// // Cargar evaluación completa
/// let fullQuery = GetAssessmentQuery(
///     assessmentId: id,
///     userId: userId,
///     projection: .full
/// )
/// let detail = try await mediator.send(fullQuery)
///
/// // Solo metadata para preview
/// let previewQuery = GetAssessmentQuery(
///     assessmentId: id,
///     userId: userId,
///     projection: .preview
/// )
/// let preview = try await mediator.send(previewQuery)
/// ```
public struct GetAssessmentQuery: Query {

    public typealias Result = AssessmentDetail

    // MARK: - Properties

    /// ID de la evaluación a cargar
    public let assessmentId: UUID

    /// ID del usuario para verificar elegibilidad
    public let userId: UUID

    /// Proyección de campos a incluir
    public let projection: AssessmentProjection

    /// Forzar recarga ignorando cache
    public let forceRefresh: Bool

    /// Metadata opcional para tracing
    public let metadata: [String: String]?

    // MARK: - Initialization

    /// Crea una nueva query para cargar una evaluación.
    ///
    /// - Parameters:
    ///   - assessmentId: ID de la evaluación
    ///   - userId: ID del usuario
    ///   - projection: Campos a incluir (default: .full)
    ///   - forceRefresh: Forzar recarga (default: false)
    ///   - metadata: Metadata opcional para tracing
    public init(
        assessmentId: UUID,
        userId: UUID,
        projection: AssessmentProjection = .full,
        forceRefresh: Bool = false,
        metadata: [String: String]? = nil
    ) {
        self.assessmentId = assessmentId
        self.userId = userId
        self.projection = projection
        self.forceRefresh = forceRefresh
        self.metadata = metadata
    }
}

// MARK: - GetAssessmentQueryHandler

/// Handler que procesa GetAssessmentQuery usando LoadAssessmentUseCase.
///
/// Implementa soporte para proyecciones de campos específicos, aplicando
/// transformaciones sobre el resultado del use case para retornar solo
/// los datos solicitados.
///
/// ## Estrategia de Proyección
/// - **includeQuestions=false**: Limpia array de preguntas (reduce payload)
/// - **includeEligibility=false**: Retorna eligibility por defecto
/// - **includeConfiguration=false**: Limpia campos de configuración
///
/// ## Cache
/// - Hereda la estrategia de cache del LoadAssessmentUseCase (stale-while-revalidate)
/// - Cache diferenciado por proyección para optimizar hits
///
/// ## Ejemplo de Uso
/// ```swift
/// let handler = GetAssessmentQueryHandler(useCase: assessmentUseCase)
/// try await mediator.registerQueryHandler(handler)
/// ```
public actor GetAssessmentQueryHandler: QueryHandler {

    public typealias QueryType = GetAssessmentQuery

    // MARK: - Dependencies

    private let useCase: any LoadAssessmentUseCaseProtocol

    // MARK: - Initialization

    /// Crea un nuevo handler para GetAssessmentQuery.
    ///
    /// - Parameter useCase: Use case que coordina la carga de evaluaciones
    public init(useCase: any LoadAssessmentUseCaseProtocol) {
        self.useCase = useCase
    }

    // MARK: - QueryHandler Implementation

    /// Procesa la query y retorna el assessment detail con proyección aplicada.
    ///
    /// - Parameter query: Query con assessmentId, userId y proyección
    /// - Returns: AssessmentDetail con campos solicitados
    /// - Throws: Error si no se puede cargar la evaluación
    public func handle(_ query: GetAssessmentQuery) async throws -> AssessmentDetail {
        // Crear input para el use case
        let input = LoadAssessmentInput(
            assessmentId: query.assessmentId,
            userId: query.userId,
            forceRefresh: query.forceRefresh
        )

        // Ejecutar use case
        let detail = try await useCase.execute(input: input)

        // Aplicar proyección
        let projectedDetail = applyProjection(detail, with: query.projection)

        return projectedDetail
    }

    // MARK: - Private Methods

    /// Aplica la proyección al AssessmentDetail.
    private func applyProjection(
        _ detail: AssessmentDetail,
        with projection: AssessmentProjection
    ) -> AssessmentDetail {
        let assessment = detail.assessment

        // Crear assessment proyectado
        let projectedAssessment = Assessment(
            id: assessment.id,
            materialId: assessment.materialId,
            title: projection.includeMetadata ? assessment.title : "",
            description: projection.includeMetadata ? assessment.description : nil,
            questions: projection.includeQuestions ? assessment.questions : [],
            timeLimitSeconds: projection.includeConfiguration ? assessment.timeLimitSeconds : nil,
            maxAttempts: projection.includeConfiguration ? assessment.maxAttempts : 0,
            passThreshold: projection.includeConfiguration ? assessment.passThreshold : 0,
            attemptsUsed: projection.includeConfiguration ? assessment.attemptsUsed : 0,
            expiresAt: projection.includeConfiguration ? assessment.expiresAt : nil
        )

        // Crear eligibility proyectada
        let projectedEligibility = projection.includeEligibility
            ? detail.eligibility
            : AssessmentEligibility(canTake: false, attemptsLeft: 0)

        // Retornar detail proyectado
        return AssessmentDetail(
            assessment: projectedAssessment,
            eligibility: projectedEligibility,
            cachedAt: detail.cachedAt,
            isStale: detail.isStale
        )
    }
}
