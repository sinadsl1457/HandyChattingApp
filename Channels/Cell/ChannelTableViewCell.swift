//
//  ChannelTableViewCell.swift
//  HandyChattingApp
//
//  Created by 황신택 on 2021/12/20.
//

import UIKit
import SDWebImage

/// to show channel list
class ChannelTableViewCell: UITableViewCell {
    @IBOutlet weak var userImageView: UIImageView!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        userImageView.layer.cornerRadius = userImageView.frame.width / 2.0
        userImageView.clipsToBounds = true
    }
    
    
    func configureCell(with model: Users) {
        nameLabel.text = model.name
        cachedUserImage(channel: model) { result in
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
    
    
    func cachedUserImage(channel: Users, completion: @escaping(Result<URL, Error>) -> Void) {
        guard let url = URL(string: channel.photoUrl) else {
            completion(.failure(CachedImageError.wrongUrl))
            return
        }
        completion(.success(url))
    }
}
