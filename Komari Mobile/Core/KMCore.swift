//
//  KMCore.swift
//  Komari Mobile
//
//  Created by Takuma Kirishima on 2/15/26.
//

import Foundation
import Security

class KMCore {
    static let KMDashboardLink = "KMDashboardLink"
    static let KMDashboardSSLEnabled = "KMDashboardSSLEnabled"
    static let KMDashboardUsername = "KMDashboardUsername"

    static let appGroupIdentifier = "group.com.argsment.Komari-Mobile"

    static let userDefaults: UserDefaults = UserDefaults(suiteName: appGroupIdentifier)!

    /// Shared with the widget so it reuses the app's session: it cannot sign in by itself when
    /// the account has 2FA enabled.
    static let cookieStorage = HTTPCookieStorage.sharedCookieStorage(forGroupContainerIdentifier: appGroupIdentifier)

    static let userGuideURL: URL = URL(string: "https://support.argsment.com/komari-mobile/user-guide")!

    static func debugLog(_ message: Any) -> Any? {
        #if DEBUG
        print("Debug - \(message)")
        #endif
        return nil
    }

    static var isKomariDashboardConfigured: Bool {
        let link = getKomariDashboardLink()
        if link.isEmpty { return false }
        let hasCredentials = !getKomariDashboardUsername().isEmpty && !getKeychainValue(forKey: "KMDashboardPassword").isEmpty
        let hasAPIKey = !getKeychainValue(forKey: "KMAPIKey").isEmpty
        return hasCredentials || hasAPIKey
    }

    // MARK: - App Initialization
    static func registerUserDefaults() {
        let defaultValues: [String: Any] = [
            KMDashboardLink: "",
            KMDashboardSSLEnabled: true,
            KMDashboardUsername: ""
        ]
        userDefaults.register(defaults: defaultValues)
    }

    /// Earlier versions kept cookies in the app's own storage. Copy them over once so existing
    /// sessions survive the move to `cookieStorage` without signing in (and entering a 2FA code) again.
    static func migrateCookiesToAppGroup() {
        let migratedKey = "KMCookiesMigratedToAppGroup"
        guard !userDefaults.bool(forKey: migratedKey) else { return }
        for cookie in HTTPCookieStorage.shared.cookies ?? [] {
            cookieStorage.setCookie(cookie)
        }
        userDefaults.set(true, forKey: migratedKey)
    }

    // MARK: - Save Configuration
    static func saveNewDashboardConfigurations(dashboardLink: String, dashboardUsername: String, dashboardPassword: String, dashboardSSLEnabled: Bool, apiKey: String) {
        userDefaults.set(dashboardLink, forKey: KMDashboardLink)
        userDefaults.set(dashboardUsername, forKey: KMDashboardUsername)
        userDefaults.set(dashboardSSLEnabled, forKey: KMDashboardSSLEnabled)

        setKeychainValue(dashboardPassword, forKey: "KMDashboardPassword")
        setKeychainValue(apiKey, forKey: "KMAPIKey")
    }

    /// Keeps the saved credentials in sync after the account itself is changed in the app.
    static func setKomariDashboardUsername(_ username: String) {
        userDefaults.set(username, forKey: KMDashboardUsername)
    }

    static func setKomariDashboardPassword(_ password: String) {
        setKeychainValue(password, forKey: "KMDashboardPassword")
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

    static func getWebSocketURL(endpoint: String) -> URL? {
        let link = getKomariDashboardLink()
        let scheme = getIsKomariDashboardSSLEnabled() ? "wss" : "ws"
        return URL(string: "\(scheme)://\(link)\(endpoint)")
    }

    // MARK: - Keychain Helpers
    private static func setKeychainValue(_ value: String, forKey key: String) {
        let data = Data(value.utf8)

        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.argsment.Komari-Mobile"
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        if !value.isEmpty {
            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
                kSecAttrService as String: "com.argsment.Komari-Mobile",
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
            ]
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    private static func getKeychainValue(forKey key: String) -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.argsment.Komari-Mobile",
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
