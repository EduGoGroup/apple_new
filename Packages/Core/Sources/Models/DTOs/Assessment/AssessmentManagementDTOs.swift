import Foundation

// MARK: - Request DTOs

/// Request para crear o actualizar un assessment.
///
/// Usado en `POST /api/v1/assessments` y `PUT /api/v1/assessments/{id}`.
public struct CreateAssessmentRequestDTO: Encodable, Sendable {
    public let title: String
    public let description: String?
    public let sourceType: String
    public let passThreshold: Double?
    public let maxAttempts: Int?
    public let timeLimitMinutes: Double?
    public let isTimed: Bool?
    public let shuffleQuestions: Bool?
    public let showCorrectAnswers: Bool?

    public init(
        title: String,
        description: String? = nil,
        sourceType: String,
        passThreshold: Double? = nil,
        maxAttempts: Int? = nil,
        timeLimitMinutes: Double? = nil,
        isTimed: Bool? = nil,
        shuffleQuestions: Bool? = nil,
        showCorrectAnswers: Bool? = nil
    ) {
        self.title = title
        self.description = description
        self.sourceType = sourceType
        self.passThreshold = passThreshold
        self.maxAttempts = maxAttempts
        self.timeLimitMinutes = timeLimitMinutes
        self.isTimed = isTimed
        self.shuffleQuestions = shuffleQuestions
        self.showCorrectAnswers = showCorrectAnswers
    }

    enum CodingKeys: String, CodingKey {
        case title, description
        case sourceType = "source_type"
        case passThreshold = "pass_threshold"
        case maxAttempts = "max_attempts"
        case timeLimitMinutes = "time_limit_minutes"
        case isTimed = "is_timed"
        case shuffleQuestions = "shuffle_questions"
        case showCorrectAnswers = "show_correct_answers"
    }
}

/// Request para crear o actualizar una pregunta.
///
/// Usado en `POST /api/v1/assessments/{id}/questions` y
/// `PUT /api/v1/assessments/{id}/questions/{questionId}`.
public struct CreateQuestionRequestDTO: Encodable, Sendable {
    public let questionText: String
    public let questionType: String
    public let options: [QuestionOptionRequestDTO]?
    public let correctAnswer: String?
    public let explanation: String?
    public let points: Double
    public let difficulty: String?
    public let tags: [String]?

    public init(
        questionText: String,
        questionType: String,
        options: [QuestionOptionRequestDTO]? = nil,
        correctAnswer: String? = nil,
        explanation: String? = nil,
        points: Double,
        difficulty: String? = nil,
        tags: [String]? = nil
    ) {
        self.questionText = questionText
        self.questionType = questionType
        self.options = options
        self.correctAnswer = correctAnswer
        self.explanation = explanation
        self.points = points
        self.difficulty = difficulty
        self.tags = tags
    }

    enum CodingKeys: String, CodingKey {
        case questionText = "question_text"
        case questionType = "question_type"
        case options
        case correctAnswer = "correct_answer"
        case explanation, points, difficulty, tags
    }
}

/// Opcion de respuesta en un request de creacion de pregunta.
public struct QuestionOptionRequestDTO: Encodable, Sendable {
    public let optionText: String
    public let sortOrder: Int

    public init(optionText: String, sortOrder: Int) {
        self.optionText = optionText
        self.sortOrder = sortOrder
    }

    enum CodingKeys: String, CodingKey {
        case optionText = "option_text"
        case sortOrder = "sort_order"
    }
}

/// Request para asignar un assessment a estudiantes o unidades.
///
/// Usado en `POST /api/v1/assessments/{id}/assign`.
public struct AssignAssessmentRequestDTO: Encodable, Sendable {
    public let studentIds: [String]?
    public let academicUnitId: String?
    public let dueDate: String?

    public init(
        studentIds: [String]? = nil,
        academicUnitId: String? = nil,
        dueDate: String? = nil
    ) {
        self.studentIds = studentIds
        self.academicUnitId = academicUnitId
        self.dueDate = dueDate
    }

    enum CodingKeys: String, CodingKey {
        case studentIds = "student_ids"
        case academicUnitId = "academic_unit_id"
        case dueDate = "due_date"
    }
}

/// Request para reordenar preguntas de un assessment.
///
/// Usado en `POST /api/v1/assessments/{id}/questions/reorder`.
public struct ReorderQuestionsRequestDTO: Encodable, Sendable {
    public let questionIds: [String]

    public init(questionIds: [String]) {
        self.questionIds = questionIds
    }

    enum CodingKeys: String, CodingKey {
        case questionIds = "question_ids"
    }
}

// MARK: - Response DTOs

/// Respuesta de gestion de un assessment (crear, actualizar, listar, detalle).
///
/// Mapea la respuesta JSON de los endpoints de gestion de assessments.
public struct AssessmentManagementResponseDTO: Decodable, Sendable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public let description: String?
    public let questionsCount: Int
    public let passThreshold: Double?
    public let maxAttempts: Int?
    public let timeLimitMinutes: Double?
    public let isTimed: Bool
    public let shuffleQuestions: Bool
    public let showCorrectAnswers: Bool
    public let status: String
    public let sourceType: String?
    public let createdAt: String
    public let updatedAt: String

    public init(
        id: String,
        title: String,
        description: String? = nil,
        questionsCount: Int = 0,
        passThreshold: Double? = nil,
        maxAttempts: Int? = nil,
        timeLimitMinutes: Double? = nil,
        isTimed: Bool = false,
        shuffleQuestions: Bool = false,
        showCorrectAnswers: Bool = true,
        status: String = "draft",
        sourceType: String? = nil,
        createdAt: String = "",
        updatedAt: String = ""
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.questionsCount = questionsCount
        self.passThreshold = passThreshold
        self.maxAttempts = maxAttempts
        self.timeLimitMinutes = timeLimitMinutes
        self.isTimed = isTimed
        self.shuffleQuestions = shuffleQuestions
        self.showCorrectAnswers = showCorrectAnswers
        self.status = status
        self.sourceType = sourceType
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, title, description, status
        case questionsCount = "questions_count"
        case passThreshold = "pass_threshold"
        case maxAttempts = "max_attempts"
        case timeLimitMinutes = "time_limit_minutes"
        case isTimed = "is_timed"
        case shuffleQuestions = "shuffle_questions"
        case showCorrectAnswers = "show_correct_answers"
        case sourceType = "source_type"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Respuesta de una pregunta de assessment.
public struct QuestionResponseDTO: Decodable, Sendable, Equatable, Identifiable {
    public let id: String
    public let sortOrder: Int
    public let questionText: String
    public let questionType: String
    public let options: [QuestionOptionResponseDTO]?
    public let correctAnswer: String?
    public let explanation: String?
    public let points: Double
    public let difficulty: String?
    public let tags: [String]?

    public init(
        id: String,
        sortOrder: Int = 0,
        questionText: String,
        questionType: String,
        options: [QuestionOptionResponseDTO]? = nil,
        correctAnswer: String? = nil,
        explanation: String? = nil,
        points: Double = 1.0,
        difficulty: String? = nil,
        tags: [String]? = nil
    ) {
        self.id = id
        self.sortOrder = sortOrder
        self.questionText = questionText
        self.questionType = questionType
        self.options = options
        self.correctAnswer = correctAnswer
        self.explanation = explanation
        self.points = points
        self.difficulty = difficulty
        self.tags = tags
    }

    enum CodingKeys: String, CodingKey {
        case id
        case sortOrder = "sort_order"
        case questionText = "question_text"
        case questionType = "question_type"
        case options
        case correctAnswer = "correct_answer"
        case explanation, points, difficulty, tags
    }
}

/// Opcion de respuesta en una pregunta (response).
public struct QuestionOptionResponseDTO: Decodable, Sendable, Equatable, Identifiable {
    public let id: String
    public let optionText: String
    public let sortOrder: Int

    public init(id: String, optionText: String, sortOrder: Int) {
        self.id = id
        self.optionText = optionText
        self.sortOrder = sortOrder
    }

    enum CodingKeys: String, CodingKey {
        case id
        case optionText = "option_text"
        case sortOrder = "sort_order"
    }
}

/// Respuesta de una asignacion de assessment.
public struct AssignmentResponseDTO: Decodable, Sendable, Equatable, Identifiable {
    public let id: String
    public let assessmentId: String
    public let studentId: String?
    public let academicUnitId: String?
    public let assignedBy: String
    public let assignedAt: String
    public let dueDate: String?

    public init(
        id: String,
        assessmentId: String,
        studentId: String? = nil,
        academicUnitId: String? = nil,
        assignedBy: String = "",
        assignedAt: String = "",
        dueDate: String? = nil
    ) {
        self.id = id
        self.assessmentId = assessmentId
        self.studentId = studentId
        self.academicUnitId = academicUnitId
        self.assignedBy = assignedBy
        self.assignedAt = assignedAt
        self.dueDate = dueDate
    }

    enum CodingKeys: String, CodingKey {
        case id
        case assessmentId = "assessment_id"
        case studentId = "student_id"
        case academicUnitId = "academic_unit_id"
        case assignedBy = "assigned_by"
        case assignedAt = "assigned_at"
        case dueDate = "due_date"
    }
}

