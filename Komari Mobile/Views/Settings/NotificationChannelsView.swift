//
//  NotificationChannelsView.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 9/29/26.
//

import SwiftUI

/// Where dashboard notifications are delivered (Komari 1.5+): master switch, active channel,
/// channel settings, message template and a test message.
struct NotificationChannelsView: View {
    private static let noChannelID = "none"
    private static let defaultTemplate = "{{emoji}}{{emoji}}{{emoji}}\nEvent: {{event}}\nClients: {{client}}\nMessage: {{message}}\nTime: {{time}}"

    @State private var isLoading = true
    @State private var errorMessage: String?

    @State private var channels: [NotificationChannel] = []
    @State private var isEnabled = false
    @State private var selectedChannelID = NotificationChannelsView.noChannelID
    @State private var template = ""
    @State private var savedTemplate = ""

    @State private var isSendingTest = false
    @State private var resultMessage: String?
    @State private var isShowResult = false

    private var selectedChannel: NotificationChannel? {
        channels.first { $0.id == selectedChannelID }
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
                        Task { await load() }
                    }
                }
            } else {
                form
            }
        }
        .navigationTitle("Notification Channel")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .alert("Notification Channel", isPresented: $isShowResult) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(resultMessage ?? "")
        }
    }

    private var form: some View {
        Form {
            Section {
                Toggle("Enable Notifications", isOn: Binding(
                    get: { isEnabled },
                    set: { newValue in
                        isEnabled = newValue
                        save(["notification_enabled": newValue])
                    }
                ))
            } footer: {
                Text("Offline, expiration, login and traffic alerts are sent through the selected channel. More channels can be added with dashboard plugins.")
            }

            Section("Channel") {
                // Saved only on user changes, so loading never rewrites the stored channel.
                Picker("Channel", selection: Binding(
                    get: { selectedChannelID },
                    set: { newValue in
                        selectedChannelID = newValue
                        save(["notification_method": newValue])
                    }
                )) {
                    Text("None").tag(Self.noChannelID)
                    ForEach(channels) { channel in
                        Text(channel.displayName).tag(channel.id)
                    }
                }

                if let selectedChannel {
                    NavigationLink {
                        NotificationChannelConfigView(channel: selectedChannel)
                    } label: {
                        Text("Configure \(selectedChannel.displayName)")
                    }
                }
            }

            Section {
                TextEditor(text: $template)
                    .font(.callout.monospaced())
                    .frame(minHeight: 140)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                if template != savedTemplate {
                    Button("Save Template") {
                        let newTemplate = template
                        save(["notification_template": newTemplate]) {
                            savedTemplate = newTemplate
                        }
                    }
                }
                Button("Restore Default Template") {
                    template = Self.defaultTemplate
                }
                .disabled(template == Self.defaultTemplate)
            } header: {
                Text("Message Template")
            } footer: {
                Text("Placeholders: {{emoji}}, {{event}}, {{client}}, {{message}}, {{time}}")
            }

            Section {
                Button {
                    sendTest()
                } label: {
                    if isSendingTest {
                        ProgressView()
                    } else {
                        Text("Send Test Notification")
                    }
                }
                .disabled(isSendingTest || !isEnabled || selectedChannel == nil)
            }
        }
    }

    private func load() async {
        do {
            async let settingsTask = AdminHandler.getSettings()
            async let channelsTask = AdminHandler.listNotificationChannels()
            let (settings, fetchedChannels) = try await (settingsTask, channelsTask)
            withAnimation {
                channels = fetchedChannels
                isEnabled = settings.notificationEnabled ?? false
                let method = settings.notificationMethod ?? Self.noChannelID
                // A channel from an uninstalled plugin no longer exists; show it as "None".
                selectedChannelID = fetchedChannels.contains { $0.id == method } ? method : Self.noChannelID
                template = settings.notificationTemplate ?? Self.defaultTemplate
                savedTemplate = template
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

    private func save(_ changes: [String: Any], onSuccess: (() -> Void)? = nil) {
        Task {
            do {
                try await AdminHandler.updateSettings(changes: changes)
                onSuccess?()
            } catch {
                resultMessage = error.localizedDescription
                isShowResult = true
            }
        }
    }

    private func sendTest() {
        isSendingTest = true
        Task {
            do {
                try await AdminHandler.sendTestNotification()
                resultMessage = String(localized: "Test notification sent.")
            } catch {
                resultMessage = error.localizedDescription
            }
            isSendingTest = false
            isShowResult = true
        }
    }
}

/// Form generated from a channel's managed configuration declaration.
struct NotificationChannelConfigView: View {
    @Environment(KMState.self) private var state
    @Environment(\.dismiss) private var dismiss

    let channel: NotificationChannel

    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var items: [ManagedConfigurationItem] = []
    @State private var textValues: [String: String] = [:]
    @State private var boolValues: [String: Bool] = [:]
    @State private var selectionValues: [String: Set<String>] = [:]
    @State private var isSaving = false
    @State private var saveError: String?

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
                        Task { await load() }
                    }
                }
            } else if items.isEmpty {
                ContentUnavailableView {
                    Label("No Settings", systemImage: "slider.horizontal.3")
                } description: {
                    Text("This channel has no settings.")
                }
            } else {
                form
            }
        }
        .navigationTitle(channel.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isLoading, errorMessage == nil, !items.isEmpty {
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            save()
                        }
                        .disabled(!isValid)
                    }
                }
            }
        }
        .task { await load() }
    }

    /// Items grouped into sections, split at `title` items.
    private var sections: [(title: String?, items: [ManagedConfigurationItem])] {
        var result: [(title: String?, items: [ManagedConfigurationItem])] = [(nil, [])]
        for item in items {
            if item.type == "title" {
                result.append((item.displayName, []))
            } else {
                result[result.count - 1].items.append(item)
            }
        }
        return result.filter { !$0.items.isEmpty }
    }

    private var form: some View {
        Form {
            ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                Section {
                    ForEach(section.items) { item in
                        field(for: item)
                    }
                } header: {
                    if let title = section.title {
                        Text(title)
                    }
                }
            }

            if let saveError {
                Section {
                    Text(saveError)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    @ViewBuilder
    private func field(for item: ManagedConfigurationItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            switch item.type {
            case "switch":
                Toggle(item.displayName, isOn: boolBinding(item.key))
            case "select":
                Picker(item.displayName, selection: textBinding(item.key)) {
                    ForEach(item.selectOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
            case "textbox", "richtext":
                Text(label(for: item))
                    .font(.subheadline)
                TextEditor(text: textBinding(item.key))
                    .font(.callout.monospaced())
                    .frame(minHeight: 100)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            case "nodes":
                NavigationLink {
                    SelectionListView(
                        title: item.displayName,
                        options: state.nodes.map { ($0.uuid, $0.name.isEmpty ? $0.uuid : $0.name) },
                        selection: selectionBinding(item.key)
                    )
                } label: {
                    LabeledContent(label(for: item), value: "\(selectionValues[item.key]?.count ?? 0)")
                }
            case "pingtasks":
                PingTaskSelectionField(title: label(for: item), selection: selectionBinding(item.key))
            case "number":
                LabeledContent(label(for: item)) {
                    TextField(item.displayName, text: textBinding(item.key))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            default:
                LabeledContent(label(for: item)) {
                    TextField(item.displayName, text: textBinding(item.key))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .multilineTextAlignment(.trailing)
                }
            }

            if let help = item.help?.localized, !help.isEmpty {
                Text(help)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func label(for item: ManagedConfigurationItem) -> String {
        item.required == true ? "\(item.displayName) *" : item.displayName
    }

    private var isValid: Bool {
        items.allSatisfy { item in
            guard item.required == true else { return true }
            switch item.type {
            case "switch", "title":
                return true
            case "nodes", "pingtasks":
                return !(selectionValues[item.key] ?? []).isEmpty
            case "number":
                return Double(textValues[item.key] ?? "") != nil
            default:
                return !(textValues[item.key] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
        }
    }

    private func textBinding(_ key: String) -> Binding<String> {
        Binding(get: { textValues[key] ?? "" }, set: { textValues[key] = $0 })
    }

    private func boolBinding(_ key: String) -> Binding<Bool> {
        Binding(get: { boolValues[key] ?? false }, set: { boolValues[key] = $0 })
    }

    private func selectionBinding(_ key: String) -> Binding<Set<String>> {
        Binding(get: { selectionValues[key] ?? [] }, set: { selectionValues[key] = $0 })
    }

    private func load() async {
        do {
            let result = try await AdminHandler.getNotificationChannelConfiguration(id: channel.id)
            let declared = (result.configuration ?? channel.configuration)?.data ?? []
            let values = result.data ?? [:]
            withAnimation {
                items = declared
                for item in declared where !item.key.isEmpty {
                    let value = values[item.key] ?? item.defaultValue ?? .null
                    switch item.type {
                    case "switch":
                        boolValues[item.key] = value.boolValue
                    case "nodes", "pingtasks":
                        selectionValues[item.key] = Set(value.identifierList)
                    case "select":
                        let text = value.stringValue
                        textValues[item.key] = text.isEmpty ? (item.selectOptions.first ?? "") : text
                    default:
                        textValues[item.key] = value.stringValue
                    }
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

    private func save() {
        var values: [String: JSONValue] = [:]
        for item in items where !item.key.isEmpty {
            switch item.type {
            case "title":
                continue
            case "switch":
                values[item.key] = .bool(boolValues[item.key] ?? false)
            case "number":
                values[item.key] = Double(textValues[item.key] ?? "").map(JSONValue.number) ?? .number(0)
            case "nodes", "pingtasks":
                // Selectors are stored as a JSON-array string (ping task ids as numbers).
                let selected = (selectionValues[item.key] ?? []).sorted()
                let array: [JSONValue] = item.type == "pingtasks"
                    ? selected.compactMap { Double($0).map(JSONValue.number) }
                    : selected.map(JSONValue.string)
                values[item.key] = .string(JSONValue.array(array).stringValue)
            default:
                values[item.key] = .string(textValues[item.key] ?? "")
            }
        }

        isSaving = true
        saveError = nil
        Task {
            do {
                try await AdminHandler.setNotificationChannelConfiguration(id: channel.id, values: values)
                dismiss()
            } catch {
                saveError = error.localizedDescription
            }
            isSaving = false
        }
    }
}

/// Multi-select list used by `nodes`/`pingtasks` selector fields.
private struct SelectionListView: View {
    let title: String
    let options: [(id: String, name: String)]
    @Binding var selection: Set<String>

    var body: some View {
        List {
            ForEach(options, id: \.id) { option in
                Button {
                    if selection.contains(option.id) {
                        selection.remove(option.id)
                    } else {
                        selection.insert(option.id)
                    }
                } label: {
                    HStack {
                        Text(option.name)
                            .foregroundStyle(.primary)
                        Spacer()
                        if selection.contains(option.id) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.accent)
                        }
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Ping tasks are fetched lazily, since only some channels declare such a field.
private struct PingTaskSelectionField: View {
    let title: String
    @Binding var selection: Set<String>
    @State private var tasks: [PingTask] = []

    var body: some View {
        NavigationLink {
            SelectionListView(
                title: title,
                options: tasks.compactMap { task in task.id.map { (String($0), task.displayName) } },
                selection: $selection
            )
        } label: {
            LabeledContent(title, value: "\(selection.count)")
        }
        .task {
            tasks = (try? await AdminHandler.getPingTasks()) ?? []
        }
    }
}
