//
//  ServerDetailView.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import SwiftUI

enum ServerDetailTab: String, CaseIterable, Identifiable {
    var id: String { self.rawValue }

    case status = "Status"
    case monitors = "Monitors"

    func localized() -> String {
        return NSLocalizedString(self.rawValue, comment: "")
    }
}

struct ServerDetailView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(KMTheme.self) var theme
    @Environment(KMState.self) var state
    var uuid: String
    @State private var activeTab: ServerDetailTab = .status

    var body: some View {
        let node = state.nodes.first(where: { $0.uuid == uuid })
        let status = state.liveStatus[uuid]
        let isOnline = state.onlineUUIDs.contains(uuid)

        Group {
            if let node {
                VStack {
                    if isOnline {
                        content(node: node, status: status)
                    } else {
                        ContentUnavailableView("Server Unavailable", systemImage: "square.stack.3d.up.slash.fill")
                    }
                }
                .navigationTitle(node.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Picker("Section", selection: $activeTab) {
                            ForEach(ServerDetailTab.allCases) {
                                Text($0.localized())
                                    .tag($0)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                    }
                }
            } else {
                ProgressView()
            }
        }
    }

    private func content(node: NodeData, status: NodeLiveStatus?) -> some View {
        ZStack {
            theme.themeBackgroundColor(scheme: scheme)
                .ignoresSafeArea()

            switch(activeTab) {
            case .status:
                ServerDetailStatusView(node: node, status: status)
            case .monitors:
                ServerDetailMonitorView(node: node)
            }
        }
    }
}
