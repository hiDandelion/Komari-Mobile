//
//  SortOrder.swift
//  Komari Mobile
//
//  Created by Takuma Kirishima on 2/15/26.
//

import Foundation

enum SortOrder {
    case ascending
    case descending

    var title: String {
        switch self {
        case .ascending: String(localized: "Ascending")
        case .descending: String(localized: "Descending")
        }
    }
}
