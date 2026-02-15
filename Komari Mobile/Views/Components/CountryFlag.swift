//
//  CountryFlag.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import SwiftUI

struct CountryFlag: View {
    let countryFlag: String

    var body: some View {
        if countryFlag == "\u{1F1F9}\u{1F1FC}" && DeviceCensorship.isChinaDevice() {
            Text("\u{1F1FC}\u{1F1F8}")
        } else {
            Text(countryFlag)
        }
    }
}
