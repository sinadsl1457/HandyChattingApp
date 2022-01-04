//
//  SearchTableViewCell.swift
//  HandyChattingApp
//
//  Created by 황신택 on 2022/01/01.
//

import UIKit
import Alamofire
import SDWebImage

enum CachedImageError: Error {
    case wrongUrl
    case faildToCachedImage
}

class SearchTableViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var userImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        userImageView.layer.cornerRadius = userImageView.frame.width / 2.0
        userImageView.clipsToBounds = true
    }
    
    
    func configureCell(with model: Users) {
        nameLabel.text = model.name
        cachedUserImage(user: model) { result in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let url):
                DispatchQueue.main.async {
                    self.userImageView.sd_setImage(with: url, completed: nil)
                }
            }
        }
    }
    
    
    func cachedUserImage(user: Users, completion: @escaping(Result<URL, Error>) -> Void) {
        guard let url = URL(string: user.photoUrl) else {
            completion(.failure(CachedImageError.wrongUrl))
            return
        }
        completion(.success(url))
    }
}
