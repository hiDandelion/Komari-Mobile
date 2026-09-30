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
            // e.g. "2FA code is required", "Password login is disabled"
            let message = RequestHandler.errorMessage(from: data, fallback: "")
            throw message.isEmpty ? KomariError.authenticationFailed : KomariError.invalidResponse(message)
        }

        // Decode the response to check status
        let decoder = JSONDecoder()
        let baseResponse = try decoder.decode(KomariBaseResponse<LoginResponseData>.self, from: data)

        guard baseResponse.isSuccess else {
            throw KomariError.invalidResponse(baseResponse.message ?? "Login failed")
        }

        return true
    }

    /// Get current user info. Uses RPC `common:getMe`, which (unlike REST `/api/me`) also
    /// recognizes API-key authentication.
    static func getMe() async throws -> MeResponseData {
        let meData: MeResponseData = try await RPC2Handler.call(method: "common:getMe")

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
