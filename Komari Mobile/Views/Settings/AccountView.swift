//
//  AccountView.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 3/7/26.
//

import SwiftUI

struct AccountView: View {
    @State private var account: MeResponseData?
    @State private var isLoading = true
    @State private var errorMessage: String?

    // Username
    @State private var username = ""
    @State private var isSavingUsername = false
    @State private var usernameMessage: String?
    @State private var usernameSuccess = false

    // Password
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isSavingPassword = false
    @State private var passwordMessage: String?
    @State private var passwordSuccess = false

    // 2FA
    @State private var isShow2FASetupSheet = false
    @State private var isShowDisable2FAAlert = false
    @State private var isDisabling2FA = false

    // OAuth2
    @State private var isShowUnbindAlert = false
    @State private var isUnbinding = false

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
                        Task { await loadAccount() }
                    }
                }
            } else {
                accountForm
            }
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadAccount() }
    }

    private var accountForm: some View {
        Form {
            usernameSection
            passwordSection
            twoFactorSection
            if let account, let ssoId = account.ssoId, !ssoId.isEmpty {
                oauthSection
            }
        }
        .sheet(isPresented: $isShow2FASetupSheet) {
            TwoFactorSetupView {
                await loadAccount()
            }
        }
        .alert("Disable 2FA", isPresented: $isShowDisable2FAAlert) {
            Button("Disable", role: .destructive) {
                Task { await disable2FA() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to disable two-factor authentication?")
        }
        .alert("Unbind SSO", isPresented: $isShowUnbindAlert) {
            Button("Unbind", role: .destructive) {
                Task { await unbindOAuth2() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let account, let ssoId = account.ssoId {
                let platform = ssoDisplayName(ssoId)
                Text("After unbinding, you will not be able to log in with your \(platform) account. Are you sure?")
            } else {
                Text("Are you sure you want to unbind your SSO account?")
            }
        }
    }

    // MARK: - Username

    private var usernameSection: some View {
        Section("Username") {
            TextField("Username", text: $username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .disabled(isSavingUsername)

            if let usernameMessage {
                Text(usernameMessage)
                    .font(.caption)
                    .foregroundStyle(usernameSuccess ? .green : .red)
            }

            Button {
                Task { await saveUsername() }
            } label: {
                if isSavingUsername {
                    ProgressView()
                } else {
                    Text("Save Username")
                }
            }
            .disabled(isSavingUsername || username.trimmingCharacters(in: .whitespaces).count < 3)
        }
    }

    // MARK: - Password

    private var passwordSection: some View {
        Section("Change Password") {
            SecureField("New Password", text: $newPassword)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .disabled(isSavingPassword)

            SecureField("Confirm Password", text: $confirmPassword)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .disabled(isSavingPassword)

            if let passwordMessage {
                Text(passwordMessage)
                    .font(.caption)
                    .foregroundStyle(passwordSuccess ? .green : .red)
            }

            Button {
                Task { await savePassword() }
            } label: {
                if isSavingPassword {
                    ProgressView()
                } else {
                    Text("Change Password")
                }
            }
            .disabled(isSavingPassword || !isPasswordValid)
        }
    }

    private var isPasswordValid: Bool {
        let pw = newPassword
        guard pw.count >= 8 else { return false }
        guard pw == confirmPassword else { return false }
        let hasUpper = pw.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLower = pw.range(of: "[a-z]", options: .regularExpression) != nil
        let hasDigit = pw.range(of: "[0-9]", options: .regularExpression) != nil
        return hasUpper && hasLower && hasDigit
    }

    // MARK: - 2FA

    private var twoFactorSection: some View {
        Section("Two-Factor Authentication") {
            HStack {
                Text("Status")
                Spacer()
                if account?.tfaEnabled == true {
                    Text("Enabled")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.green.opacity(0.15))
                        .foregroundStyle(.green)
                        .clipShape(Capsule())
                } else {
                    Text("Disabled")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.secondary.opacity(0.15))
                        .foregroundStyle(.secondary)
                        .clipShape(Capsule())
                }
            }

            if account?.tfaEnabled == true {
                Button("Disable 2FA", role: .destructive) {
                    isShowDisable2FAAlert = true
                }
                .disabled(isDisabling2FA)
            } else {
                Button("Enable 2FA") {
                    isShow2FASetupSheet = true
                }
            }
        }
    }

    // MARK: - OAuth2

    private var oauthSection: some View {
        Section("SSO") {
            if let account, let ssoId = account.ssoId, !ssoId.isEmpty {
                HStack {
                    Text(ssoDisplayName(ssoId))
                    Spacer()
                    Text(ssoUniqueId(ssoId))
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }

                Button("Unbind", role: .destructive) {
                    isShowUnbindAlert = true
                }
                .disabled(isUnbinding)
            }
        }
    }

    // MARK: - Actions

    private func loadAccount() async {
        do {
            let me = try await AuthHandler.getMe()
            withAnimation {
                account = me
                username = me.username ?? ""
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

    private func saveUsername() async {
        guard let uuid = account?.uuid else { return }
        isSavingUsername = true
        usernameMessage = nil

        do {
            try await AdminHandler.updateUsername(
                uuid: uuid,
                username: username.trimmingCharacters(in: .whitespaces)
            )
            usernameSuccess = true
            usernameMessage = "Username updated."
            await loadAccount()
        } catch {
            usernameSuccess = false
            usernameMessage = error.localizedDescription
        }
        isSavingUsername = false
    }

    private func savePassword() async {
        guard let uuid = account?.uuid else { return }
        isSavingPassword = true
        passwordMessage = nil

        do {
            try await AdminHandler.updatePassword(uuid: uuid, password: newPassword)
            passwordSuccess = true
            passwordMessage = "Password changed. All sessions have been revoked."
            newPassword = ""
            confirmPassword = ""
        } catch {
            passwordSuccess = false
            passwordMessage = error.localizedDescription
        }
        isSavingPassword = false
    }

    private func disable2FA() async {
        isDisabling2FA = true
        do {
            try await AdminHandler.disable2FA()
            await loadAccount()
        } catch {
            errorMessage = error.localizedDescription
        }
        isDisabling2FA = false
    }

    private func unbindOAuth2() async {
        isUnbinding = true
        do {
            try await AdminHandler.unbindOAuth2()
            await loadAccount()
        } catch {
            errorMessage = error.localizedDescription
        }
        isUnbinding = false
    }

    // MARK: - Helpers

    private func ssoDisplayName(_ ssoId: String) -> String {
        let platform = ssoId.split(separator: "_", maxSplits: 1).first.map(String.init) ?? ssoId
        switch platform.lowercased() {
        case "github": return "GitHub"
        case "google": return "Google"
        case "gitlab": return "GitLab"
        case "discord": return "Discord"
        default: return platform.prefix(1).uppercased() + platform.dropFirst()
        }
    }

    private func ssoUniqueId(_ ssoId: String) -> String {
        let parts = ssoId.split(separator: "_", maxSplits: 1)
        return parts.count > 1 ? String(parts[1]) : ssoId
    }
}

// MARK: - 2FA Setup Sheet

private struct TwoFactorSetupView: View {
    @Environment(\.dismiss) private var dismiss

    let onComplete: () async -> Void

    @State private var qrImageData: Data?
    @State private var otpCode = ""
    @State private var isLoadingQR = true
    @State private var isEnabling = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        if isLoadingQR {
                            ProgressView()
                                .frame(width: 200, height: 200)
                        } else if let qrImageData, let uiImage = UIImage(data: qrImageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .interpolation(.none)
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                        } else {
                            ContentUnavailableView {
                                Label("Error", systemImage: "exclamationmark.triangle")
                            } description: {
                                Text("Failed to load QR code.")
                            }
                            .frame(width: 200, height: 200)
                        }
                        Spacer()
                    }
                } header: {
                    Text("Scan QR Code")
                } footer: {
                    Text("Scan this QR code with your authenticator app, then enter the 6-digit code below.")
                }

                Section("Verification") {
                    TextField("OTP", text: $otpCode)
                        .keyboardType(.numberPad)
                        .font(.title2.monospaced())
                        .multilineTextAlignment(.center)
                        .disabled(isEnabling)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Enable 2FA")
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
                    if isEnabling {
                        ProgressView()
                    } else {
                        if #available(iOS 26.0, *) {
                            Button(role: .confirm) {
                                enable()
                            } label: {
                                Label("Enable", systemImage: "checkmark")
                            }
                            .disabled(otpCode.count != 6)
                        } else {
                            Button("Enable") {
                                enable()
                            }
                            .disabled(otpCode.count != 6)
                        }
                    }
                }
            }
            .task { await loadQRCode() }
        }
    }

    private func loadQRCode() async {
        isLoadingQR = true
        do {
            let data = try await AdminHandler.generate2FA()
            qrImageData = data
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingQR = false
    }

    private func enable() {
        isEnabling = true
        errorMessage = nil

        Task {
            do {
                try await AdminHandler.enable2FA(code: otpCode)
                await onComplete()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isEnabling = false
        }
    }
}
