//
//  PublicInfoResponse.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 7/2/26.
//

import Foundation

struct PublicInfo: Codable {
    let sitename: String?
    let description: String?
    let privateSite: Bool?
    let oauthEnable: Bool?
    let oauthProvider: String?
    let disablePasswordLogin: Bool?
    let recordEnabled: Bool?
    let recordPreserveTime: Int?
    let pingRecordPreserveTime: Int?

    enum CodingKeys: String, CodingKey {
        case sitename, description
        case privateSite = "private_site"
        case oauthEnable = "oauth_enable"
        case oauthProvider = "oauth_provider"
        case disablePasswordLogin = "disable_password_login"
        case recordEnabled = "record_enabled"
        case recordPreserveTime = "record_preserve_time"
        case pingRecordPreserveTime = "ping_record_preserve_time"
    }
}
