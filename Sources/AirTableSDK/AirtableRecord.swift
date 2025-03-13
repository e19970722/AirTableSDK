//
//  AirtableRecord.swift
//  AirTableSDK
//
//  Created by Yen Lin on 2025/3/13.
//

public struct AirtableResponse: Codable {
    public let records: [AirtableRecord]
}

public struct AirtableRecord: Codable {
    public let id: String
    public let fields: [String: String]
}

public enum AirtableError: Error {
    case invalidURL
    case noData
}
