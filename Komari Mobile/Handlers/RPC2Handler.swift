//
//  RPC2Handler.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import Foundation

class RPC2Handler {
    private static var nextID: Int = 1
    private static let lock = NSLock()

    private static func getNextID() -> Int {
        lock.lock()
        defer { lock.unlock() }
        let id = nextID
        nextID += 1
        return id
    }

    static func call<P: Encodable, R: Decodable>(method: String, params: P? = nil as EmptyParams?) async throws -> R {
        guard let url = KMCore.getAPIURL(endpoint: "/api/rpc2") else {
            throw KomariError.invalidDashboardConfiguration
        }

        let requestID = getNextID()
        let rpcRequest = RPC2Request(method: method, params: params, id: requestID)

        let encoder = JSONEncoder()
        let bodyData = try encoder.encode(rpcRequest)

        let (data, response) = try await RequestHandler.request(
            url: url,
            method: "POST",
            body: bodyData,
            headers: ["Content-Type": "application/json"]
        )

        guard response.statusCode == 200 else {
            throw KomariError.invalidResponse("RPC2 request failed with status \(response.statusCode)")
        }

        let decoder = JSONDecoder()
        do {
            let rpcResponse = try decoder.decode(RPC2Response<R>.self, from: data)

            if let error = rpcResponse.error {
                throw KomariError.rpcError(error.message ?? "Unknown RPC error")
            }

            guard let result = rpcResponse.result else {
                throw KomariError.invalidResponse("RPC2 response missing result")
            }

            return result
        } catch let error as DecodingError {
            RequestHandler.handleDecodingError(error: error)
            throw error
        }
    }
}
