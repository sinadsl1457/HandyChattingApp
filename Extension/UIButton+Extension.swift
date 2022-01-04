//
//  UIButton+Extension.swift
//  UIButton+Extension
//
//  Created by 안상희 on 2021/08/08.
//

import Foundation
import UIKit


extension UIButton {
    /// 기본 버튼 테마를 설정합니다. 버튼이 Enabled 되어있을 때 사용합니다.
    /// - Author: 안상희
    func setToEnabledButtonTheme() {
        self.backgroundColor = UIColor(named: "black")
        self.tintColor = UIColor.white
        self.frame.size.height = 40
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
    }
    
    
    /// 기본 버튼 테마를 설정합니다. 버튼이 Disabled 되었을 때 사용합니다.
    /// - Author: 안상희
    func setToDisabledButtonTheme() {
        self.backgroundColor = UIColor(named: "lightGrayNonSelectedColor")
        self.tintColor = UIColor.white
        self.frame.size.height = 40
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
    }
}
