//
//  MetricsChart.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import SwiftUI
import Charts

struct MetricsDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct MetricsChart: View {
    let title: String
    let dataPoints: [MetricsDataPoint]
    let unit: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .padding(.horizontal, 10)
                .padding(.top, 10)

            if dataPoints.isEmpty {
                Text("No Data")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                Chart(dataPoints) { point in
                    LineMark(
                        x: .value("Time", point.date),
                        y: .value(title, point.value)
                    )
                    .foregroundStyle(color.gradient)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Time", point.date),
                        y: .value(title, point.value)
                    )
                    .foregroundStyle(color.opacity(0.1).gradient)
                    .interpolationMethod(.catmullRom)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(v, specifier: "%.0f")\(unit)")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.hour())
                    }
                }
                .frame(height: 150)
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            }
        }
    }
}

struct MetricsSeriesData {
    let name: String
    let dataPoints: [MetricsDataPoint]
    let color: Color
}

struct MetricsMultiSeriesChart: View {
    let title: String
    let series: [MetricsSeriesData]
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                ForEach(series, id: \.name) { s in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(s.color)
                            .frame(width: 8, height: 8)
                        Text(s.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)

            if series.allSatisfy({ $0.dataPoints.isEmpty }) {
                Text("No Data")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                Chart {
                    ForEach(series, id: \.name) { s in
                        ForEach(s.dataPoints) { point in
                            LineMark(
                                x: .value("Time", point.date),
                                y: .value(title, point.value),
                                series: .value("Series", s.name)
                            )
                            .foregroundStyle(s.color)
                            .interpolationMethod(.catmullRom)
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(v, specifier: "%.0f")\(unit)")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.hour())
                    }
                }
                .frame(height: 150)
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            }
        }
    }
}
