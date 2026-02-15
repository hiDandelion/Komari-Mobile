//
//  KomariMobileApp.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import SwiftUI

@main
struct KomariMobileApp: App {
    var theme: KMTheme = .init()
    var state: KMState = .init()

    init() {
        KMCore.registerUserDefaults()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(state)
                .environment(theme)
        }
    }
}
