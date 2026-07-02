//
//  TerminalViewController.swift
//  Komari Mobile
//
//  Created by Junhui Lou on 7/2/26.
//

import Foundation
import UIKit
import SwiftUI
import SwiftTerm

/// Hosts a `KomariTerminalView`, connects its websocket session, and keeps the terminal content
/// inset above the keyboard. Ported from Easy SSH's `TerminalViewController`.
class TerminalViewController: UIViewController {
    let node: NodeData
    let tfaCode: String?
    var terminalView: KomariTerminalView?

    /// Invoked once with the `KomariTerminalView` owned by this controller, as soon as it exists,
    /// so the embedding SwiftUI screen can keep a direct reference.
    ///
    /// Callers mutate SwiftUI `@State` from this closure, so the delivery is always deferred to
    /// the next main-queue tick to avoid publishing state changes during a representable's update pass.
    var onTerminalReady: ((KomariTerminalView) -> Void)? {
        didSet { deliverTerminalReady() }
    }

    private var hasDeliveredTerminalReady = false

    init(node: NodeData, tfaCode: String?) {
        self.node = node
        self.tfaCode = tfaCode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func deliverTerminalReady() {
        guard !hasDeliveredTerminalReady,
              let terminalView,
              let callback = onTerminalReady else { return }
        hasDeliveredTerminalReady = true
        DispatchQueue.main.async { callback(terminalView) }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        let session = TerminalSession()
        let terminalView = KomariTerminalView(frame: view.frame, session: session)
        self.terminalView = terminalView
        deliverTerminalReady()

        // Without this, resignFirstResponder crashes on iPad when the view is rehosted.
        terminalView.disableFirstResponderDuringViewRehosting = true
        view.addSubview(terminalView)
        terminalView.disableFirstResponderDuringViewRehosting = false
        terminalView.translatesAutoresizingMaskIntoConstraints = false

        // Extend terminal view to full screen edges (not safe area)
        NSLayoutConstraint.activate([
            terminalView.topAnchor.constraint(equalTo: view.topAnchor),
            terminalView.leftAnchor.constraint(equalTo: view.leftAnchor),
            terminalView.rightAnchor.constraint(equalTo: view.rightAnchor),
            terminalView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        setupKeyboardObservers()

        session.connect(uuid: node.uuid, tfaCode: tfaCode)
    }

    // MARK: - Keyboard Handling

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        updateKeyboardInset(from: notification)
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        terminalView?.setKeyboardHeight(0)
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        updateKeyboardInset(from: notification)
    }

    private func updateKeyboardInset(from notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }

        let keyboardFrameInView = view.convert(keyboardFrame, from: nil)
        let keyboardHeight = max(0, view.bounds.maxY - keyboardFrameInView.minY)

        terminalView?.setKeyboardHeight(keyboardHeight)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

struct SwiftUITerminal: UIViewControllerRepresentable {
    typealias UIViewControllerType = TerminalViewController

    let node: NodeData
    let tfaCode: String?
    let onCreated: ((KomariTerminalView) -> Void)?

    func makeUIViewController(context: Context) -> TerminalViewController {
        let viewController = TerminalViewController(node: node, tfaCode: tfaCode)
        viewController.onTerminalReady = onCreated
        return viewController
    }

    func updateUIViewController(_ uiViewController: TerminalViewController, context: Context) {
    }
}
