//
//  PingChartView.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/18/26.
//

import SwiftUI
import Charts

struct PingChartView: View {
    @Environment(KMState.self) var state
    var node: NodeData
    @State private var selectedRange: ChartRange = ChartRange(hours: 1, label: ChartRange.rangeLabel(hours: 1))
    @State private var pingRecords: [PingRecord] = []
    @State private var tasks: [PingTaskInfo] = []
    @State private var loadingState: LoadingState = .idle
    @State private var hiddenTaskIds: Set<Int> = []
    @AppStorage("KMPingChartCutPeak", store: KMCore.userDefaults) private var cutPeak: Bool = false

    private static let taskColors: [Color] = [
        .red, .green, .blue, .orange, .purple, .teal, .pink, .yellow
    ]

    private var availableRanges: [ChartRange] {
        ChartRange.pingRanges(publicInfo: state.publicInfo)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                periodPicker
                contentSection
            }
            .padding()
        }
        .onAppear {
            let ranges = availableRanges
            if !ranges.contains(selectedRange) {
                selectedRange = ranges.first ?? ChartRange(hours: 1, label: ChartRange.rangeLabel(hours: 1))
            }
            fetchPingRecords()
        }
        .onChange(of: selectedRange) {
            pingRecords = []
            tasks = []
            loadingState = .idle
            fetchPingRecords()
        }
        .onChange(of: availableRanges) {
            // Public info can arrive after the view appears; keep the selection valid
            if !availableRanges.contains(selectedRange) {
                selectedRange = availableRanges.first ?? ChartRange(hours: 1, label: ChartRange.rangeLabel(hours: 1))
            }
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

    @ViewBuilder
    private var contentSection: some View {
        Group {
            switch loadingState {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .transition(.blurReplace)
            case .loaded:
                if tasks.isEmpty {
                    Text("No Data")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 100)
                        .transition(.blurReplace)
                } else {
                    VStack(spacing: 10) {
                        taskSummaryCard
                        chartControls
                        pingChart
                    }
                    .transition(.blurReplace)
                }
            case .error(let message):
                VStack(spacing: 10) {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Retry") {
                        fetchPingRecords()
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 100)
                .transition(.blurReplace)
            }
        }
        .animation(.smooth(duration: 0.3), value: loadingState)
    }

    private var taskSummaryCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                let isHidden = hiddenTaskIds.contains(task.id)
                Button {
                    withAnimation(.smooth(duration: 0.3)) {
                        if isHidden {
                            hiddenTaskIds.remove(task.id)
                        } else {
                            hiddenTaskIds.insert(task.id)
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Self.taskColors[index % Self.taskColors.count])
                            .frame(width: 4, height: 24)
                            .opacity(isHidden ? 0.3 : 1)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.name)
                                .font(.system(size: 14, weight: .semibold))
                            HStack(spacing: 8) {
                                // -1 means the latest probe was lost
                                if let latest = task.latest, latest >= 0 {
                                    Text("\(Int(latest)) ms")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                if let loss = task.loss {
                                    Text(String(format: "%.1f%% loss", loss))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            if let avg = task.avg {
                                Text("avg \(Int(avg)) ms")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if let p99 = task.p99, let p50 = task.p50 {
                                Text("p50 \(Int(p50)) / p99 \(Int(p99))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if let min = task.min, let max = task.max {
                                Text("min \(Int(min)) / max \(Int(max))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Image(systemName: isHidden ? "eye.slash" : "eye")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .opacity(isHidden ? 0.4 : 1)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if index < tasks.count - 1 {
                    Divider()
                        .padding(.leading, 24)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.08), radius: 5, x: 5, y: 5)
                .shadow(color: .black.opacity(0.06), radius: 5, x: -5, y: -5)
        )
    }

    // MARK: - Chart Controls

    private var allHidden: Bool {
        hiddenTaskIds.count == tasks.count
    }

    private var chartControls: some View {
        HStack {
            Toggle(isOn: $cutPeak.animation(.smooth(duration: 0.3))) {
                Label("Smooth Peaks", systemImage: "waveform.path")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .toggleStyle(.switch)
            .controlSize(.mini)
            .fixedSize()

            Spacer()

            Button {
                withAnimation(.smooth(duration: 0.3)) {
                    if allHidden {
                        hiddenTaskIds = []
                    } else {
                        hiddenTaskIds = Set(tasks.map(\.id))
                    }
                }
            } label: {
                Label(allHidden ? String(localized: "Show All") : String(localized: "Hide All"),
                      systemImage: allHidden ? "eye" : "eye.slash")
                    .font(.subheadline)
            }
        }
        .padding(.horizontal, 4)
    }

    private var pingChart: some View {
        let chartPoints = buildChartData()
        return VStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Ping")
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.top, 10)

                if chartPoints.isEmpty {
                    Text("No Data")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 120)
                } else {
                    Chart(chartPoints, id: \.id) { point in
                        LineMark(
                            x: .value("Time", point.date),
                            y: .value("Latency", point.value),
                            series: .value("Task", point.taskName)
                        )
                        .foregroundStyle(point.color)
                        .interpolationMethod(cutPeak ? .catmullRom : .linear)
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text("\(v, specifier: "%.0f")ms")
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisGridLine()
                            if selectedRange.hours > 24 {
                                AxisValueLabel(format: .dateTime.month(.defaultDigits).day())
                            } else {
                                AxisValueLabel(format: .dateTime.hour().minute())
                            }
                        }
                    }
                    .chartForegroundStyleScale(range: tasks.enumerated().compactMap { index, task in
                        hiddenTaskIds.contains(task.id) ? nil : Self.taskColors[index % Self.taskColors.count]
                    })
                    .frame(height: 200)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 10)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.08), radius: 5, x: 5, y: 5)
                .shadow(color: .black.opacity(0.06), radius: 5, x: -5, y: -5)
        )
    }

    private struct PingChartPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
        let taskName: String
        let color: Color
    }

    private func buildChartData() -> [PingChartPoint] {
        var points: [PingChartPoint] = []

        for (index, task) in tasks.enumerated() {
            guard !hiddenTaskIds.contains(task.id) else { continue }
            let color = Self.taskColors[index % Self.taskColors.count]

            let samples = pingRecords
                .filter { $0.taskId == task.id }
                .compactMap { record -> (date: Date, value: Double)? in
                    guard let timeStr = record.time,
                          let date = ServerDetailMonitorView.parseDate(timeStr),
                          let value = record.value else { return nil }
                    return (date, value)
                }
                .sorted { $0.date < $1.date }

            let times = samples.map(\.date)
            // Negative values encode packet loss; treat them as gaps
            var values: [Double?] = samples.map { $0.value >= 0 ? $0.value : nil }

            if cutPeak {
                values = cutPeakSeries(interpolateNilsLinear(times: times, values: values))
            }

            for (i, value) in values.enumerated() {
                guard let value else { continue }
                points.append(PingChartPoint(date: times[i], value: value, taskName: task.name, color: color))
            }
        }
        return points
    }

    private func fetchPingRecords() {
        loadingState = .loading
        let uuid = node.uuid
        let hours = selectedRange.hours
        let useMetricStats = state.capabilities?.hasPingMetricStats == true
        Task {
            do {
                async let recordsTask = RecordHandler.getPingRecords(uuid: uuid, hours: hours)
                async let statsTask: [PingMetricStat]? = useMetricStats
                    ? try? RecordHandler.getPingMetricStats(uuid: uuid, hours: hours)
                    : nil
                let result = try await recordsTask
                var fetchedTasks = result.tasks ?? []
                if let stats = await statsTask {
                    let statsByTask = Dictionary(stats.map { ($0.taskId, $0) }, uniquingKeysWith: { first, _ in first })
                    fetchedTasks = fetchedTasks.map { task in
                        statsByTask[String(task.id)].map(task.merging) ?? task
                    }
                }
                withAnimation {
                    pingRecords = result.records ?? []
                    tasks = fetchedTasks
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
