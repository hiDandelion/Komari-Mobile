//
//  WidgetDataProvider.swift
//  Komari Widget
//
//  Created by Junhui Lou on 2/19/26.
//

import Foundation

enum WidgetDataProvider {
    /// Ensure authentication: prefer API key, fall back to username/password login
    static func ensureAuth() async throws {
        let apiKey = WidgetKMCore.getKomariAPIKey()
        if !apiKey.isEmpty { return }

        let username = WidgetKMCore.getKomariDashboardUsername()
        let password = WidgetKMCore.getKomariDashboardPassword()

        guard !username.isEmpty, !password.isEmpty else {
            throw KomariError.authenticationFailed
        }

        try await WidgetAuthHandler.login(username: username, password: password)
    }

    /// Fetch all nodes
    static func getNodes() async throws -> [String: NodeData] {
        let result: [String: NodeData] = try await WidgetRPC2Handler.call(method: "common:getNodes")
        return result
    }

    /// Fetch latest live status for all nodes
    static func getNodesLatestStatus() async throws -> [String: NodeLiveStatus] {
        let result: [String: NodeLiveStatus] = try await WidgetRPC2Handler.call(method: "common:getNodesLatestStatus")
        return result
    }

    /// Fetch load records for a specific node via REST
    static func getRecords(uuid: String, hours: Int) async throws -> [NodeRecord] {
        guard let baseURL = WidgetKMCore.getAPIURL(endpoint: "/api/records/load") else {
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

        let (data, response) = try await WidgetRequestHandler.request(url: url)

        guard response.statusCode == 200 else {
            throw KomariError.invalidResponse("Failed to fetch records: HTTP \(response.statusCode)")
        }

        let decoder = JSONDecoder()
        let baseResponse = try decoder.decode(KomariBaseResponse<LoadRecordsData>.self, from: data)
        guard baseResponse.isSuccess, let recordsData = baseResponse.data else {
            throw KomariError.invalidResponse(baseResponse.message ?? "Failed to fetch records")
        }
        return recordsData.records ?? []
    }

    /// Fetch ping records for a specific node via RPC2
    static func getPingRecords(uuid: String, hours: Int) async throws -> PingRecordsData {
        struct PingParams: Codable {
            let uuid: String
            let type: String
            let hours: Int
        }
        let params = PingParams(uuid: uuid, type: "ping", hours: hours)
        let result: PingRecordsData = try await WidgetRPC2Handler.call(method: "common:getRecords", params: params)
        return result
    }
}
