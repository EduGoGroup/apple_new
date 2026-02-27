import Foundation

/// Read Model optimizado para evaluaciones con proyecciones configurables.
///
/// Este modelo contiene datos de evaluación optimizados para lectura,
/// con soporte para diferentes proyecciones según el caso de uso
/// (preview, full, summary). El TTL varía según el estado de la evaluación.
///
/// # Características
/// - Proyecciones (light, full, summary)
/// - TTL variable según estado (disponible: 10min, en progreso: 2min, expirada: 1h)
/// - Tags para invalidación selectiva
/// - Datos de elegibilidad pre-calculados
///
/// # Proyecciones disponibles
/// - **light**: Solo metadata (título, descripción, configuración básica)
/// - **full**: Todas las preguntas y opciones incluidas
/// - **summary**: Metadata + estadísticas sin preguntas
///
/// # Ejemplo de uso:
/// ```swift
/// // Read model completo
/// let fullModel = AssessmentReadModel(
///     from: assessmentDetail,
///     projection: .full
/// )
///
/// // Solo para preview en lista
/// let lightModel = AssessmentReadModel(
///     from: assessmentDetail,
///     projection: .light
/// )
///
/// await assessmentStore.save(fullModel)
/// ```
public struct AssessmentReadModel: ReadModel {

    // MARK: - ReadModel Protocol

    public var id: String { "assessment-\(assessmentId)-\(projection.rawValue)" }

    public var tags: Set<String> {
        var tags: Set<String> = ["assessment-\(assessmentId)"]
        if let materialId = materialId {
            tags.insert("material-\(materialId)")
        }
        if let userId = userId {
            tags.insert("user-\(userId)")
        }
        return tags
    }

    public let cachedAt: Date

    public var ttlSeconds: TimeInterval {
        switch status {
        case .available:
            return 600 // 10 minutos si está disponible
        case .inProgress:
            return 120 // 2 minutos si está en progreso
        case .completed, .expired:
            return 3600 // 1 hora si ya no cambia
        }
    }

    // MARK: - Identification

    /// ID de la evaluación
    public let assessmentId: UUID

    /// ID del material asociado
    public let materialId: UUID?

    /// ID del usuario (para datos de elegibilidad personalizados)
    public let userId: UUID?

    /// Tipo de proyección usada
    public let projection: AssessmentReadProjection

    // MARK: - Metadata (siempre incluida)

    /// Título de la evaluación
    public let title: String

    /// Descripción de la evaluación
    public let description: String?

    /// Límite de tiempo en segundos
    public let timeLimitSeconds: Int?

    /// Máximo de intentos permitidos
    public let maxAttempts: Int

    /// Umbral de aprobación (porcentaje como Int)
    public let passThreshold: Int

    /// Fecha de expiración
    public let expiresAt: Date?

    // MARK: - Status & Eligibility

    /// Estado actual de la evaluación
    public let status: AssessmentStatus

    /// Datos de elegibilidad pre-calculados
    public let eligibility: EligibilityData

    // MARK: - Questions (solo en proyección full)

    /// Preguntas de la evaluación (nil si proyección != full)
    public let questions: [QuestionSummary]?

    /// Número total de preguntas
    public let questionCount: Int

    // MARK: - Statistics (en proyecciones summary y full)

    /// Estadísticas de la evaluación
    public let statistics: AssessmentStatistics?

    // MARK: - Initialization

    /// Crea un nuevo AssessmentReadModel.
    public init(
        assessmentId: UUID,
        materialId: UUID?,
        userId: UUID?,
        projection: AssessmentReadProjection,
        title: String,
        description: String?,
        timeLimitSeconds: Int?,
        maxAttempts: Int,
        passThreshold: Int,
        expiresAt: Date?,
        status: AssessmentStatus,
        eligibility: EligibilityData,
        questions: [QuestionSummary]?,
        questionCount: Int,
        statistics: AssessmentStatistics?,
        cachedAt: Date = Date()
    ) {
        self.assessmentId = assessmentId
        self.materialId = materialId
        self.userId = userId
        self.projection = projection
        self.title = title
        self.description = description
        self.timeLimitSeconds = timeLimitSeconds
        self.maxAttempts = maxAttempts
        self.passThreshold = passThreshold
        self.expiresAt = expiresAt
        self.status = status
        self.eligibility = eligibility
        self.questions = questions
        self.questionCount = questionCount
        self.statistics = statistics
        self.cachedAt = cachedAt
    }

    /// Crea un AssessmentReadModel desde un AssessmentDetail del use case.
    public init(
        from detail: AssessmentDetail,
        userId: UUID? = nil,
        projection: AssessmentReadProjection = .full
    ) {
        let assessment = detail.assessment

        self.assessmentId = assessment.id
        self.materialId = assessment.materialId
        self.userId = userId
        self.projection = projection
        self.title = assessment.title
        self.description = assessment.description
        self.timeLimitSeconds = assessment.timeLimitSeconds
        self.maxAttempts = assessment.maxAttempts
        self.passThreshold = assessment.passThreshold
        self.expiresAt = assessment.expiresAt
        self.status = AssessmentStatus.from(detail: detail)
        self.eligibility = EligibilityData(from: detail.eligibility)
        self.questionCount = assessment.questions.count

        // Proyección de preguntas
        switch projection {
        case .light:
            self.questions = nil
            self.statistics = nil
        case .summary:
            self.questions = nil
            self.statistics = AssessmentStatistics(from: assessment)
        case .full:
            self.questions = assessment.questions.map { QuestionSummary(from: $0) }
            self.statistics = AssessmentStatistics(from: assessment)
        }

        self.cachedAt = detail.cachedAt ?? Date()
    }
}

// MARK: - Projection Types

/// Tipos de proyección disponibles para AssessmentReadModel.
public enum AssessmentReadProjection: String, Sendable, Equatable {
    /// Solo metadata básica (para listas)
    case light

    /// Metadata + estadísticas (para cards de preview)
    case summary

    /// Modelo completo con preguntas (para tomar evaluación)
    case full
}

// MARK: - Assessment Status

/// Estado de una evaluación desde la perspectiva del usuario.
public enum AssessmentStatus: String, Sendable, Equatable {
    /// Evaluación disponible para tomar
    case available

    /// Evaluación en progreso (tiene intento activo)
    case inProgress = "in_progress"

    /// Evaluación completada (ya tomó todos los intentos)
    case completed

    /// Evaluación expirada
    case expired

    /// Determina el estado desde un AssessmentDetail.
    public static func from(detail: AssessmentDetail) -> AssessmentStatus {
        // Verificar expiración
        if let expiresAt = detail.assessment.expiresAt, expiresAt < Date() {
            return .expired
        }

        // Verificar elegibilidad
        if !detail.eligibility.canTake {
            if detail.eligibility.reason == .noAttemptsLeft {
                return .completed
            }
            if detail.eligibility.reason == .expired {
                return .expired
            }
        }

        // Verificar intentos usados vs máximo
        if detail.assessment.attemptsUsed >= detail.assessment.maxAttempts {
            return .completed
        }

        return .available
    }
}

// MARK: - Eligibility Data

/// Datos de elegibilidad pre-calculados.
public struct EligibilityData: Sendable, Equatable {
    /// Si el usuario puede tomar la evaluación
    public let canTake: Bool

    /// Razón si no puede tomar
    public let reason: String?

    /// Intentos restantes
    public let attemptsLeft: Int

    /// Intentos usados
    public let attemptsUsed: Int

    /// Fecha de expiración de elegibilidad
    public let expiresAt: Date?

    /// Porcentaje de intentos usados
    public var attemptsUsedPercentage: Double {
        let total = attemptsLeft + attemptsUsed
        guard total > 0 else { return 0 }
        return Double(attemptsUsed) / Double(total) * 100
    }

    public init(
        canTake: Bool,
        reason: String?,
        attemptsLeft: Int,
        attemptsUsed: Int,
        expiresAt: Date?
    ) {
        self.canTake = canTake
        self.reason = reason
        self.attemptsLeft = attemptsLeft
        self.attemptsUsed = attemptsUsed
        self.expiresAt = expiresAt
    }

    /// Crea EligibilityData desde AssessmentEligibility del use case.
    public init(from eligibility: AssessmentEligibility) {
        self.canTake = eligibility.canTake
        self.reason = eligibility.reason?.rawValue
        self.attemptsLeft = eligibility.attemptsLeft
        self.attemptsUsed = 0 // Se actualizaría desde otra fuente
        self.expiresAt = eligibility.expiresAt
    }
}

// MARK: - Question Summary

/// Resumen de una pregunta para el read model.
public struct QuestionSummary: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let text: String
    public let type: QuestionType
    public let options: [OptionSummary]
    public let order: Int
    public let isRequired: Bool

    /// Número de opciones
    public var optionCount: Int {
        options.count
    }

    public init(
        id: UUID,
        text: String,
        type: QuestionType,
        options: [OptionSummary],
        order: Int,
        isRequired: Bool = true
    ) {
        self.id = id
        self.text = text
        self.type = type
        self.options = options
        self.order = order
        self.isRequired = isRequired
    }

    /// Crea desde AssessmentQuestion del dominio.
    public init(from question: AssessmentQuestion) {
        self.id = question.id
        self.text = question.text
        self.type = .singleChoice // Default, ya que AssessmentQuestion no tiene type
        self.options = question.options.map { OptionSummary(from: $0) }
        self.order = question.orderIndex
        self.isRequired = question.isRequired
    }
}

/// Tipo de pregunta.
public enum QuestionType: String, Sendable, Equatable {
    case singleChoice = "single_choice"
    case multipleChoice = "multiple_choice"
    case trueFalse = "true_false"
    case openEnded = "open_ended"
}

/// Resumen de una opción de respuesta.
public struct OptionSummary: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let text: String
    public let order: Int

    public init(id: UUID, text: String, order: Int) {
        self.id = id
        self.text = text
        self.order = order
    }

    /// Crea desde QuestionOption del dominio.
    public init(from option: QuestionOption) {
        self.id = option.id
        self.text = option.text
        self.order = option.orderIndex
    }
}

// MARK: - Assessment Statistics

/// Estadísticas pre-calculadas de una evaluación.
public struct AssessmentStatistics: Sendable, Equatable {
    /// Número total de preguntas
    public let totalQuestions: Int

    /// Tiempo límite formateado (ej: "30 min")
    public let formattedTimeLimit: String?

    /// Umbral de aprobación formateado (ej: "70%")
    public let formattedPassThreshold: String

    /// Puntos totales posibles
    public let totalPoints: Int

    /// Puntos mínimos para aprobar
    public let minimumPassingPoints: Int

    public init(
        totalQuestions: Int,
        formattedTimeLimit: String?,
        formattedPassThreshold: String,
        totalPoints: Int,
        minimumPassingPoints: Int
    ) {
        self.totalQuestions = totalQuestions
        self.formattedTimeLimit = formattedTimeLimit
        self.formattedPassThreshold = formattedPassThreshold
        self.totalPoints = totalPoints
        self.minimumPassingPoints = minimumPassingPoints
    }

    /// Crea desde Assessment del dominio.
    public init(from assessment: Assessment) {
        self.totalQuestions = assessment.questions.count

        if let seconds = assessment.timeLimitSeconds {
            let minutes = seconds / 60
            self.formattedTimeLimit = "\(minutes) min"
        } else {
            self.formattedTimeLimit = nil
        }

        self.formattedPassThreshold = "\(assessment.passThreshold)%"

        // Asumiendo 1 punto por pregunta
        self.totalPoints = assessment.questions.count
        self.minimumPassingPoints = Int(ceil(Double(totalPoints) * Double(assessment.passThreshold) / 100))
    }
}

// MARK: - Projection Extension

extension AssessmentReadModel {
    /// Crea una versión con diferente proyección.
    ///
    /// - Parameter newProjection: Nueva proyección a aplicar
    /// - Returns: Nuevo read model con la proyección solicitada
    public func reprojected(to newProjection: AssessmentReadProjection) -> AssessmentReadModel {
        AssessmentReadModel(
            assessmentId: assessmentId,
            materialId: materialId,
            userId: userId,
            projection: newProjection,
            title: title,
            description: description,
            timeLimitSeconds: timeLimitSeconds,
            maxAttempts: maxAttempts,
            passThreshold: passThreshold,
            expiresAt: expiresAt,
            status: status,
            eligibility: eligibility,
            questions: newProjection == .full ? questions : nil,
            questionCount: questionCount,
            statistics: newProjection != .light ? statistics : nil,
            cachedAt: cachedAt
        )
    }
}
