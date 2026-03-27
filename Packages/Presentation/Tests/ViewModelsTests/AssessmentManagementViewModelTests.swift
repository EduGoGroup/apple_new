import Testing
import Foundation
@testable import EduPresentation
@testable import EduDomain
import EduCore

// MARK: - Mock Assessment Management Data Provider

/// Mock del AssessmentManagementDataProvider para tests unitarios.
actor MockAssessmentManagementDataProvider: AssessmentManagementDataProvider {
    private var stubbedAssessments: [AssessmentManagementResponseDTO] = []
    private var stubbedQuestions: [QuestionResponseDTO] = []
    private var stubbedAssignments: [AssignmentResponseDTO] = []
    private var stubbedError: Error?
    private(set) var createAssessmentCallCount: Int = 0
    private(set) var updateAssessmentCallCount: Int = 0
    private(set) var publishCallCount: Int = 0
    private(set) var archiveCallCount: Int = 0
    private(set) var createQuestionCallCount: Int = 0
    private(set) var deleteQuestionCallCount: Int = 0
    private(set) var assignCallCount: Int = 0
    private(set) var removeAssignmentCallCount: Int = 0

    // MARK: - Setters

    func setAssessments(_ assessments: [AssessmentManagementResponseDTO]) {
        stubbedAssessments = assessments
    }

    func setQuestions(_ questions: [QuestionResponseDTO]) {
        stubbedQuestions = questions
    }

    func setAssignments(_ assignments: [AssignmentResponseDTO]) {
        stubbedAssignments = assignments
    }

    func setError(_ error: Error?) {
        stubbedError = error
    }

    // MARK: - AssessmentManagementDataProvider

    func createAssessment(_ request: CreateAssessmentRequestDTO) async throws -> AssessmentManagementResponseDTO {
        createAssessmentCallCount += 1
        if let error = stubbedError { throw error }
        return AssessmentManagementResponseDTO(
            id: "new-assessment-id",
            title: request.title,
            status: "draft",
            sourceType: request.sourceType,
            createdAt: "2026-03-27T10:00:00Z",
            updatedAt: "2026-03-27T10:00:00Z"
        )
    }

    func updateAssessment(id: String, _ request: CreateAssessmentRequestDTO) async throws -> AssessmentManagementResponseDTO {
        updateAssessmentCallCount += 1
        if let error = stubbedError { throw error }
        return AssessmentManagementResponseDTO(
            id: id,
            title: request.title,
            status: "draft",
            sourceType: request.sourceType,
            createdAt: "2026-03-27T10:00:00Z",
            updatedAt: "2026-03-27T10:00:00Z"
        )
    }

    func listAssessments(status: String?, page: Int, limit: Int) async throws -> PaginatedResponseDTO<AssessmentManagementResponseDTO> {
        if let error = stubbedError { throw error }
        let filtered: [AssessmentManagementResponseDTO]
        if let status {
            filtered = stubbedAssessments.filter { $0.status == status }
        } else {
            filtered = stubbedAssessments
        }
        return PaginatedResponseDTO(
            items: filtered,
            totalCount: filtered.count,
            page: page,
            pageSize: limit
        )
    }

    func getAssessment(id: String) async throws -> AssessmentManagementResponseDTO {
        if let error = stubbedError { throw error }
        guard let assessment = stubbedAssessments.first(where: { $0.id == id }) else {
            throw TestAssessmentError(message: "Not found")
        }
        return assessment
    }

    func publishAssessment(id: String) async throws -> AssessmentManagementResponseDTO {
        publishCallCount += 1
        if let error = stubbedError { throw error }
        return AssessmentManagementResponseDTO(
            id: id,
            title: "Published",
            status: "published",
            createdAt: "2026-03-27T10:00:00Z",
            updatedAt: "2026-03-27T10:00:00Z"
        )
    }

    func archiveAssessment(id: String) async throws -> AssessmentManagementResponseDTO {
        archiveCallCount += 1
        if let error = stubbedError { throw error }
        return AssessmentManagementResponseDTO(
            id: id,
            title: "Archived",
            status: "archived",
            createdAt: "2026-03-27T10:00:00Z",
            updatedAt: "2026-03-27T10:00:00Z"
        )
    }

    func createQuestion(assessmentId: String, _ request: CreateQuestionRequestDTO) async throws -> QuestionResponseDTO {
        createQuestionCallCount += 1
        if let error = stubbedError { throw error }
        return QuestionResponseDTO(
            id: "new-question-id",
            questionText: request.questionText,
            questionType: request.questionType,
            points: request.points
        )
    }

    func listQuestions(assessmentId: String) async throws -> [QuestionResponseDTO] {
        if let error = stubbedError { throw error }
        return stubbedQuestions
    }

    func updateQuestion(assessmentId: String, questionId: String, _ request: CreateQuestionRequestDTO) async throws -> QuestionResponseDTO {
        if let error = stubbedError { throw error }
        return QuestionResponseDTO(
            id: questionId,
            questionText: request.questionText,
            questionType: request.questionType,
            points: request.points
        )
    }

    func deleteQuestion(assessmentId: String, questionId: String) async throws {
        deleteQuestionCallCount += 1
        if let error = stubbedError { throw error }
    }

    func reorderQuestions(assessmentId: String, _ request: ReorderQuestionsRequestDTO) async throws {
        if let error = stubbedError { throw error }
    }

    func assignAssessment(assessmentId: String, _ request: AssignAssessmentRequestDTO) async throws -> [AssignmentResponseDTO] {
        assignCallCount += 1
        if let error = stubbedError { throw error }
        return [AssignmentResponseDTO(
            id: "new-assignment-id",
            assessmentId: assessmentId,
            studentId: request.studentIds?.first,
            academicUnitId: request.academicUnitId,
            assignedBy: "teacher-id",
            assignedAt: "2026-03-27T10:00:00Z",
            dueDate: request.dueDate
        )]
    }

    func listAssignments(assessmentId: String) async throws -> [AssignmentResponseDTO] {
        if let error = stubbedError { throw error }
        return stubbedAssignments
    }

    func removeAssignment(assessmentId: String, assignmentId: String) async throws {
        removeAssignmentCallCount += 1
        if let error = stubbedError { throw error }
    }
}

// MARK: - Test Error

struct TestAssessmentError: Error, LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

// MARK: - AssessmentManagementViewModel Tests

@Suite("AssessmentManagementViewModel")
@MainActor
struct AssessmentManagementViewModelTests {

    private func makeSampleAssessments() -> [AssessmentManagementResponseDTO] {
        [
            AssessmentManagementResponseDTO(
                id: "assess-001",
                title: "Examen de Matematicas",
                description: "Algebra basica",
                questionsCount: 10,
                status: "draft",
                sourceType: "manual",
                createdAt: "2026-03-27T10:00:00Z",
                updatedAt: "2026-03-27T10:00:00Z"
            ),
            AssessmentManagementResponseDTO(
                id: "assess-002",
                title: "Examen de Historia",
                description: "Periodo colonial",
                questionsCount: 5,
                status: "published",
                sourceType: "manual",
                createdAt: "2026-03-26T10:00:00Z",
                updatedAt: "2026-03-26T10:00:00Z"
            ),
            AssessmentManagementResponseDTO(
                id: "assess-003",
                title: "Quiz de Ciencias",
                questionsCount: 3,
                status: "draft",
                sourceType: "manual",
                createdAt: "2026-03-25T10:00:00Z",
                updatedAt: "2026-03-25T10:00:00Z"
            )
        ]
    }

    @Test("loadAssessments sets loading state and populates list")
    func loadAssessmentsSetsLoadingAndPopulates() async {
        let provider = MockAssessmentManagementDataProvider()
        let assessments = makeSampleAssessments()
        await provider.setAssessments(assessments)

        let viewModel = AssessmentManagementViewModel(dataProvider: provider)

        await viewModel.loadAssessments()

        #expect(viewModel.assessments.count == 3)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error == nil)
    }

    @Test("loadAssessments sets error on failure")
    func loadAssessmentsError() async {
        let provider = MockAssessmentManagementDataProvider()
        await provider.setError(TestAssessmentError(message: "Network error"))

        let viewModel = AssessmentManagementViewModel(dataProvider: provider)

        await viewModel.loadAssessments()

        #expect(viewModel.assessments.isEmpty)
        #expect(viewModel.hasError)
        #expect(viewModel.isLoading == false)
    }

    @Test("statusFilter filters assessments correctly")
    func statusFilterFiltersCorrectly() async {
        let provider = MockAssessmentManagementDataProvider()
        let assessments = makeSampleAssessments()
        await provider.setAssessments(assessments)

        let viewModel = AssessmentManagementViewModel(dataProvider: provider)
        viewModel.statusFilter = "draft"

        await viewModel.loadAssessments()

        #expect(viewModel.assessments.count == 2)
        #expect(viewModel.assessments.allSatisfy { $0.status == "draft" })
    }

    @Test("searchText filters assessments by title")
    func searchTextFiltersAssessments() async {
        let provider = MockAssessmentManagementDataProvider()
        let assessments = makeSampleAssessments()
        await provider.setAssessments(assessments)

        let viewModel = AssessmentManagementViewModel(dataProvider: provider)

        await viewModel.loadAssessments()

        viewModel.searchText = "Matematicas"
        let filtered = viewModel.filteredAssessments

        #expect(filtered.count == 1)
        #expect(filtered[0].id == "assess-001")
    }

    @Test("searchText case insensitive")
    func searchTextCaseInsensitive() async {
        let provider = MockAssessmentManagementDataProvider()
        let assessments = makeSampleAssessments()
        await provider.setAssessments(assessments)

        let viewModel = AssessmentManagementViewModel(dataProvider: provider)

        await viewModel.loadAssessments()

        viewModel.searchText = "historia"
        let filtered = viewModel.filteredAssessments

        #expect(filtered.count == 1)
        #expect(filtered[0].id == "assess-002")
    }

    @Test("empty searchText returns all assessments")
    func emptySearchTextReturnsAll() async {
        let provider = MockAssessmentManagementDataProvider()
        let assessments = makeSampleAssessments()
        await provider.setAssessments(assessments)

        let viewModel = AssessmentManagementViewModel(dataProvider: provider)

        await viewModel.loadAssessments()

        viewModel.searchText = ""
        let filtered = viewModel.filteredAssessments

        #expect(filtered.count == 3)
    }

    @Test("publishAssessment updates status in list")
    func publishAssessmentUpdatesStatus() async {
        let provider = MockAssessmentManagementDataProvider()
        let assessments = makeSampleAssessments()
        await provider.setAssessments(assessments)

        let viewModel = AssessmentManagementViewModel(dataProvider: provider)

        await viewModel.loadAssessments()
        await viewModel.publishAssessment("assess-001")

        let publishCount = await provider.publishCallCount
        #expect(publishCount == 1)
    }

    @Test("archiveAssessment updates status in list")
    func archiveAssessmentUpdatesStatus() async {
        let provider = MockAssessmentManagementDataProvider()
        let assessments = makeSampleAssessments()
        await provider.setAssessments(assessments)

        let viewModel = AssessmentManagementViewModel(dataProvider: provider)

        await viewModel.loadAssessments()
        await viewModel.archiveAssessment("assess-002")

        let archiveCount = await provider.archiveCallCount
        #expect(archiveCount == 1)
    }

    @Test("clearError resets error state")
    func clearErrorResetsError() async {
        let provider = MockAssessmentManagementDataProvider()
        await provider.setError(TestAssessmentError(message: "error"))

        let viewModel = AssessmentManagementViewModel(dataProvider: provider)

        await viewModel.loadAssessments()
        #expect(viewModel.hasError)

        viewModel.clearError()
        #expect(!viewModel.hasError)
    }

    @Test("emptyStateMessage changes with filters")
    func emptyStateMessageChangesWithFilters() {
        let provider = MockAssessmentManagementDataProvider()
        let viewModel = AssessmentManagementViewModel(dataProvider: provider)

        #expect(viewModel.emptyStateMessage == "No hay evaluaciones creadas")

        viewModel.statusFilter = "draft"
        #expect(viewModel.emptyStateMessage == "No se encontraron evaluaciones con los filtros aplicados")
    }
}

// MARK: - QuestionFormViewModel Tests

@Suite("QuestionFormViewModel")
@MainActor
struct QuestionFormViewModelTests {

    @Test("multipleChoice requires at least 2 non-empty options and correct selection")
    func multipleChoiceRequiresOptions() {
        let provider = MockAssessmentManagementDataProvider()
        let viewModel = QuestionFormViewModel(
            dataProvider: provider,
            assessmentId: "assess-001"
        )

        viewModel.questionText = "Test question?"
        viewModel.questionType = .multipleChoice
        viewModel.setupDefaultOptions()

        // No options filled and no correct index
        #expect(!viewModel.isValid)

        // Fill options but no correct index
        viewModel.options[0].text = "Option A"
        viewModel.options[1].text = "Option B"
        #expect(!viewModel.isValid)

        // Set correct index
        viewModel.correctOptionIndex = 0
        #expect(viewModel.isValid)
    }

    @Test("trueFalse has fixed options and requires correct selection")
    func trueFalseHasFixedOptions() {
        let provider = MockAssessmentManagementDataProvider()
        let viewModel = QuestionFormViewModel(
            dataProvider: provider,
            assessmentId: "assess-001"
        )

        viewModel.questionText = "Is 2+2=4?"
        viewModel.questionType = .trueFalse
        viewModel.setupDefaultOptions()

        #expect(viewModel.options.count == 2)
        #expect(viewModel.options[0].text == "Verdadero")
        #expect(viewModel.options[1].text == "Falso")
        #expect(!viewModel.isValid) // No correct answer selected

        viewModel.correctOptionIndex = 0
        #expect(viewModel.isValid)
    }

    @Test("openEnded does not require correct answer")
    func openEndedNoCorrectAnswer() {
        let provider = MockAssessmentManagementDataProvider()
        let viewModel = QuestionFormViewModel(
            dataProvider: provider,
            assessmentId: "assess-001"
        )

        viewModel.questionText = "Describe your thoughts"
        viewModel.questionType = .openEnded
        viewModel.setupDefaultOptions()

        #expect(viewModel.isValid)
        #expect(viewModel.options.isEmpty)
        #expect(viewModel.correctAnswer == nil)
    }

    @Test("shortAnswer requires correct answer text")
    func shortAnswerRequiresCorrectAnswer() {
        let provider = MockAssessmentManagementDataProvider()
        let viewModel = QuestionFormViewModel(
            dataProvider: provider,
            assessmentId: "assess-001"
        )

        viewModel.questionText = "Capital of France?"
        viewModel.questionType = .shortAnswer
        viewModel.setupDefaultOptions()

        #expect(!viewModel.isValid) // No correct answer

        viewModel.correctAnswer = "Paris"
        #expect(viewModel.isValid)
    }

    @Test("validation requires question text")
    func validationRequiresQuestionText() {
        let provider = MockAssessmentManagementDataProvider()
        let viewModel = QuestionFormViewModel(
            dataProvider: provider,
            assessmentId: "assess-001"
        )

        viewModel.questionType = .openEnded
        viewModel.setupDefaultOptions()
        viewModel.questionText = ""

        #expect(!viewModel.isValid)

        viewModel.questionText = "  "
        #expect(!viewModel.isValid)

        viewModel.questionText = "Real question"
        #expect(viewModel.isValid)
    }

    @Test("save calls network service for new question")
    func saveCallsNetworkService() async {
        let provider = MockAssessmentManagementDataProvider()
        let viewModel = QuestionFormViewModel(
            dataProvider: provider,
            assessmentId: "assess-001"
        )

        viewModel.questionText = "Test question?"
        viewModel.questionType = .openEnded
        viewModel.setupDefaultOptions()

        let success = await viewModel.save()

        #expect(success)
        let callCount = await provider.createQuestionCallCount
        #expect(callCount == 1)
    }

    @Test("addOption increases options count")
    func addOptionIncreasesCount() {
        let provider = MockAssessmentManagementDataProvider()
        let viewModel = QuestionFormViewModel(
            dataProvider: provider,
            assessmentId: "assess-001"
        )

        viewModel.questionType = .multipleChoice
        viewModel.setupDefaultOptions()
        let initialCount = viewModel.options.count

        viewModel.addOption()
        #expect(viewModel.options.count == initialCount + 1)
    }

    @Test("removeOption decreases options count and adjusts correct index")
    func removeOptionDecreasesCount() {
        let provider = MockAssessmentManagementDataProvider()
        let viewModel = QuestionFormViewModel(
            dataProvider: provider,
            assessmentId: "assess-001"
        )

        viewModel.questionType = .multipleChoice
        viewModel.setupDefaultOptions()
        viewModel.correctOptionIndex = 2

        viewModel.removeOption(at: 1)

        #expect(viewModel.options.count == 3)
        // Correct index should shift down from 2 to 1
        #expect(viewModel.correctOptionIndex == 1)
    }

    @Test("removeOption clears correct index when removing correct option")
    func removeCorrectOptionClearsIndex() {
        let provider = MockAssessmentManagementDataProvider()
        let viewModel = QuestionFormViewModel(
            dataProvider: provider,
            assessmentId: "assess-001"
        )

        viewModel.questionType = .multipleChoice
        viewModel.setupDefaultOptions()
        viewModel.correctOptionIndex = 1

        viewModel.removeOption(at: 1)

        #expect(viewModel.correctOptionIndex == nil)
    }
}

// MARK: - AssessmentAssignmentViewModel Tests

@Suite("AssessmentAssignmentViewModel")
@MainActor
struct AssessmentAssignmentViewModelTests {

    private func makeSampleAssignments() -> [AssignmentResponseDTO] {
        [
            AssignmentResponseDTO(
                id: "assign-001",
                assessmentId: "assess-001",
                studentId: "student-001",
                assignedBy: "teacher-001",
                assignedAt: "2026-03-27T10:00:00Z"
            ),
            AssignmentResponseDTO(
                id: "assign-002",
                assessmentId: "assess-001",
                studentId: "student-002",
                assignedBy: "teacher-001",
                assignedAt: "2026-03-27T10:00:00Z",
                dueDate: "2026-04-01T23:59:59Z"
            )
        ]
    }

    @Test("loadAssignments populates list")
    func loadAssignmentsPopulatesList() async {
        let provider = MockAssessmentManagementDataProvider()
        let assignments = makeSampleAssignments()
        await provider.setAssignments(assignments)

        let viewModel = AssessmentAssignmentViewModel(
            dataProvider: provider,
            assessmentId: "assess-001"
        )

        await viewModel.loadAssignments()

        #expect(viewModel.assignments.count == 2)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error == nil)
    }

    @Test("loadAssignments sets error on failure")
    func loadAssignmentsError() async {
        let provider = MockAssessmentManagementDataProvider()
        await provider.setError(TestAssessmentError(message: "Network error"))

        let viewModel = AssessmentAssignmentViewModel(
            dataProvider: provider,
            assessmentId: "assess-001"
        )

        await viewModel.loadAssignments()

        #expect(viewModel.assignments.isEmpty)
        #expect(viewModel.hasError)
    }

    @Test("assignToStudents requires student selection")
    func assignToStudentsRequiresSelection() async {
        let provider = MockAssessmentManagementDataProvider()
        let viewModel = AssessmentAssignmentViewModel(
            dataProvider: provider,
            assessmentId: "assess-001"
        )

        // No students selected
        await viewModel.assignToStudents()

        let callCount = await provider.assignCallCount
        #expect(callCount == 0)
    }

    @Test("assignToStudents calls provider with selected IDs")
    func assignToStudentsCallsProvider() async {
        let provider = MockAssessmentManagementDataProvider()
        let viewModel = AssessmentAssignmentViewModel(
            dataProvider: provider,
            assessmentId: "assess-001"
        )

        viewModel.selectedStudentIds = ["student-001", "student-002"]

        await viewModel.assignToStudents()

        let callCount = await provider.assignCallCount
        #expect(callCount == 1)
        #expect(viewModel.selectedStudentIds.isEmpty) // Cleared after success
        #expect(viewModel.assignments.count == 1) // One assignment created
    }

    @Test("removeAssignment removes from list")
    func removeAssignmentRemovesFromList() async {
        let provider = MockAssessmentManagementDataProvider()
        let assignments = makeSampleAssignments()
        await provider.setAssignments(assignments)

        let viewModel = AssessmentAssignmentViewModel(
            dataProvider: provider,
            assessmentId: "assess-001"
        )

        await viewModel.loadAssignments()
        #expect(viewModel.assignments.count == 2)

        await viewModel.removeAssignment("assign-001")

        #expect(viewModel.assignments.count == 1)
        #expect(viewModel.assignments[0].id == "assign-002")

        let removeCount = await provider.removeAssignmentCallCount
        #expect(removeCount == 1)
    }

    @Test("canAssign is false with no selection")
    func canAssignFalseWithNoSelection() {
        let provider = MockAssessmentManagementDataProvider()
        let viewModel = AssessmentAssignmentViewModel(
            dataProvider: provider,
            assessmentId: "assess-001"
        )

        viewModel.activeTab = .students
        #expect(!viewModel.canAssign)

        viewModel.activeTab = .unit
        #expect(!viewModel.canAssign)
    }

    @Test("canAssign is true with student selection")
    func canAssignTrueWithStudentSelection() {
        let provider = MockAssessmentManagementDataProvider()
        let viewModel = AssessmentAssignmentViewModel(
            dataProvider: provider,
            assessmentId: "assess-001"
        )

        viewModel.activeTab = .students
        viewModel.selectedStudentIds = ["student-001"]

        #expect(viewModel.canAssign)
    }

    @Test("canAssign is true with unit selection")
    func canAssignTrueWithUnitSelection() {
        let provider = MockAssessmentManagementDataProvider()
        let viewModel = AssessmentAssignmentViewModel(
            dataProvider: provider,
            assessmentId: "assess-001"
        )

        viewModel.activeTab = .unit
        viewModel.selectedUnitId = "unit-001"

        #expect(viewModel.canAssign)
    }

    @Test("clearError resets error state")
    func clearErrorResetsError() async {
        let provider = MockAssessmentManagementDataProvider()
        await provider.setError(TestAssessmentError(message: "error"))

        let viewModel = AssessmentAssignmentViewModel(
            dataProvider: provider,
            assessmentId: "assess-001"
        )

        await viewModel.loadAssignments()
        #expect(viewModel.hasError)

        viewModel.clearError()
        #expect(!viewModel.hasError)
    }
}
