//
//  MessagesViewController.swift
//  MsgGame
//
//  Created by Oleg Koshkin on 16/03/2017.
//  Copyright © 2017 Oleg Koshkin. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import ObjectMapper
import PKHUD

class MessagesViewController: UIViewController {

    @IBOutlet weak var itemsTableView: UITableView!
    
    let currentUser: FIRUser? = {
        return FIRAuth.auth()?.currentUser
    }()
    
    var chatVC: ChatViewController?
    var queryRef: FIRDatabaseQuery?
    var rooms: [String: Room] = [:]
    var recentRooms: [Room] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Users", style: .plain, target: self, action: #selector(openUsersController))
        self.title = currentUser?.displayName
        
        itemsTableView.register(UINib(nibName: "UserCell", bundle: nil), forCellReuseIdentifier: "CELL")
        fetchMessages()
    }
    
    func handleLogout() {
        
        queryRef?.removeAllObservers()
        try? FIRAuth.auth()?.signOut()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.window?.rootViewController = LoginViewController(nibName: "LoginViewController", bundle: nil)
    }
    
    func openUsersController() {
        let usersVC = UsersViewController(nibName: "UsersViewController", bundle: nil)
        let navigationController = UINavigationController(rootViewController: usersVC)
        usersVC.messagesController = self
        present(navigationController, animated: true, completion: nil)
    }
    
    func openMessageController(user: User) {
        
        let roomId = self.rooms.filter { (key, room) -> Bool in
            // If chat room exists already for us, you and me - open that room
            return room.isMyRoom(uid: user.uid) && room.users?.count == 2
        }.first?.key
        
        if roomId == nil {
            let ref = FIRDatabase.database().reference().child("rooms")
            let roomRef = ref.childByAutoId()
            roomRef.updateChildValues([
                "users": [currentUser?.uid, user.uid],
                "info": ["name": "\(currentUser!.displayName!) & \(user.name!)", "avatar": user.avatarURL ?? ""]
            ])
            openMessageController(with: roomRef.key)
        } else {
            openMessageController(with: roomId!)
        }
    }
    
}

extension MessagesViewController {
    func fetchMessages() {
        
        queryRef = FIRDatabase.database().reference().child("rooms")
        queryRef?.observe(.childAdded, with: { snapshot in
            if let dictionary = snapshot.value as? [String: Any] {
                self.roomChanged(key: snapshot.key, with: dictionary)
            }
        })
        
        queryRef?.observe(.childChanged, with: { snapshot in
            HUD.hide()
            if let dictionary = snapshot.value as? [String: Any] {
                self.roomChanged(key: snapshot.key, with: dictionary)
            }
        })
    }
    
    func roomChanged(key: String, with dictionary: [String: Any]) {
        let room =  Mapper<Room>().map(JSON: dictionary)
        if room?.isMyRoom(uid: self.currentUser?.uid) == true {
            self.rooms[key] = room
        }
        
        self.recentRooms = self.rooms.values.filter({ (room) -> Bool in
            return room.recent != nil
        }).sorted(by: { (room1, room2) -> Bool in
            return room1.recent?.timestamp?.intValue ?? 0 > room2.recent?.timestamp?.intValue ?? 0
        })
        
        DispatchQueue.main.async {
            self.itemsTableView.reloadData()
        }
    }
    
    func openMessageController(with roomId: String) {
        chatVC = ChatViewController(nibName: "ChatViewController", bundle: nil)
        chatVC?.roomId = roomId
        self.navigationController?.pushViewController(chatVC!, animated: true)
    }
}

extension MessagesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recentRooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CELL") as! UserCell
        cell.setupCell(with: recentRooms[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 81
    }
}

extension MessagesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        openMessageController(with: recentRooms[indexPath.row].recent!.roomId!)
    }
}

