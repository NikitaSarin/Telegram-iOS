//
//  TipView.swift
//  TelegramCalls
//
//  Created by Nikita Sarin on 28.02.2023.
//

import UIKit

final class TipView: UIView {

    private let titleLabel = UILabel {
        $0.font = .systemFont(ofSize: 16)
        $0.textColor = .white
    }

    private let blurView = UIVisualEffectView.backgroundBlur

    init(title: String) {
        super.init(frame: .zero)
        self.titleLabel.text = title

        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setup() {
        layer.cornerRadius = 20
        clipsToBounds = true

        [blurView, titleLabel].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        blurView.pin(to: self)
        titleLabel.pin(to: self, insets: .init(horizontal: 12, vertical: 6))
    }
}
