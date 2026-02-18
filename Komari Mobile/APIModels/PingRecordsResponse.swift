//
//  PingRecordsResponse.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/18/26.
//

import Foundation

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
