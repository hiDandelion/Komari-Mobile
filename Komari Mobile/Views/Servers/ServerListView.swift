//
//  ServerListView.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 2/15/26.
//

import SwiftUI

struct ServerListView: View {
    @Environment(KMState.self) var state
    @State private var backgroundImage: UIImage?
    @State private var sortIndicator: SortIndicator = .index
    @State private var sortOrder: SortOrder = .descending
    @State private var searchText: String = ""
    @State private var selectedGroup: String?
    @Namespace private var tagNamespace

    @State private var isShowDeleteServerAlert: Bool = false
    @State private var serverToDelete: NodeData?

    private func memoryUsage(for status: NodeLiveStatus?) -> Double {
        guard let s = status, s.memoryTotal > 0 else { return 0 }
        return Double(s.memoryUsed) / Double(s.memoryTotal)
    }

    private func diskUsage(for status: NodeLiveStatus?) -> Double {
        guard let s = status, s.diskTotal > 0 else { return 0 }
        return Double(s.diskUsed) / Double(s.diskTotal)
    }

    private func sortNodes(_ a: NodeData, _ b: NodeData) -> Bool {
        let statusA = state.liveStatus[a.uuid]
        let statusB = state.liveStatus[b.uuid]
        switch sortIndicator {
        case .index:
            if a.weight == b.weight {
                return sortOrder == .ascending ? a.uuid < b.uuid : a.uuid > b.uuid
            }
            return a.weight > b.weight
        case .uptime:
            let va: Int64 = statusA?.uptime ?? 0
            let vb: Int64 = statusB?.uptime ?? 0
            return sortOrder == .ascending ? va < vb : va > vb
        case .cpu:
            let va: Double = statusA?.cpuUsage ?? 0
            let vb: Double = statusB?.cpuUsage ?? 0
            return sortOrder == .ascending ? va < vb : va > vb
        case .memory:
            let va = memoryUsage(for: statusA)
            let vb = memoryUsage(for: statusB)
            return sortOrder == .ascending ? va < vb : va > vb
        case .disk:
            let va = diskUsage(for: statusA)
            let vb = diskUsage(for: statusB)
            return sortOrder == .ascending ? va < vb : va > vb
        case .upload:
            let va: Int64 = statusA?.networkOutSpeed ?? 0
            let vb: Int64 = statusB?.networkOutSpeed ?? 0
            return sortOrder == .ascending ? va < vb : va > vb
        case .download:
            let va: Int64 = statusA?.networkInSpeed ?? 0
            let vb: Int64 = statusB?.networkInSpeed ?? 0
            return sortOrder == .ascending ? va < vb : va > vb
        }
    }

    private var filteredNodes: [NodeData] {
        let sorted = state.nodes.sorted(by: sortNodes)
        let grouped = sorted.filter { node in
            if let selectedGroup {
                return node.group == selectedGroup
            }
            return true
        }
        return grouped.filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private let columns: [GridItem] = [GridItem(.adaptive(minimum: 320, maximum: 450))]

    var body: some View {
        NavigationStack(path: Bindable(state).pathServers) {
            ZStack {
                background
                    .zIndex(0)

                dashboard
                    .zIndex(1)
            }
            .navigationDestination(for: NodeData.self) { node in
                ServerDetailView(uuid: node.uuid)
            }
        }
        .alert("Delete Server", isPresented: $isShowDeleteServerAlert) {
            Button("Delete", role: .destructive) {
                if let serverToDelete {
                    Task {
                        try? await AdminHandler.removeClient(uuid: serverToDelete.uuid)
                        await state.refreshAll()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You are about to delete this server. Are you sure?")
        }
        .onAppear {
            let backgroundPhotoData = KMCore.userDefaults.data(forKey: "KMBackgroundPhotoData")
            if let backgroundPhotoData {
                backgroundImage = UIImage(data: backgroundPhotoData)
            } else {
                backgroundImage = nil
            }
        }
    }

    private var background: some View {
        Group {
            if let backgroundImage {
                GeometryReader { proxy in
                    Image(uiImage: backgroundImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: proxy.size.height)
                        .clipped()
                }
                .ignoresSafeArea()
            } else {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
            }
        }
    }

    private var dashboard: some View {
        Group {
            ScrollView {
                if !state.groupNames.isEmpty {
                    groupPicker
                        .safeAreaPadding(.horizontal, 15)
                        .padding(.bottom, 5)
                }

                serverList
            }
            .navigationTitle("Servers")
            .searchable(text: $searchText)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    moreButton
                }
            }
            .loadingState(loadingState: state.dashboardLoadingState) {
                state.loadDashboard()
            }
        }
    }

    private var moreButton: some View {
        Menu("More", systemImage: "ellipsis") {
            Picker("Sort", selection: Binding(get: {
                sortIndicator
            }, set: { newValue in
                withAnimation(.snappy) {
                    if sortIndicator == newValue {
                        switch(sortOrder) {
                        case .ascending:
                            sortOrder = .descending
                        case .descending:
                            sortOrder = .ascending
                        }
                    } else {
                        sortIndicator = newValue
                    }
                }
            })) {
                ForEach(SortIndicator.allCases, id: \.self) { indicator in
                    Button {

                    } label: {
                        Text(indicator.title)
                        if self.sortIndicator == indicator && indicator != .index {
                            Text(sortOrder.title)
                        }
                    }
                    .tag(indicator)
                }
            }
        }
    }

    private var groupPicker: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                groupTag(group: nil)
                ForEach(state.groupNames, id: \.self) { group in
                    groupTag(group: group)
                }
            }
        }
        .scrollIndicators(.never)
    }

    private func groupTag(group: String?) -> some View {
        Button(action: {
            withAnimation(.snappy) {
                selectedGroup = group
            }
        }) {
            Text(group == nil ? String(localized: "All(\(state.nodes.count))") : group!)
                .font(.callout)
                .foregroundStyle(selectedGroup == group ? .white : .primary)
                .padding(.vertical, 8)
                .padding(.horizontal, 15)
                .background {
                    if selectedGroup == group {
                        Capsule()
                            .fill(.tint)
                            .matchedGeometryEffect(id: "ACTIVETAG", in: tagNamespace)
                    } else {
                        Capsule()
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private var serverList: some View {
        Group {
            if !state.nodes.isEmpty {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(filteredNodes) { node in
                        let status = state.liveStatus[node.uuid]
                        let isOnline = state.onlineUUIDs.contains(node.uuid)
                        ServerCardView(node: node, status: status, isOnline: isOnline)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.95).combined(with: .opacity),
                                removal: .opacity
                            ))
                            .hoverEffect(.automatic)
                            .onTapGesture {
                                state.pathServers.append(node)
                            }
                            .contextMenu {
                                if let ipv4 = node.ipv4, !ipv4.isEmpty {
                                    Button {
                                        UIPasteboard.general.string = ipv4
                                    } label: {
                                        Label("Copy IPv4", systemImage: "4.circle")
                                    }
                                }
                                if let ipv6 = node.ipv6, !ipv6.isEmpty {
                                    Button {
                                        UIPasteboard.general.string = ipv6
                                    } label: {
                                        Label("Copy IPv6", systemImage: "6.circle")
                                    }
                                }
                                Button(role: .destructive) {
                                    serverToDelete = node
                                    isShowDeleteServerAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .padding(.horizontal, 15)
            } else {
                ContentUnavailableView("No Server", systemImage: "square.stack.3d.up.slash.fill")
            }
        }
    }
}
