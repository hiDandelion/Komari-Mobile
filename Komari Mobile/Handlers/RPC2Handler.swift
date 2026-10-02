//
//  RPC2Handler.swift
//  Komari Mobile
//
//  Created by Takuma Kirishima on 2/15/26.
//

import Foundation

class RPC2Handler {
    private static var nextID: Int = 1
    private static let lock = NSLock()

    /// JSON-RPC "method not found": the dashboard predates (or has dropped) the method.
    private static let methodNotFoundCode = -32601

    private static func getNextID() -> Int {
        lock.lock()
        defer { lock.unlock() }
        let id = nextID
        nextID += 1
        return id
    }

    static func call<P: Encodable, R: Decodable>(method: String, params: P? = nil as EmptyParams?, headers: [String: String] = [:]) async throws -> R {
        let rpcResponse: RPC2Response<R> = try await perform(method: method, params: params, headers: headers)
        guard let result = rpcResponse.result else {
            throw KomariError.invalidResponse("RPC2 response missing result")
        }
        return result
    }

    /// Calls a method whose result is irrelevant (many admin methods return `null` on success).
    static func callIgnoringResult<P: Encodable>(method: String, params: P? = nil as EmptyParams?, headers: [String: String] = [:]) async throws {
        let _: RPC2Response<IgnoredResult> = try await perform(method: method, params: params, headers: headers)
    }

    /// Names of every method the dashboard exposes; used to adapt to its version.
    static func availableMethods() async throws -> Set<String> {
        let methods: [String] = try await call(method: "rpc.methods")
        return Set(methods)
    }

    private struct IgnoredResult: Decodable {
        init(from decoder: Decoder) throws {}
    }

    private static func perform<P: Encodable, R: Decodable>(method: String, params: P?, headers: [String: String]) async throws -> RPC2Response<R> {
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
            headers: headers.merging(["Content-Type": "application/json"]) { current, _ in current }
        )

        guard response.statusCode == 200 else {
            throw KomariError.invalidResponse("RPC2 request failed with status \(response.statusCode)")
        }

        let decoder = JSONDecoder()
        do {
            let rpcResponse = try decoder.decode(RPC2Response<R>.self, from: data)

            if let error = rpcResponse.error {
                if error.code == methodNotFoundCode {
                    throw KomariError.unsupportedByServer
                }
                throw KomariError.rpcError(error.message ?? "Unknown RPC error")
            }

            return rpcResponse
        } catch let error as DecodingError {
            RequestHandler.handleDecodingError(error: error)
            throw error
        }
    }
}
