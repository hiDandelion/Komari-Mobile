//
//  ServerDetailStatusView.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import SwiftUI

struct ServerDetailStatusView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(KMTheme.self) var theme
    var node: NodeData
    var status: NodeLiveStatus?

    private let columns: [GridItem] = [.init(.flexible()), .init(.flexible())]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                osCard
                cpuCard
                memoryCard
                diskCard
                networkCard
                networkDataCard
                networkAddressCard
            }
            .padding()
        }
    }

    @ViewBuilder
    private func cardView<Content: View>(@ViewBuilder _ content: @escaping () -> Content) -> some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.themeSecondaryColor(scheme: scheme))
                    .shadow(color: .black.opacity(0.08), radius: 5, x: 5, y: 5)
                    .shadow(color: .black.opacity(0.06), radius: 5, x: -5, y: -5)
            )
            .frame(maxWidth: .infinity)
            .frame(height: 180)
    }

    private var osCard: some View {
        cardView {
            VStack {
                HStack {
                    Label("OS", systemImage: "opticaldisc")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 5)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Spacer()
                }

                Spacer()

                VStack {
                    GetOSLogo.logo(for: node.os)
                    Text(node.os.isEmpty ? String(localized: "Unknown") : node.os.capitalizeFirstLetter())
                        .font(.caption)
                        .lineLimit(2)
                }

                Spacer()

                HStack {
                    VStack(alignment: .leading) {
                        Text("Load \(status?.load1 ?? 0, specifier: "%.2f") \(status?.load5 ?? 0, specifier: "%.2f") \(status?.load15 ?? 0, specifier: "%.2f")")
                        Text("Processes \(status?.processCount ?? 0)")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            .padding(10)
        }
    }

    private var cpuCard: some View {
        cardView {
            VStack {
                HStack {
                    Label("CPU", systemImage: "cpu")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 5)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Spacer()
                }

                Spacer()

                VStack {
                    GetCPULogo.logo(for: node.cpuName)
                    Text(node.cpuName.isEmpty ? "Unknown" : node.cpuName)
                        .font(.caption)
                        .lineLimit(2)
                }

                Spacer()

                HStack {
                    let cpuUsage = (status?.cpuUsage ?? 0) / 100
                    Gauge(value: cpuUsage) {}
                        .gaugeStyle(.accessoryLinearCapacity)
                    Text("\(cpuUsage * 100, specifier: "%.0f")%")
                }
                .font(.caption)
            }
            .padding(10)
        }
    }

    private var memoryCard: some View {
        cardView {
            VStack {
                let memoryUsage: Double = {
                    guard let status, status.memoryTotal > 0 else { return 0 }
                    return Double(status.memoryUsed) / Double(status.memoryTotal)
                }()

                HStack {
                    Label("Memory", systemImage: "memorychip")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 5)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Spacer()
                }

                Spacer()

                HStack {
                    Gauge(value: memoryUsage) {
                        Text("\(memoryUsage * 100, specifier: "%.0f")%")
                    }
                    .gaugeStyle(.accessoryCircularCapacity)
                    .tint(.accentColor)
                }

                Spacer()

                HStack {
                    VStack(alignment: .leading) {
                        Text("Used \(formatBytes(status?.memoryUsed ?? 0))")
                        Text("Total \(formatBytes(status?.memoryTotal ?? node.memoryTotal))")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            .padding(10)
        }
    }

    private var diskCard: some View {
        cardView {
            VStack {
                let diskUsage: Double = {
                    guard let status, status.diskTotal > 0 else { return 0 }
                    return Double(status.diskUsed) / Double(status.diskTotal)
                }()

                HStack {
                    Label("Disk", systemImage: "internaldrive")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 5)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Spacer()
                }

                Spacer()

                HStack {
                    Gauge(value: diskUsage) {
                        Text("\(diskUsage * 100, specifier: "%.0f")%")
                    }
                    .gaugeStyle(.accessoryCircularCapacity)
                    .tint(.accentColor)
                }

                Spacer()

                HStack {
                    VStack(alignment: .leading) {
                        Text("Used \(formatBytes(status?.diskUsed ?? 0))")
                        Text("Total \(formatBytes(status?.diskTotal ?? node.diskTotal))")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            .padding(10)
        }
    }

    private var networkCard: some View {
        cardView {
            VStack {
                HStack {
                    Label("Network Speed", systemImage: "network")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 5)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Spacer()
                }

                Spacer()

                VStack(alignment: .leading) {
                    Text("↑ \(formatBytes(status?.networkOutSpeed ?? 0))/s")
                    Text("↓ \(formatBytes(status?.networkInSpeed ?? 0))/s")
                }

                Spacer()

                HStack {
                    HStack {
                        Text("TCP \(status?.connectionCount ?? 0)")
                        Text("UDP \(status?.connectionCountUDP ?? 0)")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    Spacer()
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(10)
        }
    }

    private var networkDataCard: some View {
        cardView {
            VStack {
                HStack {
                    Label("Network Data", systemImage: "arrow.up.left.arrow.down.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 5)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Spacer()
                }

                Spacer()

                VStack(alignment: .leading) {
                    Text("↑ \(formatBytes(status?.networkOutTotal ?? 0))")
                    Text("↓ \(formatBytes(status?.networkInTotal ?? 0))")
                }

                Spacer()
            }
            .padding(10)
        }
    }

    private var networkAddressCard: some View {
        cardView {
            VStack {
                HStack {
                    Label("IP Address", systemImage: "pin.circle")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 5)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    Spacer()

                    CountryFlag(countryFlag: node.region)
                }

                Spacer()

                VStack(alignment: .leading) {
                    if let ipv4 = node.ipv4, !ipv4.isEmpty {
                        HStack {
                            Image(systemName: "4.circle")
                            Text(ipv4)
                        }
                        .lineLimit(1)
                    }
                    if let ipv6 = node.ipv6, !ipv6.isEmpty {
                        HStack {
                            Image(systemName: "6.circle")
                            Text(ipv6)
                                .font(.caption)
                        }
                        .lineLimit(2)
                    }
                }

                Spacer()
            }
            .padding(10)
        }
        .contextMenu {
            if let ipv4 = node.ipv4, !ipv4.isEmpty {
                Button {
                    UIPasteboard.general.string = ipv4
                } label: {
                    Label("Copy IPv4", systemImage: "4.circle")
                }
            }
            if let ipv6 = node.ipv6, !ipv6.isEmpty {
                Button {
                    UIPasteboard.general.string = ipv6
                } label: {
                    Label("Copy IPv6", systemImage: "6.circle")
                }
            }
        }
    }
}
