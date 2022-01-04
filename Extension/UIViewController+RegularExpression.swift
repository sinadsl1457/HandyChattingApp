//
//  UIViewController+RegularExpression.swift
//  HandyChattingApp
//
//  Created by 황신택 on 2021/12/17.
//

import UIKit

/// 정규식
/// - Author: 안상희
struct Regex {
    /// 이메일 주소를 검증하기 위한 정규식
    static let email = "^([a-z0-9_\\.-]+)@([\\da-z\\.-]+)\\.([a-z\\.]{2,6})$"
    
    /// 아이디를 검증하기 위한 정규식
    ///
    /// 영문 소문자로 시작하는 아이디, 길이는 5~15자, 끝날 때 제한이 없습니다.
    static let id = "^[a-z]{5,15}/g"
    
    /// 비밀번호를 검증하기 위한 정규식
    ///
    /// 최소 8 자, 대문자 하나 이상, 소문자 하나, 숫자 하나 및 특수 문자 하나 이상입니다.
    static let password = #"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[$@$!%*?&])[A-Za-z\d$@$!%*?&]{8,}"#
}

/// 이메일 / 비밀번호 정규식 검증 익스텐션
/// - Author: 황신택 (sinadsl1457@gmail.com)
extension UIViewController {
    /// 이메일 주소의 형식을 검증합니다.
    /// - Parameter email: 사용자 이메일
    /// - Returns: 검증에 성공하면 true, 실패하면 false를 리턴합니다.
    /// - Author: 황신택 (sinadsl1457@gmail.com)
    func isEmailValid(_ email: String) -> Bool {
        if let range = email.range(of: Regex.email, options: [.regularExpression]), (range.lowerBound, range.upperBound) == (email.startIndex, email.endIndex) {
            return true
        }
        return false
    }

       
    /// 암호 문자열의 형식을 검증합니다.
    /// - Parameter password: 사용자 암호
    /// - Returns: 검증에 성공하면 true, 실패하면 false를 리턴합니다.
    /// - Author: 황신택 (sinadsl1457@gmail.com)
    func isPasswordValid(_ password : String) -> Bool{
        if let range = password.range(of: Regex.password, options: [.regularExpression]), (range.lowerBound, range.upperBound) == (password.startIndex, password.endIndex) {
            return true
        }
        return false
    }

}
