//
//  TwoFactorSignInView.swift
//  Komari Mobile
//
//  Created by Takuma Kirishima on 9/30/26.
//

import SwiftUI

/// Asks for a 2FA code when the saved credentials cannot sign in without one.
struct TwoFactorSignInView: View {
    /// Why the previous code was rejected, if it was
    let message: String?
    let signInAction: (String) -> Void

    @State private var code = ""

    private var canSignIn: Bool {
        RequestHandler.normalizedTwoFactorCode(code) != nil
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("Two-Factor Authentication")
                    .font(.headline)
                Text("Enter your two-factor authentication code to sign in.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            TextField("6-digit code", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .font(.title2.monospaced())
                .multilineTextAlignment(.center)
                .padding(.vertical, 10)
                .frame(maxWidth: 220)
                .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .onSubmit(signIn)

            if let message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Button("Sign In", action: signIn)
                .buttonStyle(.borderedProminent)
                .disabled(!canSignIn)
        }
        .padding()
    }

    private func signIn() {
        guard canSignIn else { return }
        signInAction(code)
    }
}
