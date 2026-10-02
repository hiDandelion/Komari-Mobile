//
//  GetRecordsResponse.swift
//  Komari Mobile
//
//  Created by Takuma Kirishima on 2/15/26.
//

import Foundation

/// Response data from REST `/api/records/load`
struct LoadRecordsData: Codable {
    let records: [NodeRecord]?
    let count: Int?
}
