//
//  Calling.ViewController.swift
//  TelegramCalling
//
//  Created by Nikita Sarin on 24.11.2022.
//

import UIKit
import AVFoundation

extension Calling {

    final class ViewController: UIViewController {

        enum PreviewMode {
            case hidden
            case fullScreen
            case pip
        }

        var window: Calling.Window?
        var onAppear: VoidClosure?
        var onDisappear: VoidClosure?

        private let viewModel: CallingViewModel
        private(set) var previewMode: PreviewMode = .hidden
        private var callInfoHidden = false

        // Views
        let gradient = GradientViewController(state: .initiatingCall)
        let infoView = Calling.InfoView()

        private(set) lazy var panel = ButtonPanel(delegate: viewModel)

        private let avatarView = AvatarView()
        private let previewVideoView = Calling.VideoView()
        private let backgroundVideoView = Calling.VideoView()
        private lazy var previewControls = VideoPreviewControls(delegate: viewModel)
        private lazy var encryptionView = Calling.EncryptionView { [weak self] in
            self?.setAvatarHidden($0)
        }
        private lazy var responseView = Calling.ResponseView(delegate: viewModel)
        private lazy var backButton = BackButton { [weak self] in
            self?.viewModel.backButtonTapped()
        }

        // Constraints
        private lazy var infoTopSafeAreaConstraint = infoView.topAnchor.constraint(
            equalTo: encryptionView.topAnchor)
        private lazy var infoTopAvatarConstraint = infoView.topAnchor.constraint(
            equalTo: avatarView.bottomAnchor, constant: 40)
        private lazy var panelBottomConstraint = panel.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor,
            constant: -32)
        private lazy var responseBottomConstraint = responseView.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor,
            constant: 150)
        private lazy var encryptionTopConstraint = encryptionView.topAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.topAnchor)

        // Gestures
        private lazy var callInfoTapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(callInfoGestureTapped))
        private lazy var previewTapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(previewGestureTapped))

        init(
            window: Calling.Window,
            viewModel: CallingViewModel
        ) {
            self.window = window
            self.viewModel = viewModel
            super.init(nibName: nil, bundle: nil)

            modalPresentationStyle = .overCurrentContext
            modalTransitionStyle = .crossDissolve
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    }
}

// MARK: - Override

extension Calling.ViewController {

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()

        viewModel.start()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.alpha = 0
        view.transform = .identity.scaledBy(x: 1.2, y: 1.2)
        UIView.animate(withDuration: 0.2) {
            self.view.alpha = 1
            self.view.transform = .identity
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        onAppear?()
        setNeedsStatusBarAppearanceUpdate()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onDisappear?()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        switch previewMode {
        case .fullScreen:
            previewVideoView.frame = view.bounds
        case .pip:
            let width = view.bounds.width / (callInfoHidden ? 5 : 3)
            let height = width / 9 * 16
            let minY = min(view.bounds.height - view.safeAreaInsets.bottom - 12, panel.frame.minY)
            previewVideoView.frame = CGRect(
                x: view.bounds.width - width - 10,
                y: minY - height - 12,
                width: width,
                height: height
            )
        case .hidden:
            break
        }
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        viewModel.stop()
        super.dismiss(animated: flag) { [self] in
            window?.resignKey()
            window = nil
            completion?()
        }
    }
}

// MARK: - Interface

extension Calling.ViewController {

    func set(encryptionKey: String) {
        encryptionView.set(encryptionKey: encryptionKey)
    }

    func set(name: String) {
        infoView.set(name: name)
        encryptionView.set(name: name)
        avatarView.set(name: name)
    }

    func set(avatar: UIImage?) {
        avatarView.set(image: avatar)
    }

    func flipPreview() {
        previewVideoView.transform = .identity.scaledBy(x: -1, y: 1)
        UIView.animate(withDuration: 0.25) { [self] in
            previewVideoView.transform = .identity
        }
    }

    func set(previewMode: PreviewMode, animated: Bool = true) {
        self.previewMode = previewMode
        updatePreview(animated: animated)
    }

    func setResponseViewHidden(_ hidden: Bool, animated: Bool) {
        callInfoTapGesture.isEnabled = hidden
        responseBottomConstraint.constant = hidden ? 150 : -32
        func perform() {
            view.setNeedsLayout()
            view.layoutIfNeeded()
            responseView.alpha = hidden ? 0 : 1
        }
        if animated {
            UIView.animate(withDuration: 0.25) {
                perform()
            }
        } else {
            perform()
        }
    }

    func setIncomingVideoHidden(_ hidden: Bool) {
        updateIncomingVideoHidden(hidden)
    }

    func setButtonPanelHidden(_ hidden: Bool) {
        updateIncomingVideoHidden(hidden)
    }

    func setBackButtonHidden(_ hidden: Bool) {
        if backButton.showed {
            UIView.animate(withDuration: 0.25) {
                self.backButton.alpha = hidden ? 0 : 1
            }
        } else if !hidden {
            backButton.show()
        }
    }

    func setCallInfoHidden(_ hidden: Bool, animated: Bool = true) {
        let alpha: CGFloat = hidden ? 0 : 1
        func perform() {
            view.setNeedsLayout()
            view.layoutIfNeeded()
            panel.alpha = alpha
            encryptionView.alpha = alpha
            if backButton.showed {
                backButton.alpha = alpha
            }
        }
        panelBottomConstraint.constant = hidden ? 150 : -32
        encryptionTopConstraint.constant = hidden ? -50 : 0
        if animated {
            UIView.animate(withDuration: 0.25) {
                perform()
            }
        } else {
            perform()
        }
    }
}

// MARK: - CallingWindowDelegate

extension Calling.ViewController: CallingWindowDelegate {

    func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = view.hitTest(point, with: event)
        return result
    }
}

// MARK: - Layout

private extension Calling.ViewController {

    func setup() {
        backButton.alpha = 0
        responseView.alpha = 0
        gradient.view.addGestureRecognizer(callInfoTapGesture)
//        previewVideoView.addGestureRecognizer(previewTapGesture)
        backgroundVideoView.isUserInteractionEnabled = false

        addChild(gradient)
        view.addSubview(gradient.view)
        gradient.view.frame = view.bounds
        gradient.didMove(toParent: self)

        updatePreview(animated: false)
        previewVideoView.frame = view.bounds

        func add(subview: UIView, to parent: UIView = view) {
            subview.translatesAutoresizingMaskIntoConstraints = false
            parent.addSubview(subview)
        }

        add(subview: avatarView)
        add(subview: backgroundVideoView)
        add(subview: panel)
        add(subview: responseView)
        add(subview: infoView)
        view.addSubview(previewVideoView)
        add(subview: encryptionView)
        add(subview: backButton)
        add(subview: previewControls, to: previewVideoView)

        backgroundVideoView.pin(to: view)
        previewControls.pin(to: previewVideoView)
        backgroundVideoView.alpha = 0

        NSLayoutConstraint.activate([
            avatarView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            avatarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 160),

            infoView.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 40),
            infoView.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            panel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            panel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            panelBottomConstraint,

            responseView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.65),
            responseView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            responseBottomConstraint,

            backButton.topAnchor.constraint(equalTo: encryptionView.topAnchor),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor),

            encryptionTopConstraint,
            encryptionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            encryptionView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        viewModel.incomingVideoView = backgroundVideoView
        viewModel.outgoingVideoView = previewVideoView
    }

    func updatePreview(animated: Bool) {
        switch previewMode {
        case .hidden:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
                previewVideoView.frame = view.bounds
            }
            viewModel.incomingVideoView = backgroundVideoView
            viewModel.outgoingVideoView = previewVideoView
        case .fullScreen:
            let location = CGPoint(x: view.bounds.width / 2, y:  view.bounds.height)
            let edge: CGFloat = 40
            let mask = CALayer()
            mask.backgroundColor = UIColor.black.cgColor
            mask.frame = CGRect(origin: CGPoint(x: location.x - edge / 2, y: location.y - edge / 2),
                                size: CGSize(width: edge, height: edge))
            mask.cornerRadius = edge / 2

            let transform = CATransform3DScale(CATransform3DIdentity, 100, 100, 1)
            let transformAnimation = CABasicAnimation(keyPath: "transform")
            transformAnimation.duration = 0.4
            transformAnimation.fromValue = NSValue(caTransform3D: mask.transform)
            transformAnimation.toValue = NSValue(caTransform3D: transform)
            transformAnimation.fillMode = .forwards
            transformAnimation.timingFunction = CAMediaTimingFunction(name: .easeIn)
            mask.transform = transform
            mask.add(transformAnimation, forKey: "transform")

            previewVideoView.layer.mask = mask

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
                previewVideoView.layer.mask = nil
            }
        default: break
        }

        previewTapGesture.isEnabled = previewMode == .pip
        previewControls.alpha = previewMode == .fullScreen ? 1 : 0

        func perform() {
            previewVideoView.alpha = previewMode == .hidden ? 0 : 1
            previewVideoView.layer.cornerRadius = previewMode == .pip ? 12 : 0

            view.setNeedsLayout()
            view.layoutIfNeeded()
        }

        if animated {
            UIView.animate(withDuration: 0.2) {
                perform()
            }
        } else {
            perform()
        }
    }

    func updateIncomingVideoHidden(_ hidden: Bool) {
        let location = avatarView.center
        let edge: CGFloat = 136
        let mask = CALayer()
        mask.backgroundColor = UIColor.black.cgColor
        mask.cornerRadius = edge / 2

        if hidden {
            mask.frame = CGRect(origin: CGPoint(x: location.x - edge / 2, y: location.y),
                                size: CGSize(width: edge, height: edge))
            viewModel.incomingVideoView = backgroundVideoView
            viewModel.outgoingVideoView = previewVideoView

            let fromTransform = CATransform3DScale(CATransform3DIdentity, 10, 10, 1)
            let toTransform = CATransform3DScale(CATransform3DIdentity, 1 / 100, 1 / 100, 1)
            mask.transform = fromTransform
            let transformAnimation = CABasicAnimation(keyPath: "transform")
            transformAnimation.duration = 0.35
            transformAnimation.fromValue = NSValue(caTransform3D: fromTransform)
            transformAnimation.toValue = NSValue(caTransform3D: toTransform)
            transformAnimation.fillMode = .forwards
            transformAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            mask.transform = toTransform
            mask.add(transformAnimation, forKey: "transform")

            backgroundVideoView.layer.mask = mask
            UIView.animate(withDuration: 0.2, delay: 0.1) { [self] in
                backgroundVideoView.alpha = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
                previewVideoView.layer.mask = nil
            }
        } else {
            mask.frame = CGRect(origin: CGPoint(x: location.x - edge / 2, y: location.y - edge / 2),
                                size: CGSize(width: edge, height: edge))
            let transform = CATransform3DScale(CATransform3DIdentity, 100, 100, 1)
            let transformAnimation = CABasicAnimation(keyPath: "transform")
            transformAnimation.duration = 1
            transformAnimation.fromValue = NSValue(caTransform3D: mask.transform)
            transformAnimation.toValue = NSValue(caTransform3D: transform)
            transformAnimation.fillMode = .forwards
            transformAnimation.timingFunction = CAMediaTimingFunction(name: .easeIn)
            mask.transform = transform
            mask.add(transformAnimation, forKey: "transform")

            backgroundVideoView.layer.mask = mask
            backgroundVideoView.alpha = 1

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
                previewVideoView.layer.mask = nil
            }
        }
        infoTopSafeAreaConstraint.isActive = !hidden
        infoTopAvatarConstraint.isActive = hidden
        infoView.setLarge(hidden)

        UIView.animate(withDuration: 0.2) {
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }
}

private extension Calling.ViewController {

    @objc func callInfoGestureTapped() {
        callInfoHidden = !callInfoHidden
        setCallInfoHidden(callInfoHidden, animated: true)
    }

    @objc func previewGestureTapped() {
        guard
            previewVideoView.alpha == 1,
            backgroundVideoView.alpha == 1
        else { return }

        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            options: .curveEaseInOut,
            animations: { [self] in
                previewVideoView.transform = .identity.scaledBy(x: 0.9, y: 0.9)
            }, completion: { [self] _ in
                previewVideoView.transform = .identity
            }
        )
        if viewModel.outgoingVideoView === previewVideoView {
            viewModel.incomingVideoView = previewVideoView
            viewModel.outgoingVideoView = backgroundVideoView
        } else {
            viewModel.incomingVideoView = backgroundVideoView
            viewModel.outgoingVideoView = previewVideoView
        }
    }

    func setAvatarHidden(_ hidden: Bool) {
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: .curveEaseInOut
        ) { [self] in
            self.avatarView.transform = hidden ? .identity.scaledBy(x: 0.01, y: 0.01) : .identity
            self.avatarView.alpha = hidden ? 0 : 1
        }
    }
}
