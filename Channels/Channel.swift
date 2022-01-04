//
//  Channel.swift
//  HandyChattingApp
//
//  Created by 황신택 on 2021/12/20.
//

import FirebaseFirestore

struct Channel {
    let id: String?
    let name: String
    let photoUrl: String?
    
    init(name: String) {
        id = nil
        self.name = name
        photoUrl = nil
    }
    
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard let name = data["name"] as? String,
              let photoUrl = data["photoUrl"] as? String else {
            return nil
        }
        
        id = document.documentID
        self.name = name
        self.photoUrl = photoUrl
    }
}

// MARK: - DatabaseRepresentation
extension Channel: DatabaseRepresentation {
    var representation: [String: Any] {
        var rep = ["name": name]
        
        if let id = id {
            rep["id"] = id
        }
        
        return rep
    }
}

// MARK: - Comparable
extension Channel: Comparable {
    static func == (lhs: Channel, rhs: Channel) -> Bool {
        return lhs.id == rhs.id
    }
    
    static func < (lhs: Channel, rhs: Channel) -> Bool {
        return lhs.name < rhs.name
    }
}
