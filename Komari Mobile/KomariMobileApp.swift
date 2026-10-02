//
//  KomariMobileApp.swift
//  Komari Mobile
//
//  Created by Takuma Kirishima on 2/15/26.
//

import SwiftUI

@main
struct KomariMobileApp: App {
    var state: KMState = .init()

    init() {
        KMCore.registerUserDefaults()
        KMCore.migrateCookiesToAppGroup()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(state)
        }
    }
}
