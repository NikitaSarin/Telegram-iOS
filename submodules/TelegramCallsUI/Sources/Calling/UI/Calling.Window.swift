//
//  Calling.Window.swift
//  TelegramCalling
//
//  Created by Nikita Sarin on 26.11.2022.
//

import UIKit

protocol CallingWindowDelegate: AnyObject {
    func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView?
}

extension Calling {

    final class Window: UIWindow {

        weak var delegate: CallingWindowDelegate?

        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            if let delegate = self.delegate {
                return delegate.hitTest(point, with: event)
            } else {
                return super.hitTest(point, with: event)
            }
        }
    }
}
