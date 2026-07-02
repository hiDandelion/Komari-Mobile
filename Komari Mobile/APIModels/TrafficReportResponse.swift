//
//  TrafficReportResponse.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 7/2/26.
//

import Foundation

struct TrafficReportNotification: Codable, Identifiable {
    let client: String?
    let enable: Bool?
    let daily: Bool?
    let weekly: Bool?
    let monthly: Bool?

    var id: String { client ?? UUID().uuidString }
}
