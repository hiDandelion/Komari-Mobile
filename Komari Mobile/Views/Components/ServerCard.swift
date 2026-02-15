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

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack {
                    ServerTitle(node: node, isOnline: isOnline)
                        .font(.callout)

                    Spacer()

                    if let status, isOnline {
                        HStack {
                            Image(systemName: "power")
                            Text("\(formatTimeInterval(seconds: status.uptime))")
                        }
                        .font(.caption)
                    }
                }
                Spacer()
            }
            .padding(.top, 5)
            .padding(.horizontal, 10)

            VStack {
                HStack(spacing: 0) {
                    gaugeView

                    infoView
                        .font(.caption2)
                        .frame(width: 100)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 5)
            .padding(.horizontal, 10)
        }
        .frame(maxWidth: .infinity, minHeight: 160)
    }

    private var gaugeView: some View {
        HStack {
            let cpuUsage = (status?.cpuUsage ?? 0) / 100
            let memoryUsage = {
                guard let status, status.memoryTotal > 0 else { return 0.0 }
                return Double(status.memoryUsed) / Double(status.memoryTotal)
            }()
            let diskUsage = {
                guard let status, status.diskTotal > 0 else { return 0.0 }
                return Double(status.diskUsed) / Double(status.diskTotal)
            }()

            VStack {
                Gauge(value: cpuUsage) {

                } currentValueLabel: {
                    VStack {
                        Text("CPU")
                        Text("\(cpuUsage * 100, specifier: "%.0f")%")
                    }
                }
                Text("\(node.cpuCores) Core")
                    .font(.caption2)
                    .frame(minWidth: 60)
                    .lineLimit(1)
            }

            VStack {
                Gauge(value: memoryUsage) {

                } currentValueLabel: {
                    VStack {
                        Text("MEM")
                        Text("\(memoryUsage * 100, specifier: "%.0f")%")
                    }
                }
                Text("\(formatBytes(node.memoryTotal, decimals: 0))")
                    .font(.caption2)
                    .frame(minWidth: 60)
                    .lineLimit(1)
            }

            VStack {
                Gauge(value: diskUsage) {

                } currentValueLabel: {
                    VStack {
                        Text("DISK")
                        Text("\(diskUsage * 100, specifier: "%.0f")%")
                    }
                }
                Text("\(formatBytes(node.diskTotal, decimals: 0))")
                    .font(.caption2)
                    .frame(minWidth: 60)
                    .lineLimit(1)
            }
        }
        .gaugeStyle(.accessoryCircularCapacity)
    }

    private var infoView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "circle.dotted.circle")
                    .frame(width: 10)
                VStack(alignment: .leading) {
                    Text("↑ \(formatBytes(status?.networkOutTotal ?? 0, decimals: 1))")
                    Text("↓ \(formatBytes(status?.networkInTotal ?? 0, decimals: 1))")
                }
            }
            .frame(alignment: .leading)

            HStack {
                Image(systemName: "network")
                    .frame(width: 10)
                VStack(alignment: .leading) {
                    Text("↑ \(formatBytes(status?.networkOutSpeed ?? 0, decimals: 1))/s")
                    Text("↓ \(formatBytes(status?.networkInSpeed ?? 0, decimals: 1))/s")
                }
            }
            .frame(alignment: .leading)
        }
        .lineLimit(1)
        .frame(minWidth: 100)
    }
}
