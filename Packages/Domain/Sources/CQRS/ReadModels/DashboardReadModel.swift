import Foundation
import EduCore

/// Read Model optimizado para el dashboard del estudiante.
///
/// Este modelo contiene todos los datos del dashboard pre-calculados,
/// diseñado para minimizar el procesamiento en tiempo de lectura.
/// Difiere del domain model al incluir datos denormalizados y
/// agregaciones pre-calculadas.
///
/// # Características
/// - Datos pre-calculados (no requiere joins en tiempo de lectura)
/// - TTL de 5 minutos por defecto
/// - Tags para invalidación selectiva (por usuario, por escuela)
/// - Proyecciones light/full disponibles
///
/// # Datos incluidos
/// - Información básica del estudiante
/// - Unidades académicas inscritas (denormalizadas)
/// - Evaluaciones recientes (últimos 5 intentos)
/// - Resumen de progreso (completados, en progreso, pendientes)
/// - Métricas agregadas
///
/// # Ejemplo de uso:
/// ```swift
/// let readModel = DashboardReadModel(
///     userId: studentId,
///     studentName: user.fullName,
///     studentEmail: user.email,
///     enrolledUnits: units.map { EnrolledUnitSummary(from: $0) },
///     recentAssessments: attempts.map { AssessmentAttemptSummary(from: $0) },
///     progress: ProgressData(from: progressSummary)
/// )
///
/// await dashboardStore.save(readModel)
/// ```
public struct DashboardReadModel: ReadModel {

    // MARK: - ReadModel Protocol

    public var id: String { "dashboard-\(userId)" }
    public var tags: Set<String> { ["user-\(userId)"] }
    public let cachedAt: Date
    public var ttlSeconds: TimeInterval { 300 } // 5 minutos

    // MARK: - Student Info

    /// ID del usuario/estudiante
    public let userId: UUID

    /// Nombre completo del estudiante
    public let studentName: String

    /// Email del estudiante
    public let studentEmail: String

    /// URL del avatar (si existe)
    public let avatarURL: URL?

    // MARK: - Enrolled Units (Denormalized)

    /// Unidades académicas inscritas con información resumida
    public let enrolledUnits: [EnrolledUnitSummary]

    // MARK: - Recent Assessments

    /// Intentos de evaluación recientes (máx. 5)
    public let recentAssessments: [AssessmentAttemptSummary]

    // MARK: - Progress Summary (Pre-calculated)

    /// Datos de progreso pre-calculados
    public let progress: ProgressData

    // MARK: - Aggregated Metrics

    /// Total de materiales disponibles
    public let totalMaterials: Int

    /// Total de evaluaciones pendientes
    public let pendingAssessments: Int

    /// Promedio general del estudiante
    public let overallAverage: Double?

    // MARK: - Metadata

    /// Indica si hay errores parciales en los datos
    public let hasPartialErrors: Bool

    /// Mensajes de error parcial (si aplica)
    public let partialErrorMessages: [String]

    // MARK: - Initialization

    /// Crea un nuevo DashboardReadModel.
    public init(
        userId: UUID,
        studentName: String,
        studentEmail: String,
        avatarURL: URL? = nil,
        enrolledUnits: [EnrolledUnitSummary],
        recentAssessments: [AssessmentAttemptSummary],
        progress: ProgressData,
        totalMaterials: Int = 0,
        pendingAssessments: Int = 0,
        overallAverage: Double? = nil,
        hasPartialErrors: Bool = false,
        partialErrorMessages: [String] = [],
        cachedAt: Date = Date()
    ) {
        self.userId = userId
        self.studentName = studentName
        self.studentEmail = studentEmail
        self.avatarURL = avatarURL
        self.enrolledUnits = enrolledUnits
        self.recentAssessments = recentAssessments
        self.progress = progress
        self.totalMaterials = totalMaterials
        self.pendingAssessments = pendingAssessments
        self.overallAverage = overallAverage
        self.hasPartialErrors = hasPartialErrors
        self.partialErrorMessages = partialErrorMessages
        self.cachedAt = cachedAt
    }

    /// Crea un DashboardReadModel desde un StudentDashboard del use case.
    ///
    /// - Parameters:
    ///   - dashboard: Dashboard del use case
    ///   - user: Usuario para información del estudiante
    public init(
        from dashboard: StudentDashboard,
        user: User
    ) {
        self.userId = user.id
        self.studentName = user.fullName
        self.studentEmail = user.email
        self.avatarURL = nil
        self.enrolledUnits = [] // Se llenaría desde otra fuente
        self.recentAssessments = dashboard.recentAttempts.map {
            AssessmentAttemptSummary(from: $0)
        }
        self.progress = ProgressData(from: dashboard.progressSummary)
        self.totalMaterials = dashboard.recentMaterials.count
        self.pendingAssessments = 0
        self.overallAverage = dashboard.progressSummary?.averagePercentage
        self.hasPartialErrors = !dashboard.metadata.partialFailures.isEmpty
        self.partialErrorMessages = dashboard.metadata.partialFailures.map { $0.message }
        self.cachedAt = dashboard.loadedAt
    }
}

// MARK: - Nested Types

/// Resumen de una unidad académica inscrita (denormalizado).
public struct EnrolledUnitSummary: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let name: String
    public let code: String
    public let schoolName: String
    public let materialsCount: Int
    public let completedMaterials: Int
    public let progressPercentage: Double

    public init(
        id: UUID,
        name: String,
        code: String,
        schoolName: String,
        materialsCount: Int,
        completedMaterials: Int,
        progressPercentage: Double
    ) {
        self.id = id
        self.name = name
        self.code = code
        self.schoolName = schoolName
        self.materialsCount = materialsCount
        self.completedMaterials = completedMaterials
        self.progressPercentage = progressPercentage
    }
}

/// Resumen de un intento de evaluación (denormalizado).
public struct AssessmentAttemptSummary: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let materialId: UUID
    public let materialTitle: String
    public let score: Int
    public let maxScore: Int
    public let percentage: Double
    public let passed: Bool
    public let completedAt: Date

    /// Calificación formateada (ej: "8/10")
    public var formattedScore: String {
        "\(score)/\(maxScore)"
    }

    /// Porcentaje formateado (ej: "80%")
    public var formattedPercentage: String {
        String(format: "%.0f%%", percentage)
    }

    public init(
        id: UUID,
        materialId: UUID,
        materialTitle: String,
        score: Int,
        maxScore: Int,
        percentage: Double,
        passed: Bool,
        completedAt: Date
    ) {
        self.id = id
        self.materialId = materialId
        self.materialTitle = materialTitle
        self.score = score
        self.maxScore = maxScore
        self.percentage = percentage
        self.passed = passed
        self.completedAt = completedAt
    }

    /// Crea un summary desde un AssessmentAttempt del use case.
    public init(from attempt: AssessmentAttempt) {
        self.id = attempt.id
        self.materialId = attempt.materialId
        self.materialTitle = attempt.materialTitle
        self.score = attempt.score
        self.maxScore = attempt.maxScore
        self.percentage = attempt.maxScore > 0
            ? Double(attempt.score) / Double(attempt.maxScore) * 100
            : 0
        self.passed = attempt.passed
        self.completedAt = attempt.completedAt
    }
}

/// Datos de progreso pre-calculados.
public struct ProgressData: Sendable, Equatable {
    /// Materiales completados
    public let completed: Int

    /// Materiales en progreso
    public let inProgress: Int

    /// Materiales pendientes
    public let pending: Int

    /// Porcentaje promedio de progreso
    public let averagePercentage: Double

    /// Total de materiales
    public var total: Int {
        completed + inProgress + pending
    }

    /// Porcentaje de completitud
    public var completionPercentage: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total) * 100
    }

    public init(
        completed: Int,
        inProgress: Int,
        pending: Int,
        averagePercentage: Double
    ) {
        self.completed = completed
        self.inProgress = inProgress
        self.pending = pending
        self.averagePercentage = averagePercentage
    }

    /// Crea ProgressData desde ProgressSummary del use case.
    public init(from summary: ProgressSummary?) {
        if let summary = summary {
            self.completed = summary.completed
            self.inProgress = summary.inProgress
            self.pending = summary.pending
            self.averagePercentage = summary.averagePercentage
        } else {
            self.completed = 0
            self.inProgress = 0
            self.pending = 0
            self.averagePercentage = 0
        }
    }

    /// ProgressData vacío.
    public static let empty = ProgressData(
        completed: 0,
        inProgress: 0,
        pending: 0,
        averagePercentage: 0
    )
}

// MARK: - Projections

/// Proyecciones disponibles para DashboardReadModel.
public enum DashboardProjection: Sendable {
    /// Solo información básica del estudiante
    case studentInfo

    /// Estudiante + progreso (sin unidades ni evaluaciones)
    case summary

    /// Modelo completo
    case full
}

extension DashboardReadModel {
    /// Aplica una proyección al read model.
    ///
    /// - Parameter projection: Tipo de proyección a aplicar
    /// - Returns: Nuevo DashboardReadModel con solo los campos relevantes
    public func projected(_ projection: DashboardProjection) -> DashboardReadModel {
        switch projection {
        case .studentInfo:
            return DashboardReadModel(
                userId: userId,
                studentName: studentName,
                studentEmail: studentEmail,
                avatarURL: avatarURL,
                enrolledUnits: [],
                recentAssessments: [],
                progress: .empty,
                totalMaterials: 0,
                pendingAssessments: 0,
                overallAverage: nil,
                hasPartialErrors: false,
                partialErrorMessages: [],
                cachedAt: cachedAt
            )

        case .summary:
            return DashboardReadModel(
                userId: userId,
                studentName: studentName,
                studentEmail: studentEmail,
                avatarURL: avatarURL,
                enrolledUnits: [],
                recentAssessments: [],
                progress: progress,
                totalMaterials: totalMaterials,
                pendingAssessments: pendingAssessments,
                overallAverage: overallAverage,
                hasPartialErrors: hasPartialErrors,
                partialErrorMessages: partialErrorMessages,
                cachedAt: cachedAt
            )

        case .full:
            return self
        }
    }
}
