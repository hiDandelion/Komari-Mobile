//
//  TerminalScreen.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 7/2/26.
//

import SwiftUI
import SwiftTerm

/// Full-screen remote terminal for a node. Mirrors the komari-web terminal page flow:
/// check whether the account has 2FA enabled (the terminal endpoint re-verifies it),
/// then open the websocket. A dropped connection (e.g. while the app was in the background)
/// reattaches to the retained server-side session without asking for 2FA again.
struct TerminalScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
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
    /// The 2FA prompt is for a fresh session on the existing terminal rather than the first connect.
    @State private var isRestartingSession: Bool = false
    /// Set once the app goes to the background; a drop noticed around then is reattached automatically.
    @State private var shouldReattachAfterBackground: Bool = false
    @State private var reattachGraceTask: Task<Void, Never>?

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
                    terminalView?.session.close()
                    dismiss()
                } label: {
                    Label("Close", systemImage: "xmark")
                }
            }
            if sessionState == .disconnected {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        reconnect()
                    } label: {
                        Label("Reconnect", systemImage: "arrow.clockwise")
                    }
                }
            }
        }
        .task {
            await resolveTFA()
        }
        .onDisappear {
            reattachGraceTask?.cancel()
            terminalView?.session.close()
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
        .onChange(of: sessionState) { _, newState in
            // The dropped socket often surfaces only after the app is active again.
            if newState == .disconnected, shouldReattachAfterBackground, scenePhase == .active {
                shouldReattachAfterBackground = false
                terminalView?.session.reattach()
            }
        }
        .alert("Two-Factor Authentication", isPresented: $isShowTFAPrompt) {
            TextField("6-digit code", text: $tfaCode)
                .keyboardType(.numberPad)
            Button("Connect") {
                if isRestartingSession {
                    isRestartingSession = false
                    terminalView?.session.connect(uuid: node.uuid, tfaCode: tfaCode)
                } else {
                    phase = .ready(tfaCode: tfaCode)
                }
            }
            Button("Cancel", role: .cancel) {
                if isRestartingSession {
                    isRestartingSession = false
                } else {
                    dismiss()
                }
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
        if await isTFARequired() {
            isShowTFAPrompt = true
        } else {
            phase = .ready(tfaCode: nil)
        }
    }

    private func isTFARequired() async -> Bool {
        // API-key setups may not expose account info; connect without a code in that case.
        (try? await AuthHandler.getMe())?.tfaEnabled ?? false
    }

    /// Resumes the server-side session when it is still retained; otherwise opens a new one,
    /// which the server re-verifies with 2FA.
    private func reconnect() {
        guard let session = terminalView?.session, session.state == .disconnected else { return }
        if session.canReattach {
            session.reattach()
            return
        }
        Task {
            if await isTFARequired() {
                tfaCode = ""
                isRestartingSession = true
                isShowTFAPrompt = true
            } else {
                session.connect(uuid: node.uuid)
            }
        }
    }

    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .background:
            reattachGraceTask?.cancel()
            shouldReattachAfterBackground = true
        case .active:
            guard shouldReattachAfterBackground else { return }
            if sessionState == .disconnected {
                shouldReattachAfterBackground = false
                terminalView?.session.reattach()
            } else {
                // Keep watching briefly: a socket killed while suspended may only report it now.
                reattachGraceTask?.cancel()
                reattachGraceTask = Task {
                    try? await Task.sleep(for: .seconds(5))
                    guard !Task.isCancelled else { return }
                    shouldReattachAfterBackground = false
                }
            }
        default:
            break
        }
    }
}
