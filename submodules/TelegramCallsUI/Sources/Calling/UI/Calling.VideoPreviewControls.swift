//
//  Calling.CameraVideoLayer.swift
//  TelegramCalls
//
//  Created by Nikita Sarin on 23.02.2023.
//

import AVFoundation
import UIKit

protocol CallingVideoPreviewControlsDelegate: InputSourceViewDelegate {
    func cancelTapped()
    func startVideoTapped()
}

extension Calling {

    final class VideoPreviewControls: UIView {

        private lazy var cancelButton = UIButton {
            $0.setTitle("Cancel", for: .normal)
            $0.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
            $0.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        }

        private let titleLabel = UILabel {
            $0.text = "Video Preview"
            $0.font = .systemFont(ofSize: 17, weight: .semibold)
            $0.textColor = .white
        }

        private let sourceView: InputSourceView
        private lazy var startVideoButton = ActionButton(title: "Start Video") { [weak delegate] in
            delegate?.startVideoTapped()
        }

        private weak var delegate: CallingVideoPreviewControlsDelegate?

        init(
            delegate: CallingVideoPreviewControlsDelegate
        ) {
            self.delegate = delegate
            self.sourceView = InputSourceView(delegate: delegate)
            super.init(frame: .zero)

            setup()
        }

        required init?(coder: NSCoder) {  fatalError("init(coder:) has not been implemented") }
    }
}

private extension Calling.VideoPreviewControls {

    func setup() {
        [cancelButton, titleLabel, sourceView, startVideoButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            cancelButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            cancelButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 8),

            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: cancelButton.centerYAnchor),

            sourceView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            sourceView.centerXAnchor.constraint(equalTo: centerXAnchor),
            sourceView.bottomAnchor.constraint(equalTo: startVideoButton.topAnchor, constant: -27),

            startVideoButton.heightAnchor.constraint(equalToConstant: 50),
            startVideoButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            startVideoButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            startVideoButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor,
                                                     constant: -32)
        ])
    }
}


private extension Calling.VideoPreviewControls {

    @objc func cancelButtonTapped() {
        delegate?.cancelTapped()
    }
}


enum VideoSourceType {
    case phoneScreen
    case frontCamera
    case backCamera
}

protocol InputSourceViewDelegate: AnyObject {
    func didChangeSource(to source: VideoSourceType)
}

final class InputSourceView: UIView {

    private let stackView = UIStackView()
    private lazy var stackLeadingConstraint = leadingAnchor.constraint(equalTo: stackView.leadingAnchor)

    private lazy var phone = UIButton {
        $0.setTitle("PHONE SCREEN", for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        $0.setTitleColor(.white, for: .normal)
        $0.alpha = 0.5
        $0.addTarget(self, action: #selector(phoneTapped), for: .touchUpInside)
    }

    private lazy var front = UIButton {
        $0.setTitle("FRONT CAMERA", for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        $0.setTitleColor(.white, for: .normal)
        $0.addTarget(self, action: #selector(frontTapped), for: .touchUpInside)
    }

    private lazy var back = UIButton {
        $0.setTitle("BACK CAMERA", for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        $0.setTitleColor(.white, for: .normal)
        $0.alpha = 0.5
        $0.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
    }

    private weak var delegate: InputSourceViewDelegate?

    init(delegate: InputSourceViewDelegate) {
        self.delegate = delegate
        super.init(frame: .zero)

        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

extension InputSourceView {

    override var intrinsicContentSize: CGSize {
        stackView.intrinsicContentSize
    }
}

private extension InputSourceView {

    func setup() {
        stackView.axis = .horizontal
        stackView.distribution = .equalCentering
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        stackView.addArrangedSubviews([
            phone,
            front,
            back
        ])

        invalidateIntrinsicContentSize()

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 22),

            stackLeadingConstraint,
            stackView.widthAnchor.constraint(equalTo: widthAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}

private extension InputSourceView {

    @objc func phoneTapped() {
        didChangeSource(to: .phoneScreen)
    }

    @objc func frontTapped() {
        didChangeSource(to: .frontCamera)
    }

    @objc func backTapped() {
        didChangeSource(to: .backCamera)
    }

    func didChangeSource(to source: VideoSourceType) {
        delegate?.didChangeSource(to: source)

        let selected: UIButton
        switch source {
        case .phoneScreen:
            selected = phone
        case .frontCamera:
            selected = front
        case .backCamera:
            selected = back
        }

        UIView.animate(withDuration: 0.15) { [self] in
            selected.alpha = 1
            [phone, front, back].filter { $0 !== selected }.forEach { $0.alpha = 0.5 }

            setNeedsLayout()
            layoutIfNeeded()
        }
    }
}
