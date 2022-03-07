//
//  CommonViewController.swift
//  HandyChattingApp
//
//  Created by 황신택 on 2021/12/24.
//

import UIKit
import PhotosUI
import FirebaseFirestore
import FirebaseAuth
import Firebase
import KakaoSDKAuth

/// Class that common methods and properties.
class CommonViewController: UIViewController {
    /// Can access currentuser
    let currentUser = Auth.auth().currentUser
    /// Property for saving user image data
    var userImage: UIImage?
    /// Create an instance with a closure and initialize the property.
    var picker: PHPickerViewController = {
        var config = PHPickerConfiguration()
        config.filter = .any(of: [.images, .videos])
        config.selectionLimit = 1
        return PHPickerViewController(configuration: config)
    }()
    
    /// whenever access to reference use it
    let database = Firestore.firestore()
    
    /// using current user email for identification When accessing each user's data.
    var path: String {
        var path = ""
        if let currentUser = currentUser {
            currentUser.providerData.forEach {
                if let providerEmail = $0.email {
                    path = currentUser.email ?? providerEmail
                }
            }
        }
        return path
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
}



