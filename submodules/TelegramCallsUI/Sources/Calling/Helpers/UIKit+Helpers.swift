//
//  UIKit+Helpers.swift
//  TelegramCalls
//
//  Created by Nikita Sarin on 03.03.2023.
//

import UIKit

extension UIEdgeInsets {
    init(horizontal: CGFloat, vertical: CGFloat) {
        self.init(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
    }

    init(all: CGFloat) {
        self.init(top: all, left: all, bottom: all, right: all)
    }
}

extension UIView {

    func pin(to view: UIView, insets: UIEdgeInsets = .zero) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -insets.right),
            topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top),
            bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -insets.bottom)
        ])
    }
}


extension UIImage {

    func inversed(size: CGSize, offset: CGFloat, background: UIColor) -> UIImage {
        let rect = CGRect(x: offset,
                          y: offset,
                          width: size.width - offset * 2,
                          height: size.height - offset * 2)
        let renderer = UIGraphicsImageRenderer(size: size)

        let result = renderer.image { ctx in
            background.set()
            ctx.fill(CGRect(origin: .zero, size: size))
            draw(in: rect, blendMode: .destinationOut, alpha: 1)
        }
        return result
    }
}
