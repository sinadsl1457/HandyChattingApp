//
//  ChannelTableViewCell.swift
//  HandyChattingApp
//
//  Created by 황신택 on 2021/12/20.
//

import UIKit
import SDWebImage
import Firebase
import FirebaseFirestore
import FirebaseAuth
import KakaoSDKAuth


/// To show channel list
class ChannelTableViewCell: UITableViewCell {
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var messageCount: UILabel!
    
    private var messageListener: ListenerRegistration?
    private let database = Firestore.firestore()
    private let currentUser = Auth.auth().currentUser
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        userImageView.layer.cornerRadius = userImageView.frame.width / 2.0
        userImageView.clipsToBounds = true
        userImageView.contentMode = .scaleAspectFill
        contentLabel.text = ""
        messageCount.layer.cornerRadius = messageCount.frame.width / 2
        messageCount.clipsToBounds = true
    }
    
    
    /// Make Initialize property
    /// - Parameter model: users
    func configureCell(with model: Users) {
        nameLabel.text = model.name
        fetchUserMessageCount(model) {[weak self] cnt in
            if let cnt = cnt {
                self?.messageCount.text = cnt
            }
        }
        
        getLastestContentMessage(model) {[weak self] content in
            if let content = content {
                self?.contentLabel.text = content
            }
        }
            
        cachedUserImage(channel: model) {[weak self] result in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let url):
                DispatchQueue.main.async {
                    self?.userImageView.sd_setImage(with: url, completed: nil)
                }
            }
        }
    }
    
    
    /// Make Url data from given users data
    /// - Parameters:
    ///   - channel: Users
    ///   - completion: URL if faild make passing error
    private func cachedUserImage(channel: Users, completion: @escaping(Result<URL, Error>) -> Void) {
        guard let url = URL(string: channel.photoUrl) else {
            completion(.failure(CachedImageError.wrongUrl))
            return
        }
        completion(.success(url))
    }
    
    private func fetchUserMessageCount(_ channel: Users, completion: @escaping(String?) -> Void) {
        guard let cnt = channel.messageCnt else {
            completion(nil)
            return
        }
        return completion(String(cnt))
    }
    
    
    /// Once access to channel reference and get latest message
    /// - Parameters:
    ///   - channel: incomingUser
    ///   - completion: lastestMessage
    func getLastestContentMessage(_ channel: Users, completion: @escaping(String?) -> Void) {
        let ref = database.collection("users/\(path)/thread/\(channel.email)/thread")
        var dic: [String: Date] = [:]
        var lastMessage = ""
        ref.getDocuments {[weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error {
                completion(nil)
                print(error.localizedDescription)
            }
            
            guard let documents = snapshot?.documents else { return }
            documents.forEach {doc in
                let data = doc.data()
                if let content = data["content"] as? String,
                   let date = data["created"] as? Timestamp {
                    
                    dic.updateValue(date.dateValue(), forKey: content)
                    let sortedDic = dic.sorted(by: { $0.value < $1.value })
                    let lastKey = sortedDic.last?.key
                    lastMessage = lastKey ?? ""
                }
            }
            
            let channelRef = self.database.collection("users/\(self.path)/thread")
            channelRef.document(channel.email).setData(["lastMessage": lastMessage], merge: true)
            channelRef.document(channel.email).getDocument { snapshot, error in
                guard let data = snapshot?.data(),
                      let lastMessage = data["lastMessage"] as? String else { return }
                completion(lastMessage)
            }
        }
    }
    
    func isHiddenCount(_ channel: Users, completion: @escaping (Bool) -> Void) {
        let channelRef = database.collection("users/\(path)/thread")
        channelRef.document(channel.email).getDocument { snapshot, error in
            guard let data = snapshot?.data(),
                  let cnt = data["messageCnt"] as? Int else { return }
            
            if cnt == 0 {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
}
