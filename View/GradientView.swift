//
//  GradientView.swift
//  iTaxi
//
//  Created by Lingeswaran Kandasamy on 1/2/18.
//  Copyright © 2018 Lingeswaran Kandasamy. All rights reserved.
//

import UIKit

@IBDesignable
class GradientView: UIView {
    @IBInspectable var topColor: UIColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) {
            didSet {
                self.setNeedsLayout()
            }
        }
        @IBInspectable var bottomColor: UIColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.3991598887) {
            didSet {
                self.setNeedsLayout()
            }
        }
        override func layoutSubviews() {
            let greadientLayer = CAGradientLayer()
            greadientLayer.colors = [topColor.cgColor, bottomColor.cgColor]
            greadientLayer.startPoint = CGPoint(x: 1, y: 1)
            greadientLayer.endPoint = CGPoint(x:0, y: 0)
            greadientLayer.frame = self.bounds
            self.layer.insertSublayer(greadientLayer, at: 0)
        }
    }

