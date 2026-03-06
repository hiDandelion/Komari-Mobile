//
//  SettingsView.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(KMState.self) var state

    var body: some View {
        NavigationStack(path: Bindable(state).pathSettings) {
            Form {
                Section("App Settings") {
                    NavigationLink(value: "dashboard-settings") {
                        Text("Dashboard Settings")
                    }
                }

                Section("Notifications") {
                    NavigationLink(value: "offline-notifications") {
                        Text("Offline Notifications")
                    }
                    NavigationLink(value: "load-alerts") {
                        Text("Load Alerts")
                    }
                    NavigationLink(value: "general-notifications") {
                        Text("General Notifications")
                    }
                }

                Section("Administration") {
                    NavigationLink(value: "ping-tasks") {
                        Text("Ping Tasks")
                    }
                    NavigationLink(value: "remote-exec") {
                        Text("Remote Exec")
                    }
                    NavigationLink(value: "sessions") {
                        Text("Sessions")
                    }
                    NavigationLink(value: "account") {
                        Text("Account")
                    }
                    NavigationLink(value: "logs") {
                        Text("Logs")
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
                case "ping-tasks":
                    PingTasksView()
                case "load-alerts":
                    LoadAlertsView()
                case "offline-notifications":
                    OfflineNotificationsView()
                case "general-notifications":
                    GeneralNotificationsView()
                case "remote-exec":
                    RemoteExecView()
                case "sessions":
                    SessionsView()
                case "account":
                    AccountView()
                case "logs":
                    LogsView()
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
