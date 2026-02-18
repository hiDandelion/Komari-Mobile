//
//  SortIndicator.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import Foundation

enum SortIndicator: CaseIterable {
    case index
    case uptime
    case cpu
    case memory
    case disk
    case uploadTraffic
    case downloadTraffic

    var title: String {
        switch self {
        case .index: String(localized: "Default")
        case .uptime: String(localized: "Up Time")
        case .cpu: String(localized: "CPU")
        case .memory: String(localized: "Memory")
        case .disk: String(localized: "Disk")
        case .uploadTraffic: String(localized: "Upload")
        case .downloadTraffic: String(localized: "Download")
        }
    }
}
