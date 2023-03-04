//
//  Calling.ButtonPanel.swift
//  TelegramCalling
//
//  Created by Nikita Sarin on 25.11.2022.
//

import UIKit

protocol CallingButtonPanelDelegate: AnyObject {
    func speakerButtonTapped(isOn: Bool)
    func flipButtonTapped()
    func videoButtonTapped(isOn: Bool)
    func muteButtonTapped(isOn: Bool)
    func endButtonTapped()
}

extension Calling {

    final class ButtonPanel: UIView {

        private weak var delegate: CallingButtonPanelDelegate?

        private let tipView = TipView(title: "Your microphone is turned off")

        private let stackView = UIStackView {
            $0.axis = .horizontal
            $0.distribution = .equalCentering
        }

        private(set) lazy var speaker = ToggleCircleButton(
            title: "speaker",
            background: Appereance.lightColor,
            imageName: "Call/speaker"
        ) { [weak self] in
            self?.delegate?.speakerButtonTapped(isOn: $0)
        }

        private(set) lazy var video = ToggleCircleButton(
            title: "video",
            background: Appereance.lightColor,
            imageName: "Call/video"
        ) { [weak self] in
            self?.delegate?.videoButtonTapped(isOn: $0)
        }

        private(set) lazy var mute = ToggleCircleButton(
            title: "mute",
            background: Appereance.lightColor,
            imageName: "Call/mute"
        ) { [weak self] in
            self?.setTipHidden(!$0)
            self?.delegate?.muteButtonTapped(isOn: $0)
        }

        private lazy var flip = CircleButton(
            title: "flip",
            background: Appereance.lightColor,
            imageName: "Call/flip"
        ) { [weak self] in
            self?.delegate?.flipButtonTapped()
        }

        private lazy var end = CircleButton(
            title: "end",
            background: Appereance.redColor,
            imageName: "Call/end"
        ) { [weak self] in
            self?.delegate?.endButtonTapped()
        }

        private lazy var stackViewTopConstraint = stackView.topAnchor.constraint(equalTo: topAnchor)

        init(delegate: CallingButtonPanelDelegate) {
            self.delegate = delegate
            super.init(frame: .zero)

            setup()
        }

        required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    }
}

extension Calling.ButtonPanel {

    func setSpeaker(hidden: Bool) {
        speaker.isHidden = hidden
    }

    func setFlip(hidden: Bool) {
        flip.isHidden = hidden
    }
}

private extension Calling.ButtonPanel {

    enum Appereance {
        static let lightColor = UIColor(white: 1, alpha: 0.25)
        static let redColor = UIColor(hex:"FF3B30")
    }

    func setup() {
        [tipView, stackView].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        setFlip(hidden: true)
        tipView.alpha = 0

        stackView.addArrangedSubviews(
            speaker,
            flip,
            video,
            mute,
            end
        )

        NSLayoutConstraint.activate([
            tipView.topAnchor.constraint(equalTo: topAnchor),
            tipView.centerXAnchor.constraint(equalTo: centerXAnchor),

            stackViewTopConstraint,
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func setTipHidden(_ hidden: Bool) {
        if hidden {
            UIView.animate(
                withDuration: 0.2,
                animations: { [tipView] in
                    tipView.alpha = 0
                }, completion: { [self] _ in
                    stackViewTopConstraint.constant = 0
                    UIView.animate(withDuration: 0.2) {
                        self.superview?.setNeedsLayout()
                        self.superview?.layoutIfNeeded()
                    }
                }
            )
        } else {
            stackViewTopConstraint.constant = 46
            UIView.animate(
                withDuration: 0.2,
                animations: { [self] in
                    self.superview?.setNeedsLayout()
                    self.superview?.layoutIfNeeded()
                }, completion: { [tipView] _ in
                    UIView.animate(withDuration: 0.2) {
                        tipView.alpha = 1
                    }
                }
            )
        }
    }
}

extension UIStackView {

    func addArrangedSubviews(_ subviews: [UIView]) {
        subviews.forEach {
            addArrangedSubview($0)
        }
    }

    func addArrangedSubviews(_ subviews: UIView...) {
        subviews.forEach {
            addArrangedSubview($0)
        }
    }
}
