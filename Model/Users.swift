//
//  Users.swift
//  HandyChattingApp
//
//  Created by 황신택 on 2021/12/31.
//

import Foundation
import FirebaseFirestore
import Firebase

/// make for manage all users
struct Users {
    var id: String = UUID().uuidString
    let name: String
    let email: String
    let photoUrl: String
}

/// I added an extension because I had to deliver multiple initialize depending on the situation.
extension Users {
    init(channelName: String) {
        name = channelName
        email = ""
        photoUrl = ""
    }
    
    
    /// it's very important that make passing to realtime listener.
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard let name = data["name"] as? String,
              let email = data["email"] as? String,
              let photoUrl = data["photoUrl"] as? String else {
                  return nil
              }
        
        self.name = name
        self.email = email
        self.photoUrl = photoUrl
    }
    
    
    /// must be need this representation whenever store to firestore.
    var rep: [String: Any] {
        [
            "id": id,
            "name": name,
            "email": email,
            "photoUrl": photoUrl
        ]
    }
}


/// use for contain method implemented like this.
extension Users: Comparable {
    static func == (lhs: Users, rhs: Users) -> Bool {
        return lhs.email == rhs.email
    }
    
    static func < (lhs: Users, rhs: Users) -> Bool {
        return lhs.name < rhs.name
    }
}
