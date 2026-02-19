//
//  WidgetUtilities.swift
//  Komari Widget
//
//  Created by Junhui Lou on 2/19/26.
//

import Foundation

func formatBytes(_ bytes: Int64, decimals: Int = 2) -> String {
    let units = ["B", "KB", "MB", "GB", "TB", "PB"]
    var value = Double(bytes)
    var unitIndex = 0

    while value >= 1024 && unitIndex < units.count - 1 {
        value /= 1024
        unitIndex += 1
    }

    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = decimals
    formatter.roundingMode = .ceiling

    guard let formattedValue = formatter.string(from: NSNumber(value: value)) else {
        return ""
    }

    return "\(formattedValue) \(units[unitIndex])"
}

func formatTimeInterval(seconds: Int64, shortened: Bool = false) -> String {
    let minutes = seconds / 60
    let hours = minutes / 60
    let days = hours / 24

    if days >= 10 {
        return "\(days)d"
    } else if days > 0 {
        return shortened ? "\(days)d" : "\(days)d\(hours % 24)h"
    } else if hours > 0 {
        return shortened ? "\(hours)h" : "\(hours)h\(minutes % 60)m"
    } else if minutes > 0 {
        return shortened ? "\(minutes)m" : "\(minutes)m\(seconds % 60)s"
    } else {
        return "\(seconds)s"
    }
}

enum WidgetDateParser {
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
}
