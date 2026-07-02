//
//  TerminalScreen.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 7/2/26.
//

import SwiftUI

/// Full-screen remote terminal for a node. Mirrors the komari-web terminal page flow:
/// check whether the account has 2FA enabled (the terminal endpoint re-verifies it),
/// then open the websocket.
struct TerminalScreen: View {
    @Environment(\.dismiss) private var dismiss
    let node: NodeData

    private enum ConnectPhase: Equatable {
        case checkingTFA
        case ready(tfaCode: String?)
    }

    @State private var phase: ConnectPhase = .checkingTFA
    @State private var terminalView: KomariTerminalView?
    @State private var sessionState: TerminalSession.State = .connecting
    @State private var isShowTFAPrompt: Bool = false
    @State private var tfaCode: String = ""

    var body: some View {
        Group {
            switch phase {
            case .checkingTFA:
                Color.black
                    .ignoresSafeArea()
            case .ready(let tfaCode):
                SwiftUITerminal(node: node, tfaCode: tfaCode) { terminal in
                    terminalView = terminal
                    sessionState = terminal.session.state
                    terminal.onSessionStateChange = { [weak terminal] state in
                        sessionState = state
                        if state == .connected {
                            _ = terminal?.becomeFirstResponder()
                        }
                    }
                }
                .ignoresSafeArea()
            }
        }
        .overlay {
            if sessionState == .connecting {
                connectingOverlay
            }
        }
        .navigationTitle(node.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Label("Close", systemImage: "xmark")
                }
            }
        }
        .task {
            await resolveTFA()
        }
        .onDisappear {
            terminalView?.session.disconnect()
        }
        .alert("Two-Factor Authentication", isPresented: $isShowTFAPrompt) {
            TextField("6-digit code", text: $tfaCode)
                .keyboardType(.numberPad)
            Button("Connect") {
                phase = .ready(tfaCode: tfaCode)
            }
            Button("Cancel", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Enter your two-factor authentication code to open the terminal.")
        }
    }

    private var connectingOverlay: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                Text("Connecting to \(node.name)…")
                    .font(.callout)
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .transition(.opacity)
    }

    private func resolveTFA() async {
        guard phase == .checkingTFA else { return }
        // API-key setups may not expose account info; connect without a code in that case.
        let tfaEnabled = (try? await AuthHandler.getMe())?.tfaEnabled ?? false
        if tfaEnabled {
            isShowTFAPrompt = true
        } else {
            phase = .ready(tfaCode: nil)
        }
    }
}
