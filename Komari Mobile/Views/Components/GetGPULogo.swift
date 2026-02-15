//
//  GetGPULogo.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import SwiftUI

struct GetGPULogo {
    @ViewBuilder
    static func logo(for gpuName: String) -> some View {
        if gpuName.lowercased().contains("amd") {
            Image("AMDLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
        } else if gpuName.lowercased().contains("apple") {
            Image("AppleLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
        } else {
            Image(systemName: "gpu")
                .resizable()
                .scaledToFit()
                .frame(height: 40)
        }
    }
}
