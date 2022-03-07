//
//  PushNotification.swift
//  HandyChattingApp
//
//  Created by 황신택 on 2022/02/19.
//

import UIKit
import UserNotifications
import FirebaseFirestore
import FirebaseAuth
import CryptoKit

class PushNotificationSender {
    var dic: [String: [Int]] = [:]
    var cnt = 0
    var values = [Int]()
    func sendPushNotification(to token: String, title: String, body: String, email: String) {
        print("accesstoken")
        let urlString = "https://fcm.googleapis.com/fcm/send"
        let url = NSURL(string: urlString)!
        let paramString: [String : Any] =
        [
            "to" : token,
            "notification" : [
                "title" : title,
                "body" : body,
                "sound": "default",
                "badge": "1",
                "mutable_content": "true"
            ],
            "data": [
                "fromUserEmail": email
            ]
        ]
        
        print(paramString)
        
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: paramString, options: [.prettyPrinted])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key=",
                         forHTTPHeaderField: "Authorization")
        let task = URLSession.shared.dataTask(with: request as URLRequest)  { (data, response, error) in
            do {
                if let jsonData = data {
                    if let jsonDataDict  = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.fragmentsAllowed) as? [String: AnyObject] {
                        NSLog("Received data:\n\(jsonDataDict))")
                    }
                }
            } catch let err as NSError {
                print(err.debugDescription)
            }
        }
        task.resume()
        
    }
    
    func updateMessageCount(_ channelEmail: String, _ path: String) {
        let channelRef = Firestore.firestore().collection("users/\(channelEmail)/thread")
        channelRef.document(path).getDocument {snapshot, _ in
            guard let data = snapshot?.data() else { return }
            guard let msgCnt = data["messageCnt"] as? Int else { return }
            
            switch msgCnt {
            case 0:
                channelRef.document(path).setData(["messageCnt": 1], merge: true)
            default: let new = msgCnt + 1
                channelRef.document(path).setData(["messageCnt": new], merge: true)
            }
        
        }
        
    }
}
