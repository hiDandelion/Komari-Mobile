//
//  RecentRecordResponse.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 7/2/26.
//

import Foundation

/// A single point returned by `GET /api/recent/{uuid}`.
/// Unlike `NodeRecord`, this endpoint returns nested objects.
struct RecentRecord: Codable {
    struct CPUInfo: Codable {
        let usage: Double?
    }

    struct UsedInfo: Codable {
        let used: Int64?
    }

    struct LoadInfo: Codable {
        let load1: Double?
        let load5: Double?
        let load15: Double?
    }

    struct NetworkInfo: Codable {
        let up: Int64?
        let down: Int64?
        let totalUp: Int64?
        let totalDown: Int64?
    }

    struct ConnectionsInfo: Codable {
        let tcp: Int?
        let udp: Int?
    }

    struct GPUInfo: Codable {
        let count: Int?
        let averageUsage: Double?

        enum CodingKeys: String, CodingKey {
            case count
            case averageUsage = "average_usage"
        }
    }

    let cpu: CPUInfo?
    let ram: UsedInfo?
    let swap: UsedInfo?
    let load: LoadInfo?
    let disk: UsedInfo?
    let network: NetworkInfo?
    let connections: ConnectionsInfo?
    let gpu: GPUInfo?
    let uptime: Int64?
    let process: Int?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case cpu, ram, swap, load, disk, network, connections, gpu, uptime, process
        case updatedAt = "updated_at"
    }
}

extension NodeRecord {
    /// Convert a nested `/api/recent` point into the flat record format used by the charts.
    /// Static totals come from `node` because the recent endpoint only reports used values.
    init(recent: RecentRecord, node: NodeData) {
        self.init(
            client: node.uuid,
            time: recent.updatedAt,
            cpuUsage: recent.cpu?.usage,
            gpuUsage: recent.gpu?.averageUsage,
            memoryUsed: recent.ram?.used,
            memoryTotal: node.memoryTotal,
            swapUsed: recent.swap?.used,
            swapTotal: node.swapTotal,
            load: recent.load?.load1,
            temperature: nil,
            diskUsed: recent.disk?.used,
            diskTotal: node.diskTotal,
            networkIn: recent.network?.down,
            networkOut: recent.network?.up,
            networkTotalUp: recent.network?.totalUp,
            networkTotalDown: recent.network?.totalDown,
            processCount: recent.process,
            connectionCount: recent.connections?.tcp,
            connectionCountUDP: recent.connections?.udp
        )
    }

    /// Convert a live status snapshot into the flat record format used by the charts.
    init(liveStatus: NodeLiveStatus) {
        self.init(
            client: liveStatus.client,
            time: liveStatus.time,
            cpuUsage: liveStatus.cpuUsage,
            gpuUsage: liveStatus.gpuUsage,
            memoryUsed: liveStatus.memoryUsed,
            memoryTotal: liveStatus.memoryTotal,
            swapUsed: liveStatus.swapUsed,
            swapTotal: liveStatus.swapTotal,
            load: liveStatus.load1,
            temperature: liveStatus.temperature,
            diskUsed: liveStatus.diskUsed,
            diskTotal: liveStatus.diskTotal,
            networkIn: liveStatus.networkInSpeed,
            networkOut: liveStatus.networkOutSpeed,
            networkTotalUp: liveStatus.networkOutTotal,
            networkTotalDown: liveStatus.networkInTotal,
            processCount: liveStatus.processCount,
            connectionCount: liveStatus.connectionCount,
            connectionCountUDP: liveStatus.connectionCountUDP
        )
    }
}
