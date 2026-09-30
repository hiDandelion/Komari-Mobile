//
//  NotificationChannelResponse.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 9/29/26.
//

import Foundation

/// A notification channel registered on the dashboard (`admin:listNotificationChannels`).
struct NotificationChannel: Codable, Identifiable, Hashable {
    let id: String
    let configuration: ManagedConfiguration?

    var displayName: String {
        configuration?.name?.localized ?? id
    }
}

/// Response of `admin:getNotificationChannelConfiguration`.
struct NotificationChannelConfiguration: Codable {
    let configuration: ManagedConfiguration?
    let data: [String: JSONValue]?
}

/// Declarative form description shared by themes, plugins and notification channels.
struct ManagedConfiguration: Codable, Hashable {
    let type: String?
    let icon: String?
    let name: LocalizedText?
    let data: [ManagedConfigurationItem]?

    enum CodingKeys: String, CodingKey {
        case type, icon, name, data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        icon = try container.decodeIfPresent(String.self, forKey: .icon)
        name = try container.decodeIfPresent(LocalizedText.self, forKey: .name)
        // Non-managed configurations carry arbitrary data here; only managed item lists are rendered.
        data = try? container.decodeIfPresent([ManagedConfigurationItem].self, forKey: .data)
    }
}

struct ManagedConfigurationItem: Codable, Hashable, Identifiable {
    let key: String
    let name: LocalizedText?
    let required: Bool?
    /// string, number, select, switch, title, textbox, richtext, nodes, pingtasks
    let type: String
    let options: String?
    let defaultValue: JSONValue?
    let help: LocalizedText?

    var id: String { key.isEmpty ? "title-\(name?.localized ?? "")" : key }

    var displayName: String {
        name?.localized ?? key
    }

    var selectOptions: [String] {
        (options ?? "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    enum CodingKeys: String, CodingKey {
        case key, name, required, type, options, help
        case defaultValue = "default"
    }
}

/// A label that is either a plain string or a `{ "en": "...", "zh_CN": "..." }` dictionary.
struct LocalizedText: Codable, Hashable {
    let values: [String: String]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            values = ["": string]
        } else {
            values = (try? container.decode([String: String].self)) ?? [:]
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if values.count == 1, let plain = values[""] {
            try container.encode(plain)
        } else {
            try container.encode(values)
        }
    }

    /// Best match for the device language, falling back to English or any value.
    var localized: String? {
        if let plain = values[""] { return plain }
        let language = Locale.current.language
        let code = language.languageCode?.identifier ?? "en"
        var candidates: [String] = []
        if code == "zh" {
            let isTraditional = language.script?.identifier == "Hant"
            candidates = isTraditional ? ["zh_TW", "zh-TW", "zh_HK", "zh-Hant"] : ["zh_CN", "zh-CN", "zh-Hans"]
        }
        candidates += [code, "en", "en_US", "en-US"]
        for candidate in candidates {
            if let value = values[candidate], !value.isEmpty { return value }
        }
        if let match = values.first(where: { $0.key.hasPrefix(code) }) {
            return match.value
        }
        return values.values.sorted().first
    }
}

/// Arbitrary JSON value, used for dynamically typed configuration values.
enum JSONValue: Codable, Hashable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case array([JSONValue])
    case object([String: JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            self = .object(try container.decode([String: JSONValue].self))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }

    /// Text representation for editing in a text field.
    var stringValue: String {
        switch self {
        case .string(let value):
            return value
        case .number(let value):
            return value.rounded() == value && abs(value) < 1e15 ? String(Int64(value)) : String(value)
        case .bool(let value):
            return value ? "true" : "false"
        case .null:
            return ""
        case .array, .object:
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
            guard let data = try? encoder.encode(self) else { return "" }
            return String(decoding: data, as: UTF8.self)
        }
    }

    var boolValue: Bool {
        switch self {
        case .bool(let value): return value
        case .number(let value): return value != 0
        case .string(let value): return value.lowercased() == "true" || value == "1"
        default: return false
        }
    }

    /// Selected identifiers of a `nodes`/`pingtasks` selector, stored as an array or a JSON-array string.
    var identifierList: [String] {
        switch self {
        case .array(let values):
            return values.map(\.stringValue)
        case .string(let text):
            guard let data = text.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([JSONValue].self, from: data) else { return [] }
            return decoded.map(\.stringValue)
        default:
            return []
        }
    }
}
