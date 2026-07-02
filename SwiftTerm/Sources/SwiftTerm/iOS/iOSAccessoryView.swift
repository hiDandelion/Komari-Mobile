//
//  iOSAccessoryView.swift
//
//  Implements an inputAccessoryView for the iOS terminal for common operations
//
//  Created by Miguel de Icaza on 5/9/20.
//
#if os(iOS) || os(visionOS)

import Foundation
import UIKit

/**
 * This class provides an input accessory for the terminal on iOS, you can access this via the `inputAccessoryView`
 * property in the `TerminalView` and casting the result to `TerminalAccessory`.
 *
 * This class surfaces some state that the terminal might want to poke at, you should at least support the following
 * properties;
 * `controlModifer` should be set if the control key is pressed
 */
public class TerminalAccessory: UIInputView, UIInputViewAudioFeedback {
    /// This points to an instanace of the `TerminalView` where events are sent
    public weak var terminalView: TerminalView?
    weak var terminal: Terminal?
    var controlButton: UIButton?
    /// This tracks whether the "control" button is turned on or not
    public var controlModifier: Bool = false {
        didSet {
            controlButton?.isSelected = controlModifier
        }
    }

    var touchButton: UIButton!
    var inputKeyboardButton: UIButton!
    var hideKeyboardButton: UIButton!

    private var rootStack: UIStackView!
    private var modifierGroup: UIStackView!
    private var charGroup: UIStackView!
    private var fKeyGroup: UIStackView!
    private var arrowGroup: UIStackView!
    private var toolGroup: UIStackView!
    private var fKeySeparator: UIView!
    private var lastBoundsWidth: CGFloat = 0
    private var needsSetup = true

    public init(frame: CGRect, inputViewStyle: UIInputView.Style, container: TerminalView)
    {
        self.terminalView = container
        self.terminal = terminalView?.getTerminal()
        super.init(frame: frame, inputViewStyle: inputViewStyle)
        allowsSelfSizing = true
    }

    public override var bounds: CGRect {
        didSet {
            if needsSetup && bounds.width > 0 {
                needsSetup = false
                setupUI()
            } else if bounds.width != lastBoundsWidth {
                lastBoundsWidth = bounds.width
                updateFKeyVisibility()
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    #if os(iOS)
    // Override for UIInputViewAudioFeedback
    public var enableInputClicksWhenVisible: Bool { true }
    #endif

    func clickAndSend(_ data: [UInt8])
    {
        #if os(iOS)
        UIDevice.current.playInputClick()
        #endif
        terminalView?.send(data)
    }

    func clickAndInsertText(_ text: String)
    {
        #if os(iOS)
        UIDevice.current.playInputClick()
        #endif
        terminalView?.insertTextFromAccessory(text)
    }

    @objc func esc(_ sender: AnyObject) { clickAndSend([0x1b]) }
    @objc func tab(_ sender: AnyObject) { clickAndSend([0x9]) }
    @objc func slash(_ sender: AnyObject) { clickAndInsertText("/") }
    @objc func pipe(_ sender: AnyObject) { clickAndInsertText("|") }
    @objc func dash(_ sender: AnyObject) { clickAndInsertText("-") }
    @objc func f1(_ sender: AnyObject) { clickAndSend(EscapeSequences.cmdF[0]) }
    @objc func f2(_ sender: AnyObject) { clickAndSend(EscapeSequences.cmdF[1]) }
    @objc func f3(_ sender: AnyObject) { clickAndSend(EscapeSequences.cmdF[2]) }
    @objc func f4(_ sender: AnyObject) { clickAndSend(EscapeSequences.cmdF[3]) }
    @objc func f5(_ sender: AnyObject) { clickAndSend(EscapeSequences.cmdF[4]) }
    @objc func f6(_ sender: AnyObject) { clickAndSend(EscapeSequences.cmdF[5]) }
    @objc func f7(_ sender: AnyObject) { clickAndSend(EscapeSequences.cmdF[6]) }
    @objc func f8(_ sender: AnyObject) { clickAndSend(EscapeSequences.cmdF[7]) }
    @objc func f9(_ sender: AnyObject) { clickAndSend(EscapeSequences.cmdF[8]) }
    @objc func f10(_ sender: AnyObject) { clickAndSend(EscapeSequences.cmdF[9]) }

    @objc
    func ctrl(_ sender: UIButton)
    {
        controlModifier.toggle()
    }

    // Controls the timer for auto-repeat
    var repeatCommand: (() -> ())? = nil
    var repeatTimer: Timer?
    var repeatTask: Task<(), Never>?

    func startTimerForKeypress(repeatKey: @escaping() -> ())
    {
        repeatKey()
        repeatCommand = repeatKey

        repeatTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 600_000_000)
            guard !(repeatTask?.isCancelled ?? true) else { return }
            let rc = self.repeatCommand
            self.repeatTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                rc? ()
            }
        }
    }

    @objc
    func cancelTimer()
    {
        repeatTimer?.invalidate()
        repeatCommand = nil
        repeatTimer = nil
        repeatTask?.cancel()
    }

    @objc func up(_ sender: UIButton)
    {
        startTimerForKeypress { self.terminalView?.sendKeyUp() }
    }

    @objc func down(_ sender: UIButton)
    {
        startTimerForKeypress { self.terminalView?.sendKeyDown() }
    }

    @objc func left(_ sender: UIButton)
    {
        startTimerForKeypress { self.terminalView?.sendKeyLeft() }
    }

    @objc func right(_ sender: UIButton)
    {
        startTimerForKeypress { self.terminalView?.sendKeyRight() }
    }


    @objc func toggleInputKeyboard(_ sender: UIButton) {
        guard let tv = terminalView else { return }
        let wasResponder = tv.isFirstResponder
        if wasResponder { _ = tv.resignFirstResponder() }

        if tv.inputView == nil {
            #if os(visionOS)
            tv.inputView = KeyboardView(frame: CGRect(origin: CGPoint.zero,
                                                        size: CGSize(width: 300,
                                                                      height: 400)),
                                         terminalView: terminalView)
            #else
            tv.inputView = KeyboardView(frame: CGRect(origin: CGPoint.zero,
                                                        size: CGSize(width: UIScreen.main.bounds.width,
                                                                      height: max((UIScreen.main.bounds.height / 5),140))),
                                         terminalView: terminalView)
            #endif
        } else {
            tv.inputView = nil
        }
        if wasResponder { _ = tv.becomeFirstResponder() }

    }

    @objc func toggleTouch(_ sender: UIButton) {
        terminalView?.allowMouseReporting.toggle()
        touchButton.isSelected = !(terminalView?.allowMouseReporting ?? false)
    }

    @objc func hideKeyboard(_ sender: UIButton) {
        _ = terminalView?.resignFirstResponder()
    }

    // MARK: - Stack View Helpers

    private func makeGroupStack(_ buttons: [UIView]) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: buttons)
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 2
        return stack
    }

    private func makeSeparator() -> UIView {
        let sep = UIView()
        sep.backgroundColor = .separator
        sep.translatesAutoresizingMaskIntoConstraints = false
        sep.widthAnchor.constraint(equalToConstant: 1).isActive = true
        return sep
    }

    private func updateFKeyVisibility() {
        guard let fKeyGroup, let fKeySeparator else { return }

        // Measure space needed: all groups except fKey + separators + spacer
        let groupsWidth = [modifierGroup, charGroup, arrowGroup, toolGroup].compactMap { $0 }.reduce(CGFloat(0)) { total, stack in
            let buttonCount = CGFloat(stack.arrangedSubviews.count)
            let minBtn: CGFloat = (UIDevice.current.userInterfaceIdiom == .phone) ? 28 : 36
            return total + buttonCount * minBtn + (buttonCount - 1) * stack.spacing
        }
        // 4 separators visible without fKeys, root spacing
        let separatorsWidth: CGFloat = 4 * 1 + 5 * 4
        let fKeyCount: CGFloat = 10
        let fKeyMinBtn: CGFloat = (UIDevice.current.userInterfaceIdiom == .phone) ? 24 : 32
        let fKeysWidth = fKeyCount * fKeyMinBtn + (fKeyCount - 1) * 2 + 1 + 4 // + separator + root spacing

        let available = bounds.width - groupsWidth - separatorsWidth
        let shouldShow = available >= fKeysWidth

        fKeyGroup.isHidden = !shouldShow
        fKeySeparator.isHidden = !shouldShow
    }

    // MARK: - Setup

    /**
     * This method setups the internal data structures to setup the UI shown on the accessory view,
     * if you provide your own implementation, you are responsible for adding all the elements to the
     * this view, and flagging some of the public properties declared here.
     */
    public func setupUI()
    {
        rootStack?.removeFromSuperview()
        terminalView?.setupKeyboardButtonColors()

        let isPhone = UIDevice.current.userInterfaceIdiom == .phone
        let mainMinWidth: CGFloat = isPhone ? 28 : 36
        let toolMinWidth: CGFloat = isPhone ? 36 : 44
        let fKeyMinWidth: CGFloat = isPhone ? 24 : 32

        // Create buttons
        let escButton = makeButton("esc", #selector(esc), isNormal: false)
        controlButton = makeButton("", #selector(ctrl), icon: "control", isNormal: false)
        let tabButton = makeButton("", #selector(tab), icon: "arrow.right.to.line.compact", isNormal: false)

        let pipeButton = makeButton("|", #selector(pipe))
        let slashButton = makeButton("/", #selector(slash))
        let dashButton = makeButton("-", #selector(dash))

        let f1Button = makeButton("F1", #selector(f1))
        let f2Button = makeButton("F2", #selector(f2))
        let f3Button = makeButton("F3", #selector(f3))
        let f4Button = makeButton("F4", #selector(f4))
        let f5Button = makeButton("F5", #selector(f5))
        let f6Button = makeButton("F6", #selector(f6))
        let f7Button = makeButton("F7", #selector(f7))
        let f8Button = makeButton("F8", #selector(f8))
        let f9Button = makeButton("F9", #selector(f9))
        let f10Button = makeButton("F10", #selector(f10))

        let leftButton = makeAutoRepeatButton("arrowtriangle.left.fill", #selector(left))
        let downButton = makeAutoRepeatButton("arrowtriangle.down.fill", #selector(down))
        let upButton = makeAutoRepeatButton("arrowtriangle.up.fill", #selector(up))
        let rightButton = makeAutoRepeatButton("arrowtriangle.right.fill", #selector(right))

        touchButton = makeButton("", #selector(toggleTouch), icon: "hand.draw", isNormal: false)
        touchButton.isSelected = terminalView?.allowMouseReporting ?? false
        inputKeyboardButton = makeButton("", #selector(toggleInputKeyboard), icon: "keyboard.badge.ellipsis", isNormal: false)
        hideKeyboardButton = makeButton("", #selector(hideKeyboard), icon: "keyboard.chevron.compact.down", isNormal: false)

        // Build group stacks
        modifierGroup = makeGroupStack([escButton, controlButton!, tabButton])
        charGroup = makeGroupStack([pipeButton, slashButton, dashButton])
        fKeyGroup = makeGroupStack([f1Button, f2Button, f3Button, f4Button, f5Button,
                                    f6Button, f7Button, f8Button, f9Button, f10Button])
        arrowGroup = makeGroupStack([leftButton, downButton, upButton, rightButton])
        toolGroup = makeGroupStack([touchButton, inputKeyboardButton, hideKeyboardButton])

        // Apply minimum width constraints
        let mainButtons = modifierGroup.arrangedSubviews + charGroup.arrangedSubviews +
                          arrowGroup.arrangedSubviews
        for btn in mainButtons {
            btn.widthAnchor.constraint(greaterThanOrEqualToConstant: mainMinWidth).isActive = true
        }
        // toolGroup needs an explicit width — icon-only buttons have tiny intrinsic sizes
        let toolGroupWidth = toolMinWidth * 2 + toolGroup.spacing * 4
        toolGroup.widthAnchor.constraint(greaterThanOrEqualToConstant: toolGroupWidth).isActive = true
        toolGroup.setContentCompressionResistancePriority(.required, for: .horizontal)
        for btn in fKeyGroup.arrangedSubviews {
            btn.widthAnchor.constraint(greaterThanOrEqualToConstant: fKeyMinWidth).isActive = true
        }

        // Spacer view
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // Separators
        let sep1 = makeSeparator()
        let sep2 = makeSeparator()
        fKeySeparator = makeSeparator()
        let sep4 = makeSeparator()

        // Root stack
        rootStack = UIStackView(arrangedSubviews: [
            modifierGroup, sep1,
            charGroup, sep2,
            fKeyGroup, fKeySeparator,
            spacer,
            arrowGroup, sep4,
            toolGroup
        ])
        rootStack.axis = .horizontal
        rootStack.alignment = .fill
        rootStack.distribution = .fill
        rootStack.spacing = 4
        rootStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(rootStack)
        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            rootStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
            rootStack.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            rootStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
        ])

        lastBoundsWidth = bounds.width
        updateFKeyVisibility()
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        needsSetup = true
        setupUI()
    }

    func makeAutoRepeatButton(_ iconName: String, _ action: Selector) -> UIButton {
        let b = makeButton("", action, icon: iconName)
        b.addTarget(self, action: #selector(cancelTimer), for: .touchUpOutside)
        b.addTarget(self, action: #selector(cancelTimer), for: .touchCancel)
        b.addTarget(self, action: #selector(cancelTimer), for: .touchUpInside)
        return b
    }

    func makeButton(_ title: String, _ action: Selector, icon: String = "", isNormal: Bool = true) -> UIButton {
        let b = BackgroundSelectedButton(type: .roundedRect)

        TerminalAccessory.styleButton(b)
        b.addTarget(self, action: action, for: .touchDown)
        b.setTitle(title, for: .normal)
        guard let terminalView else {
            return b
        }
        b.color = isNormal ? terminalView.buttonBackgroundColor : terminalView.buttonDarkBackgroundColor
        b.setTitleColor(terminalView.buttonColor, for: .normal)
        b.setTitleColor(terminalView.buttonColor, for: .selected)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        b.backgroundColor = isNormal ? terminalView.buttonBackgroundColor : terminalView.buttonDarkBackgroundColor

        if icon != "" {
            if let img = UIImage(systemName: icon, withConfiguration: UIImage.SymbolConfiguration(pointSize: 10.0)) {
                b.setImage(img.withTintColor(terminalView.buttonColor, renderingMode: .alwaysOriginal), for: .normal)
            }
        }
        return b
    }

    // I am not committed to this style, this is just something quick to get going
    static func styleButton(_ b: UIButton) {
        b.layer.cornerRadius = 7
        b.layer.masksToBounds = true
    }
}


class BackgroundSelectedButton: UIButton {

    var color: UIColor?

    override var isSelected: Bool {
        didSet {
            self.backgroundColor = isSelected ? UIView().tintColor : color
        }
    }
}
#endif
