//
//  Calling.swift
//  TelegramCalls
//
//  Created by Nikita Sarin on 27.02.2023.
//

import AVFoundation
import UIKit

extension Calling {

    final class VideoView: UIView {

        enum Rotation {
            case degrees0
            case degrees90
            case degrees180
            case degrees270

            var angle: CGFloat {
                switch self {
                case .degrees0: return 0
                case .degrees90: return 90
                case .degrees180: return 180
                case .degrees270: return 270
                }
            }
        }

        private lazy var blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))

        private weak var content: UIView?
        private var rotation: Rotation = .degrees0
        private var ratio: CGFloat = 9 / 16

        private var ratioContentConstraint: NSLayoutConstraint?

        override init(frame: CGRect = .zero) {
            super.init(frame: frame)
            setup()
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func layoutSubviews() {
            super.layoutSubviews()
            guard let content = content else { return }
            switch rotation {
            case .degrees0, .degrees180:
                let width = bounds.width
                let height = width / ratio
                content.frame = CGRect(origin: CGPoint(x: (bounds.width - width) / 2,
                                                       y: (bounds.height - height) / 2),
                                       size: CGSize(width: width, height: height))
            case .degrees90, .degrees270:
                let height = bounds.height
                let width = height * ratio
                content.frame = CGRect(origin: .zero,
                                        size: CGSize(width: width, height: height))
            }
        }

        func set(content: UIView?) {
            if let new = content {
                insertSubview(new, at: 0)
            }
            self.content = content
            apply(rotation: rotation)
        }

        func set(rotation: Rotation) {
            self.rotation = rotation
            apply(rotation: rotation)
        }

        func set(ratio: CGFloat) {
            self.ratio = ratio
            superview?.setNeedsLayout()
            superview?.layoutIfNeeded()
        }
    }
}

private extension Calling.VideoView {

    func setup() {
        backgroundColor = .black
        clipsToBounds = true

        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.isUserInteractionEnabled = false
        blurView.alpha = 0
        addSubview(blurView)
        blurView.pin(to: self)
    }

    func apply(rotation: Rotation) {
        let angle = rotation.angle * .pi / 180
        content?.transform = .identity.rotated(by: angle)
        superview?.setNeedsLayout()
        superview?.layoutIfNeeded()
    }
}
