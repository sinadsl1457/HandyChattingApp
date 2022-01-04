//
//  DataManager.swift
//  HandyChattingApp
//
//  Created by 황신택 on 2022/01/03.
//

import Foundation
import FirebaseFirestore
import Firebase

class DataManager {
    static let shared = DataManager()
    
    private init() { }
    
    let database = Firestore.firestore()
    var usersReference: CollectionReference {
        return database.collection("users")
    }
    var chatsReference: CollectionReference {
        return database.collection("chats")
    }
    
}


extension DataManager {
   public func userExists(with email: String, completion: @escaping(Bool) -> Void) {
        usersReference.document(email).getDocument { querySnapshot, error in
            guard let data = querySnapshot?.data(), data["email"] as? String != nil else {
                completion(false)
                return
            }
            
            completion(true)
        }
    }
    
   public func createNewUserDocument(name: String, email: String, photoUrl: String? = nil) {
        guard let urlStr = photoUrl else { return }
        
        let user = Users(name: name, email: email, photoUrl: urlStr)
        
        usersReference.document(email).setData(user.rep)
    }
}
