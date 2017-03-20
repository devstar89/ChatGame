//
//  UsersViewController.swift
//  MsgGame
//
//  Created by Oleg Koshkin on 15/03/2017.
//  Copyright © 2017 Oleg Koshkin. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import PKHUD

class UsersViewController: UIViewController {

    @IBOutlet weak var itemsTableView: UITableView!
    var users: [User] = []
    let currentUser: FIRUser? = {
        return FIRAuth.auth()?.currentUser
    }()
    
    weak var messagesController: MessagesViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(handleClose))
        self.title = "Users"
        
        itemsTableView.register(UINib(nibName: "UserCell", bundle: nil), forCellReuseIdentifier: "CELL")
        
        fetchUsers()
    }
    
    func handleClose() {
        dismiss(animated: true, completion: nil)
    }

    func fetchUsers() {
        
        HUD.show(.progress)
        FIRDatabase.database().reference().child("users").observe(.childAdded, with: { (snapshot) in
            
            HUD.hide()
            if snapshot.key == self.currentUser?.uid {
                return
            }

            if let dictionary = snapshot.value as? [String: String] {
                let user = User()
                user.uid = snapshot.key
                user.setValuesFromDictionary(dict: dictionary)
                self.users.append(user)
                
                DispatchQueue.main.async {
                    self.itemsTableView.reloadData()
                }
            }
        })
    }
}

extension UsersViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CELL") as! UserCell
        cell.setupCell(with: users[indexPath.row])
        return cell
    }

}

extension UsersViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 81
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        dismiss(animated: true, completion: {
            self.messagesController?.openMessageController(user: self.users[indexPath.row])
        })
    }
}
