//
//  Calling.swift
//  TelegramCalls
//
//  Created by Nikita Sarin on 23.02.2023.
//

import UIKit
import AVFoundation
import SwiftSignalKit
import Display

public enum Calling {

    public struct Input {

        let call: PresentationCallImpl
        let appearPromise: ValuePromise<Bool>
        let lockPortrait: (Bool) -> Void

        public init(
            call: PresentationCallImpl,
            appearPromise: ValuePromise<Bool>,
            lockPortrait: @escaping (Bool) -> Void
        ) {
            self.call = call
            self.appearPromise = appearPromise
            self.lockPortrait = lockPortrait
        }
    }


    static weak var viewController: UIViewController?

    public static func present(input: Calling.Input) {
        input.lockPortrait(true)
        let window = Calling.Window()
        let viewController = make(input: input, window: window)
        window.delegate = viewController
        window.backgroundColor = .clear
        window.windowLevel = .alert
        window.rootViewController = UIViewController()

        func perform() {
            let old = Self.viewController
            Self.viewController = viewController
            if let old = old {
                old.dismiss(animated: true) {
                    window.makeKeyAndVisible()
                    window.rootViewController?.present(viewController, animated: true)
                }
            } else {
                window.makeKeyAndVisible()
                window.rootViewController?.present(viewController, animated: true)
            }
        }

        if UIApplication.shared.statusBarOrientation.isLandscape {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                perform()
            }
        } else {
            perform()
        }
    }

    public static func dismiss(animated: Bool) {
        Calling.viewController?.dismiss(animated: animated)
    }

    private static func make(input: Calling.Input, window: Calling.Window) -> Calling.ViewController {
        let viewModel = Calling.ViewModel(call: input.call)
        let viewController = Calling.ViewController(window: window, viewModel: viewModel)
        viewModel.view = viewController

        viewController.onAppear = {
            input.appearPromise.set(true)
        }
        viewController.onDisappear = {
            if Calling.viewController == viewController {
                input.appearPromise.set(false)
                input.lockPortrait(false)
            }
        }
        return viewController
    }
}

protocol CallingViewModel: CallingButtonPanelDelegate,
                           CallingResponseViewDelegate,
                           CallingVideoPreviewControlsDelegate {

    var incomingVideoView: Calling.VideoView? { get set }

    var outgoingVideoView: Calling.VideoView? { get set }

    func start()

    func stop()

    func backButtonTapped()
}
