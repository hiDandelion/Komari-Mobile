//
//  WidgetNetworking.swift
//  Komari Widget
//
//  Created by Junhui Lou on 2/19/26.
//

import Foundation

// MARK: - Errors

enum KomariError: LocalizedError {
    case invalidDashboardConfiguration
    case authenticationFailed
    case networkError(Error)
    case decodingError
    case invalidResponse(String)
    case rpcError(String)

    var errorDescription: String? {
        switch self {
        case .invalidDashboardConfiguration:
            return "Dashboard is not properly configured."
        case .authenticationFailed:
            return "Authentication failed."
        case .networkError(let error):
            return error.localizedDescription
        case .decodingError:
            return "Unable to decode data."
        case .invalidResponse(let message):
            return message
        case .rpcError(let message):
            return "RPC Error: \(message)"
        }
    }
}

// MARK: - Request Handler

enum WidgetRequestHandler {
    static func request(url: URL, method: String = "GET", body: Data? = nil, headers: [String: String]? = nil) async throws -> (Data, HTTPURLResponse) {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.httpBody = body

        let apiKey = WidgetKMCore.getKomariAPIKey()
        if !apiKey.isEmpty {
            urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        if let headers {
            for (key, value) in headers {
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
        }

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw KomariError.networkError(URLError(.badServerResponse))
        }

        return (data, httpResponse)
    }
}

// MARK: - RPC2 Handler

enum WidgetRPC2Handler {
    private static var nextID: Int = 1

    static func call<P: Encodable, R: Decodable>(method: String, params: P? = nil as EmptyParams?) async throws -> R {
        guard let url = WidgetKMCore.getAPIURL(endpoint: "/api/rpc2") else {
            throw KomariError.invalidDashboardConfiguration
        }

        let requestID = nextID
        nextID += 1
        let rpcRequest = RPC2Request(method: method, params: params, id: requestID)

        let encoder = JSONEncoder()
        let bodyData = try encoder.encode(rpcRequest)

        let (data, response) = try await WidgetRequestHandler.request(
            url: url,
            method: "POST",
            body: bodyData,
            headers: ["Content-Type": "application/json"]
        )

        guard response.statusCode == 200 else {
            throw KomariError.invalidResponse("RPC2 request failed with status \(response.statusCode)")
        }

        let decoder = JSONDecoder()
        let rpcResponse = try decoder.decode(RPC2Response<R>.self, from: data)

        if let error = rpcResponse.error {
            throw KomariError.rpcError(error.message ?? "Unknown RPC error")
        }

        guard let result = rpcResponse.result else {
            throw KomariError.invalidResponse("RPC2 response missing result")
        }

        return result
    }
}

// MARK: - Auth Handler

enum WidgetAuthHandler {
    @discardableResult
    static func login(username: String, password: String) async throws -> Bool {
        guard let url = WidgetKMCore.getAPIURL(endpoint: "/api/login") else {
            throw KomariError.invalidDashboardConfiguration
        }

        let bodyDict: [String: String] = [
            "username": username,
            "password": password
        ]

        let bodyData = try JSONSerialization.data(withJSONObject: bodyDict)

        let (data, response) = try await WidgetRequestHandler.request(
            url: url,
            method: "POST",
            body: bodyData,
            headers: ["Content-Type": "application/json"]
        )

        guard response.statusCode == 200 else {
            throw KomariError.authenticationFailed
        }

        let decoder = JSONDecoder()
        let baseResponse = try decoder.decode(KomariBaseResponse<LoginResponseData>.self, from: data)

        guard baseResponse.isSuccess else {
            throw KomariError.invalidResponse(baseResponse.message ?? "Login failed")
        }

        return true
    }
}
