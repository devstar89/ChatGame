//
//  UserCell.swift
//  MsgGame
//
//  Created by Oleg Koshkin on 16/03/2017.
//  Copyright © 2017 Oleg Koshkin. All rights reserved.
//

import UIKit
import Kingfisher
import FirebaseDatabase
import FirebaseAuth

class UserCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    
    func setupCell(with user: User) {
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
        timestampLabel.text = ""
    }
    
    func setupCell(with room: Room) {
        avatarImageView.image = nil
        if let avatarURL = room.avatarUrl {
            let resource = ImageResource(downloadURL: URL(string: avatarURL)!)
            avatarImageView.kf.setImage(with: resource)
        }
        timestampLabel.text = Formatter.service.timestamp(number: room.recent?.timestamp)
        nameLabel.text = room.name
        
        if let mediaType =  room.recent?.mediaType {
            switch mediaType {
            case .photo:
                emailLabel.text = "Sent photo"
            case .video:
                emailLabel.text = "Sent video"
            default:
                emailLabel.text = "Sent file"
            }
        } else {
            emailLabel.text = room.recent?.text
        }
        emailLabel.textColor = FIRAuth.auth()?.currentUser?.uid == room.recent?.senderId ? UIColor.darkGray : UIColor.blue
    }
}
