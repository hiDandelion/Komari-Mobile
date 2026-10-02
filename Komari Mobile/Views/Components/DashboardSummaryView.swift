//
//  DashboardSummaryView.swift
//  Komari Mobile
//
//  Created by Takuma Kirishima on 7/2/26.
//

import SwiftUI

/// Aggregate stats across online nodes, mirroring komari-web's home summary cards
struct DashboardSummaryView: View {
    let nodes: [NodeData]
    let liveStatus: [String: NodeLiveStatus]
    let onlineUUIDs: Set<String>

    private struct SummaryStats {
        var onlineCount: Int = 0
        var totalCount: Int = 0
        var regionCount: Int = 0
        var totalUp: Int64 = 0
        var totalDown: Int64 = 0
        var speedUp: Int64 = 0
        var speedDown: Int64 = 0
    }

    private var stats: SummaryStats {
        var stats = SummaryStats()
        stats.totalCount = nodes.count
        var regions: Set<String> = []

        for node in nodes where onlineUUIDs.contains(node.uuid) {
            stats.onlineCount += 1
            regions.insert(node.region)
            guard let status = liveStatus[node.uuid] else { continue }
            stats.totalUp += status.networkOutTotal
            stats.totalDown += status.networkInTotal
            stats.speedUp += status.networkOutSpeed
            stats.speedDown += status.networkInSpeed
        }
        stats.regionCount = regions.count
        return stats
    }

    var body: some View {
        let stats = stats
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                statCard(title: "Online", systemImage: "power", color: .green) {
                    Text("\(stats.onlineCount) / \(stats.totalCount)")
                        .contentTransition(.numericText())
                }

                statCard(title: "Regions", systemImage: "globe", color: .blue) {
                    Text("\(stats.regionCount)")
                        .contentTransition(.numericText())
                }

                statCard(title: "Speed", systemImage: "gauge.with.dots.needle.67percent", color: .orange) {
                    upDownValue(up: "\(formatBytes(stats.speedUp))/s", down: "\(formatBytes(stats.speedDown))/s")
                }

                statCard(title: "Traffic", systemImage: "chart.bar.fill", color: .purple) {
                    upDownValue(up: formatBytes(stats.totalUp), down: formatBytes(stats.totalDown))
                }
            }
        }
        .scrollIndicators(.never)
    }

    private func statCard(title: LocalizedStringKey, systemImage: String, color: Color, @ViewBuilder value: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label {
                Text(title)
            } icon: {
                Image(systemName: systemImage)
                    .foregroundStyle(color)
            }
            .font(.caption2.weight(.medium))
            .foregroundStyle(.secondary)

            value()
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(minWidth: 90, minHeight: 62, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }

    private func upDownValue(up: String, down: String) -> some View {
        HStack(spacing: 8) {
            HStack(spacing: 2) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundStyle(.teal)
                Text(up)
            }
            HStack(spacing: 2) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundStyle(.blue)
                Text(down)
            }
        }
        .contentTransition(.numericText())
    }
}
