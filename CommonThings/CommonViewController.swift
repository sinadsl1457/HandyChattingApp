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

/// class that common collects method and property
class CommonViewController: UIViewController {
    let currentUser = Auth.auth().currentUser
    var userImage: UIImage?
    var picker: PHPickerViewController = {
        var config = PHPickerConfiguration()
        config.filter = .any(of: [.images, .videos])
        config.selectionLimit = 1
        return PHPickerViewController(configuration: config)
    }()
    
    let database = Firestore.firestore()
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



