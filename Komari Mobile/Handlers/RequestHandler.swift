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

        return (data, httpResponse)
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
