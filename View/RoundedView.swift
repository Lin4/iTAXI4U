//
//  RoundedView.swift
//  iTaxi
//
//  Created by Lingeswaran Kandasamy on 1/2/18.
//  Copyright © 2018 Lingeswaran Kandasamy. All rights reserved.
//

import UIKit

class RoundedView: UIView {
    @IBInspectable var borderColor: UIColor? {
        didSet{
             setupView()
        }
    }
    override func awakeFromNib() {
        setupView()
    }
    func setupView() {
        self.layer.cornerRadius = self.frame.size.width/2
        self.layer.borderWidth = 1.2
        self.layer.borderColor = #colorLiteral(red: 0.1019607857, green: 0.2784313858, blue: 0.400000006, alpha: 1)
    }
}
