//
//  CircleButton.swift
//  TelegramCalling
//
//  Created by Nikita Sarin on 25.11.2022.
//

import UIKit

class CircleButton: ResponsiveControl {

    fileprivate let imageView = UIImageView {
        $0.contentMode = .scaleAspectFit
        $0.tintColor = .white
    }

    fileprivate let imageContainer = UIView {
        $0.isUserInteractionEnabled = false
        $0.layer.cornerRadius = 28
        $0.clipsToBounds = true
    }

    private let label = UILabel {
        $0.isUserInteractionEnabled = false
        $0.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        $0.textColor = .white
    }

    private let imageInset: CGFloat

    init(
        title: String,
        background: UIColor,
        imageName: String,
        imageInset: CGFloat = 1,
        action: VoidClosure?
    ) {
        self.imageInset = imageInset
        super.init(action: action)

        imageView.image = UIImage(bundleImageName: imageName)?.withRenderingMode(.alwaysTemplate)
        imageContainer.backgroundColor = background
        label.text = title

        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

private extension CircleButton {

    func setup() {
        [imageContainer, imageView, label].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        imageContainer.addSubview(imageView)
        addSubview(imageContainer)
        addSubview(label)

        NSLayoutConstraint.activate([
            imageContainer.topAnchor.constraint(equalTo: topAnchor),
            imageContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageContainer.widthAnchor.constraint(equalToConstant: 56),
            imageContainer.heightAnchor.constraint(equalTo: imageContainer.widthAnchor),

            imageView.topAnchor.constraint(equalTo: imageContainer.topAnchor,
                                           constant: imageInset),
            imageView.leadingAnchor.constraint(equalTo: imageContainer.leadingAnchor,
                                               constant: imageInset),
            imageView.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: imageContainer.centerYAnchor),

            label.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.heightAnchor.constraint(equalToConstant: 14),
            label.topAnchor.constraint(equalTo: imageContainer.bottomAnchor, constant: 6),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}

final class ToggleCircleButton: CircleButton {

    private let filledImageView = UIImageView {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.isUserInteractionEnabled = false
        $0.contentMode = .scaleAspectFit
        $0.layer.cornerRadius = 28
        $0.clipsToBounds = true
        $0.alpha = 0
    }

    var isOn: Bool = false {
        didSet {
            imageContainer.alpha = isOn ? 0 : 1
            filledImageView.alpha = isOn ? 1 : 0
        }
    }

    private let action: (Bool) -> Void

    init(
        title: String,
        background: UIColor,
        imageName: String,
        imageInset: CGFloat = 1,
        action: @escaping (Bool) -> Void
    ) {
        self.action = action
        super.init(title: title, background: background, imageName: imageName, action: nil)
        let inversed = imageView.image?.inversed(size: CGSize(width: 56, height: 56),
                                       offset: imageInset,
                                       background: .white)
        filledImageView.image = inversed
        addSubview(filledImageView)
        filledImageView.pin(to: imageContainer)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func didTouchUpInside() {
        super.didTouchUpInside()
        isOn = !isOn
        action(isOn)
    }
}

final class BackButton: ResponsiveControl {

    private let stackView = UIStackView {
        $0.axis = .horizontal
        $0.alignment = .center
        $0.distribution = .equalCentering
        $0.spacing = 30
        $0.isUserInteractionEnabled = false
    }

    private let imageView = UIImageView {
        $0.image = UIImage(bundleImageName: "Call/back")?.withRenderingMode(.alwaysTemplate)
        $0.tintColor = .white
    }

    private let label = UILabel {
        $0.text = "Back"
        $0.font = .systemFont(ofSize: 17)
        $0.textColor = .white
    }

    override init(action: VoidClosure?) {
        super.init(action: action)
        setup()
    }

    var showed = false

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func show() {
        showed = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) { [self] in
                stackView.spacing = -2
                alpha = 1
                transform = .identity
            }
        }
    }
}

private extension BackButton {

    func setup() {
        transform = .identity.translatedBy(x: 50, y: 0)
        alpha = 0
        addSubview(stackView)
        stackView.pin(to: self)
        stackView.addArrangedSubviews(imageView, label)
    }
}
