import Testing
import Foundation
import EduCore
@testable import EduNetwork

@Suite("NetworkError Tests")
struct NetworkErrorTests {
    // MARK: - Error Creation Tests

    @Test("NetworkError.from creates correct error for status codes")
    func testNetworkErrorFromStatusCode() {
        #expect(NetworkError.from(statusCode: 401) == .unauthorized)
        #expect(NetworkError.from(statusCode: 403) == .forbidden)
        #expect(NetworkError.from(statusCode: 404) == .notFound)
        #expect(NetworkError.from(statusCode: 429) == .rateLimited(retryAfter: nil))
        #expect(NetworkError.from(statusCode: 429, retryAfter: 30) == .rateLimited(retryAfter: 30))
        #expect(NetworkError.from(statusCode: 500) == .serverError(statusCode: 500, message: nil))
        #expect(NetworkError.from(statusCode: 500, message: "Server error") == .serverError(statusCode: 500, message: "Server error"))
    }

    @Test("NetworkError.from handles URLError correctly")
    func testNetworkErrorFromURLError() {
        let notConnected = NetworkError.from(urlError: URLError(.notConnectedToInternet))
        if case .networkFailure = notConnected {
            // Expected
        } else {
            Issue.record("Expected networkFailure for notConnectedToInternet")
        }

        let timeout = NetworkError.from(urlError: URLError(.timedOut))
        #expect(timeout == .timeout)

        let cancelled = NetworkError.from(urlError: URLError(.cancelled))
        #expect(cancelled == .cancelled)

        let sslError = NetworkError.from(urlError: URLError(.secureConnectionFailed))
        if case .sslError = sslError {
            // Expected
        } else {
            Issue.record("Expected sslError for secureConnectionFailed")
        }
    }

    // MARK: - Status Code Validation Tests

    @Test("NetworkError.isSuccessStatusCode validates 2xx codes")
    func testIsSuccessStatusCode() {
        #expect(NetworkError.isSuccessStatusCode(200))
        #expect(NetworkError.isSuccessStatusCode(201))
        #expect(NetworkError.isSuccessStatusCode(204))
        #expect(NetworkError.isSuccessStatusCode(299))
        #expect(!NetworkError.isSuccessStatusCode(199))
        #expect(!NetworkError.isSuccessStatusCode(300))
        #expect(!NetworkError.isSuccessStatusCode(400))
        #expect(!NetworkError.isSuccessStatusCode(500))
    }

    @Test("NetworkError.isClientError validates 4xx codes")
    func testIsClientError() {
        #expect(NetworkError.isClientError(400))
        #expect(NetworkError.isClientError(401))
        #expect(NetworkError.isClientError(404))
        #expect(NetworkError.isClientError(499))
        #expect(!NetworkError.isClientError(399))
        #expect(!NetworkError.isClientError(500))
        #expect(!NetworkError.isClientError(200))
    }

    @Test("NetworkError.isServerError validates 5xx codes")
    func testIsServerError() {
        #expect(NetworkError.isServerError(500))
        #expect(NetworkError.isServerError(502))
        #expect(NetworkError.isServerError(503))
        #expect(NetworkError.isServerError(599))
        #expect(!NetworkError.isServerError(499))
        #expect(!NetworkError.isServerError(600))
        #expect(!NetworkError.isServerError(200))
    }

    // MARK: - LocalizedError Tests

    @Test("NetworkError provides localized descriptions")
    func testNetworkErrorLocalizedDescription() {
        let invalidURL = NetworkError.invalidURL("bad-url")
        #expect(invalidURL.localizedDescription.contains("bad-url"))

        let noData = NetworkError.noData
        #expect(!noData.localizedDescription.isEmpty)

        let decodingError = NetworkError.decodingError(type: "User", underlyingError: "missing field")
        #expect(decodingError.localizedDescription.contains("User"))

        let serverError = NetworkError.serverError(statusCode: 500, message: "Internal error")
        #expect(serverError.localizedDescription.contains("500"))

        let unauthorized = NetworkError.unauthorized
        #expect(!unauthorized.localizedDescription.isEmpty)

        let forbidden = NetworkError.forbidden
        #expect(!forbidden.localizedDescription.isEmpty)

        let notFound = NetworkError.notFound
        #expect(!notFound.localizedDescription.isEmpty)

        let rateLimited = NetworkError.rateLimited(retryAfter: 30)
        #expect(rateLimited.localizedDescription.contains("30"))

        let timeout = NetworkError.timeout
        #expect(!timeout.localizedDescription.isEmpty)

        let cancelled = NetworkError.cancelled
        #expect(!cancelled.localizedDescription.isEmpty)
    }

    // MARK: - Debug Description Tests

    @Test("NetworkError provides debug descriptions")
    func testNetworkErrorDebugDescription() {
        let invalidURL = NetworkError.invalidURL("test-url")
        #expect(invalidURL.debugDescription.contains("invalidURL"))
        #expect(invalidURL.debugDescription.contains("test-url"))

        let decodingError = NetworkError.decodingError(type: "Material", underlyingError: "key not found")
        #expect(decodingError.debugDescription.contains("decodingError"))
        #expect(decodingError.debugDescription.contains("Material"))

        let serverError = NetworkError.serverError(statusCode: 503, message: nil)
        #expect(serverError.debugDescription.contains("503"))
    }

    // MARK: - Equatable Tests

    @Test("NetworkError equatable works correctly")
    func testNetworkErrorEquatable() {
        #expect(NetworkError.unauthorized == NetworkError.unauthorized)
        #expect(NetworkError.notFound == NetworkError.notFound)
        #expect(NetworkError.timeout == NetworkError.timeout)
        #expect(NetworkError.cancelled == NetworkError.cancelled)
        #expect(NetworkError.noData == NetworkError.noData)

        #expect(NetworkError.serverError(statusCode: 500, message: "A") ==
                NetworkError.serverError(statusCode: 500, message: "A"))
        #expect(NetworkError.serverError(statusCode: 500, message: "A") !=
                NetworkError.serverError(statusCode: 500, message: "B"))
        #expect(NetworkError.serverError(statusCode: 500, message: nil) !=
                NetworkError.serverError(statusCode: 501, message: nil))

        #expect(NetworkError.rateLimited(retryAfter: 30) ==
                NetworkError.rateLimited(retryAfter: 30))
        #expect(NetworkError.rateLimited(retryAfter: 30) !=
                NetworkError.rateLimited(retryAfter: 60))
    }
}

@Suite("Repository Error Tests")
struct RepositoryErrorTests {
    // MARK: - MaterialsRepositoryError Tests

    @Test("MaterialsRepositoryError provides localized descriptions")
    func testMaterialsRepositoryErrorDescriptions() {
        let invalidId = MaterialsRepositoryError.invalidMaterialId("bad-id")
        #expect(invalidId.localizedDescription.contains("bad-id"))

        let notFound = MaterialsRepositoryError.materialNotFound("mat-123")
        #expect(notFound.localizedDescription.contains("mat-123"))

        let emptyAnswers = MaterialsRepositoryError.emptyAnswers
        #expect(!emptyAnswers.localizedDescription.isEmpty)

        let invalidTime = MaterialsRepositoryError.invalidTimeSpent(9999)
        #expect(invalidTime.localizedDescription.contains("9999"))

        let unauthorized = MaterialsRepositoryError.unauthorized
        #expect(!unauthorized.localizedDescription.isEmpty)

        let assessmentNotFound = MaterialsRepositoryError.assessmentNotFound("mat-456")
        #expect(assessmentNotFound.localizedDescription.contains("mat-456"))

        let networkError = MaterialsRepositoryError.networkError(.timeout)
        #expect(!networkError.localizedDescription.isEmpty)
    }

    @Test("MaterialsRepositoryError equatable works correctly")
    func testMaterialsRepositoryErrorEquatable() {
        #expect(MaterialsRepositoryError.emptyAnswers == MaterialsRepositoryError.emptyAnswers)
        #expect(MaterialsRepositoryError.unauthorized == MaterialsRepositoryError.unauthorized)
        #expect(MaterialsRepositoryError.invalidMaterialId("a") == MaterialsRepositoryError.invalidMaterialId("a"))
        #expect(MaterialsRepositoryError.invalidMaterialId("a") != MaterialsRepositoryError.invalidMaterialId("b"))
    }

    // MARK: - ProgressRepositoryError Tests

    @Test("ProgressRepositoryError provides localized descriptions")
    func testProgressRepositoryErrorDescriptions() {
        let invalidMaterialId = ProgressRepositoryError.invalidMaterialId("bad-mat")
        #expect(invalidMaterialId.localizedDescription.contains("bad-mat"))

        let invalidUserId = ProgressRepositoryError.invalidUserId("bad-user")
        #expect(invalidUserId.localizedDescription.contains("bad-user"))

        let invalidPercentage = ProgressRepositoryError.invalidPercentage(150)
        #expect(invalidPercentage.localizedDescription.contains("150"))

        let unauthorized = ProgressRepositoryError.unauthorized
        #expect(!unauthorized.localizedDescription.isEmpty)

        let forbidden = ProgressRepositoryError.forbidden
        #expect(!forbidden.localizedDescription.isEmpty)

        let networkError = ProgressRepositoryError.networkError(.noData)
        #expect(!networkError.localizedDescription.isEmpty)
    }

    @Test("ProgressRepositoryError equatable works correctly")
    func testProgressRepositoryErrorEquatable() {
        #expect(ProgressRepositoryError.unauthorized == ProgressRepositoryError.unauthorized)
        #expect(ProgressRepositoryError.forbidden == ProgressRepositoryError.forbidden)
        #expect(ProgressRepositoryError.invalidPercentage(50) == ProgressRepositoryError.invalidPercentage(50))
        #expect(ProgressRepositoryError.invalidPercentage(50) != ProgressRepositoryError.invalidPercentage(75))
    }

    // MARK: - StatsRepositoryError Tests

    @Test("StatsRepositoryError provides localized descriptions")
    func testStatsRepositoryErrorDescriptions() {
        let unauthorized = StatsRepositoryError.unauthorized
        #expect(!unauthorized.localizedDescription.isEmpty)

        let forbidden = StatsRepositoryError.forbidden
        #expect(forbidden.localizedDescription.contains("administrador"))

        let networkError = StatsRepositoryError.networkError(.timeout)
        #expect(!networkError.localizedDescription.isEmpty)
    }

    @Test("StatsRepositoryError equatable works correctly")
    func testStatsRepositoryErrorEquatable() {
        #expect(StatsRepositoryError.unauthorized == StatsRepositoryError.unauthorized)
        #expect(StatsRepositoryError.forbidden == StatsRepositoryError.forbidden)
        #expect(StatsRepositoryError.networkError(.timeout) == StatsRepositoryError.networkError(.timeout))
        #expect(StatsRepositoryError.networkError(.timeout) != StatsRepositoryError.networkError(.noData))
    }
}

@Suite("Retry Policy Tests")
struct RetryPolicyTests {
    @Test("ExponentialBackoffRetryPolicy calculates correct delays")
    func testExponentialBackoffDelays() {
        let policy = ExponentialBackoffRetryPolicy(
            baseDelay: 1.0,
            maxDelay: 30.0,
            jitterFactor: 0.0,
            maxRetryCount: 5
        )

        // delay = baseDelay * 2^(attempt-1)
        #expect(policy.delay(forAttempt: 1) == 1.0)  // 1 * 2^0 = 1
        #expect(policy.delay(forAttempt: 2) == 2.0)  // 1 * 2^1 = 2
        #expect(policy.delay(forAttempt: 3) == 4.0)  // 1 * 2^2 = 4
        #expect(policy.delay(forAttempt: 4) == 8.0)  // 1 * 2^3 = 8
        #expect(policy.delay(forAttempt: 5) == 16.0) // 1 * 2^4 = 16
    }

    @Test("ExponentialBackoffRetryPolicy respects maxDelay")
    func testExponentialBackoffMaxDelay() {
        let policy = ExponentialBackoffRetryPolicy(
            baseDelay: 10.0,
            maxDelay: 30.0,
            jitterFactor: 0.0,
            maxRetryCount: 5
        )

        // Without max: 10 * 2^4 = 160, but max is 30
        #expect(policy.delay(forAttempt: 5) == 30.0)
    }

    @Test("ExponentialBackoffRetryPolicy identifies retriable errors")
    func testExponentialBackoffRetriableErrors() {
        let policy = ExponentialBackoffRetryPolicy.standard

        // Retriable errors
        #expect(policy.shouldRetry(error: .timeout))
        #expect(policy.shouldRetry(error: .networkFailure(underlyingError: "offline")))
        #expect(policy.shouldRetry(error: .rateLimited(retryAfter: nil)))
        #expect(policy.shouldRetry(error: .serverError(statusCode: 500, message: nil)))
        #expect(policy.shouldRetry(error: .serverError(statusCode: 502, message: nil)))
        #expect(policy.shouldRetry(error: .serverError(statusCode: 503, message: nil)))
        #expect(policy.shouldRetry(error: .serverError(statusCode: 504, message: nil)))

        // Non-retriable errors
        #expect(!policy.shouldRetry(error: .unauthorized))
        #expect(!policy.shouldRetry(error: .forbidden))
        #expect(!policy.shouldRetry(error: .notFound))
        #expect(!policy.shouldRetry(error: .cancelled))
        #expect(!policy.shouldRetry(error: .invalidURL("bad")))
        #expect(!policy.shouldRetry(error: .noData))
    }

    @Test("ExponentialBackoffRetryPolicy maxRetryCount is configurable")
    func testExponentialBackoffMaxRetryCount() {
        let policy3 = ExponentialBackoffRetryPolicy(maxRetryCount: 3)
        #expect(policy3.maxRetryCount == 3)

        let policy5 = ExponentialBackoffRetryPolicy(maxRetryCount: 5)
        #expect(policy5.maxRetryCount == 5)
    }

    @Test("LinearBackoffRetryPolicy calculates correct delays")
    func testLinearBackoffDelays() {
        let policy = LinearBackoffRetryPolicy(
            baseDelay: 1.0,
            delayIncrement: 2.0,
            maxDelay: 20.0,
            maxRetryCount: 5
        )

        // delay = baseDelay + delayIncrement * (attempt - 1)
        #expect(policy.delay(forAttempt: 1) == 1.0)  // 1 + 2*0 = 1
        #expect(policy.delay(forAttempt: 2) == 3.0)  // 1 + 2*1 = 3
        #expect(policy.delay(forAttempt: 3) == 5.0)  // 1 + 2*2 = 5
        #expect(policy.delay(forAttempt: 4) == 7.0)  // 1 + 2*3 = 7
    }

    @Test("FixedDelayRetryPolicy returns same delay for all attempts")
    func testFixedDelayPolicy() {
        let policy = FixedDelayRetryPolicy(delay: 5.0, maxRetryCount: 3)

        #expect(policy.delay(forAttempt: 1) == 5.0)
        #expect(policy.delay(forAttempt: 2) == 5.0)
        #expect(policy.delay(forAttempt: 3) == 5.0)
    }

    @Test("Retry policy presets have correct configurations")
    func testRetryPolicyPresets() {
        let aggressive = ExponentialBackoffRetryPolicy.aggressive
        #expect(aggressive.maxRetryCount == 5)

        let conservative = ExponentialBackoffRetryPolicy.conservative
        #expect(conservative.maxRetryCount == 3)

        let standard = ExponentialBackoffRetryPolicy.standard
        #expect(standard.maxRetryCount == 3)

        let none = ExponentialBackoffRetryPolicy.none
        #expect(none.maxRetryCount == 0)
    }
}

@Suite("JSONValue Tests")
struct JSONValueTests {
    @Test("JSONValue decodes all primitive types")
    func testJSONValuePrimitives() throws {
        let decoder = JSONDecoder()

        let boolJSON = "true".data(using: .utf8)!
        let boolValue = try decoder.decode(JSONValue.self, from: boolJSON)
        #expect(boolValue == .bool(true))
        #expect(boolValue.boolValue == true)

        let intJSON = "42".data(using: .utf8)!
        let intValue = try decoder.decode(JSONValue.self, from: intJSON)
        #expect(intValue == .integer(42))
        #expect(intValue.intValue == 42)

        let doubleJSON = "3.14".data(using: .utf8)!
        let doubleValue = try decoder.decode(JSONValue.self, from: doubleJSON)
        #expect(doubleValue == .double(3.14))
        #expect(doubleValue.doubleValue == 3.14)

        let stringJSON = "\"hello\"".data(using: .utf8)!
        let stringValue = try decoder.decode(JSONValue.self, from: stringJSON)
        #expect(stringValue == .string("hello"))
        #expect(stringValue.stringValue == "hello")

        let nullJSON = "null".data(using: .utf8)!
        let nullValue = try decoder.decode(JSONValue.self, from: nullJSON)
        #expect(nullValue == .null)
        #expect(nullValue.isNull)
    }

    @Test("JSONValue decodes arrays")
    func testJSONValueArray() throws {
        let json = "[1, 2, 3]".data(using: .utf8)!
        let decoder = JSONDecoder()
        let value = try decoder.decode(JSONValue.self, from: json)

        if case .array(let array) = value {
            #expect(array.count == 3)
            #expect(array[0] == .integer(1))
        } else {
            Issue.record("Expected array")
        }
    }

    @Test("JSONValue decodes objects")
    func testJSONValueObject() throws {
        let json = "{\"name\": \"test\", \"count\": 5}".data(using: .utf8)!
        let decoder = JSONDecoder()
        let value = try decoder.decode(JSONValue.self, from: json)

        if case .object(let object) = value {
            #expect(object["name"] == .string("test"))
            #expect(object["count"] == .integer(5))
        } else {
            Issue.record("Expected object")
        }
    }

    @Test("JSONValue accessors return nil for wrong types")
    func testJSONValueWrongTypeAccessors() {
        let stringValue = JSONValue.string("hello")

        #expect(stringValue.boolValue == nil)
        #expect(stringValue.intValue == nil)
        #expect(stringValue.arrayValue == nil)
        #expect(stringValue.objectValue == nil)
        #expect(!stringValue.isNull)
    }

    @Test("JSONValue doubleValue works for int")
    func testJSONValueIntToDouble() {
        let intValue = JSONValue.integer(42)
        #expect(intValue.doubleValue == 42.0)
    }
}
