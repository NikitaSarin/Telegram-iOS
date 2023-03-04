//
//  Calling.ViewModel.swift
//  TelegramCalling
//
//  Created by Nikita Sarin on 25.11.2022.
//

import UIKit
import AVFoundation
import AccountContext
import SwiftSignalKit
import TelegramCore
import Postbox
import AvatarNode
import Display
import CallsEmoji

extension Calling {

    enum CallState {
        case waiting
        case reconnectiong
        case requesting
        case ringing
        case exchangingEncryptionKeys
        case inProgress(duration: TimeInterval)
        case ended
    }
}

extension Calling {

    final class ViewModel {

        private var _incomingVideoState: PresentationCallState.RemoteVideoState?
        private var _state: PresentationCallState.State?
        private var _chatPeer: Peer?
        private var _title: String?
        private var _debugTitle: String?
        private var _keyHash: Data?

        weak var view: Calling.ViewController?
        var incomingVideoView: Calling.VideoView? {
            didSet {
                _incomingVideoContent?.removeFromSuperview()
                incomingVideoView?.set(content: _incomingVideoContent)
            }
        }
        var outgoingVideoView: Calling.VideoView?  {
            didSet {
                _outgoingVideoContent?.removeFromSuperview()
                outgoingVideoView?.set(content: _outgoingVideoContent)
            }
        }

        private var _incomingVideoContent: UIView?
        private var _outgoingVideoContent: UIView?

        private let call: PresentationCallImpl
        private var disposables = DisposableSet()
        private var timeTimer: Foundation.Timer?

        init(call: PresentationCallImpl) {
            self.call = call
        }
    }
}

extension Calling.ViewModel: CallingViewModel {

    func start() {
        (call.state |> deliverOnMainQueue)
            .start { [weak self] in
                self?.process(state: $0)
            }
            .store(in: &disposables)
        let peer = context
            .engine
            .data
            .get(TelegramEngine.EngineData.Item.Peer.Peer(id: call.peerId))
        (peer |> deliverOnMainQueue)
            .start { [weak self] in
                self?._debugTitle = $0?.debugDisplayTitle
                let peer = $0?._asPeer()
                if self?._chatPeer == nil, let peer = peer {
                    self?.fetchImage(for: peer)
                }
                self?._chatPeer = $0?._asPeer()
                self?.updateTitle()
            }
            .store(in: &disposables)
        if call.isOutgoing, call.isVideo {
            call.makeOutgoingVideoView { [weak self] data in
                guard let data = data else { return }
                self?.outgoingVideoView?.set(content: data.view)
                self?._outgoingVideoContent = data.view
                data.setOnOrientationUpdated { orientation, ratio in
                    self?.outgoingVideoView?.set(rotation: orientation.viewRotation)
                    self?.outgoingVideoView?.set(ratio: CGFloat(ratio))
                }
                self?.view?.set(previewMode: .pip)
                self?.view?.panel.video.isOn = true
            }
        }
    }

    func stop() { }

    func backButtonTapped() { }
}

extension Calling.ViewModel: CallingButtonPanelDelegate {

    func speakerButtonTapped(isOn: Bool) {
        call.setCurrentAudioOutput(isOn ? .speaker : .builtin)
    }

    func videoButtonTapped(isOn: Bool) {
        if isOn {
            _outgoingVideoContent?.removeFromSuperview()
            call.makeOutgoingVideoView { [weak self] data in
                guard let data = data else { return }
                self?.outgoingVideoView?.set(content: data.view)
                self?._outgoingVideoContent = data.view
                data.setOnOrientationUpdated { orientation, _ in
                    self?.outgoingVideoView?.set(rotation: orientation.viewRotation)
                }
                data.setOnFirstFrameReceived { ratio in
                    self?.outgoingVideoView?.set(ratio: CGFloat(ratio))
                    self?.view?.set(previewMode: .fullScreen)
                }
            }
        } else {
            view?.set(previewMode: .hidden)
            view?.panel.setSpeaker(hidden: false)
            view?.panel.setFlip(hidden: true)
            call.disableVideo()
        }
    }

    func muteButtonTapped(isOn: Bool) {
        call.setIsMuted(isOn)
    }

    func endButtonTapped() {
        _ = call.hangUp()
    }

    func flipButtonTapped() {
        call.switchVideoCamera()
    }
}

extension Calling.ViewModel: CallingResponseViewDelegate {

    func acceptButtonTapped() {
        call.answer()
    }

    func declineButtonTapped() {
        _ = call.hangUp()
    }
}

extension Calling.ViewModel: CallingVideoPreviewControlsDelegate {

    func didChangeSource(to source: VideoSourceType) {
        switch source {
        case .phoneScreen:
            break
        case .frontCamera, .backCamera:
            call.switchVideoCamera()
        }
    }

    func startVideoTapped() {
        call.requestVideo()
        view?.set(previewMode: .pip)
        view?.panel.setSpeaker(hidden: true)
        view?.panel.setFlip(hidden: false)
    }

    func cancelTapped() {
        view?.panel.video.isOn = false
        view?.set(previewMode: .hidden)
        call.disableVideo()
    }
}

private extension Calling.ViewModel {

    var context: AccountContext { call.context }

    func process(state: PresentationCallState) {
        if state.remoteVideoState != _incomingVideoState {
            _incomingVideoState = state.remoteVideoState
            switch state.remoteVideoState {
            case .active:
                if _incomingVideoContent == nil {
                    call.makeIncomingVideoView { [weak self] data in
                        guard let data = data else { return }
                        self?.incomingVideoView?.set(content: data.view)
                        self?._incomingVideoContent = data.view
                        data.setOnOrientationUpdated { orientation, ratio in
                            self?.incomingVideoView?.set(rotation: orientation.viewRotation)
                            self?.incomingVideoView?.set(ratio: CGFloat(ratio))
                        }
                        data.setOnFirstFrameReceived { _ in
                            self?.view?.setIncomingVideoHidden(false)
                        }
                    }
                } else {
                    view?.setIncomingVideoHidden(false)
                }
            default:
                view?.setIncomingVideoHidden(true)
            }
        }
        if _state != state.state {
            _state = state.state
            var callEnded = false
            var weakSignal = false
            switch state.state {
            case .terminated:
                view?.set(previewMode: .hidden)
                callEnded = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    Calling.dismiss(animated: true)
                }
                timeTimer?.invalidate()
                timeTimer = nil
            case let .active(_, reception, keyHash):
                if _keyHash != keyHash,
                    let text = stringForEmojiHashOfData(keyHash, 4) {
                    _keyHash = keyHash
                    view?.set(encryptionKey: text)
                }
                let signal = Int(reception ?? 4)
                weakSignal = signal <= 1
                timeTimer?.invalidate()
                timeTimer = .scheduledTimer(withTimeInterval: 0.5,
                                            repeats: true,
                                            block: { [weak view] _ in
                    view?.infoView.set(state: state.state.viewState)
                })
                view?.infoView.set(signalQuality: signal)
            default: break
            }
            if state.state == .ringing {
                view?.setResponseViewHidden(call.isOutgoing, animated: false)
                view?.setCallInfoHidden(!call.isOutgoing, animated: false)
            } else {
                view?.setResponseViewHidden(true, animated: true)
                view?.setCallInfoHidden(callEnded, animated: true)
            }
            if weakSignal {
                view?.gradient.set(state: .weakSignal)
            } else {
                view?.gradient.set(state: state.state.gradientState)
            }
            view?.infoView.set(state: state.state.viewState)
        }
    }

    func fetchImage(for peer: Peer) {
        guard
            let representation = peer.largeProfileImage,
            let imageData = peerAvatarImageData(
                account: context.account,
                peerReference: PeerReference(peer),
                authorOfMessage: nil,
                representation: representation,
                synchronousLoad: false
            )
        else { return }

        let targetSize = CGSize(width: 136, height: 136)
        (imageData |> deliverOnMainQueue).start { [weak self] data in
            guard
                let (data, _) = data,
                let image = generateImage(
                    targetSize,
                    contextGenerator: { size, context -> Void in
                        if let imageSource = CGImageSourceCreateWithData(data as CFData, nil), let dataImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) {
                            context.setBlendMode(.copy)
                            context.draw(dataImage, in: CGRect(origin: CGPoint(), size: targetSize))
                        }
                    },
                    scale: 2.0
                )
            else { return }
            self?.view?.set(avatar: image)
        }.store(in: &disposables)
    }

    func updateTitle() {
        view?.set(name: _title ?? _debugTitle ?? "")
    }
}

extension  PresentationCallState.State {

    var gradientState: GradientViewController.State {
        switch self {
        case .terminating, .terminated, .waiting, .ringing, .requesting, .connecting, .reconnecting:
            return .initiatingCall
        case .active:
            return .callEstablished
        }
    }

    var viewState: Calling.CallState {
        switch self {
        case .ringing:
            return .ringing
        case .requesting:
            return .requesting
        case .connecting:
            return .exchangingEncryptionKeys
        case let .active(timestamp, _, _):
            return .inProgress(duration: CFAbsoluteTimeGetCurrent() - timestamp)
        case .waiting:
            return .waiting
        case .reconnecting(_, _, _):
            return .reconnectiong
        case .terminating, .terminated:
            return .ended
        }
    }
}

extension PresentationCallVideoView.Orientation {
    var viewRotation: Calling.VideoView.Rotation {
        switch self {
        case .rotation0: return .degrees0
        case .rotation90: return .degrees90
        case .rotation180: return .degrees180
        case .rotation270: return .degrees270
        }
    }
}
