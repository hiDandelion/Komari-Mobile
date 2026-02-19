//
//  WidgetKMCore.swift
//  Komari Widget
//
//  Created by Junhui Lou on 2/19/26.
//

import Foundation
import Security

enum WidgetKMCore {
    // MARK: - Constants
    private static let KMDashboardLink = "KMDashboardLink"
    private static let KMDashboardSSLEnabled = "KMDashboardSSLEnabled"
    private static let KMDashboardUsername = "KMDashboardUsername"

    private static let keychainService = "com.argsment.Komari-Mobile"
    private static let keychainAccessGroup = "C7AS5D38Q8.com.argsment.Komari-Mobile"

    static let userDefaults: UserDefaults = UserDefaults(suiteName: "group.com.argsment.Komari-Mobile")!

    // MARK: - Configuration Check
    static var isConfigured: Bool {
        let link = getKomariDashboardLink()
        if link.isEmpty { return false }
        let hasCredentials = !getKomariDashboardUsername().isEmpty && !getKeychainValue(forKey: "KMDashboardPassword").isEmpty
        let hasAPIKey = !getKeychainValue(forKey: "KMAPIKey").isEmpty
        return hasCredentials || hasAPIKey
    }

    // MARK: - Get Configuration
    static func getKomariDashboardLink() -> String {
        return userDefaults.string(forKey: KMDashboardLink) ?? ""
    }

    static func getKomariDashboardUsername() -> String {
        return userDefaults.string(forKey: KMDashboardUsername) ?? ""
    }

    static func getKomariDashboardPassword() -> String {
        return getKeychainValue(forKey: "KMDashboardPassword")
    }

    static func getIsKomariDashboardSSLEnabled() -> Bool {
        return userDefaults.bool(forKey: KMDashboardSSLEnabled)
    }

    static func getKomariAPIKey() -> String {
        return getKeychainValue(forKey: "KMAPIKey")
    }

    static func getBaseURL() -> String {
        let link = getKomariDashboardLink()
        let scheme = getIsKomariDashboardSSLEnabled() ? "https" : "http"
        return "\(scheme)://\(link)"
    }

    static func getAPIURL(endpoint: String) -> URL? {
        return URL(string: "\(getBaseURL())\(endpoint)")
    }

    // MARK: - Keychain (Read-Only)
    private static func getKeychainValue(forKey key: String) -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: keychainService,
            kSecAttrAccessGroup as String: keychainAccessGroup,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess, let data = item as? Data else {
            return ""
        }

        return String(data: data, encoding: .utf8) ?? ""
    }
}
