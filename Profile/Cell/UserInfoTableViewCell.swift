//
//  UserInfoTableViewCell.swift
//  HandyChattingApp
//
//  Created by 황신택 on 2021/12/22.
//

import UIKit
import Firebase
import FirebaseAuth

/// Display userInfomation in cell
class UserInfoTableViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()

    }
    
    /// get user name, email using current User email data
    /// - Parameter user: currentUser
    func configureUserInfoCell(with user: User) {
        var path = ""
        user.providerData.forEach({ userInfo in
            path = user.email ?? userInfo.email!
        })
    
        DataManager.shared.usersReference.document(path).getDocument { snapshot, error in
            guard let data = snapshot?.data(),
                  let email = data["email"] as? String,
                  let name = data["name"] as? String else {
                print(error?.localizedDescription ?? "")
                return
            }
            self.nameLabel.text = name
            self.emailLabel.text = email
        }
    }
}
