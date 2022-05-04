//
//  EaseOutFunctions.swift
//
//
//  Created by German Azcona on 5/4/22.
//

import Foundation
import UIKit

struct EaseOutFunctions {

    static func easeOutSine(_ value: CGFloat) -> CGFloat {
        let sign: CGFloat = value < 0 ? -1 : 1
        return sin((abs(value) * .pi) / 2.0) * sign
    }

    static func easeOutCubic(_ value: CGFloat) -> CGFloat {
        let sign: CGFloat = value < 0 ? -1 : 1
        return (1.0 - pow(1.0 - abs(value), 3.0)) * sign
    }

    /// sigmoid function: https://dhemery.github.io/DHE-Modules/technical/sigmoid/
    /// You can use this to progressively applies more or less transformations depending
    /// on what part of the transition we are.
    static func easeOutSigmoid(_ value: CGFloat, curvature: CGFloat = -0.5) -> CGFloat {
        let value: CGFloat = value
        let curvature: CGFloat = max(-1.0, min(1.0, curvature)) // cap it from -1 to 1.
        return (value - curvature * value) / (curvature - 2 * curvature * abs(value) + 1)
    }
}
