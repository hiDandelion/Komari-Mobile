//
//  NodeLiveStatus.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import Foundation

struct NodeLiveStatus: Codable {
    let client: String
    let time: String
    let cpuUsage: Double
    let gpuUsage: Double
    let memoryUsed: Int64
    let memoryTotal: Int64
    let swapUsed: Int64
    let swapTotal: Int64
    let load1: Double
    let load5: Double
    let load15: Double
    let temperature: Double
    let diskUsed: Int64
    let diskTotal: Int64
    let networkInSpeed: Int64
    let networkOutSpeed: Int64
    let networkOutTotal: Int64
    let networkInTotal: Int64
    let processCount: Int
    let connectionCount: Int
    let connectionCountUDP: Int
    let online: Bool
    let uptime: Int64
    /// Per-device GPU data (Komari ≥ 1.5)
    let gpuCount: Int?
    let gpuDetailedInfo: [GPUDeviceStatus]?

    /// `connections` is the TCP + UDP total
    var tcpConnectionCount: Int {
        max(0, connectionCount - connectionCountUDP)
    }

    /// Older dashboards always report 0 for `gpu` and no device count.
    var hasGPU: Bool {
        (gpuCount ?? 0) > 0 || gpuUsage > 0
    }

    enum CodingKeys: String, CodingKey {
        case client, time, online, uptime, load5, load15
        case gpuCount = "gpu_count"
        case gpuDetailedInfo = "gpu_detailed_info"
        case cpuUsage = "cpu"
        case gpuUsage = "gpu"
        case memoryUsed = "ram"
        case memoryTotal = "ram_total"
        case swapUsed = "swap"
        case swapTotal = "swap_total"
        case load1 = "load"
        case temperature = "temp"
        case diskUsed = "disk"
        case diskTotal = "disk_total"
        case networkInSpeed = "net_in"
        case networkOutSpeed = "net_out"
        case networkOutTotal = "net_total_up"
        case networkInTotal = "net_total_down"
        case processCount = "process"
        case connectionCount = "connections"
        case connectionCountUDP = "connections_udp"
    }
}

struct GPUDeviceStatus: Codable, Hashable {
    let name: String?
    let memoryTotal: Int64?
    let memoryUsed: Int64?
    /// Percent (0–100)
    let utilization: Double?
    /// °C
    let temperature: Int?

    enum CodingKeys: String, CodingKey {
        case name, utilization, temperature
        case memoryTotal = "memory_total"
        case memoryUsed = "memory_used"
    }
}
