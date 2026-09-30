//
//  ChartRange.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 7/2/26.
//

import Foundation

/// A selectable time range for history charts. Presets are gated by the
/// dashboard's record preserve times from /api/public, with a dynamic
/// maximum range appended when the server preserves a non-preset amount.
struct ChartRange: Hashable, Identifiable {
    /// Hours of history; 0 means real-time (live)
    let hours: Int
    let label: String

    var id: Int { hours }
    var isLive: Bool { hours == 0 }

    static let live = ChartRange(hours: 0, label: String(localized: "Live"))

    static func rangeLabel(hours: Int) -> String {
        hours >= 24 && hours % 24 == 0 ? "\(hours / 24)d" : "\(hours)h"
    }

    var chartPeriod: ChartPeriod {
        switch hours {
        case 0: .live
        case ...4: .fourHours
        case ...24: .oneDay
        case ...168: .sevenDays
        default: .thirtyDays
        }
    }

    private static func ranges(presets: [Int], maxHours: Int) -> [ChartRange] {
        var ranges = presets
            .filter { $0 <= maxHours }
            .map { ChartRange(hours: $0, label: rangeLabel(hours: $0)) }
        if maxHours > 0, !presets.contains(maxHours), maxHours > (ranges.last?.hours ?? 0) {
            ranges.append(ChartRange(hours: maxHours, label: rangeLabel(hours: maxHours)))
        }
        return ranges
    }

    /// Ranges for the load charts: live plus presets up to record_preserve_time
    static func loadRanges(publicInfo: PublicInfo?) -> [ChartRange] {
        var result: [ChartRange] = [.live]
        // Komari ≥ 1.5 reports record_enabled = false as soon as any single metric has zero
        // retention, so only treat history as disabled when nothing is preserved at all.
        if publicInfo?.recordEnabled == false, (publicInfo?.recordPreserveTime ?? 0) <= 0 {
            return result
        }
        let maxHours = publicInfo?.recordPreserveTime ?? 720
        result.append(contentsOf: ranges(presets: [4, 24, 168, 720], maxHours: maxHours))
        return result
    }

    /// Ranges for the ping charts: presets up to ping_record_preserve_time
    static func pingRanges(publicInfo: PublicInfo?) -> [ChartRange] {
        let maxHours = publicInfo?.pingRecordPreserveTime ?? 24
        let result = ranges(presets: [1, 6, 12, 24], maxHours: maxHours)
        return result.isEmpty ? [ChartRange(hours: 1, label: rangeLabel(hours: 1))] : result
    }
}
