//
//  ResponsiveControl.swift
//  TelegramCalls
//
//  Created by Nikita Sarin on 24.02.2023.
//

import UIKit

typealias VoidClosure = () -> Void

class Control: UIControl {

    private let action: VoidClosure?

    init(action: VoidClosure?) {
        self.action = action
        super.init(frame: .zero)

        addTarget(self, action: #selector(didTouchUpInside), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc func didTouchUpInside() {
        action?()
    }
}

class ResponsiveControl: Control {

    private let feedback = UIImpactFeedbackGenerator(style: .medium)

    var needFeedback = true
    var needTransform = true

    override init(action: VoidClosure?) {
        super.init(action: action)

        addTarget(self, action: #selector(didTouchDown), for: .touchDown)
        addTarget(self, action: #selector(didTouchUp), for: .touchUpInside)
        addTarget(self, action: #selector(didTouchUp), for: .touchUpOutside)
        addTarget(self, action: #selector(didTouchUp), for: .touchCancel)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

extension ResponsiveControl {

    @objc func didTouchUp() {
        if needTransform {
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut) { [self] in
                transform = .identity
            }
        }
    }

    @objc func didTouchDown() {
        if needFeedback {
            feedback.impactOccurred()
        }
        if needTransform {
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut) { [self] in
                transform = .identity.scaledBy(x: 0.9, y: 0.9)
            }
        }
    }
}
