//
//  ServerDetailMonitorView.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import SwiftUI
import Charts

enum MonitorPeriod: String, CaseIterable {
    case oneHour = "1h"
    case fourHours = "4h"
    case oneDay = "24h"
    case sevenDays = "7d"
    case thirtyDays = "30d"

    var localizedTitle: String {
        switch self {
        case .oneHour: "1h"
        case .fourHours: "4h"
        case .oneDay: "24h"
        case .sevenDays: "7d"
        case .thirtyDays: "30d"
        }
    }

    var hours: Int {
        switch self {
        case .oneHour: 1
        case .fourHours: 4
        case .oneDay: 24
        case .sevenDays: 168
        case .thirtyDays: 720
        }
    }
}

struct ServerDetailMonitorView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(KMTheme.self) var theme
    var node: NodeData
    @State private var period: MonitorPeriod = .oneDay
    @State private var records: [NodeRecord] = []
    @State private var loadingState: LoadingState = .idle

    private static let rfc3339Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let rfc3339FractionalFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static func parseDate(_ string: String) -> Date? {
        if let date = rfc3339Formatter.date(from: string) {
            return date
        }
        return rfc3339FractionalFormatter.date(from: string)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                metricsSection
            }
            .padding()
        }
        .toolbar {
            ToolbarItem {
                Menu("Period", systemImage: "calendar") {
                    Picker("Period", selection: $period) {
                        ForEach(MonitorPeriod.allCases, id: \.rawValue) { p in
                            Text(p.localizedTitle)
                                .tag(p)
                        }
                    }
                }
            }
        }
        .onAppear {
            fetchRecords()
        }
        .onChange(of: period) {
            records = []
            loadingState = .idle
            fetchRecords()
        }
    }

    @ViewBuilder
    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Metrics")
                .font(.headline)
                .foregroundStyle(.secondary)

            switch loadingState {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 100)
            case .loaded:
                if records.isEmpty {
                    Text("No Data")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 100)
                } else {
                    VStack(spacing: 10) {
                        cpuChart
                        memoryChart
                        diskChart
                        networkInChart
                        networkOutChart
                    }
                }
            case .error(let message):
                VStack(spacing: 10) {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Retry") {
                        fetchRecords()
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 100)
            }
        }
    }

    @ViewBuilder
    private func chartCard<Content: View>(@ViewBuilder _ content: @escaping () -> Content) -> some View {
        VStack(spacing: 10) {
            content()
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.themeSecondaryColor(scheme: scheme))
                .shadow(color: .black.opacity(0.08), radius: 5, x: 5, y: 5)
                .shadow(color: .black.opacity(0.06), radius: 5, x: -5, y: -5)
        )
    }

    private var cpuChart: some View {
        let points = records.compactMap { record -> MetricsDataPoint? in
            guard let cpu = record.cpuUsage,
                  let timeStr = record.time,
                  let date = Self.parseDate(timeStr) else { return nil }
            return MetricsDataPoint(date: date, value: Double(cpu))
        }
        return chartCard {
            MetricsChart(title: "CPU", dataPoints: points, unit: "%", color: .blue)
        }
    }

    private var memoryChart: some View {
        let points = records.compactMap { record -> MetricsDataPoint? in
            guard let used = record.memoryUsed, let total = record.memoryTotal, total > 0,
                  let timeStr = record.time,
                  let date = Self.parseDate(timeStr) else { return nil }
            return MetricsDataPoint(date: date, value: Double(used) / Double(total) * 100)
        }
        return chartCard {
            MetricsChart(title: "Memory", dataPoints: points, unit: "%", color: .green)
        }
    }

    private var diskChart: some View {
        let points = records.compactMap { record -> MetricsDataPoint? in
            guard let used = record.diskUsed, let total = record.diskTotal, total > 0,
                  let timeStr = record.time,
                  let date = Self.parseDate(timeStr) else { return nil }
            return MetricsDataPoint(date: date, value: Double(used) / Double(total) * 100)
        }
        return chartCard {
            MetricsChart(title: "Disk", dataPoints: points, unit: "%", color: .orange)
        }
    }

    private var networkInChart: some View {
        let points = records.compactMap { record -> MetricsDataPoint? in
            guard let netIn = record.networkIn,
                  let timeStr = record.time,
                  let date = Self.parseDate(timeStr) else { return nil }
            return MetricsDataPoint(date: date, value: Double(netIn) / 1024)
        }
        return chartCard {
            MetricsChart(title: "Network In", dataPoints: points, unit: "KB/s", color: .purple)
        }
    }

    private var networkOutChart: some View {
        let points = records.compactMap { record -> MetricsDataPoint? in
            guard let netOut = record.networkOut,
                  let timeStr = record.time,
                  let date = Self.parseDate(timeStr) else { return nil }
            return MetricsDataPoint(date: date, value: Double(netOut) / 1024)
        }
        return chartCard {
            MetricsChart(title: "Network Out", dataPoints: points, unit: "KB/s", color: .red)
        }
    }

    private func fetchRecords() {
        loadingState = .loading
        Task {
            do {
                let result = try await RecordHandler.getRecords(uuid: node.uuid, hours: period.hours)
                withAnimation {
                    records = result
                    loadingState = .loaded
                }
            } catch {
                withAnimation {
                    loadingState = .error(error.localizedDescription)
                }
            }
        }
    }
}
