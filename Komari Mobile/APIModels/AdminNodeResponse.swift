//
//  AdminNodeResponse.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/24/26.
//

import Foundation

struct AdminNodeData: Codable, Identifiable {
    let uuid: String
    let token: String?
    let name: String
    let cpuName: String?
    let virtualization: String?
    let arch: String?
    let cpuCores: Int?
    let os: String?
    let gpuName: String?
    let ipv4: String?
    let ipv6: String?
    let region: String?
    let memoryTotal: Int64?
    let swapTotal: Int64?
    let diskTotal: Int64?
    let version: String?
    let weight: Int?
    let price: Double?
    let remark: String?
    let publicRemark: String?
    let group: String?
    let tags: String?
    let hidden: Bool?
    let trafficLimit: Int64?
    let trafficLimitType: String?
    let currency: String?
    let billingCycle: Int?
    let expiredAt: String?
    let autoRenewal: Bool?
    let createdAt: String?
    let updatedAt: String?

    var id: String { uuid }

    enum CodingKeys: String, CodingKey {
        case uuid, token, name, virtualization, arch, os, region, version, weight
        case price, group, tags, hidden, currency, ipv4, ipv6, remark
        case cpuName = "cpu_name"
        case cpuCores = "cpu_cores"
        case gpuName = "gpu_name"
        case publicRemark = "public_remark"
        case memoryTotal = "mem_total"
        case swapTotal = "swap_total"
        case diskTotal = "disk_total"
        case trafficLimit = "traffic_limit"
        case trafficLimitType = "traffic_limit_type"
        case billingCycle = "billing_cycle"
        case expiredAt = "expired_at"
        case autoRenewal = "auto_renewal"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
