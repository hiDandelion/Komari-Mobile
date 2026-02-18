//
//  AuthHandler.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import Foundation

class AuthHandler {
    /// Login with username/password. On success, session cookie is stored automatically.
    @discardableResult
    static func login(username: String, password: String, tfaCode: String? = nil) async throws -> Bool {
        guard let url = KMCore.getAPIURL(endpoint: "/api/login") else {
            throw KomariError.invalidDashboardConfiguration
        }

        var bodyDict: [String: String] = [
            "username": username,
            "password": password
        ]
        if let tfaCode, !tfaCode.isEmpty {
            bodyDict["2fa_code"] = tfaCode
        }

        let bodyData = try JSONSerialization.data(withJSONObject: bodyDict)

        let (data, response) = try await RequestHandler.request(
            url: url,
            method: "POST",
            body: bodyData,
            headers: ["Content-Type": "application/json"]
        )

        guard response.statusCode == 200 else {
            throw KomariError.authenticationFailed
        }

        // Decode the response to check status
        let decoder = JSONDecoder()
        let baseResponse = try decoder.decode(KomariBaseResponse<LoginResponseData>.self, from: data)

        guard baseResponse.isSuccess else {
            throw KomariError.invalidResponse(baseResponse.message ?? "Login failed")
        }

        return true
    }

    /// Get current user info (returns plain object, not wrapped in KomariBaseResponse)
    static func getMe() async throws -> MeResponseData {
        guard let url = KMCore.getAPIURL(endpoint: "/api/me") else {
            throw KomariError.invalidDashboardConfiguration
        }

        let (data, response) = try await RequestHandler.request(url: url)

        guard response.statusCode == 200 else {
            throw KomariError.authenticationFailed
        }

        let decoder = JSONDecoder()
        let meData = try decoder.decode(MeResponseData.self, from: data)

        guard meData.loggedIn == true else {
            throw KomariError.authenticationFailed
        }

        return meData
    }

    /// Logout
    static func logout() async throws {
        guard let url = KMCore.getAPIURL(endpoint: "/api/logout") else {
            throw KomariError.invalidDashboardConfiguration
        }

        _ = try await RequestHandler.request(url: url)
    }
}
