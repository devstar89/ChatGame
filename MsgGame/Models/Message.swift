//
//  Message.swift
//  MsgGame
//
//  Created by Oleg Koshkin on 16/03/2017.
//  Copyright © 2017 Oleg Koshkin. All rights reserved.
//

import Foundation
import FirebaseAuth
import ObjectMapper

class Message: Mappable {
    
    enum MediaType : String {
        case photo = "Photo"
        case video = "Video"
        case File = "File"
    }
    
    var roomId: String?
    var messageId: String?
    var senderId: String?
    var text: String?
    var mediaUrl: String?
    var timestamp: NSNumber?
    var mediaType: MediaType?
    var width: NSNumber?
    var height: NSNumber?
    
    init() {
        
    }
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        roomId <- map["roomId"]
        senderId <- map["senderId"]
        text <- map["text"]
        mediaUrl <- map["mediaUrl"]
        timestamp <- map["timestamp"]
        mediaType <- map["mediaType"]
        width <- map["width"]
        height <- map["height"]
    }
    
    init(roomId: String?, text: String? = nil, mediaUrl: String? = nil, mediaType: MediaType? = nil, width: NSNumber? = nil, height: NSNumber? = nil) {
        self.senderId = FIRAuth.auth()?.currentUser?.uid
        self.roomId = roomId
        self.text = text
        self.mediaUrl = mediaUrl
        self.timestamp = NSDate().timeIntervalSince1970 as NSNumber?
        self.mediaType = mediaType
        self.width = width
        self.height = height
    }
}
