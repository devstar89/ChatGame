//
//  ChatTextCell.swift
//  MsgGame
//
//  Created by Oleg Koshkin on 16/03/2017.
//  Copyright © 2017 Oleg Koshkin. All rights reserved.
//

import UIKit


class ChatTextCell: ChatCell {
    @IBOutlet weak var messageLabel: UILabel!
    
    override func setupCell(with message: Message) {
        super.setupCell(with: message)
        messageLabel.text = message.text
        messageLabel.transform = contentTransform
    }
}
