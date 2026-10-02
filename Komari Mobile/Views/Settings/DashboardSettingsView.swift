//
//  DashboardSettingsView.swift
//  Komari Mobile
//
//  Created by Takuma Kirishima on 2/15/26.
//

import SwiftUI

struct DashboardSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(KMState.self) private var state
    @State private var link: String = KMCore.getKomariDashboardLink()
    @State private var username: String = KMCore.getKomariDashboardUsername()
    @State private var password: String = KMCore.getKomariDashboardPassword()
    @State private var apiKey: String = KMCore.getKomariAPIKey()
    @State private var isSSLEnabled: Bool = KMCore.getIsKomariDashboardSSLEnabled()
    @State private var useAPIKey: Bool = !KMCore.getKomariAPIKey().isEmpty
    @State private var testResult: String = ""
    @State private var isTesting: Bool = false
    @State private var isShowTFAPrompt: Bool = false
    @State private var tfaCode: String = ""

    var body: some View {
        Form {
            Section {
                TextField("Dashboard Link", text: $link)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onChange(of: link) {
                        link = link.replacingOccurrences(of: "^(http|https)://", with: "", options: .regularExpression)
                    }
            } header: {
                Text("Dashboard Info")
            } footer: {
                Text("Dashboard Link Example: komari.hidandelion.com")
            }

            Section("Authentication") {
                Toggle("Use API Key", isOn: $useAPIKey)
                    .onChange(of: useAPIKey) {
                        if useAPIKey {
                            username = ""
                            password = ""
                        } else {
                            apiKey = ""
                        }
                    }

                if useAPIKey {
                    SecureField("API Key", text: $apiKey)
                } else {
                    TextField("Username", text: $username)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    SecureField("Password", text: $password)
                }
            }

            Section {
                Toggle("Enable SSL", isOn: $isSSLEnabled)
            }

            Section {
                Button("Save & Apply") {
                    KMCore.saveNewDashboardConfigurations(
                        dashboardLink: link,
                        dashboardUsername: username,
                        dashboardPassword: password,
                        dashboardSSLEnabled: isSSLEnabled,
                        apiKey: apiKey
                    )
                    state.loadDashboard()
                    dismiss()
                }
            }
            
            Section {
                Button("Test Connection") {
                    testConnection()
                }
                .disabled(isTesting)
            } footer: {
                if !testResult.isEmpty {
                    Text(testResult)
                        .font(.caption)
                        .foregroundStyle(testResult.contains("Success") ? .green : .red)
                }
            }
        }
        .navigationTitle("Dashboard Settings")
        .alert("Two-Factor Authentication", isPresented: $isShowTFAPrompt) {
            TextField("6-digit code", text: $tfaCode)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
            Button("Test Connection") {
                testConnection(tfaCode: tfaCode)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter your two-factor authentication code to sign in.")
        }
    }

    private func testConnection(tfaCode: String? = nil) {
        isTesting = true
        testResult = ""
        // Temporarily save to test
        KMCore.saveNewDashboardConfigurations(
            dashboardLink: link,
            dashboardUsername: username,
            dashboardPassword: password,
            dashboardSSLEnabled: isSSLEnabled,
            apiKey: apiKey
        )
        Task {
            do {
                if !username.isEmpty && !password.isEmpty {
                    try await AuthHandler.login(username: username, password: password, tfaCode: tfaCode)
                }
                _ = try await AuthHandler.getMe()
                testResult = "Success! Connection verified."
            } catch KomariError.twoFactorRequired {
                self.tfaCode = ""
                isShowTFAPrompt = true
            } catch {
                testResult = "Error: \(error.localizedDescription)"
            }
            isTesting = false
        }
    }
}
