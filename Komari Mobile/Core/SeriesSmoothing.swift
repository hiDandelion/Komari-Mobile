//
//  SeriesSmoothing.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 7/2/26.
//
//  Swift ports of komari-web's chart smoothing helpers (src/utils/RecordHelper.tsx).
//

import Foundation

/// Linearly interpolate `nil` gaps between valid points.
/// Gaps wider than `median gap × maxGapMultiplier` (clamped to [minCap, maxCap]) are kept as holes.
func interpolateNilsLinear(
    times: [Date],
    values: [Double?],
    maxGapMultiplier: Double = 6,
    minCapSeconds: TimeInterval = 2 * 60,
    maxCapSeconds: TimeInterval = 30 * 60
) -> [Double?] {
    guard times.count == values.count else { return values }

    var out = values
    let validIndices = values.indices.filter { values[$0] != nil }
    guard validIndices.count >= 2 else { return values }

    var gaps: [TimeInterval] = []
    for s in 0..<(validIndices.count - 1) {
        let dt = times[validIndices[s + 1]].timeIntervalSince(times[validIndices[s]])
        if dt > 0 { gaps.append(dt) }
    }
    guard !gaps.isEmpty else { return values }

    let median = gaps.sorted()[gaps.count / 2]
    let maxGap = min(max(median * maxGapMultiplier, minCapSeconds), maxCapSeconds)

    for s in 0..<(validIndices.count - 1) {
        let i0 = validIndices[s]
        let i1 = validIndices[s + 1]
        guard i1 > i0 + 1,
              let v0 = values[i0],
              let v1 = values[i1] else { continue }

        let t0 = times[i0]
        let dt = times[i1].timeIntervalSince(t0)
        guard dt > 0, dt <= maxGap else { continue }

        for j in (i0 + 1)..<i1 {
            let ratio = times[j].timeIntervalSince(t0) / dt
            out[j] = v0 + (v1 - v0) * ratio
        }
    }
    return out
}

/// Remove spikes relative to a sliding window, then smooth with an exponentially
/// weighted moving average. `nil` values are filled with the running EWMA.
func cutPeakSeries(
    _ values: [Double?],
    alpha: Double = 0.3,
    windowSize: Int = 15,
    spikeThreshold: Double = 0.3
) -> [Double?] {
    guard !values.isEmpty else { return values }

    var result = values
    let halfWindow = windowSize / 2

    // Pass 1: null out values deviating too far from their neighborhood mean
    for i in result.indices {
        guard let current = result[i] else { continue }

        var neighbors: [Double] = []
        for j in max(0, i - halfWindow)...min(result.count - 1, i + halfWindow) where j != i {
            if let v = result[j] { neighbors.append(v) }
        }
        guard neighbors.count >= 2 else { continue }

        let mean = neighbors.reduce(0, +) / Double(neighbors.count)
        if mean > 0 {
            if abs(current - mean) / mean > spikeThreshold {
                result[i] = nil
            }
        } else if abs(current) > 10 {
            result[i] = nil
        }
    }

    // Pass 2: EWMA smoothing, filling gaps with the running average
    var ewma: Double?
    for i in result.indices {
        if let current = result[i] {
            if let previous = ewma {
                ewma = alpha * current + (1 - alpha) * previous
            } else {
                ewma = current
            }
            result[i] = ewma
        } else if let previous = ewma {
            result[i] = previous
        }
    }
    return result
}
