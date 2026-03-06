//
//  SettingsResponse.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 3/7/26.
//

import Foundation

struct DashboardSettings: Codable {
    let expireNotificationEnabled: Bool?
    let expireNotificationLeadDays: Int?
    let loginNotification: Bool?
    let trafficLimitPercentage: Double?

    enum CodingKeys: String, CodingKey {
        case expireNotificationEnabled = "expire_notification_enabled"
        case expireNotificationLeadDays = "expire_notification_lead_days"
        case loginNotification = "login_notification"
        case trafficLimitPercentage = "traffic_limit_percentage"
    }
}
