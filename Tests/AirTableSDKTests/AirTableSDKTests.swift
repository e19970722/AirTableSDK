import XCTest
@testable import AirTableSDK

// Naming Structure: test_UnitOfWork_StateUnderTest_ExpectedBehavior

final class AirTableSDKTests: XCTestCase {
    
    var mockSession: MockURLSession = MockURLSession()
    
    override func setUpWithError() throws {

    }
    
    override func tearDownWithError() throws {
        
    }
    
    class MockURLSession: URLSession {
        var delay: TimeInterval = 0
        var mockData: Data?
        var mockResponse: URLResponse?
        var mockError: Error?
        
        override func dataTask(with request: URLRequest, 
                               completionHandler: @escaping (Data?, URLResponse?, (any Error)?) -> Void) -> URLSessionDataTask {
            let task = MockURLSessionDataTask {
                DispatchQueue.global().asyncAfter(deadline: .now() + self.delay) {
                    completionHandler(self.mockData, self.mockResponse, self.mockError)
                }
            }
            return task
        }
    }
    
    class MockURLSessionDataTask: URLSessionDataTask {
        private let closure: () -> Void
        
        init(closure: @escaping () -> Void) {
            self.closure = closure
        }
        
        override func resume() {
            closure()
        }
    }
    
    func test_AirTableSDK_fetchRecordsWithValidParam_returnRecords() throws {
        // Given
        let sdk = AirtableSDK(baseId: "testBaseID", apiKey: "testAPIKey", session: mockSession)
        
        // When
        let jsonString = """
        {
            "records": [
                        { "id": "rec123", "fields": { "name": "Test Item" } }
                    ]
        }
        """
        mockSession.mockData = jsonString.data(using: .utf8)
        mockSession.mockResponse = HTTPURLResponse(url: URL(string: "https://airtable.com.tw")!,
                                                   statusCode: 200,
                                                   httpVersion: nil,
                                                   headerFields: nil)
        
        let expectation = XCTestExpectation(description: "CompletionHandler called")
        sdk.fetchRecords(from: "testTable") { result in
            switch result {
            case .success(let record):
                XCTAssertEqual(record.count, 1)
                expectation.fulfill()
            case .failure:
                XCTFail()
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 10)
    }
    
    func test_AirTableSDK_fetchRecordsWithInvalidBaseID_returnInvalidURL() throws {
        // Given
        let sdk = AirtableSDK(baseId: "", apiKey: "testAPIKey", session: mockSession)
        
        // When
        mockSession.mockResponse = HTTPURLResponse(url: URL(string: "https://airtable.com.tw")!,
                                                   statusCode: -1,
                                                   httpVersion: nil,
                                                   headerFields: nil)
        
        let expectation = XCTestExpectation(description: "CompletionHandler called")
        sdk.fetchRecords(from: "testTable") { result in
            switch result {
            case .success:
                XCTFail()
            case .failure(let error):
                XCTAssertEqual(error, AirtableError.invalidURL)
                expectation.fulfill()
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 10)
    }
    
    func test_AirTableSDK_fetchRecordsWithInvalidTableName_returnInvalidURL() throws {
        // Given
        let sdk = AirtableSDK(baseId: "testBaseID", apiKey: "testAPIKey", session: mockSession)
        
        // When
        mockSession.mockResponse = HTTPURLResponse(url: URL(string: "https://airtable.com.tw")!,
                                                   statusCode: -1,
                                                   httpVersion: nil,
                                                   headerFields: nil)
        
        let expectation = XCTestExpectation(description: "CompletionHandler called")
        sdk.fetchRecords(from: "") { result in
            switch result {
            case .success:
                XCTFail()
            case .failure(let error):
                XCTAssertEqual(error, AirtableError.invalidURL)
                expectation.fulfill()
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 10)
    }
    
    func test_AirTableSDK_fetchRecordsWithInvalidAPIKey_returnUnauthorized() throws {
        // Given
        let sdk = AirtableSDK(baseId: "testBaseID", apiKey: "", session: mockSession)
        
        // When
        mockSession.mockResponse = HTTPURLResponse(url: URL(string: "https://airtable.com.tw")!,
                                                   statusCode: 401,
                                                   httpVersion: nil,
                                                   headerFields: nil)
        
        let expectation = XCTestExpectation(description: "CompletionHandler called")
        sdk.fetchRecords(from: "testTable") { result in
            switch result {
            case .success:
                XCTFail()
            case .failure(let error):
                XCTAssertEqual(error, AirtableError.unauthorized)
                expectation.fulfill()
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 10)
    }
    
    func test_AirTableSDK_fetchRecordsWithStatusCode599_returnBadServerResponse() throws {
        // Given
        let sdk = AirtableSDK(baseId: "testBaseID", apiKey: "testAPIKey", session: mockSession)
        
        // When
        mockSession.mockResponse = HTTPURLResponse(url: URL(string: "https://airtable.com.tw")!,
                                                   statusCode: 599,
                                                   httpVersion: nil,
                                                   headerFields: nil)
        
        let expectation = XCTestExpectation(description: "CompletionHandler called")
        sdk.fetchRecords(from: "testTable") { result in
            switch result {
            case .success:
                XCTFail()
            case .failure(let error):
                XCTAssertEqual(error, AirtableError.badServerResponse)
                expectation.fulfill()
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 10)
    }
    
    func test_AirTableSDK_fetchRecordsWithResponseEmptyData_returnNoData() throws {
        // Given
        let sdk = AirtableSDK(baseId: "testBaseID", apiKey: "testAPIKey", session: mockSession)
        
        // When
        mockSession.mockResponse = HTTPURLResponse(url: URL(string: "https://airtable.com.tw")!,
                                                   statusCode: 200,
                                                   httpVersion: nil,
                                                   headerFields: nil)
        mockSession.mockData = nil
        
        let expectation = XCTestExpectation(description: "CompletionHandler called")
        sdk.fetchRecords(from: "testTable") { result in
            switch result {
            case .success:
                XCTFail()
            case .failure(let error):
                XCTAssertEqual(error, AirtableError.noData)
                expectation.fulfill()
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 10)
    }
    
    func test_AirTableSDK_fetchRecordsWithReturnInvalidJSON_returnDecodingError() throws {
        // Given
        let sdk = AirtableSDK(baseId: "testBaseID", apiKey: "testAPIKey", session: mockSession)
        
        // When
        let jsonString = """
        {
            "records": [
                        { "id": "rec123", "fields": { "name": "Test Item" }
        }
        """
        mockSession.mockData = jsonString.data(using: .utf8)
        mockSession.mockResponse = HTTPURLResponse(url: URL(string: "https://airtable.com.tw")!,
                                                   statusCode: 200,
                                                   httpVersion: nil,
                                                   headerFields: nil)
        
        let expectation = XCTestExpectation(description: "CompletionHandler called")
        sdk.fetchRecords(from: "testTable") { result in
            switch result {
            case .success:
                XCTFail()
            case .failure(let error):
                XCTAssertEqual(error, AirtableError.decodingError)
                expectation.fulfill()
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 10)
    }
    
    func test_AirTableSDK_fetchRecordsWithTimeoutResponse_returnTimeout() throws {
        // Given
        let sdk = AirtableSDK(baseId: "testBaseID", apiKey: "testAPIKey", session: mockSession)
        
        // When
        mockSession.mockResponse = HTTPURLResponse(url: URL(string: "https://airtable.com.tw")!,
                                                   statusCode: 408,
                                                   httpVersion: nil,
                                                   headerFields: nil)
        
        let expectation = XCTestExpectation(description: "CompletionHandler called")
        sdk.fetchRecords(from: "testTable") { result in
            switch result {
            case .success:
                XCTFail()
            case .failure(let error):
                XCTAssertEqual(error, AirtableError.timeout)
                expectation.fulfill()
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 10)
    }
    
    func test_AirTableSDK_fetchRecordsWithLateResponse_returnTimeout() throws {
        // Given
        let sdk = AirtableSDK(baseId: "testBaseID", apiKey: "testAPIKey", session: mockSession)
        
        // When
        mockSession.delay = 31
        mockSession.mockError = URLError(.timedOut)
        mockSession.mockResponse = HTTPURLResponse(url: URL(string: "https://airtable.com.tw")!,
                                                   statusCode: 200,
                                                   httpVersion: nil,
                                                   headerFields: nil)
        
        let expectation = XCTestExpectation(description: "CompletionHandler called")
        sdk.fetchRecords(from: "testTable") { result in
            switch result {
            case .success:
                XCTFail()
            case .failure(let error):
                XCTAssertEqual(error, AirtableError.timeout)
                expectation.fulfill()
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 31)
    }
    
    func test_AirTableSDK_fetchRecordsWithOtherError_returnUnknownError() throws {
        // Given
        let sdk = AirtableSDK(baseId: "testBaseID", apiKey: "testAPIKey", session: mockSession)
        
        // When
        mockSession.mockError = URLError(.unknown)
        mockSession.mockResponse = HTTPURLResponse(url: URL(string: "https://airtable.com.tw")!,
                                                   statusCode: -1,
                                                   httpVersion: nil,
                                                   headerFields: nil)
        
        let expectation = XCTestExpectation(description: "CompletionHandler called")
        sdk.fetchRecords(from: "testTable") { result in
            switch result {
            case .success:
                XCTFail()
            case .failure(let error):
                XCTAssertEqual(error, AirtableError.unknown)
                expectation.fulfill()
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 10)
    }
}
