//
//  ChatCell.swift
//  MsgGame
//
//  Created by Oleg Koshkin on 19/03/2017.
//  Copyright © 2017 Oleg Koshkin. All rights reserved.
//

import UIKit
import Kingfisher
import FirebaseDatabase
import FirebaseAuth

protocol ChatCellDelegate: class {
    func openMedia(indexPath: IndexPath, with: Any?)
}

class ChatCell: UITableViewCell {
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var messageContentView: UIView!
    @IBOutlet weak var timestampLabel: UILabel!
    
    var contentTransform: CGAffineTransform!
    
    weak var delegate: ChatCellDelegate?
    var indexPath: IndexPath?
    
    func setupCell(with message: Message) {
        avatarImageView.image = nil
        timestampLabel.text = Formatter.service.timestamp(number: message.timestamp)
        if let sender = message.senderId {
            if let image = ImageCache.default.retrieveImageInMemoryCache(forKey: message.senderId!) {
                self.avatarImageView.image = image
            } else {
                let dbRef = FIRDatabase.database().reference()
                dbRef.child("users").child(sender).observeSingleEvent(of: .value, with: { (snapshot) in
                    // Get avatar url
                    let value = snapshot.value as? NSDictionary
                    if let avatarURL = value?["avatar"] as? String {
                        let resource = ImageResource(downloadURL: URL(string: avatarURL)!, cacheKey: message.senderId)
                        self.avatarImageView.kf.setImage(with: resource)
                    }
                })
            }
        }
        updateUI(isSending: message.senderId == FIRAuth.auth()?.currentUser?.uid)
    }
    
    func updateUI(isSending: Bool) {
        if isSending {
            contentTransform = CGAffineTransform(scaleX: -1, y: 1)
        } else {
            contentTransform = CGAffineTransform.identity
        }
        
        contentView.transform = contentTransform
        avatarImageView.transform = contentTransform
        timestampLabel.transform = contentTransform
    }
}
