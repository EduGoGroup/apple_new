import Foundation

// MARK: - Teacher Review DTOs

/// Resumen de un intento para la vista de revision del profesor.
///
/// Mapea la respuesta JSON de `GET /api/v1/assessments/{id}/attempts`.
/// Distinto de `AttemptSummaryDTO` (que es para el listado propio del estudiante).
public struct TeacherAttemptSummaryDTO: Codable, Sendable, Equatable, Identifiable {
    /// ID del intento.
    public let attemptId: String

    /// ID del estudiante.
    public let studentId: String

    /// Nombre del estudiante.
    public let studentName: String

    /// Email del estudiante.
    public let studentEmail: String

    /// Puntaje obtenido (nil si aun no calificado).
    public let score: Double?

    /// Puntaje maximo posible.
    public let maxScore: Double?

    /// Porcentaje de puntaje (nil si aun no calificado).
    public let percentage: Double?

    /// Estado del intento (pending_review, completed, etc.).
    public let status: String

    /// Numero de respuestas pendientes de revision.
    public let pendingReviews: Int

    /// Fecha de completado del intento.
    public let completedAt: String?

    public var id: String { attemptId }

    enum CodingKeys: String, CodingKey {
        case attemptId = "attempt_id"
        case studentId = "student_id"
        case studentName = "student_name"
        case studentEmail = "student_email"
        case score
        case maxScore = "max_score"
        case percentage
        case status
        case pendingReviews = "pending_reviews"
        case completedAt = "completed_at"
    }
}

// MARK: - Assessment Stats DTO

/// Estadisticas de un assessment.
///
/// Mapea la respuesta JSON de `GET /api/v1/assessments/{id}/stats`.
public struct AssessmentStatsDTO: Codable, Sendable, Equatable {
    /// Total de intentos registrados.
    public let totalAttempts: Int

    /// Intentos completados.
    public let completedAttempts: Int

    /// Intentos pendientes de revision.
    public let pendingReviews: Int

    /// Puntaje promedio.
    public let averageScore: Double

    /// Puntaje mediano.
    public let medianScore: Double

    /// Puntaje mas alto.
    public let highestScore: Double

    /// Puntaje mas bajo.
    public let lowestScore: Double

    /// Tasa de aprobacion (0.0 - 1.0).
    public let passRate: Double

    /// Tiempo promedio en segundos.
    public let averageTimeSeconds: Int

    /// Estadisticas por pregunta.
    public let questionStats: [QuestionStatDTO]

    enum CodingKeys: String, CodingKey {
        case totalAttempts = "total_attempts"
        case completedAttempts = "completed_attempts"
        case pendingReviews = "pending_reviews"
        case averageScore = "average_score"
        case medianScore = "median_score"
        case highestScore = "highest_score"
        case lowestScore = "lowest_score"
        case passRate = "pass_rate"
        case averageTimeSeconds = "average_time_seconds"
        case questionStats = "question_stats"
    }
}

// MARK: - Question Stat DTO

/// Estadistica de una pregunta individual.
public struct QuestionStatDTO: Codable, Sendable, Equatable {
    /// Indice de la pregunta.
    public let questionIndex: Int

    /// Texto de la pregunta.
    public let questionText: String

    /// Tasa de respuesta correcta (0.0 - 1.0).
    public let correctRate: Double

    /// Puntos promedio obtenidos.
    public let averagePoints: Double

    /// Puntos maximos posibles.
    public let maxPoints: Double

    enum CodingKeys: String, CodingKey {
        case questionIndex = "question_index"
        case questionText = "question_text"
        case correctRate = "correct_rate"
        case averagePoints = "average_points"
        case maxPoints = "max_points"
    }
}

// MARK: - Attempt Review Detail DTO

/// Detalle de un intento para revision del profesor.
///
/// Mapea la respuesta JSON de `GET /api/v1/attempts/{id}/review`.
public struct AttemptReviewDetailDTO: Codable, Sendable, Equatable {
    /// ID del intento.
    public let attemptId: String

    /// Nombre del estudiante.
    public let studentName: String

    /// Email del estudiante.
    public let studentEmail: String

    /// Estado del intento.
    public let status: String

    /// Respuestas del estudiante para revision.
    public let answers: [AnswerForReviewDTO]

    /// Puntaje actual del intento.
    public let currentScore: Double

    /// Puntaje maximo posible.
    public let maxScore: Double

    enum CodingKeys: String, CodingKey {
        case attemptId = "attempt_id"
        case studentName = "student_name"
        case studentEmail = "student_email"
        case status
        case answers
        case currentScore = "current_score"
        case maxScore = "max_score"
    }
}

// MARK: - Answer For Review DTO

/// Respuesta individual de un estudiante para revision.
public struct AnswerForReviewDTO: Codable, Sendable, Equatable, Identifiable {
    /// ID de la respuesta.
    public let answerId: String

    /// Indice de la pregunta.
    public let questionIndex: Int

    /// Texto de la pregunta.
    public let questionText: String

    /// Tipo de pregunta (multiple_choice, open_ended, etc.).
    public let questionType: String

    /// Respuesta del estudiante.
    public let studentAnswer: String?

    /// Respuesta correcta (nil para preguntas abiertas).
    public let correctAnswer: String?

    /// Si la respuesta es correcta (nil si no aplica o pendiente).
    public let isCorrect: Bool?

    /// Puntos obtenidos (nil si pendiente de revision).
    public let pointsEarned: Double?

    /// Puntos maximos posibles.
    public let maxPoints: Double

    /// Estado de revision (auto_graded, pending, reviewed).
    public let reviewStatus: String

    /// Feedback del revisor.
    public let reviewFeedback: String?

    public var id: String { answerId }

    enum CodingKeys: String, CodingKey {
        case answerId = "answer_id"
        case questionIndex = "question_index"
        case questionText = "question_text"
        case questionType = "question_type"
        case studentAnswer = "student_answer"
        case correctAnswer = "correct_answer"
        case isCorrect = "is_correct"
        case pointsEarned = "points_earned"
        case maxPoints = "max_points"
        case reviewStatus = "review_status"
        case reviewFeedback = "review_feedback"
    }
}

// MARK: - Review Answer Request DTO

/// Request para calificar una respuesta individual.
///
/// Usado en `POST /api/v1/attempts/{id}/answers/{answerId}/review`.
public struct ReviewAnswerRequestDTO: Codable, Sendable {
    /// Puntos otorgados.
    public let pointsAwarded: Double

    /// Feedback del revisor.
    public let feedback: String

    public init(pointsAwarded: Double, feedback: String) {
        self.pointsAwarded = pointsAwarded
        self.feedback = feedback
    }

    enum CodingKeys: String, CodingKey {
        case pointsAwarded = "points_awarded"
        case feedback
    }
}
