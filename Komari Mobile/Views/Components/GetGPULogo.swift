//
//  GetGPULogo.swift
//  Komari Mobile
//
//  Created by Takuma Kirishima on 2/15/26.
//

import SwiftUI

struct GetGPULogo {
    @ViewBuilder
    static func logo(for gpuName: String) -> some View {
        if gpuName.lowercased().contains("amd") {
            Image("AMDLogo")
                .resizable()
                .scaledToFit()
        } else if gpuName.lowercased().contains("apple") {
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
