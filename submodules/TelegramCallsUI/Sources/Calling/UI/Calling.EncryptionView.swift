//
//  Calling.EncryptionView.swift
//  TelegramCalls
//
//  Created by Nikita Sarin on 28.02.2023.
//

import UIKit

extension UIVisualEffectView {
    static var backgroundBlur: UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        view.alpha = 0.8
        return view
    }
}

extension Calling {

    final class EncryptionView: UIView {

        private lazy var keyView = KeyView { [weak self] in
            self?.keyViewTapped()
        }
        private let tipView = EncryptionTipView()
        private lazy var messageView = MessageView { [weak self] in
            self?.okButtonTapped()
        }

        private lazy var keyTapGesture = UITapGestureRecognizer(target: self,
                                                                action: #selector(keyViewTapped))

        private lazy var cornerConstraints = [
            keyView.topAnchor.constraint(equalTo: topAnchor, constant: -5),
            keyView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 32),
            keyView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        private lazy var centerConstraints = [
            keyView.topAnchor.constraint(equalTo: topAnchor, constant: 90),
            keyView.centerXAnchor.constraint(equalTo: centerXAnchor),
            messageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        private let stateChanged: (Bool) -> Void

        init(stateChanged: @escaping (Bool) -> Void) {
            self.stateChanged = stateChanged
            super.init(frame: .zero)
            setup()
        }

        required init?(coder: NSCoder) {  fatalError("init(coder:) has not been implemented")  }

        func set(name: String) {
            messageView.set(name: name)
        }

        func set(encryptionKey: String) {
            keyView.set(key: encryptionKey)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.setTipHidden(false, animated: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    self.setTipHidden(true, animated: true)
                }
            }
        }
    }
}

private extension Calling.EncryptionView {

    var smallTransform: CGAffineTransform {
        .identity.scaledBy(x: 0.55, y: 0.55).translatedBy(x: 100, y: -50)
    }

    func setup() {
        messageView.alpha = 0
        messageView.transform = smallTransform
        keyView.set(large: false)

        tipView.addGestureRecognizer(keyTapGesture)
        setTipHidden(true, animated: false)

        [messageView, tipView, keyView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            tipView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            tipView.topAnchor.constraint(equalTo: keyView.bottomAnchor, constant: 8),
            tipView.heightAnchor.constraint(equalToConstant: 38),

            keyView.topAnchor.constraint(equalTo: messageView.topAnchor, constant: 20),
            keyView.centerXAnchor.constraint(equalTo: messageView.centerXAnchor),

            messageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.9)
        ])
        NSLayoutConstraint.activate(cornerConstraints)
    }

    @objc func keyViewTapped() {
        stateChanged(true)
        setTipHidden(true, animated: true)
        keyView.isUserInteractionEnabled = false
        NSLayoutConstraint.deactivate(cornerConstraints)
        NSLayoutConstraint.activate(centerConstraints)
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: .curveEaseInOut
        ) { [self] in
            messageView.transform = .identity
            messageView.alpha = 1
            keyView.set(large: true)
            superview?.setNeedsLayout()
            superview?.layoutIfNeeded()
        }
    }

    @objc func okButtonTapped() {
        stateChanged(false)
        keyView.isUserInteractionEnabled = true
        NSLayoutConstraint.deactivate(centerConstraints)
        NSLayoutConstraint.activate(cornerConstraints)
        UIView.animate(
            withDuration: 0.17,
            delay: 0,
            options: .curveEaseOut
        ) { [self] in
            messageView.alpha = 0
            messageView.transform = smallTransform
            keyView.set(large: false)
            superview?.setNeedsLayout()
            superview?.layoutIfNeeded()
        }
    }

    func setTipHidden(_ hidden: Bool, animated: Bool) {
        func perform() {
            tipView.alpha = hidden ? 0 : 1
            tipView.transform = hidden ? .identity
                .scaledBy(x: 0.2, y: 0.2)
                .translatedBy(x: 300, y: -70) : .identity
        }
        if animated {
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
                perform()
            }
        } else {
            perform()
        }
    }
}

private final class MessageView: UIView {

    private let backgroundBlurView = UIVisualEffectView.backgroundBlur

    private let titleLabel = UILabel {
        $0.font = .systemFont(ofSize: 16, weight: .bold)
        $0.textColor = .white
        $0.text = "This call is end-to end encrypted"
    }

    private let messageLabel = UILabel {
        $0.font = .systemFont(ofSize: 16, weight: .regular)
        $0.textColor = .white
        $0.numberOfLines = 0
        $0.textAlignment = .center
    }

    private lazy var button = UIButton {
        $0.setTitle("OK", for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 20)
        $0.addTarget(self, action: #selector(okButtonTapped), for: .touchUpInside)
    }

    private let action: VoidClosure?

    init(action: VoidClosure?) {
        self.action = action
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {  fatalError("init(coder:) has not been implemented") }

    func set(name: String) {
        let components = name.components(separatedBy: " ")
        let firstName = components.first ?? ""
        messageLabel.text = "If the emoji on \(firstName)'s screen are the same, this call is 100% secure."
    }

    func setup() {
        clipsToBounds = true
        layer.cornerRadius = 20

        [backgroundBlurView, titleLabel, messageLabel, button].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        backgroundBlurView.pin(to: self)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 78),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 20),

            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            messageLabel.centerXAnchor.constraint(equalTo: centerXAnchor),

            button.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 20),
            button.heightAnchor.constraint(equalToConstant: 56),
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.centerXAnchor.constraint(equalTo: centerXAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @objc func okButtonTapped() {
        action?()
    }
}

private final class EncryptionTipView: UIView {

    private let titleLabel = UILabel {
        $0.font = .systemFont(ofSize: 16)
        $0.textColor = .white
        $0.text = "Encryption key of this call"
    }

    private let imageView = UIImageView {
        $0.image = UIImage(bundleImageName: "Call/lock")?.withRenderingMode(.alwaysTemplate)
        $0.tintColor = .white
        $0.contentMode = .scaleAspectFit
    }

    private let blurView = UIVisualEffectView.backgroundBlur

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setup() {
        layer.cornerRadius = 14
        clipsToBounds = true

        [blurView, imageView, titleLabel].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        blurView.pin(to: self)

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 14),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 3),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),

            heightAnchor.constraint(equalToConstant: 38)
        ])
    }
}

