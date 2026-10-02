//
//  KMState.swift
//  Komari Mobile
//
//  Created by Takuma Kirishima on 2/15/26.
//

import Foundation
import SwiftUI
import Observation

/// Features that depend on the dashboard version, detected from its RPC method list.
struct ServerCapabilities: Equatable {
    let methods: Set<String>

    /// Load alerts were removed from Komari 1.5 (now provided by plugins)
    var hasLoadAlerts: Bool { methods.contains("admin:getAllLoadNotifications") }
    /// Traffic reports were removed from Komari 1.5 (now provided by plugins)
    var hasTrafficReports: Bool { methods.contains("admin:listTrafficReportNotifications") }
    /// Pluggable notification channels (Komari 1.5+)
    var hasNotificationChannels: Bool { methods.contains("admin:listNotificationChannels") }
    var canSwitchAgentVersion: Bool { methods.contains("admin:switchAgentVersion") }
    /// Per-probe ping statistics from the metric store (Komari 1.5+)
    var hasPingMetricStats: Bool { methods.contains("public:getPingMetricStats") }
}

/// Signing in with the saved credentials is waiting for a 2FA code.
struct TwoFactorChallenge: Equatable {
    /// Why the previous code was rejected, if it was
    let rejectionMessage: String?
}

enum MainTab: String, CaseIterable {
    case servers = "servers"
    case settings = "settings"

    var systemName: String {
        switch self {
        case .servers: "server.rack"
        case .settings: "gearshape"
        }
    }

    var title: String {
        switch self {
        case .servers: String(localized: "Servers")
        case .settings: String(localized: "Settings")
        }
    }
}

@Observable
class KMState {
    var pathServers: NavigationPath = .init()
    var pathSettings: NavigationPath = .init()

    var tab: MainTab = .servers

    var dashboardLoadingState: LoadingState = .idle
    var twoFactorChallenge: TwoFactorChallenge?
    var nodes: [NodeData] = .init()
    var liveStatus: [String: NodeLiveStatus] = .init()
    var onlineUUIDs: Set<String> = .init()
    var publicInfo: PublicInfo?
    /// Unknown until discovered; version-dependent features stay hidden meanwhile
    var capabilities: ServerCapabilities?
    private var timer: Timer?

    var groupNames: [String] {
        let groups = nodes.compactMap { $0.group }.filter { !$0.isEmpty }
        return Array(Set(groups)).sorted()
    }

    /// `tfaCode` answers a `twoFactorChallenge` from the previous attempt.
    func loadDashboard(tfaCode: String? = nil) {
        twoFactorChallenge = nil
        let link = KMCore.getKomariDashboardLink()
        guard !link.isEmpty else {
            dashboardLoadingState = .error("Dashboard is not properly configured.")
            return
        }

        dashboardLoadingState = .loading

        Task {
            do {
                // Log in with saved credentials unless the stored session already belongs to
                // that user; every login creates another server-side session.
                let username = KMCore.getKomariDashboardUsername()
                let password = KMCore.getKomariDashboardPassword()
                if !username.isEmpty && !password.isEmpty,
                   (try? await AuthHandler.getMe())?.username != username {
                    try await AuthHandler.login(username: username, password: password, tfaCode: tfaCode)
                }

                try await loadNodes()
                try await refreshLiveStatus()
                dashboardLoadingState = .loaded
                await loadPublicInfo()
                await loadCapabilities()
            } catch {
                withAnimation {
                    switch error as? KomariError {
                    case .twoFactorRequired:
                        twoFactorChallenge = TwoFactorChallenge(rejectionMessage: nil)
                    case .invalidTwoFactorCode:
                        twoFactorChallenge = TwoFactorChallenge(rejectionMessage: error.localizedDescription)
                    default:
                        break
                    }
                    dashboardLoadingState = .error(error.localizedDescription)
                }
                return
            }
        }

        startAutoRefresh()
    }

    func startAutoRefresh() {
        stopAutoRefresh()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task {
                try? await self?.refreshLiveStatus()
            }
        }
    }

    func stopAutoRefresh() {
        timer?.invalidate()
        timer = nil
    }

    private var loadNodesTask: Task<Void, Error>?
    private var refreshLiveStatusTask: Task<Void, Error>?

    func loadNodes() async throws {
        loadNodesTask?.cancel()

        loadNodesTask = Task {
            let nodesMap = try await NodeHandler.getNodes()

            guard !Task.isCancelled else { return }

            withAnimation {
                self.nodes = Array(nodesMap.values).sorted { $0.weight < $1.weight }
            }
        }

        try await loadNodesTask?.value
    }

    func refreshLiveStatus() async throws {
        refreshLiveStatusTask?.cancel()

        refreshLiveStatusTask = Task {
            let statusMap = try await NodeHandler.getNodesLatestStatus()

            guard !Task.isCancelled else { return }

            withAnimation {
                self.liveStatus = statusMap
                self.onlineUUIDs = Set(statusMap.values.filter { $0.online }.map { $0.client })
            }
        }

        try await refreshLiveStatusTask?.value
    }

    func refreshAll() async {
        try? await loadNodes()
        try? await refreshLiveStatus()
        await loadPublicInfo()
        await loadCapabilities()
    }

    /// Public site info is optional: older dashboards may not expose it, so failures are non-fatal.
    func loadPublicInfo() async {
        publicInfo = try? await PublicHandler.getPublicInfo()
    }

    func loadCapabilities() async {
        guard let methods = try? await RPC2Handler.availableMethods() else { return }
        let discovered = ServerCapabilities(methods: methods)
        if capabilities != discovered {
            capabilities = discovered
        }
    }
}
