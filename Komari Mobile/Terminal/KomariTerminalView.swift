//
//  KomariTerminalView.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 7/2/26.
//

import Foundation
import UIKit
import SwiftTerm

/// `TerminalView` bound to a Komari remote terminal websocket session.
/// Ported from Easy SSH's `BaseTerminalView`/`SSHTerminalView` with the SSH channel
/// replaced by `TerminalSession`.
class KomariTerminalView: TerminalView, TerminalViewDelegate {
    let session: TerminalSession

    var onSessionStateChange: ((TerminalSession.State) -> Void)?

    /// Avoids a first-responder crash on iPad when the view is moved between superviews.
    var disableFirstResponderDuringViewRehosting: Bool = false

    private var keyboardTapRecognizer: UITapGestureRecognizer!

    private static var defaultFontSize: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 16 : 12
    }

    init(frame: CGRect, session: TerminalSession) {
        self.session = session
        super.init(frame: frame)

        terminalDelegate = self
        font = UIFont.monospacedSystemFont(ofSize: Self.defaultFontSize, weight: .regular)
        applyAppearance()

        addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(handlePinch)))
        keyboardTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(activate))

        wireSession()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Matches the komari-web terminal page: black background with light foreground.
    private func applyAppearance() {
        backgroundColor = .black
        nativeBackgroundColor = .black
        nativeForegroundColor = UIColor(white: 0.92, alpha: 1.0)
        caretColor = UIColor(white: 0.92, alpha: 1.0)
    }

    private func wireSession() {
        session.onOutput = { [weak self] data in
            self?.feed(byteArray: ArraySlice(data))
        }
        session.onText = { [weak self] text in
            // Server status notices use bare newlines; give them proper carriage returns.
            self?.feed(text: text.replacingOccurrences(of: "\n", with: "\r\n"))
        }
        session.onStateChange = { [weak self] state in
            guard let self else { return }
            if state == .disconnected {
                var message = "\r\n \(String(localized: "Disconnected"))"
                if let detail = self.session.closeMessage, !detail.isEmpty {
                    message += " (\(detail))"
                }
                self.feed(text: message + "\r\n")
            }
            self.onSessionStateChange?(state)
        }
    }

    // MARK: - Keyboard Focus

    override public func resignFirstResponder() -> Bool {
        if disableFirstResponderDuringViewRehosting {
            return true
        }
        // Tap-to-refocus once the keyboard has been dismissed.
        addGestureRecognizer(keyboardTapRecognizer)
        return super.resignFirstResponder()
    }

    @objc
    private func activate() {
        if becomeFirstResponder() {
            removeGestureRecognizer(keyboardTapRecognizer)
        }
    }

    // MARK: - Pinch to Zoom

    @objc
    private func handlePinch(_ gestureRecognizer: UIPinchGestureRecognizer) {
        guard gestureRecognizer.state == .began || gestureRecognizer.state == .changed else { return }
        let newSize = font.pointSize * gestureRecognizer.scale
        gestureRecognizer.scale = 1.0
        guard newSize >= 5, newSize <= 72 else { return }
        font = UIFont.monospacedSystemFont(ofSize: newSize, weight: .regular)
    }

    // MARK: - TerminalViewDelegate

    func send(source: TerminalView, data: ArraySlice<UInt8>) {
        session.send(data: Data(data))
    }

    func sizeChanged(source: TerminalView, newCols: Int, newRows: Int) {
        session.updateSize(cols: newCols, rows: newRows)
    }

    func setTerminalTitle(source: TerminalView, title: String) {
    }

    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
    }

    func scrolled(source: TerminalView, position: Double) {
    }

    func requestOpenLink(source: TerminalView, link: String, params: [String: String]) {
        guard let encoded = link.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encoded),
              url.scheme == "http" || url.scheme == "https" else { return }
        UIApplication.shared.open(url)
    }

    func clipboardCopy(source: TerminalView, content: Data) {
        if let text = String(data: content, encoding: .utf8) {
            UIPasteboard.general.string = text
        }
    }

    func rangeChanged(source: TerminalView, startY: Int, endY: Int) {
    }
}
