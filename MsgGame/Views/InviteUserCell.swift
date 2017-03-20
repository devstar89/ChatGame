//
//  InviteUserCell.swift
//  MsgGame
//
//  Created by Oleg Koshkin on 17/03/2017.
//  Copyright © 2017 Oleg Koshkin. All rights reserved.
//

import UIKit
import Kingfisher

protocol InviteUserCellDelegate : class {
    func inviteUser(index: IndexPath?)
}

class InviteUserCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var btnInvite: UIButton!
    var indexPath: IndexPath?
    weak var delegate: InviteUserCellDelegate?
    
    @IBAction func inviteUser(_ sender: Any) {
        delegate?.inviteUser(index: indexPath)
    }
    
    func setupCell(with user: User, invited: Bool, indexPath: IndexPath) {
        avatarImageView.image = nil
        if let avatarURL =  user.avatarURL {
            if let image = ImageCache.default.retrieveImageInMemoryCache(forKey: user.uid!) {
                self.avatarImageView.image = image
            } else {
                let resource = ImageResource(downloadURL: URL(string: avatarURL)!, cacheKey: user.uid)
                avatarImageView.kf.setImage(with: resource)
            }
        }
        nameLabel.text = user.name
        emailLabel.text = user.email
        btnInvite.isHidden = invited
        self.indexPath = indexPath
    }
}
