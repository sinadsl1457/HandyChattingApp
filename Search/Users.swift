//
//  Users.swift
//  HandyChattingApp
//
//  Created by 황신택 on 2021/12/31.
//

import Foundation
import FirebaseFirestore
import Firebase

struct Users {
    var id: String = UUID().uuidString
    let name: String
    let email: String
    let photoUrl: String
}


extension Users {
    init(channelName: String) {
        name = channelName
        email = ""
        photoUrl = ""
    }
    
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
    
    var rep: [String: Any] {
        [
            "id": id,
            "name": name,
            "email": email,
            "photoUrl": photoUrl
        ]
    }
}


extension Users: Comparable {
    static func == (lhs: Users, rhs: Users) -> Bool {
        return lhs.email == rhs.email
    }
    
    static func < (lhs: Users, rhs: Users) -> Bool {
        return lhs.name < rhs.name
    }
}
