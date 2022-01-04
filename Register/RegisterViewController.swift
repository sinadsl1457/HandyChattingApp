//
//  RegisterViewController.swift
//  HandyChattingApp
//
//  Created by 황신택 on 2021/12/17.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import Firebase
import PhotosUI
import KakaoSDKAuth

class RegisterViewController: CommonViewController {
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var uploadBtn: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var repeatPasswordTextField: UITextField!
    
    
    @IBAction func completeBtn(_ sender: Any) {
        guard let email = emailTextField.text,
              let name = nameTextField.text,
              let password = passwordTextField.text,
              let repeatPassword = repeatPasswordTextField.text else { return }
        
        guard isEmailValid(email) else {
            alert(message: "you should enter right email form.")
            return
        }
        
        guard isPasswordValid(password) else {
            alert(message: "password contain least one a capital letter and special characters.")
            return
        }
        
        guard password == repeatPassword else {
            alert(message: "you must be enter same password.")
            return
        }
        
        
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
#if DEBUG
                print(error.localizedDescription)
#endif
            }
            AppSettings.displayName = name
            if let image = self.userImage {
                StorageManager.shared.uploadImageToFireStore(image, name: name) { url in
                    DataManager.shared.createNewUserDocument(name: name,
                                                             email: email,
                                                             photoUrl: url?.absoluteString)
                }
            }
        }
    }
    
    
    
    @IBAction func uploadPhoto(_ sender: Any) {
        present(picker, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        picker.delegate = self
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2.0
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        uploadBtn.setTitleColor(UIColor.dynamicColor(light: .black, dark: .white), for: .normal)
        uploadBtn.layer.cornerRadius = 10
        uploadBtn.clipsToBounds = true
        passwordTextField.isSecureTextEntry = true
        repeatPasswordTextField.isSecureTextEntry = true
        addKeyboardWillHide()
        addKeyboardWillShow()
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing(_:))))
        
        passwordTextField.text = "Kkl4547967!"
        repeatPasswordTextField.text = "Kkl4547967!"
    }
    
    
    func addKeyboardWillShow() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { noti in
            guard let height = (noti.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height else { return }
            self.view.frame.origin.y = 50 - height
        }
    }
    
    func addKeyboardWillHide() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            self.view.frame.origin.y = 0
        }
    }
}


extension RegisterViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        let itemProvider = results.first?.itemProvider
        
        if let itemProvider = itemProvider {
            itemProvider.canLoadObject(ofClass: UIImage.self)
            itemProvider.loadObject(ofClass: UIImage.self) { image, _ in
                guard let image = image as? UIImage else { return }
                self.userImage = image
                DispatchQueue.main.async {
                    self.profileImageView.image = image
                }
            }
        } else {
#if DEBUG
            print("faild to load")
#endif
        }
    }
}



