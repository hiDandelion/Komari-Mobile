//
//  AdminHandler.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import Foundation

class AdminHandler {
    /// Edit a client's settings
    static func editClient(uuid: String, changes: [String: Any]) async throws {
        guard let url = KMCore.getAPIURL(endpoint: "/api/admin/client/\(uuid)/edit") else {
            throw KomariError.invalidDashboardConfiguration
        }

        let bodyData = try JSONSerialization.data(withJSONObject: changes)

        let (data, response) = try await RequestHandler.request(
            url: url,
            method: "POST",
            body: bodyData,
            headers: ["Content-Type": "application/json"]
        )

        guard response.statusCode == 200 else {
            throw KomariError.invalidResponse("Edit client failed with status \(response.statusCode)")
        }

        let decoder = JSONDecoder()
        let baseResponse = try decoder.decode(KomariBaseResponse<String?>.self, from: data)

        guard baseResponse.isSuccess else {
            throw KomariError.invalidResponse(baseResponse.message ?? "Edit client failed")
        }
    }

    /// Remove a client
    static func removeClient(uuid: String) async throws {
        guard let url = KMCore.getAPIURL(endpoint: "/api/admin/client/\(uuid)/remove") else {
            throw KomariError.invalidDashboardConfiguration
        }

        let (data, response) = try await RequestHandler.request(
            url: url,
            method: "POST",
            headers: ["Content-Type": "application/json"]
        )

        guard response.statusCode == 200 else {
            throw KomariError.invalidResponse("Remove client failed with status \(response.statusCode)")
        }

        let decoder = JSONDecoder()
        let baseResponse = try decoder.decode(KomariBaseResponse<String?>.self, from: data)

        guard baseResponse.isSuccess else {
            throw KomariError.invalidResponse(baseResponse.message ?? "Remove client failed")
        }
    }

    /// Reorder clients
    static func reorderClients(uuids: [String]) async throws {
        guard let url = KMCore.getAPIURL(endpoint: "/api/admin/client/order") else {
            throw KomariError.invalidDashboardConfiguration
        }

        let bodyData = try JSONSerialization.data(withJSONObject: ["uuids": uuids])

        let (data, response) = try await RequestHandler.request(
            url: url,
            method: "POST",
            body: bodyData,
            headers: ["Content-Type": "application/json"]
        )

        guard response.statusCode == 200 else {
            throw KomariError.invalidResponse("Reorder clients failed with status \(response.statusCode)")
        }

        let decoder = JSONDecoder()
        let baseResponse = try decoder.decode(KomariBaseResponse<String?>.self, from: data)

        guard baseResponse.isSuccess else {
            throw KomariError.invalidResponse(baseResponse.message ?? "Reorder clients failed")
        }
    }
}
