//
//  HomeView.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(KMTheme.self) var theme
    @Environment(KMState.self) var state

    var body: some View {
        TabView(selection: Bindable(state).tab) {
            Tab(value: MainTab.servers) {
                ServerListView()
            } label: {
                Label(MainTab.servers.title, systemImage: MainTab.servers.systemName)
            }

            Tab(value: MainTab.settings) {
                SettingsView()
            } label: {
                Label(MainTab.settings.title, systemImage: MainTab.settings.systemName)
            }
        }
    }
}
