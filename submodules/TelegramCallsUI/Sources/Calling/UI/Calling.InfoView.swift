//
//  CallStateView.swift
//  TelegramCalls
//
//  Created by Nikita Sarin on 27.02.2023.
//

import UIKit

extension Calling {

    final class InfoView: UIView {

        private let nameLabel = UILabel {
            $0.textColor = .white
            $0.font = .systemFont(ofSize: 28)
        }

        private let stateView = CallStateView()

        private let tipView = TipView(title: "Weak network signal")

        override init(frame: CGRect = .zero) {
            super.init(frame: frame)
            setup()
        }

        required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        func setLarge(_ large: Bool) {
            nameLabel.font = large ? .systemFont(ofSize: 28) : .systemFont(ofSize: 17, weight: .bold)
        }

        func set(signalQuality: Int) {
            stateView.qualityView.set(quality: signalQuality)
            UIView.animate(withDuration: 0.1) {
                self.tipView.alpha = signalQuality <= 1 ? 1 : 0
            }
        }

        func set(state: Calling.CallState) {
            stateView.setState(state)
            switch state {
            case .ended:
                nameLabel.text = "Call Ended"
            default: break
            }
        }

        func set(name: String) {
            nameLabel.text = name
        }
    }
}

private extension Calling.InfoView {

    func setup() {
        tipView.alpha = 0
        [nameLabel, stateView, tipView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: topAnchor),
            nameLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor),

            stateView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            stateView.centerXAnchor.constraint(equalTo: centerXAnchor),

            tipView.topAnchor.constraint(equalTo: stateView.bottomAnchor, constant: 12),
            tipView.centerXAnchor.constraint(equalTo: centerXAnchor),
            tipView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}

private final class CallStateView: UIStackView {

    let qualityView = CallSignalQualityView()

    let label = UILabel {
        $0.textColor = .white
        $0.font = .systemFont(ofSize: 16)
    }

    let progressView = ProgressView()
    let formatter = DateComponentsFormatter()

    private var current: Calling.CallState?

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        setup()
        formatter.zeroFormattingBehavior = .pad
    }

    required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setState(_ state: Calling.CallState) {
        let text: String?
        let qualityAlpha: CGFloat
        let progressAlpha: CGFloat
        var needAnimate = true
        switch state {
        case .waiting:
            qualityAlpha = 0
            text = "Waiting"
            progressAlpha = 1
        case .requesting:
            qualityAlpha = 0
            text = "Requesting"
            progressAlpha = 1
        case .ringing:
            qualityAlpha = 0
            text = "Ringing"
            progressAlpha = 1
        case .exchangingEncryptionKeys:
            qualityAlpha = 0
            text = "Exchanging encryption keys"
            progressAlpha = 1
        case .inProgress(let duration):
            qualityAlpha = 1
            formatter.allowedUnits = duration >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
            text = formatter.string(from: duration)
            progressAlpha = 0
            if case .inProgress = current {
                needAnimate = false
            }
        case .reconnectiong:
            qualityAlpha = 0
            text = "Reconnecting"
            progressAlpha = 1
        case .ended:
            qualityAlpha = 0
            text = nil
            progressAlpha = 0
        }

        func perform() {
            qualityView.alpha = qualityAlpha
            qualityView.isHidden = qualityAlpha == 0
            label.text = text
            progressView.alpha = progressAlpha
            progressView.isHidden = progressAlpha == 0
        }

        if needAnimate {
            UIView.animate(
                withDuration: 0.3,
                animations: {
                    self.alpha = 0
                    self.transform = .identity.scaledBy(x: 0.9, y: 0.9)
                },
                completion: { _ in
                    perform()
                    UIView.animate(withDuration: 0.3) {
                        self.alpha = 1
                        self.transform = .identity
                    }
                }
            )
        } else {
            perform()
        }
        current = state
    }

    func setup() {
        qualityView.alpha = 0
        progressView.alpha = 0
        spacing = 7
        distribution = .equalCentering
        alignment = .center
        qualityView.set(quality: 3)
        addArrangedSubviews(
            qualityView,
            label,
            progressView
        )
    }
}

private final class CallSignalQualityView: UIView {

    private lazy var segments = (0..<4).map { _ in
        let layer = CALayer()
        layer.cornerRadius = 1
        layer.backgroundColor = UIColor.white.cgColor
        layer.masksToBounds = true
        return layer
    }

    private let spacing: CGFloat = 2
    private let width: CGFloat = 3

    override init(frame: CGRect) {
        super.init(frame: frame)
        segments.forEach { layer.addSublayer($0) }
        invalidateIntrinsicContentSize()
    }

    required init(coder: NSCoder) {  fatalError("init(coder:) has not been implemented") }

    override var intrinsicContentSize: CGSize {
        let count = CGFloat(segments.count)
        return CGSize(width: count * width + (count - 1) * spacing, height: 12)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        for index in (0..<segments.count) {
            let segment = segments[index]
            let height = bounds.height * (CGFloat(index + 1) / CGFloat(segments.count))
            segment.frame = CGRect(
                x: CGFloat(index) * (spacing + width),
                y: bounds.height - height,
                width: 3,
                height: height
            )
        }
    }

    func set(quality: Int) {
        let clamped = min(max(0, quality), segments.count)
        segments.prefix(clamped).forEach { $0.opacity = 1 }
        segments.suffix(segments.count - clamped).forEach { $0.opacity = 0.3 }
    }
}

private final class ProgressView: UIView {

    private lazy var dots = (0..<3).map { index in
        let layer = CALayer()
        layer.cornerRadius = 2
        layer.backgroundColor = UIColor.white.cgColor
        layer.masksToBounds = true
        return layer
    }

    private let spacing: CGFloat = 2
    private let edge: CGFloat = 4

    override init(frame: CGRect) {
        super.init(frame: frame)
        for index in (0..<dots.count) {
            let dot = dots[index]
            layer.addSublayer(dot)
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.2) {
                self.addAnimation(to: dot)
            }
        }
        invalidateIntrinsicContentSize()
    }

    required init(coder: NSCoder) {  fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()

        for index in (0..<dots.count) {
            let dot = dots[index]
            dot.frame = CGRect(
                x: CGFloat(index) * (spacing + edge),
                y: 0,
                width: edge,
                height: edge
            )
        }
    }

    override var intrinsicContentSize: CGSize {
        let count = CGFloat(dots.count)
        return CGSize(width: count * edge + (count - 1) * spacing, height: edge)
    }

    func addAnimation(to layer: CALayer) {
        let scaling = CABasicAnimation(keyPath: "transform.scale")
        scaling.toValue = 0.5
        scaling.duration = 0.7
        scaling.autoreverses = true
        scaling.repeatCount = .infinity
        layer.add(scaling, forKey: nil)
    }
}
