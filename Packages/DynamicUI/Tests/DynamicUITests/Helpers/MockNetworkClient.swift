import Foundation
import EduNetwork

/// Mock del cliente de red para tests unitarios de DynamicUI.
actor MockNetworkClient: NetworkClientProtocol {
    var mockResponse: (any Sendable)?
    var mockError: Error?
    var mockData: Data?
    var mockHTTPResponse: HTTPURLResponse?
    private(set) var requestHistory: [HTTPRequest] = []

    var requestCount: Int { requestHistory.count }

    func setDataResponse(
        data: Data,
        statusCode: Int = 200,
        headers: [String: String] = [:]
    ) {
        let url = URL(string: "https://mock.test")!
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: headers
        )!
        self.mockData = data
        self.mockHTTPResponse = response
        self.mockError = nil
    }

    func setDecodableResponse<T: Sendable>(_ response: T) {
        self.mockResponse = response
        self.mockError = nil
    }

    func setError(_ error: Error) {
        self.mockError = error
    }

    var lastRequest: HTTPRequest? {
        requestHistory.last
    }

    func reset() {
        mockResponse = nil
        mockError = nil
        mockData = nil
        mockHTTPResponse = nil
        requestHistory.removeAll()
    }

    // MARK: - NetworkClientProtocol

    func request<T: Decodable & Sendable>(_ request: HTTPRequest) async throws -> T {
        requestHistory.append(request)
        if let error = mockError { throw error }
        if let response = mockResponse as? T { return response }
        throw NetworkError.noData
    }

    func requestData(_ request: HTTPRequest) async throws -> (Data, HTTPURLResponse) {
        requestHistory.append(request)
        if let error = mockError { throw error }
        guard let data = mockData else { throw NetworkError.noData }
        let response = mockHTTPResponse ?? HTTPURLResponse(
            url: URL(string: request.url)!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        return (data, response)
    }

    func upload<T: Decodable & Sendable>(data: Data, request: HTTPRequest) async throws -> T {
        throw NetworkError.noData
    }

    func upload<T: Decodable & Sendable>(fileURL: URL, request: HTTPRequest) async throws -> T {
        throw NetworkError.noData
    }

    func download(_ request: HTTPRequest) async throws -> URL {
        throw NetworkError.noData
    }

    func downloadData(_ request: HTTPRequest) async throws -> Data {
        throw NetworkError.noData
    }
}
