//
//  ServerDetailMonitorView.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import SwiftUI
import Charts

struct ServerDetailMonitorView: View {
    @Environment(KMState.self) var state
    var node: NodeData
    @State private var selectedRange: ChartRange = ChartRange(hours: 24, label: ChartRange.rangeLabel(hours: 24))
    @State private var records: [NodeRecord] = []
    @State private var liveRecords: [NodeRecord] = []
    @State private var loadingState: LoadingState = .idle

    /// Maximum number of points kept in the live buffer (matches komari-web)
    private static let liveBufferSize = 150

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

    static func parseDate(_ string: String) -> Date? {
        if let date = rfc3339Formatter.date(from: string) {
            return date
        }
        return rfc3339FractionalFormatter.date(from: string)
    }

    private var availableRanges: [ChartRange] {
        ChartRange.loadRanges(publicInfo: state.publicInfo)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                periodPicker
                metricsSection
            }
            .padding()
        }
        .onAppear {
            let ranges = availableRanges
            if !ranges.contains(selectedRange) {
                selectedRange = ranges.first(where: { $0.hours == 24 }) ?? ranges.last ?? .live
            }
            fetchRecords()
        }
        .onChange(of: selectedRange) {
            records = []
            liveRecords = []
            loadingState = .idle
            fetchRecords()
        }
        .onChange(of: availableRanges) {
            // Public info can arrive after the view appears; keep the selection valid
            if !availableRanges.contains(selectedRange) {
                selectedRange = availableRanges.first(where: { $0.hours == 24 }) ?? availableRanges.last ?? .live
            }
        }
        .onChange(of: state.liveStatus[node.uuid]?.time) {
            appendLivePoint()
        }
    }

    private var periodPicker: some View {
        Picker("Period", selection: $selectedRange) {
            ForEach(availableRanges) { range in
                Text(range.label)
                    .tag(range)
            }
        }
        .pickerStyle(.segmented)
    }

    /// Records feeding the charts: the rolling live buffer in real-time mode, otherwise history
    private var displayRecords: [NodeRecord] {
        selectedRange.isLive ? liveRecords : records
    }

    @ViewBuilder
    private var metricsSection: some View {
        Group {
            switch loadingState {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .transition(.blurReplace)
            case .loaded:
                if displayRecords.isEmpty {
                    Text("No Data")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 100)
                        .transition(.blurReplace)
                } else {
                    VStack(spacing: 10) {
                        cpuChart
                        memoryChart
                        diskChart
                        networkSpeedChart
                        connectionsChart
                        processChart
                        gpuChart
                    }
                    .transition(.blurReplace)
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
                .transition(.blurReplace)
            }
        }
        .animation(.smooth(duration: 0.3), value: loadingState)
    }

    @ViewBuilder
    private func chartCard<Content: View>(@ViewBuilder _ content: @escaping () -> Content) -> some View {
        VStack(spacing: 10) {
            content()
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.08), radius: 5, x: 5, y: 5)
                .shadow(color: .black.opacity(0.06), radius: 5, x: -5, y: -5)
        )
    }

    private var currentChartPeriod: ChartPeriod { selectedRange.chartPeriod }

    private var cpuChart: some View {
        let points = displayRecords.compactMap { record -> MetricsDataPoint? in
            guard let cpu = record.cpuUsage,
                  let timeStr = record.time,
                  let date = Self.parseDate(timeStr) else { return nil }
            return MetricsDataPoint(date: date, value: Double(cpu))
        }
        return chartCard {
            MetricsChart(title: "CPU", dataPoints: points, unit: "%", color: .blue, period: currentChartPeriod)
        }
    }

    private var memoryChart: some View {
        let points = displayRecords.compactMap { record -> MetricsDataPoint? in
            guard let used = record.memoryUsed, let total = record.memoryTotal, total > 0,
                  let timeStr = record.time,
                  let date = Self.parseDate(timeStr) else { return nil }
            return MetricsDataPoint(date: date, value: Double(used) / Double(total) * 100)
        }
        return chartCard {
            MetricsChart(title: "Memory", dataPoints: points, unit: "%", color: .green, period: currentChartPeriod)
        }
    }

    private var diskChart: some View {
        let points = displayRecords.compactMap { record -> MetricsDataPoint? in
            guard let used = record.diskUsed, let total = record.diskTotal, total > 0,
                  let timeStr = record.time,
                  let date = Self.parseDate(timeStr) else { return nil }
            return MetricsDataPoint(date: date, value: Double(used) / Double(total) * 100)
        }
        return chartCard {
            MetricsChart(title: "Disk", dataPoints: points, unit: "%", color: .orange, period: currentChartPeriod)
        }
    }

    private var networkSpeedChart: some View {
        let inPoints = displayRecords.compactMap { record -> MetricsDataPoint? in
            guard let netIn = record.networkIn,
                  let timeStr = record.time,
                  let date = Self.parseDate(timeStr) else { return nil }
            return MetricsDataPoint(date: date, value: Double(netIn) / 1024)
        }
        let outPoints = displayRecords.compactMap { record -> MetricsDataPoint? in
            guard let netOut = record.networkOut,
                  let timeStr = record.time,
                  let date = Self.parseDate(timeStr) else { return nil }
            return MetricsDataPoint(date: date, value: Double(netOut) / 1024)
        }
        return chartCard {
            MetricsMultiSeriesChart(
                title: "Network Speed",
                series: [
                    MetricsSeriesData(name: "In", dataPoints: inPoints, color: .purple),
                    MetricsSeriesData(name: "Out", dataPoints: outPoints, color: .red)
                ],
                unit: "KB/s",
                period: currentChartPeriod
            )
        }
    }

    private var connectionsChart: some View {
        let tcpPoints = displayRecords.compactMap { record -> MetricsDataPoint? in
            guard let tcp = record.connectionCount,
                  let timeStr = record.time,
                  let date = Self.parseDate(timeStr) else { return nil }
            return MetricsDataPoint(date: date, value: Double(tcp))
        }
        let udpPoints = displayRecords.compactMap { record -> MetricsDataPoint? in
            guard let udp = record.connectionCountUDP,
                  let timeStr = record.time,
                  let date = Self.parseDate(timeStr) else { return nil }
            return MetricsDataPoint(date: date, value: Double(udp))
        }
        return chartCard {
            MetricsMultiSeriesChart(
                title: "Connections",
                series: [
                    MetricsSeriesData(name: "TCP", dataPoints: tcpPoints, color: .blue),
                    MetricsSeriesData(name: "UDP", dataPoints: udpPoints, color: .teal)
                ],
                unit: "",
                period: currentChartPeriod
            )
        }
    }

    private var processChart: some View {
        let points = displayRecords.compactMap { record -> MetricsDataPoint? in
            guard let process = record.processCount,
                  let timeStr = record.time,
                  let date = Self.parseDate(timeStr) else { return nil }
            return MetricsDataPoint(date: date, value: Double(process))
        }
        return chartCard {
            MetricsChart(title: "Process", dataPoints: points, unit: "", color: .pink, period: currentChartPeriod)
        }
    }

    @ViewBuilder
    private var gpuChart: some View {
        // History always carries a `gpu` value (0 without a GPU)
        let hasGPU = !node.gpuName.isEmpty || displayRecords.contains { ($0.gpuUsage ?? 0) > 0 }
        if hasGPU {
            let points = displayRecords.compactMap { record -> MetricsDataPoint? in
                guard let gpu = record.gpuUsage,
                      let timeStr = record.time,
                      let date = Self.parseDate(timeStr) else { return nil }
                return MetricsDataPoint(date: date, value: Double(gpu))
            }
            chartCard {
                MetricsChart(title: "GPU", dataPoints: points, unit: "%", color: .indigo, period: currentChartPeriod)
            }
        }
    }

    private func fetchRecords() {
        loadingState = .loading
        if selectedRange.isLive {
            fetchRecentRecords()
            return
        }
        Task {
            do {
                let result = try await RecordHandler.getRecords(uuid: node.uuid, hours: selectedRange.hours)
                // Sort records by time ascending (matching komari-web behavior); parse each date once
                let sorted = result
                    .map { record in (record.fillingTotals(from: node), record.time.flatMap(Self.parseDate) ?? .distantPast) }
                    .sorted { $0.1 < $1.1 }
                    .map(\.0)
                withAnimation {
                    records = sorted
                    loadingState = .loaded
                }
            } catch {
                withAnimation {
                    loadingState = .error(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Live Mode

    private func fetchRecentRecords() {
        Task {
            do {
                let recent = try await PublicHandler.getRecentRecords(uuid: node.uuid)
                let seeded = recent.suffix(Self.liveBufferSize).map { NodeRecord(recent: $0, node: node) }
                withAnimation {
                    liveRecords = seeded
                    loadingState = .loaded
                }
            } catch {
                withAnimation {
                    loadingState = .error(error.localizedDescription)
                }
            }
        }
    }

    private func appendLivePoint() {
        guard selectedRange.isLive, case .loaded = loadingState,
              let status = state.liveStatus[node.uuid] else { return }
        // Skip duplicates (the auto-refresh may deliver the same sample twice)
        guard liveRecords.last?.time != status.time else { return }
        liveRecords.append(NodeRecord(liveStatus: status))
        if liveRecords.count > Self.liveBufferSize {
            liveRecords.removeFirst(liveRecords.count - Self.liveBufferSize)
        }
    }
}
