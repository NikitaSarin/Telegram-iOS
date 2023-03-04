//
//  Calling.KeyView.swift
//  TelegramCalls
//
//  Created by Nikita Sarin on 01.03.2023.
//

import UIKit

extension Calling {

    final class KeyView: ResponsiveControl {

        private let stackView = UIStackView {
            $0.spacing = 30
            $0.axis = .horizontal
            $0.distribution = .equalCentering
            $0.alignment = .center
        }

        override init(action: VoidClosure?) {
            super.init(action: action)
            needTransform = false
            setup()
        }

        required init?(coder: NSCoder) {  fatalError("init(coder:) has not been implemented")  }


        func set(key: String) {
            alpha = 0
            stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

            for letter in key {
                let label = UILabel {
                    $0.font = .systemFont(ofSize: 38)
                    $0.text = String(letter)
                }
                stackView.addArrangedSubview(label)
            }
            setNeedsLayout()
            layoutIfNeeded()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) { [self] in
                    stackView.spacing = 4
                    alpha = 1
                }
            }
        }

        func set(large: Bool) {
            stackView.transform = large ? .identity :  .identity.scaledBy(x: 0.55, y: 0.55)
        }

        private func setup() {
            stackView.isUserInteractionEnabled = false
            alpha = 0
            addSubview(stackView)
            stackView.pin(to: self)
        }
    }
}
