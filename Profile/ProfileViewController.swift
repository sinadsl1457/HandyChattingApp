//
//  ProfileViewController.swift
//  HandyChattingApp
//
//  Created by 황신택 on 2021/12/22.
//

import UIKit
import FirebaseAuth
import Firebase
import Photos
import PhotosUI
import SDWebImage

/// Notification that send profile image
extension Notification.Name {
    static let sendPic = Notification.Name("sendPic")
}

/// User can modify profile and see
class ProfileViewController: CommonViewController {
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var profileTableView: UITableView!
    @IBOutlet weak var loadingView: UIView! {
        didSet {
            loadingView.layer.cornerRadius = 6
        }
    }
    /// For save nickname alertcontroller
    var nickNameAlertController: UIAlertController?
    

    /// Create UIAlertAction for user nickname change
    /// - Parameter sender: UIbutton
    @IBAction func changeNickName(_ sender: Any) {
        let alert = UIAlertController(title: "닉네임 변경", message: nil, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "변경", style: .default) { _ in
            self.alert(message: "변경 되었습니다.")
            self.textFieldDidChange()
        }
        alert.addTextField { nickName in
            nickName.placeholder = "원하시는 닉네임을 입력하세요."
        }
        
        let cancel = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        
        alert.addAction(okAction)
        alert.addAction(cancel)
        
        present(alert, animated: true, completion: nil)
        nickNameAlertController = alert
    }
    
    
    /// User can change their picture in library
    /// - Parameter sender: UIbutton
    @IBAction func changeProfilePicture(_ sender: Any) {
        present(picker, animated: true, completion: nil)
    }
    
    
    /// User can logout
    /// - Parameter sender: UIbutton
    @IBAction func logout(_ sender: Any) {
        let alertController = UIAlertController(
            title: nil,
            message: "로그아웃을 할까요?",
            preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        alertController.addAction(cancelAction)
        
        let signOutAction = UIAlertAction(
            title: "로그아웃",
            style: .destructive) { _ in
                do {
                    try Auth.auth().signOut()
                } catch {
                    print("Error signing out: \(error.localizedDescription)")
                }
            }
        self.database.collection("users")
            .document(self.path)
            .setData(["signin": false],merge: true)
        alertController.addAction(signOutAction)
        present(alertController, animated: true)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        picker.delegate = self
        profileTableView.separatorStyle = .none
        title = "설정화면"
    }
    
    private func showActivity() {
        activityIndicator.startAnimating()
        loadingView.isHidden = false
    }
    
    private func hideActivity() {
        activityIndicator.stopAnimating()
        loadingView.isHidden = true
    }
    
    
    /// Change the nickname of the current user. If successful, access the user's documentary and update the nickname part.
    /// Access the documentary of all users who are currently talking to the user and change all nicknames of current user.
    private func textFieldDidChange() {
        guard let alertController = nickNameAlertController else {
            return
        }
        guard let nickNameText = alertController.textFields?.first else { return }
        if let currentUser = currentUser {
            let changeRequest = currentUser.createProfileChangeRequest()
            changeRequest.displayName = nickNameText.text
            changeRequest.commitChanges {[weak self] error in
                guard let self = self else { return }
                if let error = error {
    #if DEBUG
                    print(error.localizedDescription)
    #endif
                } else {
                    self.profileTableView.reloadData()
                    // update current user ncikname
                    DataManager.shared.usersReference.document(self.path).updateData(["name": nickNameText.text ?? "error"])
                    // get current user Reference
                    let userRef = self.database.collection("users/\(self.path)/thread")
                    userRef.getDocuments { snapshot, error in
                        guard let documents = snapshot?.documents else {
                            print(error?.localizedDescription ?? "")
                            return
                        }

                        // repeat and access documentary of all related users.
                        for document in documents {
                             let data = document.data()
                            guard let email = data["email"] as? String else { return }
                          let channelUserRef = self.database.collection("users/\(email)/thread")
                            channelUserRef.document(self.path).updateData(["name": nickNameText.text ?? "no name"])
                        }
                    }
                    AppSettings.displayName = nickNameText.text ?? "unknown"
                }
            }
        }
    }
}


extension ProfileViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 1
        default:
            return 1
        }
    }
    

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ImageTableViewCell", for: indexPath) as! ImageTableViewCell
            cell.selectionStyle = .none
            if let currentUser = currentUser {
                cell.configureCell(with: currentUser)
            }
            
            // When the picture is displayed, the indicator ends.
                self.hideActivity()
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "UserInfoTableViewCell", for: indexPath) as! UserInfoTableViewCell
            cell.selectionStyle = .none
            if let currentUser = currentUser {
                cell.configureUserInfoCell(with: currentUser)
            }
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingTableViewCell", for: indexPath) as! SettingTableViewCell
            cell.selectionStyle = .none
            return cell
        }
    }
}


extension ProfileViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 200
        } else if indexPath.section == 1 {
            return 100
        } else {
            return 200
        }
    }
}

// MARK: PHPickerViewControllerDelegate
extension ProfileViewController: PHPickerViewControllerDelegate {
    /// using PHPickerViewController user can pick picture and then upload to firebase storage.
    /// after upload picture, given url update the document field of the user.
    /// - Parameters:
    ///   - picker: PHPickerViewController
    ///   - results: PHPickerResult
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        let itemProvider = results.first?.itemProvider
        
        if let itemProvider = itemProvider {
            itemProvider.canLoadObject(ofClass: UIImage.self)
            itemProvider.loadObject(ofClass: UIImage.self) {[weak self] image, _ in
                guard let self = self else { return }
                guard let image = image as? UIImage else { return }
                
                NotificationCenter.default.post(name: .sendPic, object: nil, userInfo: ["pic": image])
                
                if let currentUser = self.currentUser {
                    StorageManager.shared.uploadImageToFireStore(image, name: currentUser.displayName ?? "unknown") { url in
                        DataManager.shared.usersReference.document(self.path).updateData(["photoUrl": url?.absoluteString ?? ""])
                        
                        let userRef = self.database.collection("users/\(self.path)/thread")
                        userRef.getDocuments { snapshot, error in
                            guard let documents = snapshot?.documents else {
                                print(error?.localizedDescription ?? "")
                                return
                            }
                            
                            for document in documents {
                                 let data = document.data()
                                guard let email = data["email"] as? String else { return }
                              let channelUserRef = self.database.collection("users/\(email)/thread")
                                channelUserRef.document(self.path).updateData(["photoUrl": url?.absoluteString ?? ""])
                            }
                        }
                    }
                }
            }
        } else {
#if DEBUG
            print("faild to load")
#endif
        }
    }
}



