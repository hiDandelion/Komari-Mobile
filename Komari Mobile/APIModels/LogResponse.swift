//
//  LogResponse.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 3/7/26.
//

import Foundation

struct AuditLog: Codable, Identifiable {
    let id: Int?
    let ip: String?
    let uuid: String?
    let message: String?
    let msgType: String?
    let time: String?

    enum CodingKeys: String, CodingKey {
        case id, ip, uuid, message
        case msgType = "msg_type"
        case time
    }
}

struct LogsData: Codable {
    let logs: [AuditLog]?
    let total: Int?
}
