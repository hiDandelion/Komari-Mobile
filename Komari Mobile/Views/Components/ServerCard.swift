//
//  ServerCard.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import SwiftUI

struct ServerCard: View {
    let node: NodeData
    let status: NodeLiveStatus?
    let isOnline: Bool

    private var cpuUsage: Double {
        status?.cpuUsage ?? 0
    }

    private var memoryUsagePercent: Double {
        guard let status, status.memoryTotal > 0 else { return 0 }
        return Double(status.memoryUsed) / Double(status.memoryTotal) * 100
    }

    private var diskUsagePercent: Double {
        guard let status, status.diskTotal > 0 else { return 0 }
        return Double(status.diskUsed) / Double(status.diskTotal) * 100
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header: Flag + Name | Online/Offline badge
            HStack {
                ServerTitle(node: node, isOnline: isOnline)
                    .font(.callout)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 6)

            Divider()
                .padding(.horizontal, 12)

            // Content
            VStack(spacing: 8) {
                // OS row
                HStack {
                    Text("OS")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    HStack(spacing: 4) {
                        GetOSLogo.logo(for: node.os)
                            .scaleEffect(0.5)
                            .frame(width: 20, height: 20)
                        Text("\(GetOSLogo.name(for: node.os)) / \(node.arch)")
                            .font(.subheadline)
                            .lineLimit(1)
                    }
                }

                // CPU
                UsageBar(label: "CPU", value: cpuUsage)

                // RAM
                UsageBar(label: "RAM", value: memoryUsagePercent)
                if let status {
                    Text("(\(formatBytes(status.memoryUsed)) / \(formatBytes(status.memoryTotal > 0 ? status.memoryTotal : node.memoryTotal)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, -4)
                }

                // Disk
                UsageBar(label: "Disk", value: diskUsagePercent)
                if let status {
                    Text("(\(formatBytes(status.diskUsed)) / \(formatBytes(status.diskTotal > 0 ? status.diskTotal : node.diskTotal)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, -4)
                }

                // Total Traffic
                HStack {
                    Text("Total Traffic")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("↑ \(formatBytes(status?.networkOutTotal ?? 0))  ↓ \(formatBytes(status?.networkInTotal ?? 0))")
                        .font(.subheadline)
                }

                // Network Speed
                HStack {
                    Text("Network Speed")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("↑ \(formatBytes(status?.networkOutSpeed ?? 0))/s  ↓ \(formatBytes(status?.networkInSpeed ?? 0))/s")
                        .font(.subheadline)
                }

                // Uptime
                HStack {
                    Text("Uptime")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if isOnline, let status {
                        Text(formatTimeInterval(seconds: status.uptime))
                            .font(.subheadline)
                    } else {
                        Text("-")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
    }
}
