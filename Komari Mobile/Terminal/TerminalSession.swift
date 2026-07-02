//
//  TerminalSession.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 7/2/26.
//

import Foundation

/// WebSocket session for Komari's remote terminal.
///
/// Wire protocol (mirrors komari-web `pages/terminal/index.tsx`):
/// - Endpoint: `ws(s)://<host>/api/admin/client/<uuid>/terminal[?2fa_code=<code>]`
/// - Keystrokes are sent as raw UTF-8 binary frames.
/// - Terminal output arrives as binary frames; pre-connection status notices arrive as text frames.
/// - Resize and heartbeat are JSON text frames (the server forwards text frames starting with `{`
///   to the agent as control messages).
class TerminalSession {
    enum State {
        case connecting
        case connected
        case disconnected
    }

    private(set) var state: State = .connecting

    /// Raw PTY output bytes to feed into the terminal.
    var onOutput: ((Data) -> Void)?
    /// Human-readable status notices from the server (e.g. waiting for agent, timeout).
    var onText: ((String) -> Void)?
    var onStateChange: ((State) -> Void)?

    /// Close reason or error description available once the session is disconnected.
    private(set) var closeMessage: String?

    private var webSocketTask: URLSessionWebSocketTask?
    private var receiveTask: Task<Void, Never>?
    private var heartbeatTask: Task<Void, Never>?
    private var hasReceivedOutput = false
    private var currentCols = 0
    private var currentRows = 0

    // Cookies are attached manually so the session cookie reliably rides on the ws(s) handshake.
    private static let socketSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpShouldSetCookies = false
        return URLSession(configuration: config)
    }()

    private static let timestampFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    func connect(uuid: String, tfaCode: String? = nil) {
        var endpoint = "/api/admin/client/\(uuid)/terminal"
        if let tfaCode, !tfaCode.isEmpty {
            let encodedCode = tfaCode.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? tfaCode
            endpoint += "?2fa_code=\(encodedCode)"
        }

        guard let url = KMCore.getWebSocketURL(endpoint: endpoint) else {
            closeMessage = String(localized: "Dashboard is not properly configured.")
            state = .disconnected
            onStateChange?(.disconnected)
            return
        }

        var request = URLRequest(url: url)

        // The server rejects websocket upgrades without a matching Origin (unless an API key is used).
        request.setValue(KMCore.getBaseURL(), forHTTPHeaderField: "Origin")

        let apiKey = KMCore.getKomariAPIKey()
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        if let cookieURL = KMCore.getAPIURL(endpoint: "/"),
           let cookies = HTTPCookieStorage.shared.cookies(for: cookieURL),
           !cookies.isEmpty,
           let cookieHeader = HTTPCookie.requestHeaderFields(with: cookies)["Cookie"] {
            request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
        }

        let task = Self.socketSession.webSocketTask(with: request)
        webSocketTask = task
        state = .connecting
        onStateChange?(.connecting)
        task.resume()

        startReceiving(task: task)
        startHeartbeat()
        sendResize()
    }

    func disconnect() {
        guard state != .disconnected else { return }
        state = .disconnected
        receiveTask?.cancel()
        receiveTask = nil
        heartbeatTask?.cancel()
        heartbeatTask = nil
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
    }

    /// Terminal keystrokes, sent as raw binary frames. Empty frames would crash the server's
    /// first-byte check, so they are dropped.
    func send(data: Data) {
        guard !data.isEmpty, state != .disconnected else { return }
        webSocketTask?.send(.data(data)) { _ in }
    }

    func updateSize(cols: Int, rows: Int) {
        currentCols = cols
        currentRows = rows
        sendResize()
    }

    private func sendResize() {
        guard currentCols > 0, currentRows > 0 else { return }
        sendControl("{\"type\":\"resize\",\"cols\":\(currentCols),\"rows\":\(currentRows)}")
    }

    private func sendControl(_ json: String) {
        guard state != .disconnected else { return }
        webSocketTask?.send(.string(json)) { _ in }
    }

    private func startReceiving(task: URLSessionWebSocketTask) {
        receiveTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    let message = try await task.receive()
                    guard let self, !Task.isCancelled else { return }
                    self.handleMessage(message)
                } catch {
                    guard let self, !Task.isCancelled else { return }
                    self.handleClose(error: error)
                    return
                }
            }
        }
    }

    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        if state == .connecting {
            state = .connected
            onStateChange?(.connected)
        }

        switch message {
        case .data(let data):
            if !hasReceivedOutput {
                hasReceivedOutput = true
                // The resize sent while the agent was still attaching is dropped by the server;
                // first output means the agent is live, so sync the PTY size again.
                sendResize()
            }
            onOutput?(data)
        case .string(let text):
            onText?(text)
        @unknown default:
            break
        }
    }

    private func handleClose(error: Error?) {
        guard state != .disconnected else { return }
        state = .disconnected
        heartbeatTask?.cancel()
        heartbeatTask = nil
        if let reason = webSocketTask?.closeReason, let text = String(data: reason, encoding: .utf8), !text.isEmpty {
            closeMessage = text
        } else if let error {
            closeMessage = error.localizedDescription
        }
        onStateChange?(.disconnected)
    }

    private func startHeartbeat() {
        heartbeatTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(10))
                guard let self, !Task.isCancelled else { return }
                let timestamp = Self.timestampFormatter.string(from: Date())
                self.sendControl("{\"type\":\"heartbeat\",\"timestamp\":\"\(timestamp)\"}")
            }
        }
    }
}
