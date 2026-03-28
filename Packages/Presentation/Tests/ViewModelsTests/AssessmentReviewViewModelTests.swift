import Testing
import Foundation
@testable import EduPresentation
@testable import EduDomain
import EduCore
import EduInfrastructure

// MARK: - Mock Assessment Review Network Service

/// Mock del AssessmentReviewNetworkServiceProtocol para tests unitarios.
actor MockAssessmentReviewNetworkService: AssessmentReviewNetworkServiceProtocol {
    private var stubbedAttempts: [TeacherAttemptSummaryDTO] = []
    private var stubbedStats: AssessmentStatsDTO?
    private var stubbedDetail: AttemptReviewDetailDTO?
    private var stubbedError: Error?
    private(set) var listAttemptsCallCount: Int = 0
    private(set) var getStatsCallCount: Int = 0
    private(set) var getAttemptForReviewCallCount: Int = 0
    private(set) var reviewAnswerCallCount: Int = 0
    private(set) var finalizeAttemptCallCount: Int = 0
    private(set) var finalizeAllCallCount: Int = 0

    // MARK: - Setters

    func setAttempts(_ attempts: [TeacherAttemptSummaryDTO]) {
        stubbedAttempts = attempts
    }

    func setStats(_ stats: AssessmentStatsDTO) {
        stubbedStats = stats
    }

    func setDetail(_ detail: AttemptReviewDetailDTO) {
        stubbedDetail = detail
    }

    func setError(_ error: Error?) {
        stubbedError = error
    }

    // MARK: - Protocol Conformance

    func listAttempts(assessmentId: String) async throws -> [TeacherAttemptSummaryDTO] {
        listAttemptsCallCount += 1
        if let error = stubbedError { throw error }
        return stubbedAttempts
    }

    func getStats(assessmentId: String) async throws -> AssessmentStatsDTO {
        getStatsCallCount += 1
        if let error = stubbedError { throw error }
        guard let stats = stubbedStats else {
            throw TestReviewError(message: "No stats configured")
        }
        return stats
    }

    func getAttemptForReview(attemptId: String) async throws -> AttemptReviewDetailDTO {
        getAttemptForReviewCallCount += 1
        if let error = stubbedError { throw error }
        guard let detail = stubbedDetail else {
            throw TestReviewError(message: "No detail configured")
        }
        return detail
    }

    func reviewAnswer(attemptId: String, answerId: String, request: ReviewAnswerRequestDTO) async throws {
        reviewAnswerCallCount += 1
        if let error = stubbedError { throw error }
    }

    func finalizeAttempt(attemptId: String) async throws {
        finalizeAttemptCallCount += 1
        if let error = stubbedError { throw error }
    }

    func finalizeAll(assessmentId: String) async throws {
        finalizeAllCallCount += 1
        if let error = stubbedError { throw error }
    }
}

// MARK: - Test Error

struct TestReviewError: Error, LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

// MARK: - Test Helpers

private func makeSampleAttempts() -> [TeacherAttemptSummaryDTO] {
    [
        TeacherAttemptSummaryDTO(
            attemptId: "attempt-001",
            studentId: "student-001",
            studentName: "Carlos Mendoza",
            studentEmail: "est.carlos@edugo.test",
            score: 85.0,
            maxScore: 100.0,
            percentage: 85.0,
            status: "completed",
            pendingReviews: 0,
            completedAt: Date()
        ),
        TeacherAttemptSummaryDTO(
            attemptId: "attempt-002",
            studentId: "student-002",
            studentName: "Sofia Ramirez",
            studentEmail: "est.sofia@edugo.test",
            score: nil,
            maxScore: 100.0,
            percentage: nil,
            status: "pending_review",
            pendingReviews: 2,
            completedAt: Date()
        ),
        TeacherAttemptSummaryDTO(
            attemptId: "attempt-003",
            studentId: "student-003",
            studentName: "Diego Lopez",
            studentEmail: "est.diego@edugo.test",
            score: 60.0,
            maxScore: 100.0,
            percentage: 60.0,
            status: "completed",
            pendingReviews: 0,
            completedAt: Date()
        )
    ]
}

private func makeSampleDetail() -> AttemptReviewDetailDTO {
    AttemptReviewDetailDTO(
        attemptId: "attempt-002",
        studentName: "Sofia Ramirez",
        studentEmail: "est.sofia@edugo.test",
        status: "pending_review",
        answers: [
            AnswerForReviewDTO(
                answerId: "answer-001",
                questionIndex: 0,
                questionText: "Cual es la capital de Francia?",
                questionType: "multiple_choice",
                studentAnswer: "Paris",
                correctAnswer: "Paris",
                isCorrect: true,
                pointsEarned: 10.0,
                maxPoints: 10.0,
                reviewStatus: "auto_graded",
                reviewFeedback: nil
            ),
            AnswerForReviewDTO(
                answerId: "answer-002",
                questionIndex: 1,
                questionText: "Describe el ciclo del agua",
                questionType: "open_ended",
                studentAnswer: "El agua se evapora y luego llueve",
                correctAnswer: nil,
                isCorrect: nil,
                pointsEarned: nil,
                maxPoints: 20.0,
                reviewStatus: "pending",
                reviewFeedback: nil
            )
        ],
        currentScore: 10.0,
        maxScore: 30.0
    )
}

private func makeSampleStats() -> AssessmentStatsDTO {
    AssessmentStatsDTO(
        totalAttempts: 3,
        completedAttempts: 2,
        pendingReviews: 1,
        averageScore: 72.5,
        medianScore: 72.5,
        highestScore: 85.0,
        lowestScore: 60.0,
        passRate: 66.7,
        averageTimeSeconds: 900,
        questionStats: []
    )
}

private func makeMediator(networkService: MockAssessmentReviewNetworkService) async -> Mediator {
    let mediator = Mediator()
    let svc: any AssessmentReviewNetworkServiceProtocol = networkService
    await mediator.registerOrReplaceQueryHandler(GetAttemptListQueryHandler(networkService: svc))
    await mediator.registerOrReplaceQueryHandler(GetAssessmentStatsQueryHandler(networkService: svc))
    await mediator.registerOrReplaceQueryHandler(GetAttemptDetailQueryHandler(networkService: svc))
    await mediator.registerOrReplaceCommandHandler(ReviewAnswerCommandHandler(networkService: svc))
    await mediator.registerOrReplaceCommandHandler(FinalizeAttemptCommandHandler(networkService: svc))
    await mediator.registerOrReplaceCommandHandler(FinalizeAllCommandHandler(networkService: svc))
    return mediator
}

// MARK: - AssessmentReviewViewModel Tests

@Suite("AssessmentReviewViewModel")
@MainActor
struct AssessmentReviewViewModelTests {

    @Test("loadAttempts fetches data and populates attempts list")
    func loadAttemptsFetchesData() async {
        let networkService = MockAssessmentReviewNetworkService()
        let attempts = makeSampleAttempts()
        await networkService.setAttempts(attempts)

        let mediator = await makeMediator(networkService: networkService)
        let viewModel = AssessmentReviewViewModel(mediator: mediator)

        await viewModel.loadAttempts(assessmentId: "assess-001")

        #expect(viewModel.attempts.count == 3)
        #expect(viewModel.isLoadingAttempts == false)
        #expect(viewModel.attemptsError == nil)

        let callCount = await networkService.listAttemptsCallCount
        #expect(callCount == 1)
    }

    @Test("loadAttempts sets error on failure")
    func loadAttemptsError() async {
        let networkService = MockAssessmentReviewNetworkService()
        await networkService.setError(TestReviewError(message: "Network error"))

        let mediator = await makeMediator(networkService: networkService)
        let viewModel = AssessmentReviewViewModel(mediator: mediator)

        await viewModel.loadAttempts(assessmentId: "assess-001")

        #expect(viewModel.attempts.isEmpty)
        #expect(viewModel.hasError)
        #expect(viewModel.isLoadingAttempts == false)
    }

    @Test("loadStats fetches assessment statistics")
    func loadStatsFetchesStats() async {
        let networkService = MockAssessmentReviewNetworkService()
        await networkService.setStats(makeSampleStats())

        let mediator = await makeMediator(networkService: networkService)
        let viewModel = AssessmentReviewViewModel(mediator: mediator)

        await viewModel.loadStats(assessmentId: "assess-001")

        #expect(viewModel.stats != nil)
        #expect(viewModel.stats?.totalAttempts == 3)
        #expect(viewModel.stats?.passRate == 66.7)

        let callCount = await networkService.getStatsCallCount
        #expect(callCount == 1)
    }

    @Test("reviewAnswer updates selectedAttempt and shows success")
    func reviewAnswerUpdatesScore() async {
        let networkService = MockAssessmentReviewNetworkService()
        let detail = makeSampleDetail()
        await networkService.setDetail(detail)

        let mediator = await makeMediator(networkService: networkService)
        let viewModel = AssessmentReviewViewModel(mediator: mediator)

        await viewModel.reviewAnswer(
            attemptId: "attempt-002",
            answerId: "answer-002",
            points: 15.0,
            feedback: "Buen intento, falta mencionar la condensacion"
        )

        #expect(viewModel.isSavingReview == false)
        #expect(viewModel.selectedAttempt != nil)
        #expect(viewModel.successMessage == "Respuesta calificada")
        #expect(viewModel.reviewError == nil)

        let reviewCount = await networkService.reviewAnswerCallCount
        #expect(reviewCount == 1)

        let detailCount = await networkService.getAttemptForReviewCallCount
        #expect(detailCount == 1)
    }

    @Test("reviewAnswer sets error on failure")
    func reviewAnswerError() async {
        let networkService = MockAssessmentReviewNetworkService()
        await networkService.setError(TestReviewError(message: "Conflict"))

        let mediator = await makeMediator(networkService: networkService)
        let viewModel = AssessmentReviewViewModel(mediator: mediator)

        await viewModel.reviewAnswer(
            attemptId: "attempt-002",
            answerId: "answer-002",
            points: 15.0,
            feedback: "feedback"
        )

        #expect(viewModel.isSavingReview == false)
        #expect(viewModel.reviewError != nil)
        #expect(viewModel.successMessage == nil)
    }

    @Test("finalizeAttempt clears selectedAttempt and shows success")
    func finalizeAttemptClearsSelection() async {
        let networkService = MockAssessmentReviewNetworkService()

        let mediator = await makeMediator(networkService: networkService)
        let viewModel = AssessmentReviewViewModel(mediator: mediator)

        await viewModel.finalizeAttempt(attemptId: "attempt-001")

        #expect(viewModel.selectedAttempt == nil)
        #expect(viewModel.isFinalizing == false)
        #expect(viewModel.successMessage == "Revision finalizada")
        #expect(viewModel.reviewError == nil)

        let callCount = await networkService.finalizeAttemptCallCount
        #expect(callCount == 1)
    }

    @Test("finalizeAll reloads attempts list")
    func finalizeAllReloadsAttempts() async {
        let networkService = MockAssessmentReviewNetworkService()
        let attempts = makeSampleAttempts()
        await networkService.setAttempts(attempts)

        let mediator = await makeMediator(networkService: networkService)
        let viewModel = AssessmentReviewViewModel(mediator: mediator)

        await viewModel.finalizeAll(assessmentId: "assess-001")

        #expect(viewModel.attempts.count == 3)
        #expect(viewModel.isFinalizing == false)
        #expect(viewModel.successMessage == "Todas las revisiones finalizadas")

        let finalizeCount = await networkService.finalizeAllCallCount
        #expect(finalizeCount == 1)

        let listCount = await networkService.listAttemptsCallCount
        #expect(listCount == 1)
    }

    @Test("canFinalizeAll logic")
    func canFinalizeAllLogic() async {
        let networkService = MockAssessmentReviewNetworkService()
        let mediator = await makeMediator(networkService: networkService)
        let viewModel = AssessmentReviewViewModel(mediator: mediator)

        // Empty attempts: cannot finalize
        #expect(!viewModel.canFinalizeAll)

        // Load attempts with one pending_review
        await networkService.setAttempts(makeSampleAttempts())
        await viewModel.loadAttempts(assessmentId: "assess-001")

        // Has pending reviews: cannot finalize all
        #expect(viewModel.pendingReviewCount == 1)
        #expect(!viewModel.canFinalizeAll)

        // Remove pending review attempt (simulate all reviewed)
        let completedOnly = makeSampleAttempts().filter { $0.status == "completed" }
        await networkService.setAttempts(completedOnly)
        await viewModel.loadAttempts(assessmentId: "assess-001")

        // All completed, no pending: can finalize
        #expect(viewModel.pendingReviewCount == 0)
        #expect(viewModel.canFinalizeAll)
    }

    @Test("filteredAttempts filters by status and search text")
    func filteredAttemptsFiltersCorrectly() async {
        let networkService = MockAssessmentReviewNetworkService()
        await networkService.setAttempts(makeSampleAttempts())

        let mediator = await makeMediator(networkService: networkService)
        let viewModel = AssessmentReviewViewModel(mediator: mediator)

        await viewModel.loadAttempts(assessmentId: "assess-001")

        // Filter by status
        viewModel.filter = "pending_review"
        #expect(viewModel.filteredAttempts.count == 1)
        #expect(viewModel.filteredAttempts[0].studentName == "Sofia Ramirez")

        // Filter by search text
        viewModel.filter = "all"
        viewModel.searchText = "carlos"
        #expect(viewModel.filteredAttempts.count == 1)
        #expect(viewModel.filteredAttempts[0].studentName == "Carlos Mendoza")

        // No match
        viewModel.searchText = "xyz"
        #expect(viewModel.filteredAttempts.isEmpty)
    }

    @Test("clearError resets all error states")
    func clearErrorResetsErrors() async {
        let networkService = MockAssessmentReviewNetworkService()
        await networkService.setError(TestReviewError(message: "error"))

        let mediator = await makeMediator(networkService: networkService)
        let viewModel = AssessmentReviewViewModel(mediator: mediator)

        await viewModel.loadAttempts(assessmentId: "assess-001")
        #expect(viewModel.hasError)

        viewModel.clearError()
        #expect(!viewModel.hasError)
        #expect(viewModel.attemptsError == nil)
        #expect(viewModel.detailError == nil)
        #expect(viewModel.reviewError == nil)
    }

    @Test("emptyStateMessage changes with filters")
    func emptyStateMessageChangesWithFilters() async {
        let networkService = MockAssessmentReviewNetworkService()
        let mediator = await makeMediator(networkService: networkService)
        let viewModel = AssessmentReviewViewModel(mediator: mediator)

        #expect(viewModel.emptyStateMessage == "No hay intentos registrados para esta evaluacion")

        viewModel.filter = "pending_review"
        #expect(viewModel.emptyStateMessage == "No se encontraron intentos con los filtros aplicados")
    }
}
