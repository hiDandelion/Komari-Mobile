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
    let weight: Int?
    /// Runs on every node, including ones added later (`clients` is then ignored)
    let defaultOn: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name, type, target, interval, clients, weight
        case defaultOn = "default_on"
    }

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
