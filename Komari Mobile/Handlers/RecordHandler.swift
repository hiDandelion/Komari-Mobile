//
//  RecordHandler.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import Foundation

class RecordHandler {
    /// Fetch load records for a specific node via REST endpoint
    static func getRecords(uuid: String, hours: Int) async throws -> [NodeRecord] {
        guard let baseURL = KMCore.getAPIURL(endpoint: "/api/records/load") else {
            throw KomariError.invalidDashboardConfiguration
        }

        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw KomariError.invalidDashboardConfiguration
        }
        components.queryItems = [
            URLQueryItem(name: "uuid", value: uuid),
            URLQueryItem(name: "hours", value: String(hours))
        ]

        guard let url = components.url else {
            throw KomariError.invalidDashboardConfiguration
        }

        let (data, response) = try await RequestHandler.request(url: url)

        guard response.statusCode == 200 else {
            throw KomariError.invalidResponse("Failed to fetch records: HTTP \(response.statusCode)")
        }

        let decoder = JSONDecoder()
        do {
            let baseResponse = try decoder.decode(KomariBaseResponse<LoadRecordsData>.self, from: data)
            guard baseResponse.isSuccess, let recordsData = baseResponse.data else {
                throw KomariError.invalidResponse(baseResponse.message ?? "Failed to fetch records")
            }
            return recordsData.records ?? []
        } catch let error as DecodingError {
            RequestHandler.handleDecodingError(error: error)
            throw error
        }
    }
}
