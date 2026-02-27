import Testing
import Foundation
@testable import EduNetwork

// MARK: - Test Fixtures

/// Helper para crear fixtures de test.
enum TestFixtures {
    static let baseURL = "https://api.edugo.com"

    static let validMaterialId = "550e8400-e29b-41d4-a716-446655440001"
    static let validUserId = "550e8400-e29b-41d4-a716-446655440099"
    static let invalidId = "not-a-uuid"

    static func createMaterialDTO() -> MaterialDTO {
        MaterialDTO(
            id: validMaterialId,
            title: "Test Material",
            description: "Test Description",
            subject: "Math",
            grade: "6th",
            academicUnitId: "550e8400-e29b-41d4-a716-446655440010",
            schoolId: "550e8400-e29b-41d4-a716-446655440020",
            uploadedByTeacherId: "550e8400-e29b-41d4-a716-446655440030",
            fileType: "application/pdf",
            fileSizeBytes: 1024,
            fileUrl: "https://storage.test.com/file.pdf",
            status: .ready,
            isPublic: true,
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: nil,
            processingStartedAt: Date(),
            processingCompletedAt: Date()
        )
    }

    static func createAttemptResultDTO() -> AttemptResultDTO {
        AttemptResultDTO(
            attemptId: "attempt-001",
            assessmentId: "assess-001",
            materialId: validMaterialId,
            score: 80,
            maxScore: 100,
            correctAnswers: 8,
            totalQuestions: 10,
            passed: true,
            passThreshold: 70,
            previousBestScore: 65,
            canRetake: true,
            timeSpentSeconds: 180,
            startedAt: Date(),
            completedAt: Date(),
            feedback: [
                QuestionFeedback(
                    questionId: "q-001",
                    questionText: "What is 2+2?",
                    selectedOption: "4",
                    correctAnswer: "4",
                    isCorrect: true,
                    message: "Correct!"
                )
            ]
        )
    }

    static func createProgressDTO() -> ProgressDTO {
        ProgressDTO(
            userId: validUserId,
            materialId: validMaterialId,
            percentage: 75,
            lastUpdated: Date()
        )
    }

    static func createGlobalStatsDTO() -> GlobalStatsDTO {
        GlobalStatsDTO(
            totalUsers: 15000,
            totalMaterials: 2500,
            totalSchools: 150,
            totalTeachers: 800,
            totalStudents: 12000,
            totalAssessments: 45000,
            averageProgress: 68.5
        )
    }
}

// MARK: - Materials Repository Tests

@Suite("MaterialsRepository Tests")
struct MaterialsRepositoryTests {
    @Test("getMaterials returns list of materials")
    func testGetMaterials() async throws {
        let mock = MockNetworkClient()
        let repository = MaterialsRepository(client: mock, baseURL: TestFixtures.baseURL)

        let materials = [TestFixtures.createMaterialDTO()]
        await mock.setResponse(materials)

        let result = try await repository.getMaterials()

        #expect(result.count == 1)
        #expect(result[0].id == TestFixtures.validMaterialId)

        let wasRequested = await mock.wasRequestedWith(url: "/v1/materials")
        #expect(wasRequested)
    }

    @Test("getMaterial returns single material by ID")
    func testGetMaterialById() async throws {
        let mock = MockNetworkClient()
        let repository = MaterialsRepository(client: mock, baseURL: TestFixtures.baseURL)

        await mock.setResponse(TestFixtures.createMaterialDTO())

        let result = try await repository.getMaterial(id: TestFixtures.validMaterialId)

        #expect(result.id == TestFixtures.validMaterialId)
        #expect(result.title == "Test Material")

        let wasRequested = await mock.wasRequestedWith(url: TestFixtures.validMaterialId)
        #expect(wasRequested)
    }

    @Test("getMaterial throws invalidMaterialId for empty ID")
    func testGetMaterialEmptyId() async throws {
        let mock = MockNetworkClient()
        let repository = MaterialsRepository(client: mock, baseURL: TestFixtures.baseURL)

        await #expect(throws: MaterialsRepositoryError.invalidMaterialId("")) {
            _ = try await repository.getMaterial(id: "")
        }
    }

    @Test("getMaterial throws invalidMaterialId for non-UUID")
    func testGetMaterialInvalidId() async throws {
        let mock = MockNetworkClient()
        let repository = MaterialsRepository(client: mock, baseURL: TestFixtures.baseURL)

        await #expect(throws: MaterialsRepositoryError.invalidMaterialId(TestFixtures.invalidId)) {
            _ = try await repository.getMaterial(id: TestFixtures.invalidId)
        }
    }

    @Test("getMaterial throws materialNotFound on 404")
    func testGetMaterialNotFound() async throws {
        let mock = MockNetworkClient()
        let repository = MaterialsRepository(client: mock, baseURL: TestFixtures.baseURL)

        await mock.setError(.notFound)

        await #expect(throws: MaterialsRepositoryError.materialNotFound(TestFixtures.validMaterialId)) {
            _ = try await repository.getMaterial(id: TestFixtures.validMaterialId)
        }
    }

    @Test("submitAssessment returns assessment result")
    func testSubmitAssessment() async throws {
        let mock = MockNetworkClient()
        let repository = MaterialsRepository(client: mock, baseURL: TestFixtures.baseURL)

        await mock.setResponse(TestFixtures.createAttemptResultDTO())

        let request = CreateAttemptRequest(
            answers: [
                AnswerRequest(questionId: "q-001", selectedAnswerId: "a-001", timeSpentSeconds: 30)
            ],
            timeSpentSeconds: 120
        )

        let result = try await repository.submitAssessment(
            materialId: TestFixtures.validMaterialId,
            request: request
        )

        #expect(result.score == 80)
        #expect(result.passed == true)

        let wasRequested = await mock.wasRequestedWith(url: "assessment/attempts")
        #expect(wasRequested)
    }

    @Test("submitAssessment throws emptyAnswers for empty answers")
    func testSubmitAssessmentEmptyAnswers() async throws {
        let mock = MockNetworkClient()
        let repository = MaterialsRepository(client: mock, baseURL: TestFixtures.baseURL)

        let request = CreateAttemptRequest(answers: [], timeSpentSeconds: 120)

        await #expect(throws: MaterialsRepositoryError.emptyAnswers) {
            _ = try await repository.submitAssessment(
                materialId: TestFixtures.validMaterialId,
                request: request
            )
        }
    }

    @Test("submitAssessment throws invalidTimeSpent for time too low")
    func testSubmitAssessmentTimeTooLow() async throws {
        let mock = MockNetworkClient()
        let repository = MaterialsRepository(client: mock, baseURL: TestFixtures.baseURL)

        let request = CreateAttemptRequest(
            answers: [AnswerRequest(questionId: "q", selectedAnswerId: "a", timeSpentSeconds: 0)],
            timeSpentSeconds: 0
        )

        await #expect(throws: MaterialsRepositoryError.invalidTimeSpent(0)) {
            _ = try await repository.submitAssessment(
                materialId: TestFixtures.validMaterialId,
                request: request
            )
        }
    }

    @Test("submitAssessment throws invalidTimeSpent for time too high")
    func testSubmitAssessmentTimeTooHigh() async throws {
        let mock = MockNetworkClient()
        let repository = MaterialsRepository(client: mock, baseURL: TestFixtures.baseURL)

        let request = CreateAttemptRequest(
            answers: [AnswerRequest(questionId: "q", selectedAnswerId: "a", timeSpentSeconds: 30)],
            timeSpentSeconds: 8000
        )

        await #expect(throws: MaterialsRepositoryError.invalidTimeSpent(8000)) {
            _ = try await repository.submitAssessment(
                materialId: TestFixtures.validMaterialId,
                request: request
            )
        }
    }

    @Test("submitAssessment throws assessmentNotFound on 404")
    func testSubmitAssessmentNotFound() async throws {
        let mock = MockNetworkClient()
        let repository = MaterialsRepository(client: mock, baseURL: TestFixtures.baseURL)

        await mock.setError(.notFound)

        let request = CreateAttemptRequest(
            answers: [AnswerRequest(questionId: "q", selectedAnswerId: "a", timeSpentSeconds: 30)],
            timeSpentSeconds: 120
        )

        await #expect(throws: MaterialsRepositoryError.assessmentNotFound(TestFixtures.validMaterialId)) {
            _ = try await repository.submitAssessment(
                materialId: TestFixtures.validMaterialId,
                request: request
            )
        }
    }

    @Test("MaterialsRepository throws unauthorized on 401")
    func testMaterialsRepositoryUnauthorized() async throws {
        let mock = MockNetworkClient()
        let repository = MaterialsRepository(client: mock, baseURL: TestFixtures.baseURL)

        await mock.setError(.unauthorized)

        await #expect(throws: MaterialsRepositoryError.unauthorized) {
            _ = try await repository.getMaterials()
        }
    }
}

// MARK: - Progress Repository Tests

@Suite("ProgressRepository Tests")
struct ProgressRepositoryTests {
    @Test("updateProgress returns updated progress")
    func testUpdateProgress() async throws {
        let mock = MockNetworkClient()
        let repository = ProgressRepository(client: mock, baseURL: TestFixtures.baseURL)

        await mock.setResponse(TestFixtures.createProgressDTO())

        let request = UpsertProgressRequest(
            materialId: TestFixtures.validMaterialId,
            userId: TestFixtures.validUserId,
            percentage: 75
        )

        let result = try await repository.updateProgress(request: request)

        #expect(result.percentage == 75)
        #expect(result.userId == TestFixtures.validUserId)

        let wasRequested = await mock.wasRequestedWith(url: "/v1/progress")
        let wasRequestedPut = await mock.wasRequestedWith(method: .put)
        #expect(wasRequested)
        #expect(wasRequestedPut)
    }

    @Test("updateProgress throws invalidMaterialId for invalid material ID")
    func testUpdateProgressInvalidMaterialId() async throws {
        let mock = MockNetworkClient()
        let repository = ProgressRepository(client: mock, baseURL: TestFixtures.baseURL)

        let request = UpsertProgressRequest(
            materialId: TestFixtures.invalidId,
            userId: TestFixtures.validUserId,
            percentage: 50
        )

        await #expect(throws: ProgressRepositoryError.invalidMaterialId(TestFixtures.invalidId)) {
            _ = try await repository.updateProgress(request: request)
        }
    }

    @Test("updateProgress throws invalidUserId for invalid user ID")
    func testUpdateProgressInvalidUserId() async throws {
        let mock = MockNetworkClient()
        let repository = ProgressRepository(client: mock, baseURL: TestFixtures.baseURL)

        let request = UpsertProgressRequest(
            materialId: TestFixtures.validMaterialId,
            userId: TestFixtures.invalidId,
            percentage: 50
        )

        await #expect(throws: ProgressRepositoryError.invalidUserId(TestFixtures.invalidId)) {
            _ = try await repository.updateProgress(request: request)
        }
    }

    @Test("updateProgress throws invalidPercentage for negative percentage")
    func testUpdateProgressNegativePercentage() async throws {
        let mock = MockNetworkClient()
        let repository = ProgressRepository(client: mock, baseURL: TestFixtures.baseURL)

        let request = UpsertProgressRequest(
            materialId: TestFixtures.validMaterialId,
            userId: TestFixtures.validUserId,
            percentage: -5
        )

        await #expect(throws: ProgressRepositoryError.invalidPercentage(-5)) {
            _ = try await repository.updateProgress(request: request)
        }
    }

    @Test("updateProgress throws invalidPercentage for percentage over 100")
    func testUpdateProgressOverPercentage() async throws {
        let mock = MockNetworkClient()
        let repository = ProgressRepository(client: mock, baseURL: TestFixtures.baseURL)

        let request = UpsertProgressRequest(
            materialId: TestFixtures.validMaterialId,
            userId: TestFixtures.validUserId,
            percentage: 150
        )

        await #expect(throws: ProgressRepositoryError.invalidPercentage(150)) {
            _ = try await repository.updateProgress(request: request)
        }
    }

    @Test("updateProgress accepts boundary values 0 and 100")
    func testUpdateProgressBoundaryValues() async throws {
        let mock = MockNetworkClient()
        let repository = ProgressRepository(client: mock, baseURL: TestFixtures.baseURL)

        // Test 0%
        await mock.setResponse(ProgressDTO(
            userId: TestFixtures.validUserId,
            materialId: TestFixtures.validMaterialId,
            percentage: 0,
            lastUpdated: Date()
        ))

        let request0 = UpsertProgressRequest(
            materialId: TestFixtures.validMaterialId,
            userId: TestFixtures.validUserId,
            percentage: 0
        )
        let result0 = try await repository.updateProgress(request: request0)
        #expect(result0.percentage == 0)

        // Test 100%
        await mock.setResponse(ProgressDTO(
            userId: TestFixtures.validUserId,
            materialId: TestFixtures.validMaterialId,
            percentage: 100,
            lastUpdated: Date()
        ))

        let request100 = UpsertProgressRequest(
            materialId: TestFixtures.validMaterialId,
            userId: TestFixtures.validUserId,
            percentage: 100
        )
        let result100 = try await repository.updateProgress(request: request100)
        #expect(result100.percentage == 100)
    }

    @Test("ProgressRepository throws unauthorized on 401")
    func testProgressRepositoryUnauthorized() async throws {
        let mock = MockNetworkClient()
        let repository = ProgressRepository(client: mock, baseURL: TestFixtures.baseURL)

        await mock.setError(.unauthorized)

        let request = UpsertProgressRequest(
            materialId: TestFixtures.validMaterialId,
            userId: TestFixtures.validUserId,
            percentage: 50
        )

        await #expect(throws: ProgressRepositoryError.unauthorized) {
            _ = try await repository.updateProgress(request: request)
        }
    }

    @Test("ProgressRepository throws forbidden on 403")
    func testProgressRepositoryForbidden() async throws {
        let mock = MockNetworkClient()
        let repository = ProgressRepository(client: mock, baseURL: TestFixtures.baseURL)

        await mock.setError(.forbidden)

        let request = UpsertProgressRequest(
            materialId: TestFixtures.validMaterialId,
            userId: TestFixtures.validUserId,
            percentage: 50
        )

        await #expect(throws: ProgressRepositoryError.forbidden) {
            _ = try await repository.updateProgress(request: request)
        }
    }
}

// MARK: - Stats Repository Tests

@Suite("StatsRepository Tests")
struct StatsRepositoryTests {
    @Test("getGlobalStats returns stats")
    func testGetGlobalStats() async throws {
        let mock = MockNetworkClient()
        let repository = StatsRepository(client: mock, baseURL: TestFixtures.baseURL)

        await mock.setResponse(TestFixtures.createGlobalStatsDTO())

        let result = try await repository.getGlobalStats()

        #expect(result.totalUsers == 15000)
        #expect(result.totalMaterials == 2500)
        #expect(result.averageProgress == 68.5)

        let wasRequested = await mock.wasRequestedWith(url: "/v1/stats/global")
        #expect(wasRequested)
    }

    @Test("getGlobalStats handles partial data")
    func testGetGlobalStatsPartial() async throws {
        let mock = MockNetworkClient()
        let repository = StatsRepository(client: mock, baseURL: TestFixtures.baseURL)

        let partialStats = GlobalStatsDTO(
            totalUsers: 100,
            totalMaterials: 10,
            totalSchools: nil,
            totalTeachers: nil,
            totalStudents: nil,
            totalAssessments: nil,
            averageProgress: nil
        )
        await mock.setResponse(partialStats)

        let result = try await repository.getGlobalStats()

        #expect(result.totalUsers == 100)
        #expect(result.totalMaterials == 10)
        #expect(result.totalSchools == nil)
        #expect(result.averageProgress == nil)
    }

    @Test("StatsRepository throws unauthorized on 401")
    func testStatsRepositoryUnauthorized() async throws {
        let mock = MockNetworkClient()
        let repository = StatsRepository(client: mock, baseURL: TestFixtures.baseURL)

        await mock.setError(.unauthorized)

        await #expect(throws: StatsRepositoryError.unauthorized) {
            _ = try await repository.getGlobalStats()
        }
    }

    @Test("StatsRepository throws forbidden on 403")
    func testStatsRepositoryForbidden() async throws {
        let mock = MockNetworkClient()
        let repository = StatsRepository(client: mock, baseURL: TestFixtures.baseURL)

        await mock.setError(.forbidden)

        await #expect(throws: StatsRepositoryError.forbidden) {
            _ = try await repository.getGlobalStats()
        }
    }
}
