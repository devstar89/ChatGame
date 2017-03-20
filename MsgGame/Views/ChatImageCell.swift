//
//  ChatImageCell.swift
//  MsgGame
//
//  Created by Oleg Koshkin on 16/03/2017.
//  Copyright © 2017 Oleg Koshkin. All rights reserved.
//

import UIKit
import Kingfisher

class ChatImageCell: ChatCell {

    @IBOutlet weak var attachmentView: UIImageView!
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    override func setupCell(with message: Message) {
        super.setupCell(with: message)

        self.attachmentView.image = nil
        if let image = ImageCache.default.retrieveImageInMemoryCache(forKey: message.messageId!) {
            self.updateImage(image: image, w: message.width, h: message.height, processing: message.mediaUrl == nil)
        } else {
            updateImage(image: nil, w: message.width, h: message.height, processing: true)
            if let mediaUrl = message.mediaUrl {
                let resource = ImageResource(downloadURL: URL(string: mediaUrl)!, cacheKey: message.messageId!)
                self.avatarImageView.kf.setImage(with: resource, placeholder: nil, options: nil, progressBlock: nil, completionHandler: { [weak self] (image, error, cacheType, url) in
                    self?.updateImage(image: image, w: message.width, h: message.height, processing: false)
                })
            }
        }
    }
    
    func updateImage(image: UIImage?, w: NSNumber?, h: NSNumber?, processing: Bool) {
        let width = w as? CGFloat ?? 120.0, height = h as? CGFloat ?? 120.0
        let size = CGSize(width: messageContentView.bounds.size.width - 88, height: 120)
        let contentRatio = size.height / size.width
        let imageRatio = height / width
        
        self.attachmentView.image = image
        if imageRatio > contentRatio {
            heightConstraint.constant = min(size.height, height)
            widthConstraint.constant = heightConstraint.constant / imageRatio
        } else {
            widthConstraint.constant = min(size.width, width)
            heightConstraint.constant = widthConstraint.constant * imageRatio
        }
       
        if processing {
            loadingIndicator.isHidden = false
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
        
        self.layoutSubviews()
        
        attachmentView.transform = contentTransform
    }
    
    @IBAction func zoomImage(_ sender: Any) {
        delegate?.openMedia(indexPath: indexPath!, with: attachmentView)
    }
}
