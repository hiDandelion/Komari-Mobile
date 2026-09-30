//
//  RequestHandler.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import Foundation

enum KomariError: LocalizedError {
    case invalidDashboardConfiguration
    case authenticationFailed
    case networkError(Error)
    case decodingError
    case invalidResponse(String)
    case rpcError(String)
    case unsupportedByServer

    var errorDescription: String? {
        switch self {
        case .invalidDashboardConfiguration:
            return String(localized: "Dashboard is not properly configured.")
        case .authenticationFailed:
            return String(localized: "Authentication failed.")
        case .networkError(let error):
            return error.localizedDescription
        case .decodingError:
            return "Unable to decode data."
        case .invalidResponse(let message):
            return message
        case .rpcError(let message):
            return "RPC Error: \(message)"
        case .unsupportedByServer:
            return String(localized: "This feature is not supported by your Komari dashboard version.")
        }
    }
}

class RequestHandler {
    static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = HTTPCookieStorage.shared
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        return URLSession(configuration: config)
    }()

    static func request(url: URL, method: String = "GET", body: Data? = nil, headers: [String: String]? = nil) async throws -> (Data, HTTPURLResponse) {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.httpBody = body

        // Attach API key if available and no session cookie
        let apiKey = KMCore.getKomariAPIKey()
        if !apiKey.isEmpty {
            urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        if let headers {
            for (key, value) in headers {
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
        }

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw KomariError.networkError(URLError(.badServerResponse))
        }

        // Unknown API paths fall through to the dashboard's web frontend, which answers with
        // index.html. That happens for endpoints removed in newer Komari releases. The final URL
        // is checked so redirects out of the API (e.g. logout → "/") are not mistaken for it.
        if (httpResponse.url ?? url).path.contains("/api/"),
           httpResponse.value(forHTTPHeaderField: "Content-Type")?.lowercased().hasPrefix("text/html") == true {
            throw KomariError.unsupportedByServer
        }

        return (data, httpResponse)
    }

    /// Header carrying a 2FA code for sensitive operations (remote exec, disabling 2FA, …).
    static func twoFactorHeaders(_ code: String?) -> [String: String] {
        guard let code, !code.isEmpty else { return [:] }
        return ["X-2FA-Code": code]
    }

    /// Error message from a `{status, message}` body, falling back to a generic description.
    static func errorMessage(from data: Data, fallback: String) -> String {
        struct ErrorBody: Decodable {
            let message: String?
        }
        if let body = try? JSONDecoder().decode(ErrorBody.self, from: data),
           let message = body.message, !message.isEmpty {
            return message
        }
        return fallback
    }

    static func handleDecodingError(error: DecodingError) {
        switch error {
        case .dataCorrupted(let context):
            _ = KMCore.debugLog("Data corrupted - \(context.debugDescription)")
        case .keyNotFound(let key, let context):
            _ = KMCore.debugLog("Key '\(key)' not found - \(context.debugDescription)")
        case .typeMismatch(let type, let context):
            _ = KMCore.debugLog("Type '\(type)' mismatch - \(context.debugDescription)")
        case .valueNotFound(let type, let context):
            _ = KMCore.debugLog("Value of type '\(type)' not found - \(context.debugDescription)")
        @unknown default:
            _ = KMCore.debugLog("Unknown decoding error")
        }
    }
}
