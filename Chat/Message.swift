//
//  Message.swift
//  HandyChattingApp
//
//  Created by 황신택 on 2021/12/21.
//

import UIKit
import Firebase
import MessageKit
import FirebaseFirestore


/// for implement message function made data structure like this.
/// must be conform to MessageType protocol
struct Message: MessageType {
    /// documentId
    let id: String?
    
    /// messageId
    var messageId: String {
        return id ?? UUID().uuidString
    }
    
    /// message content
    let content: String?
    
    /// message sent date
    let sentDate: Date
    
    /// It's used to identify who's sending it.
    let sender: SenderType
    
    /// Use to define the associated value when the message type is text and when it is a picture.
    var kind: MessageKind {
        if let image = image {
            let mediaItem = ImageMediaItem(image: image)
            return .photo(mediaItem)
        } else {
            return .text(content!)
        }
    }
    
    /// Image message
    var image: UIImage?
    
    /// uploaded photo url
    var downloadURL: URL?
    
    /// user profilepicture url
    let senderUrl: String
    
    /// use this init whenever passing to savemethod
    /// - Parameters:
    ///   - user: currentUser
    ///   - users: Users
    ///   - content: message content
    init(user: User, users: Users, content: String) {
        sender = Sender(senderId: user.uid, displayName: users.name)
        self.content = content
        sentDate = Date()
        id = nil
        senderUrl = users.photoUrl
    }
    
    
    /// use this init whenever user upload picture in chat, 
    /// - Parameters:
    ///   - user: currentUser
    ///   - image: selected Image
    ///   - users: Users
    init(user: User, image: UIImage, users: Users) {
        sender = Sender(senderId: user.uid, displayName: users.name)
        self.image = image
        content = ""
        sentDate = Date()
        id = nil
        senderUrl = ""
    }
    
    
    /// whenever listener passing to documentChange to handlemethod use this init
    /// bc we can only get data json type.
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        guard let sendDate = data["created"] as? Timestamp,
              let senderId = data["senderId"] as? String,
              let senderName = data["senderName"] as? String,
              let senderUrl = data["senderUrl"] as? String
               else {
                  return nil
              }
        
        id = document.documentID
        self.senderUrl = senderUrl
        self.sentDate = sendDate.dateValue()
        sender = Sender(senderId: senderId, displayName: senderName)
        
        if let content = data["content"] as? String {
            self.content = content
            downloadURL = nil
        } else if let urlString = data["url"] as? String, let url = URL(string: urlString) {
            downloadURL = url
            content = ""
        } else {
            return nil
        }
    }
}


// MARK: - DatabaseRepresentation
extension Message: DatabaseRepresentation {
    /// whenever add document to reference need this representation.
    var representation: [String: Any] {
        var rep: [String: Any] = [
            "created": sentDate,
            "senderId": sender.senderId,
            "senderName": sender.displayName,
            "senderUrl": senderUrl
        ]
        
        if let url = downloadURL {
            rep["url"] = url.absoluteString
        } else {
            rep["content"] = content
        }
        return rep
    }
}

// MARK: - Comparable
extension Message: Comparable {
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
    
    static func < (lhs: Message, rhs: Message) -> Bool {
        return lhs.sentDate < rhs.sentDate
    }
}
