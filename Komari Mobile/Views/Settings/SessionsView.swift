//
//  SessionsView.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 3/7/26.
//

import SwiftUI

struct SessionsView: View {
    @State private var sessions: [SessionInfo] = []
    @State private var currentSession: String = ""
    @State private var isLoading = true
    @State private var errorMessage: String?

    @State private var sessionToDelete: SessionInfo?
    @State private var isShowDeleteAlert = false
    @State private var isShowRevokeAllAlert = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let errorMessage {
                ContentUnavailableView {
                    Label("Error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(errorMessage)
                } actions: {
                    Button("Retry") {
                        Task { await loadSessions() }
                    }
                }
            } else if sessions.isEmpty {
                ContentUnavailableView {
                    Label("No Sessions", systemImage: "person.badge.key")
                } description: {
                    Text("No active sessions found.")
                }
            } else {
                sessionList
            }
        }
        .navigationTitle("Sessions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(role: .destructive) {
                    isShowRevokeAllAlert = true
                } label: {
                    Label("Revoke All", systemImage: "trash")
                }
            }
        }
        .alert("Delete Session", isPresented: $isShowDeleteAlert, presenting: sessionToDelete) { session in
            Button("Delete", role: .destructive) {
                guard let token = session.session else { return }
                Task {
                    try? await AdminHandler.removeSession(session: token)
                    await loadSessions()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { session in
            Text("Are you sure you want to delete this session?")
        }
        .alert("Revoke All Sessions", isPresented: $isShowRevokeAllAlert) {
            Button("Revoke All", role: .destructive) {
                Task {
                    try? await AdminHandler.removeAllSessions()
                    await loadSessions()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will log out all sessions including the current one. You will need to log in again.")
        }
        .task { await loadSessions() }
    }

    private var sessionList: some View {
        List {
            ForEach(sessions) { session in
                SessionRow(session: session, isCurrent: session.session == currentSession)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        if session.session != currentSession {
                            Button(role: .destructive) {
                                sessionToDelete = session
                                isShowDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .contextMenu {
                        if session.session != currentSession {
                            Button(role: .destructive) {
                                sessionToDelete = session
                                isShowDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
            }
        }
    }

    private func loadSessions() async {
        do {
            let result = try await AdminHandler.getSessions()
            withAnimation {
                currentSession = result.current
                sessions = result.sessions.sorted {
                    ($0.createdAt ?? "") > ($1.createdAt ?? "")
                }
                isLoading = false
                errorMessage = nil
            }
        } catch {
            withAnimation {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

// MARK: - Session Row

private struct SessionRow: View {
    let session: SessionInfo
    let isCurrent: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if isCurrent {
                Text("Current")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.blue.opacity(0.15))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }
            
            HStack {
                Text(session.session ?? "Session")
                    .font(.caption.bold().monospaced())

                Spacer()

                if let method = session.loginMethod, !method.isEmpty {
                    Text(method)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                if let ip = session.ip, !ip.isEmpty {
                    HStack(spacing: 2) {
                        Image(systemName: "network")
                        Text(ip)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                if let latestIp = session.latestIp, !latestIp.isEmpty, latestIp != session.ip {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.right")
                        Text(latestIp)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            if let created = session.createdAt {
                HStack(spacing: 2) {
                    Image(systemName: "clock")
                    Text(formatDate(created))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            if let expires = session.expires {
                HStack(spacing: 2) {
                    Image(systemName: "hourglass")
                    Text(formatDate(expires))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            if let latestOnline = session.latestOnline {
                HStack(spacing: 2) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                    Text("Last seen \(formatRelativeDate(latestOnline))")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
        return dateString
    }

    private func formatRelativeDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = formatter.date(from: dateString)
        if date == nil {
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: dateString)
        }
        guard let date else { return dateString }

        let relative = RelativeDateTimeFormatter()
        relative.unitsStyle = .abbreviated
        return relative.localizedString(for: date, relativeTo: .now)
    }
}
