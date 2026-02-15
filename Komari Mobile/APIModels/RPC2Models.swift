//
//  RPC2Models.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import Foundation

struct RPC2Request<P: Encodable>: Encodable {
    let jsonrpc: String = "2.0"
    let method: String
    let params: P?
    let id: Int
}

struct RPC2Response<R: Decodable>: Decodable {
    let jsonrpc: String?
    let result: R?
    let error: RPC2Error?
    let id: Int?
}

struct RPC2Error: Decodable, LocalizedError {
    let code: Int?
    let message: String?

    var errorDescription: String? {
        message ?? "Unknown RPC error (code: \(code ?? -1))"
    }
}

struct EmptyParams: Codable {}
