//
//  NodeRecord.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import Foundation

struct NodeRecord: Codable {
    let client: String?
    let time: String?
    let cpuUsage: Double?
    let gpuUsage: Double?
    let memoryUsed: Int64?
    let memoryTotal: Int64?
    let swapUsed: Int64?
    let swapTotal: Int64?
    let load: Double?
    let temperature: Double?
    let diskUsed: Int64?
    let diskTotal: Int64?
    let networkIn: Int64?
    let networkOut: Int64?
    let networkTotalUp: Int64?
    let networkTotalDown: Int64?
    let processCount: Int?
    let connectionCount: Int?
    let connectionCountUDP: Int?

    enum CodingKeys: String, CodingKey {
        case client, time, load
        case cpuUsage = "cpu"
        case gpuUsage = "gpu"
        case memoryUsed = "ram"
        case memoryTotal = "ram_total"
        case swapUsed = "swap"
        case swapTotal = "swap_total"
        case temperature = "temp"
        case diskUsed = "disk"
        case diskTotal = "disk_total"
        case networkIn = "net_in"
        case networkOut = "net_out"
        case networkTotalUp = "net_total_up"
        case networkTotalDown = "net_total_down"
        case processCount = "process"
        case connectionCount = "connections"
        case connectionCountUDP = "connections_udp"
    }
}
