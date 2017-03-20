//
//  User.swift
//  MsgGame
//
//  Created by Oleg Koshkin on 16/03/2017.
//  Copyright © 2017 Oleg Koshkin. All rights reserved.
//

import Foundation

class User {
    var uid: String?
    var name: String?
    var email: String?
    var avatarURL: String?
    
    func setValuesFromDictionary(dict: [String: String]){
        name = dict["name"]
        email = dict["email"]
        avatarURL = dict["avatar"]
    }
}
