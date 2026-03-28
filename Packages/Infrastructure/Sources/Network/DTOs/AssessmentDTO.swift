import Foundation

// MARK: - Assessment Response DTO

/// Respuesta de un assessment del backend.
///
/// Mapea la respuesta JSON de `GET /api/v1/assessments/{id}`.
public struct AssessmentDTO: Decodable, Sendable, Equatable {
    /// Identificador unico del assessment.
    public let id: String

    /// ID del material asociado.
    public let materialId: String

    /// Titulo del assessment.
    public let title: String

    /// Descripcion del assessment.
    public let description: String?

    /// Preguntas del assessment.
    public let questions: [AssessmentQuestionDTO]

    /// Limite de tiempo en segundos.
    public let timeLimitSeconds: Int?

    /// Maximo de intentos permitidos.
    public let maxAttempts: Int

    /// Umbral de aprobacion (porcentaje como Int).
    public let passThreshold: Int

    /// Intentos ya usados por el usuario.
    public let attemptsUsed: Int

    /// Fecha de expiracion del assessment.
    public let expiresAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case materialId = "material_id"
        case title
        case description
        case questions
        case timeLimitSeconds = "time_limit_seconds"
        case maxAttempts = "max_attempts"
        case passThreshold = "pass_threshold"
        case attemptsUsed = "attempts_used"
        case expiresAt = "expires_at"
    }
}

// MARK: - Assessment Question DTO

/// Pregunta de un assessment del backend.
public struct AssessmentQuestionDTO: Decodable, Sendable, Equatable {
    /// Identificador unico de la pregunta.
    public let id: String

    /// Texto de la pregunta.
    public let text: String

    /// Tipo de pregunta (multiple_choice, true_false, open_ended, short_answer).
    public let questionType: String

    /// Opciones de respuesta.
    public let options: [AssessmentQuestionOptionDTO]

    /// Si la pregunta es obligatoria.
    public let isRequired: Bool

    /// Indice de orden de la pregunta.
    public let orderIndex: Int

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case questionType = "question_type"
        case options
        case isRequired = "is_required"
        case orderIndex = "order_index"
    }
}

// MARK: - Assessment Question Option DTO

/// Opcion de respuesta de una pregunta.
public struct AssessmentQuestionOptionDTO: Decodable, Sendable, Equatable {
    /// Identificador unico de la opcion.
    public let id: String

    /// Texto de la opcion.
    public let text: String

    /// Indice de orden de la opcion.
    public let orderIndex: Int

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case orderIndex = "order_index"
    }
}

// MARK: - Eligibility Response DTO

/// Respuesta de elegibilidad del backend.
///
/// Mapea la respuesta JSON de `GET /api/v1/assessments/{id}/eligibility`.
public struct EligibilityDTO: Decodable, Sendable, Equatable {
    /// Si el usuario puede tomar la evaluacion.
    public let canTake: Bool

    /// Razon si no puede tomar (nil si canTake=true).
    public let reason: String?

    /// Intentos restantes.
    public let attemptsLeft: Int

    /// Fecha de expiracion de la elegibilidad.
    public let expiresAt: Date?

    enum CodingKeys: String, CodingKey {
        case canTake = "can_take"
        case reason
        case attemptsLeft = "attempts_left"
        case expiresAt = "expires_at"
    }
}

// MARK: - Start Attempt Response DTO

/// Respuesta al iniciar un intento.
///
/// Mapea la respuesta JSON de `POST /api/v1/assessments/{id}/start`.
public struct StartAttemptResponseDTO: Decodable, Sendable, Equatable {
    /// ID del intento creado.
    public let attemptId: String

    enum CodingKeys: String, CodingKey {
        case attemptId = "attempt_id"
    }
}

// MARK: - Save Answer Request DTO

/// Request para guardar una respuesta individual.
///
/// Usado en `PUT /api/v1/attempts/{attemptId}/answers/{questionIndex}`.
public struct SaveAnswerRequestDTO: Encodable, Sendable, Equatable {
    /// ID de la pregunta.
    public let questionId: String

    /// ID de la opcion seleccionada.
    public let selectedOptionId: String

    /// Tiempo empleado en la pregunta en segundos.
    public let timeSpentSeconds: Int

    public init(questionId: String, selectedOptionId: String, timeSpentSeconds: Int) {
        self.questionId = questionId
        self.selectedOptionId = selectedOptionId
        self.timeSpentSeconds = timeSpentSeconds
    }

    enum CodingKeys: String, CodingKey {
        case questionId = "question_id"
        case selectedOptionId = "selected_option_id"
        case timeSpentSeconds = "time_spent_seconds"
    }
}

// MARK: - Submit Attempt Request DTO

/// Request para enviar un intento completo.
///
/// Usado en `POST /api/v1/attempts/{attemptId}/submit`.
public struct SubmitAttemptRequestDTO: Encodable, Sendable, Equatable {
    /// Respuestas del usuario.
    public let answers: [AnswerSubmissionDTO]

    /// Tiempo total empleado en segundos.
    public let timeSpentSeconds: Int

    /// Clave de idempotencia para prevenir duplicados.
    public let idempotencyKey: String

    public init(answers: [AnswerSubmissionDTO], timeSpentSeconds: Int, idempotencyKey: String) {
        self.answers = answers
        self.timeSpentSeconds = timeSpentSeconds
        self.idempotencyKey = idempotencyKey
    }

    enum CodingKeys: String, CodingKey {
        case answers
        case timeSpentSeconds = "time_spent_seconds"
        case idempotencyKey = "idempotency_key"
    }
}

// MARK: - Answer Submission DTO

/// Una respuesta individual dentro del submit.
public struct AnswerSubmissionDTO: Encodable, Sendable, Equatable {
    /// ID de la pregunta.
    public let questionId: String

    /// ID de la opcion seleccionada.
    public let selectedOptionId: String

    /// Tiempo empleado en la pregunta en segundos.
    public let timeSpentSeconds: Int

    /// Fecha en que se respondio.
    public let answeredAt: Date

    public init(questionId: String, selectedOptionId: String, timeSpentSeconds: Int, answeredAt: Date) {
        self.questionId = questionId
        self.selectedOptionId = selectedOptionId
        self.timeSpentSeconds = timeSpentSeconds
        self.answeredAt = answeredAt
    }

    enum CodingKeys: String, CodingKey {
        case questionId = "question_id"
        case selectedOptionId = "selected_option_id"
        case timeSpentSeconds = "time_spent_seconds"
        case answeredAt = "answered_at"
    }
}

// MARK: - Attempt Result DTO (v2)

/// Resultado de un intento del nuevo endpoint de assessments.
///
/// Mapea la respuesta JSON de:
/// - `POST /api/v1/attempts/{attemptId}/submit`
/// - `GET /api/v1/attempts/{attemptId}/results`
public struct AttemptResultResponseDTO: Decodable, Sendable, Equatable {
    /// ID del intento.
    public let attemptId: String

    /// ID del assessment.
    public let assessmentId: String

    /// ID del usuario.
    public let userId: String

    /// Puntaje obtenido.
    public let score: Int

    /// Puntaje maximo posible.
    public let maxScore: Int

    /// Indica si el usuario aprobo.
    public let passed: Bool

    /// Numero de respuestas correctas.
    public let correctAnswers: Int

    /// Numero total de preguntas.
    public let totalQuestions: Int

    /// Tiempo total empleado en segundos.
    public let timeSpentSeconds: Int

    /// Feedback detallado por pregunta.
    public let feedback: [AnswerFeedbackDTO]

    /// Fecha de inicio del intento.
    public let startedAt: Date

    /// Fecha de finalizacion del intento.
    public let completedAt: Date

    /// Indica si puede reintentar.
    public let canRetake: Bool

    enum CodingKeys: String, CodingKey {
        case attemptId = "attempt_id"
        case assessmentId = "assessment_id"
        case userId = "user_id"
        case score
        case maxScore = "max_score"
        case passed
        case correctAnswers = "correct_answers"
        case totalQuestions = "total_questions"
        case timeSpentSeconds = "time_spent_seconds"
        case feedback
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case canRetake = "can_retake"
    }
}

// MARK: - Answer Feedback DTO

/// Feedback de una pregunta individual del nuevo endpoint.
public struct AnswerFeedbackDTO: Decodable, Sendable, Equatable {
    /// ID de la pregunta.
    public let questionId: String

    /// Indica si la respuesta fue correcta.
    public let isCorrect: Bool

    /// ID de la opcion correcta.
    public let correctOptionId: String

    /// Explicacion del feedback.
    public let explanation: String?

    /// ID de la opcion que el estudiante selecciono (nil si el backend no lo incluye).
    public let studentSelectedOptionId: String?

    enum CodingKeys: String, CodingKey {
        case questionId = "question_id"
        case isCorrect = "is_correct"
        case correctOptionId = "correct_option_id"
        case explanation
        case studentSelectedOptionId = "student_selected_option_id"
    }
}

// MARK: - Paginated Attempts DTO

/// Respuesta paginada de intentos del usuario.
///
/// Mapea la respuesta JSON de `GET /api/v1/users/me/attempts`.
public struct PaginatedAttemptsDTO: Decodable, Sendable, Equatable {
    /// Lista de intentos.
    public let items: [AttemptSummaryDTO]

    /// Numero total de intentos.
    public let totalCount: Int

    /// Pagina actual.
    public let page: Int

    /// Tamano de pagina.
    public let pageSize: Int

    enum CodingKeys: String, CodingKey {
        case items
        case totalCount = "total_count"
        case page
        case pageSize = "page_size"
    }
}

// MARK: - Attempt Summary DTO

/// Resumen de un intento (para listados).
public struct AttemptSummaryDTO: Decodable, Sendable, Equatable {
    /// ID del intento.
    public let attemptId: String

    /// ID del assessment.
    public let assessmentId: String

    /// Puntaje obtenido.
    public let score: Int

    /// Puntaje maximo.
    public let maxScore: Int

    /// Indica si aprobo.
    public let passed: Bool

    /// Fecha de finalizacion.
    public let completedAt: Date

    enum CodingKeys: String, CodingKey {
        case attemptId = "attempt_id"
        case assessmentId = "assessment_id"
        case score
        case maxScore = "max_score"
        case passed
        case completedAt = "completed_at"
    }
}
