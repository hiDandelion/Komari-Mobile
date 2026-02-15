//
//  SettingsView.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(KMTheme.self) var theme
    @Environment(KMState.self) var state

    var body: some View {
        NavigationStack(path: Bindable(state).pathSettings) {
            Form {
                Section {
                    NavigationLink(value: "dashboard-settings") {
                        Text("Dashboard Settings")
                    }
                }

                Section {
                    NavigationLink(value: "theme-settings") {
                        Text("Theme Settings")
                    }
                }

                Section("About") {
                    Link("User Guide", destination: KMCore.userGuideURL)
                    NavigationLink(value: "acknowledgments") {
                        Text("Acknowledgments")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationDestination(for: String.self) { target in
                switch(target) {
                case "dashboard-settings":
                    DashboardSettingsView()
                case "theme-settings":
                    ThemeSettingsView()
                case "acknowledgments":
                    AcknowledgmentView()
                default:
                    EmptyView()
                }
            }
            .safeAreaInset(edge: .bottom) {
                Rectangle()
                    .fill(.clear)
                    .frame(height: 50)
            }
        }
    }
}
