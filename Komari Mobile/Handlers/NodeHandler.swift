//
//  NodeHandler.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import Foundation

class NodeHandler {
    /// Fetch all nodes basic info via RPC2 common:getNodes
    static func getNodes() async throws -> [String: NodeData] {
        let result: [String: NodeData] = try await RPC2Handler.call(method: "common:getNodes")
        return result
    }

    /// Fetch latest live status for all nodes via RPC2 common:getNodesLatestStatus
    static func getNodesLatestStatus() async throws -> [String: NodeLiveStatus] {
        let result: [String: NodeLiveStatus] = try await RPC2Handler.call(method: "common:getNodesLatestStatus")
        return result
    }
}
