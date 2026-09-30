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

/// Per-task statistics from `public:getPingMetricStats` (Komari ≥ 1.5). Loss is counted per
/// probe, whereas the stats of `common:getRecords` are computed over downsampled buckets.
struct PingMetricStat: Codable {
    let taskId: String
    let total: Int?
    let loss: Double?
    let min: Double?
    let max: Double?
    let avg: Double?
    let latest: Double?
    let p50: Double?
    let p99: Double?

    enum CodingKeys: String, CodingKey {
        case total, loss, min, max, avg, latest, p50, p99
        case taskId = "task_id"
    }
}

struct PingMetricStatsData: Codable {
    let stats: [PingMetricStat]?
}

extension PingTaskInfo {
    /// Replaces the bucket-based statistics with the per-probe ones where available.
    func merging(_ stat: PingMetricStat) -> PingTaskInfo {
        PingTaskInfo(
            id: id,
            name: name,
            interval: interval,
            loss: stat.loss ?? loss,
            p99: stat.p99 ?? p99,
            p50: stat.p50 ?? p50,
            min: stat.min ?? min,
            max: stat.max ?? max,
            avg: stat.avg ?? avg,
            latest: stat.latest ?? latest,
            total: stat.total ?? total,
            type: type
        )
    }
}
