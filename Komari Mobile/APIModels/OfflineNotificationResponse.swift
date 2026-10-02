//
//  OfflineNotificationResponse.swift
//  Komari Mobile
//
//  Created by Takuma Kirishima on 3/3/26.
//

import Foundation

struct OfflineNotification: Codable, Identifiable {
    let client: String?
    let enable: Bool?
    let gracePeriod: Int?       // seconds
    let lastNotified: String?

    var id: String { client ?? UUID().uuidString }

    enum CodingKeys: String, CodingKey {
        case client, enable
        case gracePeriod = "grace_period"
        case lastNotified = "last_notified"
    }
}
