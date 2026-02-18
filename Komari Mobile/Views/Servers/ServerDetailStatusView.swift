//
//  ServerDetailStatusView.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import SwiftUI

struct ServerDetailStatusView: View {
    var node: NodeData
    var status: NodeLiveStatus?

    private var cpuUsage: Double { status?.cpuUsage ?? 0 }
    private var gpuUsage: Double { status?.gpuUsage ?? 0 }

    private var memoryPercent: Double {
        guard let s = status, s.memoryTotal > 0 else { return 0 }
        return Double(s.memoryUsed) / Double(s.memoryTotal) * 100
    }

    private var swapPercent: Double {
        guard let s = status, s.swapTotal > 0 else { return 0 }
        return Double(s.swapUsed) / Double(s.swapTotal) * 100
    }

    private var diskPercent: Double {
        guard let s = status, s.diskTotal > 0 else { return 0 }
        return Double(s.diskUsed) / Double(s.diskTotal) * 100
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                systemInfoSection
                processorSection
                resourcesSection
                networkSection
                addressSection
            }
            .padding()
        }
    }

    // MARK: - Card Container

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        )
    }

    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
        .font(.subheadline)
    }

    // MARK: - System Info

    private var systemInfoSection: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("System", systemImage: "desktopcomputer")

                // OS row with logo
                HStack(spacing: 10) {
                    GetOSLogo.logo(for: node.os)
                        .scaleEffect(0.6)
                        .frame(width: 28, height: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(GetOSLogo.name(for: node.os))
                            .font(.headline)
                        Text("\(node.arch) · \(node.kernelVersion)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Divider()

                if !node.virtualization.isEmpty {
                    infoRow("Virtualization", value: node.virtualization)
                }

                if let status {
                    infoRow("Uptime", value: formatTimeInterval(seconds: status.uptime))

                    if status.temperature > 0 {
                        HStack {
                            Text("Temperature")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(String(format: "%.1f°C", status.temperature))
                                .foregroundStyle(temperatureColor(status.temperature))
                        }
                        .font(.subheadline)
                    }

                    infoRow("Load Average", value: String(format: "%.2f  %.2f  %.2f", status.load1, status.load5, status.load15))
                    infoRow("Processes", value: "\(status.processCount)")
                }
            }
            .padding(14)
        }
    }

    // MARK: - CPU & GPU

    private var processorSection: some View {
        HStack(spacing: 12) {
            // CPU
            card {
                VStack(alignment: .leading, spacing: 10) {
                    sectionHeader("CPU", systemImage: "cpu")
                    Spacer()
                    HStack(spacing: 8) {
                        GetCPULogo.logo(for: node.cpuName)
                            .frame(width: 28, height: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(node.cpuName.isEmpty ? "Unknown" : node.cpuName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .lineLimit(2)
                            Text("\(node.cpuCores) Cores")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    UsageBar(label: "Usage", value: cpuUsage)
                }
                .padding(14)
                .frame(minHeight: 150)
            }

            // GPU
            card {
                VStack(alignment: .leading, spacing: 10) {
                    sectionHeader("GPU", systemImage: "cpu")
                    Spacer()
                    HStack(spacing: 8) {
                        GetGPULogo.logo(for: node.gpuName)
                            .frame(width: 28, height: 28)
                        Text(node.gpuName.isEmpty ? "N/A" : node.gpuName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(2)
                    }
                    Spacer()
                    UsageBar(label: "Usage", value: gpuUsage)
                }
                .padding(14)
                .frame(minHeight: 150)
            }
        }
    }

    // MARK: - Resources (Memory, Swap, Disk)

    private var resourcesSection: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("Resources", systemImage: "gauge.with.dots.needle.33percent")

                // Memory
                UsageBar(label: "Memory", value: memoryPercent)
                HStack {
                    Text("\(formatBytes(status?.memoryUsed ?? 0)) / \(formatBytes(status?.memoryTotal ?? node.memoryTotal))")
                    Spacer()
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, -6)

                // Swap
                if node.swapTotal > 0 || (status?.swapTotal ?? 0) > 0 {
                    UsageBar(label: "Swap", value: swapPercent)
                    HStack {
                        Text("\(formatBytes(status?.swapUsed ?? 0)) / \(formatBytes(status?.swapTotal ?? node.swapTotal))")
                        Spacer()
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, -6)
                }

                // Disk
                UsageBar(label: "Disk", value: diskPercent)
                HStack {
                    Text("\(formatBytes(status?.diskUsed ?? 0)) / \(formatBytes(status?.diskTotal ?? node.diskTotal))")
                    Spacer()
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, -6)
            }
            .padding(14)
        }
    }

    // MARK: - Network

    private var networkSection: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("Network", systemImage: "network")

                infoRow("Upload Speed", value: "\(formatBytes(status?.networkOutSpeed ?? 0))/s")
                infoRow("Download Speed", value: "\(formatBytes(status?.networkInSpeed ?? 0))/s")

                Divider()

                infoRow("Total Upload", value: formatBytes(status?.networkOutTotal ?? 0))
                infoRow("Total Download", value: formatBytes(status?.networkInTotal ?? 0))

                Divider()

                infoRow("TCP Connections", value: "\(status?.connectionCount ?? 0)")
                infoRow("UDP Connections", value: "\(status?.connectionCountUDP ?? 0)")
            }
            .padding(14)
        }
    }

    // MARK: - IP Address

    private var addressSection: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    sectionHeader("IP Address", systemImage: "globe")
                    Spacer()
                    CountryFlag(countryFlag: node.region)
                }

                if let ipv4 = node.ipv4, !ipv4.isEmpty {
                    HStack(spacing: 8) {
                        Text("IPv4")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(.blue))
                        Text(ipv4)
                            .font(.subheadline.monospaced())
                            .lineLimit(1)
                            .textSelection(.enabled)
                    }
                }

                if let ipv6 = node.ipv6, !ipv6.isEmpty {
                    HStack(spacing: 8) {
                        Text("IPv6")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(.purple))
                        Text(ipv6)
                            .font(.caption.monospaced())
                            .lineLimit(2)
                            .textSelection(.enabled)
                    }
                }
            }
            .padding(14)
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

    // MARK: - Helpers

    private func temperatureColor(_ temp: Double) -> Color {
        if temp >= 80 { return .red }
        if temp >= 60 { return .orange }
        return .green
    }
}
