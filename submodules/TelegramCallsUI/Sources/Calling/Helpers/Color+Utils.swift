//
//  Color+Utils.swift
//  TelegramCalls
//
//  Created by Nikita Sarin on 21.02.2023.
//

import UIKit

extension UIColor {

    struct Components {
        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        let alpha: CGFloat
    }

    var components: Components {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return Components(red: red, green: green, blue: blue, alpha: alpha)
    }

    convenience init(hex: String) {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        if ((cString.count) != 6) {
            fatalError()
        }
        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        self.init(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }

    func interpolated(to another: UIColor, progress: CGFloat) -> UIColor {
        let from = components
        let to = another.components
        return UIColor(
            red: from.red + progress * (to.red - from.red),
            green: from.green + progress * (to.green - from.green),
            blue: from.blue + progress * (to.blue - from.blue),
            alpha: from.alpha + progress * (to.alpha - from.alpha)
        )
    }
}


extension UIColor {

    var mtl: SIMD4<Float> {
        let components = cgColor.components!
        return SIMD4<Float>(
            Float(components[0]),
            Float(components[1]),
            Float(components[2]),
            Float(components[3]))
    }
}
