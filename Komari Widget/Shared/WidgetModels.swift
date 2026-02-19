//
//  WidgetModels.swift
//  Komari Widget
//
//  Created by Junhui Lou on 2/19/26.
//

import Foundation

// MARK: - Node Data

struct NodeData: Codable, Identifiable, Hashable {
    let uuid: String
    let name: String
    let cpuName: String
    let virtualization: String
    let arch: String
    let cpuCores: Int
    let os: String
    let kernelVersion: String
    let gpuName: String
    let region: String
    let publicRemark: String?
    let memoryTotal: Int64
    let swapTotal: Int64
    let diskTotal: Int64
    let version: String?
    let weight: Int
    let price: Double?
    let billingCycle: Int?
    let currency: String?
    let group: String?
    let tags: String?
    let hidden: Bool?
    let trafficLimit: Int64?
    let trafficLimitType: String?
    let ipv4: String?
    let ipv6: String?
    let createdAt: String?
    let updatedAt: String?

    var id: String { uuid }

    enum CodingKeys: String, CodingKey {
        case uuid, name, virtualization, arch, os, region, version, weight
        case price, currency, group, tags, hidden, ipv4, ipv6
        case cpuName = "cpu_name"
        case cpuCores = "cpu_cores"
        case kernelVersion = "kernel_version"
        case gpuName = "gpu_name"
        case publicRemark = "public_remark"
        case memoryTotal = "mem_total"
        case swapTotal = "swap_total"
        case diskTotal = "disk_total"
        case billingCycle = "billing_cycle"
        case trafficLimit = "traffic_limit"
        case trafficLimitType = "traffic_limit_type"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Node Live Status

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

    enum CodingKeys: String, CodingKey {
        case client, time, online, uptime, load5, load15
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

// MARK: - Node Record

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

// MARK: - RPC2 Models

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

// MARK: - Komari Base Response

struct KomariBaseResponse<T: Codable>: Codable {
    let status: String
    let message: String?
    let data: T?

    var isSuccess: Bool {
        status == "success"
    }
}

// MARK: - Login / Me Responses

struct LoginResponseData: Codable {}

struct MeResponseData: Codable {
    let username: String?
    let loggedIn: Bool?
    let uuid: String?
    let ssoType: String?
    let ssoId: String?
    let tfaEnabled: Bool?

    enum CodingKeys: String, CodingKey {
        case username, uuid
        case loggedIn = "logged_in"
        case ssoType = "sso_type"
        case ssoId = "sso_id"
        case tfaEnabled = "2fa_enabled"
    }
}

// MARK: - Load Records Response

struct LoadRecordsData: Codable {
    let records: [NodeRecord]?
    let count: Int?
}

// MARK: - Ping Records Response

struct PingRecord: Codable {
    let client: String?
    let taskId: Int?
    let time: String?
    let value: Double?

    enum CodingKeys: String, CodingKey {
        case client, time, value
        case taskId = "task_id"
    }
}

struct PingTaskInfo: Codable {
    let id: Int
    let name: String
    let interval: Int?
    let loss: Double?
    let p99: Double?
    let p50: Double?
    let min: Double?
    let max: Double?
    let avg: Double?
    let latest: Double?
    let total: Int?
    let type: String?
}

struct PingRecordsData: Codable {
    let count: Int?
    let records: [PingRecord]?
    let tasks: [PingTaskInfo]?
}
