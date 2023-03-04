//
//  AvatarView.swift
//  TelegramCalls
//
//  Created by Nikita Sarin on 28.02.2023.
//

import UIKit

class AvatarView: UIView {

    enum Appearence {
        static let edge: CGFloat = 136
    }

    private let containerView = UIImageView {
        $0.backgroundColor = UIColor(red: 0.125, green: 0.58, blue: 0.98, alpha: 1)
        $0.layer.cornerRadius = Appearence.edge / 2
        $0.clipsToBounds = true
    }

    private let imageView = UIImageView {
        $0.contentMode = .scaleAspectFit
    }

    private let label = UILabel {
        $0.font = .systemFont(ofSize: 40, weight: .medium)
        $0.textColor = .white
    }

    private let gradientLayer: CALayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor(white: 1, alpha: 0),
            UIColor(white: 1, alpha: 0.3)
        ].map { $0.cgColor }
        layer.startPoint = CGPoint(x: 0.5, y: 0)
        layer.endPoint = CGPoint(x: 0.5, y: 1)
        return layer
    }()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = containerView.bounds
    }

    func set(name: String) {
        let components = name.components(separatedBy: " ")
        var result = ""
        if let firstName = components.first?.prefix(1) {
            result = String(firstName).capitalized
        }
        if components.count > 1 {
            let secondName = components[1].prefix(1)
            result += " "
            result += String(secondName).capitalized
        }
        label.text = result
    }

    func set(image: UIImage?) {
        imageView.image = image
    }
}

private extension AvatarView {

    func setup() {
        [containerView, imageView, label].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        addSubview(containerView)
        containerView.addSubview(label)
        containerView.layer.addSublayer(gradientLayer)
        containerView.addSubview(imageView)

        containerView.pin(to: self)
        imageView.pin(to: containerView)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),

            widthAnchor.constraint(equalToConstant: Appearence.edge),
            heightAnchor.constraint(equalTo: widthAnchor)
        ])
    }
}
