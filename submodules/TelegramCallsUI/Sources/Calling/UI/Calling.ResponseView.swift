//
//  Calling.ResponseView.swift
//  TelegramCalls
//
//  Created by Nikita Sarin on 02.03.2023.
//

import UIKit

protocol CallingResponseViewDelegate: AnyObject {
    func acceptButtonTapped()
    func declineButtonTapped()
}

extension Calling {

    final class ResponseView: UIStackView {

        private lazy var accept = CircleButton(
            title: "accept",
            background: Appereance.greenColor,
            imageName: "Call/CallAcceptButton"
        ) { [weak self] in
            self?.delegate?.acceptButtonTapped()
        }

        private lazy var decline = CircleButton(
            title: "decline",
            background: Appereance.redColor,
            imageName: "Call/CallDeclineButton"
        ) { [weak self] in
            self?.delegate?.declineButtonTapped()
        }

        private weak var delegate: CallingResponseViewDelegate?

        init(delegate: CallingResponseViewDelegate) {
            self.delegate = delegate
            super.init(frame: .zero)

            setup()
        }

        required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    }
}

private extension Calling.ResponseView {

    enum Appereance {
        static let greenColor = UIColor(hex:"73DA59")
        static let redColor = UIColor(hex:"FF3B30")
    }

    func setup() {
        axis = .horizontal
        distribution = .equalCentering
        addArrangedSubviews(decline, accept)
    }
}
