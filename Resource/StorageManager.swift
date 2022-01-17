//
//  StorageManager.swift
//  HandyChattingApp
//
//  Created by 황신택 on 2022/01/03.
//

import Foundation
import Firebase
import FirebaseStorage


/// this class use that whenever user have to upload picture or download url
/// easily can access to firebase storage.
final class StorageManager {
    static let shared = StorageManager()
    private init() { }
    private let storage = Storage.storage().reference()
}


extension StorageManager {
    
    /// once you try passing to image and then successfully putdata where correct path,  you can download that url.
    /// - Parameters:
    ///   - image: selected pic
    ///   - name: user name
    ///   - completion: url from storage
   public func uploadImageToFireStore(_ image: UIImage, name: String, completion: @escaping (URL?) -> Void) {
        guard let scaledImage = image.scaledToSafeUploadSize,
              let data = scaledImage.jpegData(compressionQuality: 0.4) else {
                  return  completion(nil)
              }
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        let imageName = [UUID().uuidString, String(Date().timeIntervalSince1970)].joined()
        
        let imageReference = storage.child("UserPic: \(name)/\(imageName)")
        imageReference.putData(data, metadata: metadata) { _, error in
            if let error = error {
                print(error.localizedDescription)
            }
            
#if DEBUG
            print("Success uploaded your pic")
#endif
            
            imageReference.downloadURL { url, _ in
                print("download Url")
                completion(url)
            }
        }
    }
    
    
}
