// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

public class AirtableSDK {
    private let baseId: String
    private let apiKey: String
    private let session: URLSession

    public init(baseId: String, apiKey: String, session: URLSession = .shared) {
        self.baseId = baseId
        self.apiKey = apiKey
        self.session = session
    }

    public func fetchRecords(from tableName: String, completion: @escaping (Result<[AirtableRecord], AirtableError>) -> Void) {

        guard !apiKey.isEmpty else {
            completion(.failure(.unauthorized))
            return
        }
        
        let urlString = "https://api.airtable.com/v0/\(baseId)/\(tableName)"
        guard !baseId.isEmpty, !tableName.isEmpty,
              let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        session.dataTask(with: request) { data, response, error in
            
            if let urlError = error as? URLError, urlError.code == .timedOut {
                completion(.failure(.timeout))
                return
            } else if error != nil {
                completion(.failure(.unknown))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode != 200 {
                switch httpResponse.statusCode {
                case 401:
                    completion(.failure(.unauthorized))
                case 408:
                    completion(.failure(.timeout))
                default:
                    completion(.failure(.badServerResponse))
                }
                return
            }

            guard let data = data else {
                completion(.failure(.noData))
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode(AirtableResponse.self, from: data)
                completion(.success(decodedResponse.records))
            } catch {
                completion(.failure(.decodingError))
            }
            
        }.resume()
    }
}

