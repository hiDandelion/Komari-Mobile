//
//  SettingsView.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(KMState.self) var state
    @State private var dashboardVersion: String?

    var body: some View {
        NavigationStack(path: Bindable(state).pathSettings) {
            Form {
                Section("App Settings") {
                    NavigationLink(value: "dashboard-settings") {
                        TextWithColorfulIcon(titleKey: "Dashboard Settings", systemName: "gearshape.fill", color: .blue)
                    }
                }

                Section("Notifications") {
                    NavigationLink(value: "offline-notifications") {
                        TextWithColorfulIcon(titleKey: "Offline Notifications", systemName: "wifi.slash", color: .blue)
                    }
                    NavigationLink(value: "load-alerts") {
                        TextWithColorfulIcon(titleKey: "Load Alerts", systemName: "exclamationmark.triangle", color: .orange)
                    }
                    NavigationLink(value: "traffic-reports") {
                        TextWithColorfulIcon(titleKey: "Traffic Reports", systemName: "calendar.badge.clock", color: .purple)
                    }
                    NavigationLink(value: "general-notifications") {
                        TextWithColorfulIcon(titleKey: "General Notifications", systemName: "bell", color: .red)
                    }
                }

                Section("Administration") {
                    NavigationLink(value: "ping-tasks") {
                        TextWithColorfulIcon(titleKey: "Ping Tasks", systemName: "network", color: .blue)
                    }
                    NavigationLink(value: "remote-exec") {
                        TextWithColorfulIcon(titleKey: "Remote Exec", systemName: "terminal", color: .black)
                    }
                    NavigationLink(value: "sessions") {
                        TextWithColorfulIcon(titleKey: "Sessions", systemName: "person.2", color: .teal)
                    }
                    NavigationLink(value: "account") {
                        TextWithColorfulIcon(titleKey: "Account", systemName: "person.crop.circle", color: .green)
                    }
                    NavigationLink(value: "logs") {
                        TextWithColorfulIcon(titleKey: "Logs", systemName: "doc.text", color: .gray)
                    }
                }

                Section("About") {
                    Link(destination: KMCore.userGuideURL) {
                        TextWithColorfulIcon(titleKey: "User Guide", systemName: "book", color: .blue)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    NavigationLink(value: "acknowledgments") {
                        TextWithColorfulIcon(titleKey: "Acknowledgments", systemName: "heart", color: .pink)
                    }
                    if let dashboardVersion {
                        LabeledContent {
                            Text(dashboardVersion)
                                .font(.subheadline.monospaced())
                        } label: {
                            TextWithColorfulIcon(titleKey: "Dashboard Version", systemName: "server.rack", color: .indigo)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .task {
                guard dashboardVersion == nil,
                      let versionData = try? await PublicHandler.getVersion() else { return }
                var parts: [String] = []
                if let version = versionData.version, !version.isEmpty {
                    parts.append(version)
                }
                if let hash = versionData.hash, !hash.isEmpty {
                    parts.append("(\(String(hash.prefix(7))))")
                }
                if !parts.isEmpty {
                    dashboardVersion = parts.joined(separator: " ")
                }
            }
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
                case "traffic-reports":
                    TrafficReportsView()
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
        }
    }
}
