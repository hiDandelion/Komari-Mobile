//
//  LoadAlertResponse.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 3/3/26.
//

import Foundation

struct LoadAlert: Codable, Identifiable {
    let id: Int?
    let name: String?
    let clients: [String]?
    let metric: String?       // "cpu", "ram", "disk", "net_in", "net_out"
    let threshold: Double?
    let ratio: Double?
    let interval: Int?        // minutes
    let lastNotified: String?

    var displayName: String {
        name ?? "(Unnamed)"
    }

    var displayMetric: String {
        switch metric?.lowercased() {
        case "cpu": "CPU"
        case "ram": "RAM"
        case "disk": "Disk"
        case "net_in": "Net In"
        case "net_out": "Net Out"
        default: metric?.uppercased() ?? "Unknown"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, name, clients, metric, threshold, ratio, interval
        case lastNotified = "last_notified"
    }
}
