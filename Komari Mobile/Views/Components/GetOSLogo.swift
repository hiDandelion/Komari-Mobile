//
//  GetOSLogo.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import SwiftUI

struct GetOSLogo {
    @ViewBuilder
    static func logo(for osName: String) -> some View {
        if osName.lowercased().contains("debian") {
            Image("DebianLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
        } else if osName.lowercased().contains("ubuntu") {
            Image("UbuntuLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
        } else if osName.lowercased().contains("windows") {
            Image("WindowsLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
        } else if osName.lowercased().contains("darwin") {
            Image("macOSLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
        } else if osName.lowercased().contains("ios") {
            Image("iOSLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
        } else {
            Image(systemName: "server.rack")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
        }
    }
}
