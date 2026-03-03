//
//  PingTaskResponse.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 3/3/26.
//

import Foundation

struct PingTask: Codable, Identifiable {
    let id: Int?
    let name: String?
    let type: String?
    let target: String?
    let interval: Int?
    let clients: [String]?

    var displayName: String {
        name ?? "(Unnamed)"
    }

    var displayType: String {
        switch type?.lowercased() {
        case "icmp": "ICMP"
        case "tcp": "TCP"
        case "http": "HTTP"
        default: type?.uppercased() ?? "Unknown"
        }
    }
}
