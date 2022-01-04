//
//  StorageManager.swift
//  HandyChattingApp
//
//  Created by 황신택 on 2022/01/03.
//

import Foundation
import Firebase
import FirebaseStorage

public enum StorageError: Error {
    case failedtoUpload
    case faildtoGetDownloadUrl
}

final class StorageManager {
    static let shared = StorageManager()
    private init() { }
    private let storage = Storage.storage().reference()
}


extension StorageManager {
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
                completion(url)
            }
        }
    }
    
    
}
