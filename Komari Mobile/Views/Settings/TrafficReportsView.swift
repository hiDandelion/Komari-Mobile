//
//  TrafficReportsView.swift
//  Komari Mobile
//
//  Created by Takuma Kirishima on 7/2/26.
//

import SwiftUI

struct TrafficReportsView: View {
    @Environment(KMState.self) private var state

    @State private var reports: [TrafficReportNotification] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    @State private var nodeToEdit: NodeData?
    @State private var editEnabled = false
    @State private var editDaily = false
    @State private var editWeekly = false
    @State private var editMonthly = false

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
                        Task { await loadReports() }
                    }
                }
            } else if state.nodes.isEmpty {
                ContentUnavailableView {
                    Label("No Servers", systemImage: "server.rack")
                } description: {
                    Text("No servers available to configure traffic reports.")
                }
            } else {
                nodeList
            }
        }
        .navigationTitle("Traffic Reports")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $nodeToEdit) { node in
            TrafficReportFormView(
                node: node,
                enabled: editEnabled,
                daily: editDaily,
                weekly: editWeekly,
                monthly: editMonthly
            ) { enabled, daily, weekly, monthly in
                let entry: [String: Any] = [
                    "client": node.uuid,
                    "enable": enabled,
                    "daily": daily,
                    "weekly": weekly,
                    "monthly": monthly
                ]
                try await AdminHandler.editTrafficReportNotifications(entries: [entry])
                await loadReports()
            }
        }
        .task { await loadReports() }
    }

    private var nodeList: some View {
        List {
            ForEach(state.nodes) { node in
                let report = reports.first { $0.client == node.uuid }
                TrafficReportRow(node: node, report: report)
                    .contextMenu {
                        Button {
                            prepareEdit(node: node, report: report)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button {
                            prepareEdit(node: node, report: report)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                    }
            }
        }
    }

    private func prepareEdit(node: NodeData, report: TrafficReportNotification?) {
        editEnabled = report?.enable ?? false
        editDaily = report?.daily ?? false
        editWeekly = report?.weekly ?? false
        editMonthly = report?.monthly ?? false
        nodeToEdit = node
    }

    private func loadReports() async {
        do {
            let fetched = try await AdminHandler.getTrafficReportNotifications()
            withAnimation {
                reports = fetched
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

// MARK: - Row

private struct TrafficReportRow: View {
    let node: NodeData
    let report: TrafficReportNotification?

    private var isEnabled: Bool {
        report?.enable ?? false
    }

    private var cadenceText: String {
        var parts: [String] = []
        if report?.daily == true { parts.append(String(localized: "TrafficReport.Daily", defaultValue: "Daily")) }
        if report?.weekly == true { parts.append(String(localized: "TrafficReport.Weekly", defaultValue: "Weekly")) }
        if report?.monthly == true { parts.append(String(localized: "TrafficReport.Monthly", defaultValue: "Monthly")) }
        return parts.isEmpty ? "—" : parts.joined(separator: " / ")
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(node.name.isEmpty ? node.uuid : node.name)
                    .font(.headline)

                HStack {
                    Image(systemName: "calendar.badge.clock")
                    Text(cadenceText)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text(isEnabled ? String(localized: "Enabled") : String(localized: "Disabled"))
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(isEnabled ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                .foregroundStyle(isEnabled ? .green : .red)
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Form

private struct TrafficReportFormView: View {
    @Environment(\.dismiss) private var dismiss

    let node: NodeData
    @State var enabled: Bool
    @State var daily: Bool
    @State var weekly: Bool
    @State var monthly: Bool
    let onSave: (Bool, Bool, Bool, Bool) async throws -> Void

    @State private var isSaving = false
    @State private var errorMessage: String?

    init(node: NodeData, enabled: Bool, daily: Bool, weekly: Bool, monthly: Bool, onSave: @escaping (Bool, Bool, Bool, Bool) async throws -> Void) {
        self.node = node
        self._enabled = State(initialValue: enabled)
        self._daily = State(initialValue: daily)
        self._weekly = State(initialValue: weekly)
        self._monthly = State(initialValue: monthly)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent {
                        Text(node.name.isEmpty ? node.uuid : node.name)
                            .font(.headline)
                    } label: {
                        Text("Server")
                    }
                }

                Section {
                    Toggle("Enabled", isOn: $enabled)
                }

                Section {
                    Toggle(String(localized: "TrafficReport.Daily", defaultValue: "Daily"), isOn: $daily)
                    Toggle(String(localized: "TrafficReport.Weekly", defaultValue: "Weekly"), isOn: $weekly)
                    Toggle(String(localized: "TrafficReport.Monthly", defaultValue: "Monthly"), isOn: $monthly)
                } header: {
                    Text("Report Type")
                } footer: {
                    if enabled && !hasCadence {
                        Text("Select at least one report type.")
                            .foregroundStyle(.red)
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Edit Traffic Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if #available(iOS 26.0, *) {
                        Button(role: .cancel) {
                            dismiss()
                        } label: {
                            Label("Cancel", systemImage: "xmark")
                        }
                    } else {
                        Button("Cancel", role: .cancel) {
                            dismiss()
                        }
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        if #available(iOS 26.0, *) {
                            Button(role: .confirm) {
                                save()
                            } label: {
                                Label("Done", systemImage: "checkmark")
                            }
                            .disabled(!isValid)
                        } else {
                            Button("Done") {
                                save()
                            }
                            .disabled(!isValid)
                        }
                    }
                }
            }
        }
    }

    private var hasCadence: Bool {
        daily || weekly || monthly
    }

    private var isValid: Bool {
        !enabled || hasCadence
    }

    private func save() {
        isSaving = true
        errorMessage = nil

        Task {
            do {
                try await onSave(enabled, daily, weekly, monthly)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}
