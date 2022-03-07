//
//  UIVIewController+Alert.swift
//  HandyChattingApp
//
//  Created by 황신택 on 2021/12/17.
//

import UIKit

extension UIViewController {
    /// Use it when there is notification to user.
    /// - Parameters:
    ///   - title: notification title
    ///   - message: notification content
    ///   - handler: UIAlertAction
    func alert(title: String = "알림", message: String, handler: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "확인", style: .default, handler: handler)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    
    /// Use it when choose ok or cancel
    /// - Parameters:
    ///   - title: notification title
    ///   - message: notification content
    ///   - handler: UIAlertAction
    func chooseAlert(title: String = "알림", message: String, handler: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "확인", style: .default, handler: handler)
        alert.addAction(okAction)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
