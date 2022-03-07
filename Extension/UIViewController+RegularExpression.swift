//
//  UIViewController+RegularExpression.swift
//  HandyChattingApp
//
//  Created by 황신택 on 2021/12/17.
//

import UIKit

/// Regular Expression
struct Regex {
    /// Regular expression to verify your email address.
    static let email = "^([a-z0-9_\\.-]+)@([\\da-z\\.-]+)\\.([a-z\\.]{2,6})$"
    
    /// Regular expression to verify your ID.
    /// The ID that starts with lowercase English characters, the length is 5 to 15 characters, and there is no limit at the end.
    static let id = "^[a-z]{5,15}/g"
    
    /// Regular expression to verify your Passwod.
    /// There are at least 8 characters, at least one uppercase letter, one lowercase letter, one number, and at least.
    static let password = #"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[$@$!%*?&])[A-Za-z\d$@$!%*?&]{8,}"#
}


extension UIViewController {
    /// Verifies the format of the email address.
    /// - Parameter email: user email
    /// - Returns: if success verified email return true otherwise false
    func isEmailValid(_ email: String) -> Bool {
        if let range = email.range(of: Regex.email, options: [.regularExpression]), (range.lowerBound, range.upperBound) == (email.startIndex, email.endIndex) {
            return true
        }
        return false
    }

       
    /// Verifies the format of the password address.
    /// - Parameter password: user password
    /// - Returns: if success verified passwrod return true otherwise false
    func isPasswordValid(_ password : String) -> Bool{
        if let range = password.range(of: Regex.password, options: [.regularExpression]), (range.lowerBound, range.upperBound) == (password.startIndex, password.endIndex) {
            return true
        }
        return false
    }

}
