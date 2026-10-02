//
//  TerminalSession.swift
//  Komari Mobile
//
//  Created by Takuma Kirishima on 7/2/26.
//

import Foundation

/// WebSocket session for Komari's remote terminal.
///
/// Wire protocol (mirrors komari-web `pages/terminal/index.tsx`):
/// - Endpoint: `ws(s)://<host>/api/admin/client/<uuid>/terminal[?2fa_code=<code>]`
/// - Right after the upgrade the server sends `{"request_id":"<id>"}` as a text frame. The id
///   lets a dropped websocket reattach via `?request_id=<id>` (no 2FA) while the server keeps
///   the session around (5 minutes).
/// - Keystrokes are sent as raw UTF-8 binary frames.
/// - Terminal output arrives as binary frames; pre-connection status notices arrive as text frames.
/// - Resize, heartbeat and close are JSON text frames (the server forwards text frames starting
///   with `{` to the agent as control messages; `close` also tears down the server-side session).
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

    /// Server-side session id, used to reattach after the websocket drops.
    private(set) var requestID: String?

    /// Whether a dropped connection can be resumed without starting a new session.
    var canReattach: Bool { requestID != nil }

    private var uuid: String?
    private var webSocketTask: URLSessionWebSocketTask?
    private var receiveTask: Task<Void, Never>?
    private var heartbeatTask: Task<Void, Never>?
    private var hasReceivedOutput = false
    /// Whether the current connection has been acknowledged with a `request_id` frame.
    private var hasReceivedRequestID = false
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

    /// Opens a new terminal session. The server verifies 2FA for new sessions only.
    func connect(uuid: String, tfaCode: String? = nil) {
        self.uuid = uuid
        requestID = nil
        var queryItems: [URLQueryItem] = []
        if let tfaCode = RequestHandler.normalizedTwoFactorCode(tfaCode) {
            queryItems.append(URLQueryItem(name: "2fa_code", value: tfaCode))
        }
        open(queryItems: queryItems)
    }

    /// Reattaches to the previous server-side session after the websocket dropped.
    func reattach() {
        guard state == .disconnected, let requestID else { return }
        open(queryItems: [URLQueryItem(name: "request_id", value: requestID)])
    }

    /// Drops the websocket but keeps the server-side session resumable via `reattach()`.
    func disconnect() {
        guard state != .disconnected else { return }
        state = .disconnected
        teardown()
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
    }

    /// Ends the terminal for good: asks the server to close the session and the agent's shell.
    func close() {
        let resumable = canReattach
        requestID = nil
        guard state != .disconnected, let task = webSocketTask else { return }
        state = .disconnected
        teardown()
        webSocketTask = nil
        guard resumable else {
            task.cancel(with: .normalClosure, reason: nil)
            return
        }
        task.send(.string("{\"type\":\"close\"}")) { _ in
            task.cancel(with: .normalClosure, reason: nil)
        }
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

    private func open(queryItems: [URLQueryItem]) {
        guard let uuid,
              let baseURL = KMCore.getWebSocketURL(endpoint: "/api/admin/client/\(uuid)/terminal"),
              var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            closeMessage = String(localized: "Dashboard is not properly configured.")
            state = .disconnected
            onStateChange?(.disconnected)
            return
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
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
           let cookies = KMCore.cookieStorage.cookies(for: cookieURL),
           !cookies.isEmpty,
           let cookieHeader = HTTPCookie.requestHeaderFields(with: cookies)["Cookie"] {
            request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
        }

        closeMessage = nil
        hasReceivedOutput = false
        hasReceivedRequestID = false

        let task = Self.socketSession.webSocketTask(with: request)
        webSocketTask = task
        state = .connecting
        onStateChange?(.connecting)
        task.resume()

        startReceiving(task: task)
        startHeartbeat()
        sendResize()
    }

    private func teardown() {
        receiveTask?.cancel()
        receiveTask = nil
        heartbeatTask?.cancel()
        heartbeatTask = nil
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
            if let id = Self.parseRequestID(text) {
                requestID = id
                hasReceivedRequestID = true
                return
            }
            onText?(text)
        @unknown default:
            break
        }
    }

    private static func parseRequestID(_ text: String) -> String? {
        guard text.hasPrefix("{"),
              let data = text.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let id = object["request_id"] as? String,
              !id.isEmpty else {
            return nil
        }
        return id
    }

    private func handleClose(error: Error?) {
        guard state != .disconnected else { return }
        state = .disconnected
        heartbeatTask?.cancel()
        heartbeatTask = nil
        // A connection the server never acknowledged (e.g. an expired session) cannot be resumed.
        if !hasReceivedRequestID {
            requestID = nil
        }
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
