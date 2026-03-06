//
//  LogsView.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 3/7/26.
//

import SwiftUI

struct LogsView: View {
    @State private var logs: [AuditLog] = []
    @State private var total = 0
    @State private var page = 1
    @State private var limit = 20
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedLog: AuditLog?

    private var totalPages: Int {
        max(1, Int(ceil(Double(total) / Double(limit))))
    }

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
                        Task { await loadLogs() }
                    }
                }
            } else if logs.isEmpty {
                ContentUnavailableView {
                    Label("No Logs", systemImage: "doc.text")
                } description: {
                    Text("No audit logs found.")
                }
            } else {
                logList
            }
        }
        .navigationTitle("Logs")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedLog) { log in
            LogDetailView(log: log)
        }
        .task { await loadLogs() }
    }

    private var logList: some View {
        List {
            ForEach(logs) { log in
                LogRow(log: log)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedLog = log
                    }
            }

            if totalPages > 1 {
                paginationControls
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            }
        }
    }

    private var paginationControls: some View {
        HStack(spacing: 8) {
            Spacer()

            Button {
                page = max(1, page - 1)
                Task { await loadLogs() }
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(page <= 1)

            Text("\(page) / \(totalPages)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()

            Button {
                page = min(totalPages, page + 1)
                Task { await loadLogs() }
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(page >= totalPages)

            Spacer()
        }
        .padding(.vertical, 12)
    }

    private func loadLogs() async {
        if logs.isEmpty {
            isLoading = true
        }
        do {
            let result = try await AdminHandler.getLogs(limit: limit, page: page)
            withAnimation {
                logs = result.logs
                total = result.total
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

// MARK: - Log Row

private struct LogRow: View {
    let log: AuditLog

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if let msgType = log.msgType, !msgType.isEmpty {
                    Text(msgType)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(typeColor(msgType).opacity(0.15))
                        .foregroundStyle(typeColor(msgType))
                        .clipShape(Capsule())
                }

                Spacer()

                if let id = log.id {
                    Text("#\(id)")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }

            if let message = log.message, !message.isEmpty {
                Text(message)
                    .font(.subheadline)
                    .lineLimit(2)
            }

            if let ip = log.ip, !ip.isEmpty {
                HStack(spacing: 2) {
                    Image(systemName: "network")
                    Text(ip)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            if let time = log.time {
                HStack(spacing: 2) {
                    Image(systemName: "clock")
                    Text(formatDate(time))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func typeColor(_ type: String) -> Color {
        switch type.lowercased() {
        case "login": return .blue
        case "error": return .red
        case "warning": return .orange
        default: return .secondary
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
        return dateString
    }
}

// MARK: - Log Detail

private struct LogDetailView: View {
    let log: AuditLog
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if let id = log.id {
                    detailRow("ID", value: "\(id)")
                }
                if let ip = log.ip, !ip.isEmpty {
                    detailRow("IP", value: ip)
                }
                if let uuid = log.uuid, !uuid.isEmpty {
                    detailRow("UUID", value: uuid)
                }
                if let msgType = log.msgType, !msgType.isEmpty {
                    detailRow("Type", value: msgType)
                }
                if let message = log.message, !message.isEmpty {
                    Section("Message") {
                        Text(message)
                            .font(.subheadline)
                            .textSelection(.enabled)
                    }
                }
                if let time = log.time {
                    detailRow("Time", value: formatDate(time))
                }
            }
            .navigationTitle("Log Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func detailRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.monospaced())
                .textSelection(.enabled)
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
        return dateString
    }
}
