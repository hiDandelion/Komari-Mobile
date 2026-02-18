//
//  MeResponse.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import Foundation

struct MeResponseData: Codable {
    let username: String?
    let loggedIn: Bool?
    let uuid: String?
    let ssoType: String?
    let ssoId: String?
    let tfaEnabled: Bool?

    enum CodingKeys: String, CodingKey {
        case username, uuid
        case loggedIn = "logged_in"
        case ssoType = "sso_type"
        case ssoId = "sso_id"
        case tfaEnabled = "2fa_enabled"
    }
}
