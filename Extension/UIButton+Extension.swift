//
//  UIButton+Extension.swift
//  UIButton+Extension
//
//  Created by 안상희 on 2021/08/08.
//

import Foundation
import UIKit


extension UIButton {
    /// Set the default button theme. Use it when the button is enabled.
    func setToEnabledButtonTheme() {
        self.backgroundColor = UIColor(named: "black")
        self.tintColor = UIColor.white
        self.frame.size.height = 40
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
    }
    
    
    /// Set the default button theme. Use when the button is disabled.
    func setToDisabledButtonTheme() {
        self.backgroundColor = UIColor(named: "lightGrayNonSelectedColor")
        self.tintColor = UIColor.white
        self.frame.size.height = 40
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
    }
}
