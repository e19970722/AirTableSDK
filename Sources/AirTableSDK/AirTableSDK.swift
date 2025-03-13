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

    public func fetchRecords(from tableName: String, completion: @escaping (Result<[AirtableRecord], Error>) -> Void) {
        let urlString = "https://api.airtable.com/v0/\(baseId)/\(tableName)"
        guard let url = URL(string: urlString) else {
            completion(.failure(AirtableError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(AirtableError.noData))
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode(AirtableResponse.self, from: data)
                completion(.success(decodedResponse.records))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

