//
//  GetCPULogo.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import SwiftUI

struct GetCPULogo {
    @ViewBuilder
    static func logo(for cpuName: String) -> some View {
        if cpuName.lowercased().contains("amd") {
            Image("AMDLogo")
                .resizable()
                .scaledToFit()
        } else if cpuName.lowercased().contains("intel") {
            Image("IntelLogo")
                .resizable()
                .scaledToFit()
        } else if cpuName.lowercased().contains("neoverse") {
            Image("ARMLogo")
                .resizable()
                .scaledToFit()
        } else if cpuName.lowercased().contains("apple") {
            Image("AppleLogo")
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "cpu")
                .resizable()
                .scaledToFit()
        }
    }
}
