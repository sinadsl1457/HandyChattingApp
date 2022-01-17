//
//  DataManager.swift
//  HandyChattingApp
//
//  Created by 황신택 on 2022/01/03.
//

import Foundation
import FirebaseFirestore
import Firebase

/// It is a class that collects methods used to handle users' data.
class DataManager {
    static let shared = DataManager()
    
    private init() { }
    
    let database = Firestore.firestore()
    var usersReference: CollectionReference {
        return database.collection("users")
    }
}


extension DataManager {
    
    /// check to user already exist in firestore.
    /// - Parameters:
    ///   - email: user email
    ///   - completion: passing to bool value if not exist passing to true in other words false.
   public func userExists(with email: String, completion: @escaping(Bool) -> Void) {
        usersReference.document(email).getDocument { querySnapshot, error in
            guard let data = querySnapshot?.data(), data["email"] as? String != nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    
    /// given user's data save to firestore
    /// - Parameters:
    ///   - name: user name
    ///   - email: user email
    ///   - photoUrl: user photo Url
   public func createNewUserDocument(name: String, email: String, photoUrl: String? = nil) {
        guard let urlStr = photoUrl else { return }
        let user = Users(name: name, email: email, photoUrl: urlStr)
        usersReference.document(email).setData(user.rep)
    }

    
    /// when need to current user's data from firestore.
    /// - Parameters:
    ///   - email: currentUser email
    ///   - completion: if exist userdata in firestore, passing Users Instance.
    public func getUserInfo(email: String, completion: @escaping (Users?) -> Void) {
        usersReference.document(email).getDocument { snapshot, error in
            guard let data = snapshot?.data(),
                  let name = data["name"] as? String,
                  let photoUrl = data["photoUrl"] as? String,
                  let email = data["email"] as? String else {
                print(error?.localizedDescription ?? "")
                completion(nil)
                return
            }
        
            let users = Users(name: name, email: email, photoUrl: photoUrl)
            completion(users)
        }
    }
}
