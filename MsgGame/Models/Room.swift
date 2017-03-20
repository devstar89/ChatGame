//
//  MessageThread.swift
//  MsgGame
//
//  Created by Oleg Koshkin on 16/03/2017.
//  Copyright © 2017 Oleg Koshkin. All rights reserved.
//

import Foundation
import ObjectMapper

class Room: Mappable {
    var users: [String]?
    var recent: Message?
    var name: String?
    var avatarUrl: String?
    
    required init?(map: Map) {
        
    }

    func mapping(map: Map) {
        users <- map["users"]
        recent <- map["recent"]
        name <- map["info.name"]
        avatarUrl <- map["info.avatar"]
    }
    
    func isMyRoom(uid: String?) -> Bool {
        if uid == nil {
            return false
        }
        
        return users?.contains(uid!) ?? false
    }
}
