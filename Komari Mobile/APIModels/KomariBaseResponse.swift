//
//  KomariBaseResponse.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import Foundation

struct KomariBaseResponse<T: Codable>: Codable {
    let status: String
    let message: String?
    let data: T?

    var isSuccess: Bool {
        status == "success"
    }
}
