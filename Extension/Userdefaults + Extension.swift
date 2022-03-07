//
//  Userdefaults + Extension.swift
//  HandyChattingApp
//
//  Created by 황신택 on 2022/03/03.
//

import Foundation

extension UserDefaults {
    static let suitName = "group.com.TaekToy.HandyChattingApp"
    static let extensions = UserDefaults(suiteName: suitName)!
    
    private enum Keys {
        static let badge = "badge"
    }
    
    var badge: Int {
        get { UserDefaults.extensions.integer(forKey: Keys.badge) }
        set { UserDefaults.extensions.set(newValue, forKey: Keys.badge) }
    }
    
}
