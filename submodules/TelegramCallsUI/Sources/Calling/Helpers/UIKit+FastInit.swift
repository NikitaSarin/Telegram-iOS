//
//  UIKit+FastInit.swift
//  Pivanji
//
//  Created by Сарин Никита Сергеевич on 27.01.2021.
//  Copyright © 2021 Urodsk. All rights reserved.
//

import UIKit

extension UIView {
    @objc convenience init(_ configurator: (UIView) -> Void) {
        self.init()
        configurator(self)
    }
}

extension UILabel {
    @objc convenience init(_ configurator: (UILabel) -> Void) {
        self.init()
        configurator(self)
    }
}

extension UIStackView {
    @objc convenience init(_ configurator: (UIStackView) -> Void) {
        self.init()
        configurator(self)
    }
}

extension UIControl {
    @objc convenience init(_ configurator: (UIControl) -> Void) {
        self.init()
        configurator(self)
    }
}

extension UIButton {
    @objc convenience init(_ configurator: (UIButton) -> Void) {
        self.init()
        configurator(self)
    }
}

extension UITableView {
    @objc convenience init(_ configurator: (UITableView) -> Void) {
        self.init()
        configurator(self)
    }
}

extension UIImageView {
    @objc convenience init(_ configurator: (UIImageView) -> Void) {
        self.init()
        configurator(self)
    }
}

extension UISlider {
    @objc convenience init(_ configurator: (UISlider) -> Void) {
        self.init()
        configurator(self)
    }
}

extension UIPickerView {
    @objc convenience init(_ configurator: (UIPickerView) -> Void) {
        self.init()
        configurator(self)
    }
}
