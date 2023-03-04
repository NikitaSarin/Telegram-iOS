//
//  ActionButton.swift
//  TelegramCalls
//
//  Created by Nikita Sarin on 24.02.2023.
//

import UIKit

final class ActionButton: ResponsiveControl {

    private let titleLabel = UILabel {
        $0.font = .systemFont(ofSize: 17, weight: .bold)
        $0.textColor = .black
    }

    init(title: String, action: VoidClosure?) {
        super.init(action: action)

        titleLabel.text = title
        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

private extension ActionButton {

    func setup() {
        layer.cornerRadius = 10
        backgroundColor = .white
        layer.compositingFilter = "screenBlendMode"

        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            heightAnchor.constraint(equalToConstant: 50)
        ])
    }
}
