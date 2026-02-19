//
//  LoadIndicatorEnum.swift
//  Komari Widget
//
//  Created by Junhui Lou on 2/19/26.
//

import AppIntents

enum LoadIndicator: String, AppEnum {
    case cpu
    case memory
    case disk
    case networkIn
    case networkOut

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Load Indicator"

    static var caseDisplayRepresentations: [LoadIndicator: DisplayRepresentation] = [
        .cpu: "CPU",
        .memory: "Memory",
        .disk: "Disk",
        .networkIn: "Network In",
        .networkOut: "Network Out"
    ]

    var unit: String {
        switch self {
        case .cpu: return "%"
        case .memory: return "%"
        case .disk: return "%"
        case .networkIn: return "/s"
        case .networkOut: return "/s"
        }
    }

    var label: String {
        switch self {
        case .cpu: return "CPU"
        case .memory: return "RAM"
        case .disk: return "Disk"
        case .networkIn: return "Net ↓"
        case .networkOut: return "Net ↑"
        }
    }
}
