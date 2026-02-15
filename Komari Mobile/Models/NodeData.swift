//
//  NodeData.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import Foundation

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
