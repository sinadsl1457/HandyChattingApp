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

class CommonViewController: UIViewController {
    let currentUser = Auth.auth().currentUser
    var userImage: UIImage?
    var picker: PHPickerViewController = {
        var config = PHPickerConfiguration()
        config.filter = .any(of: [.images, .videos])
        config.selectionLimit = 1
        return PHPickerViewController(configuration: config)
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
}


