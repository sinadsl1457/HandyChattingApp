//
//  ImageTableViewCell.swift
//  HandyChattingApp
//
//  Created by 황신택 on 2021/12/22.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import Firebase
import SDWebImage

class ImageTableViewCell: UITableViewCell {
    @IBOutlet weak var profileImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        makeChangedRealTimeUserPic()
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2.0
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
    }
    
     func configureCell(with user: User) {
       var path = ""
        user.providerData.forEach {
            path = user.email ?? $0.email!
        }
        
        DataManager.shared.usersReference.document(path).getDocument {[weak self] snapshot, error in
            guard let self = self else { return }
            guard let data = snapshot,
                  let photoUrl = data["photoUrl"] as? String,
                  let url = URL(string: photoUrl) else {
                print(error?.localizedDescription ?? "")
                return
            }
            
            DispatchQueue.main.async {
                self.profileImageView.sd_setImage(with: url, completed: nil)
            }
        }
    }
    
    
   private func makeChangedRealTimeUserPic() {
        NotificationCenter.default.addObserver(forName: .sendPic, object: nil, queue: .main) {[weak self] noti in
            guard let self = self else { return }
            guard let image = noti.userInfo?["pic"] as? UIImage else { return }
            self.profileImageView.image = image
        }
    }
}
