//
//  SessionResponse.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 3/7/26.
//

import Foundation

struct SessionsResponse: Codable {
    let status: String?
    let current: String?
    let data: [SessionInfo]?
}

struct SessionInfo: Codable, Identifiable {
    let uuid: String?
    let session: String?
    let userAgent: String?
    let ip: String?
    let loginMethod: String?
    let latestOnline: String?
    let latestIp: String?
    let latestUserAgent: String?
    let expires: String?
    let createdAt: String?

    var id: String { session ?? UUID().uuidString }

    enum CodingKeys: String, CodingKey {
        case uuid, session, ip, expires
        case userAgent = "user_agent"
        case loginMethod = "login_method"
        case latestOnline = "latest_online"
        case latestIp = "latest_ip"
        case latestUserAgent = "latest_user_agent"
        case createdAt = "created_at"
    }
}
