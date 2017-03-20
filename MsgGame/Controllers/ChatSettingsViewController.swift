//
//  ChatSettingsViewController.swift
//  MsgGame
//
//  Created by Oleg Koshkin on 17/03/2017.
//  Copyright © 2017 Oleg Koshkin. All rights reserved.
//

import UIKit
import PKHUD
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import ObjectMapper

class ChatSettingsViewController: UIViewController {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var txtRoom: UITextField!
    @IBOutlet weak var itemsTableView: UITableView!
    @IBOutlet weak var btnEdit: UIButton!
    
    var roomId: String!
    var room: Room?
    var users: [User] = []
    var roomRef: FIRDatabaseQuery?
    
    var avatar: UIImage?
    var nameTitle: String?
    
    weak var chatVC: ChatViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Room Settings"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Chat", style: .plain, target: self, action: #selector(handleClose))
        itemsTableView.register(UINib(nibName: "InviteUserCell", bundle: nil), forCellReuseIdentifier: "CELL")
        
        fetchUsers()
        fetchRoomInfo()
    }
    
    func handleClose() {
        roomRef?.removeAllObservers()
        navigationController!.popViewController(animated: true)
    }
    
    @IBAction func handleUpdateSettings(_ sender: Any) {
        if txtRoom.isEnabled { // Update Room Settings
            if txtRoom.text == "" || (avatar == nil && nameTitle == txtRoom.text) {
                return
            }
            
            HUD.show(.progress)
            if avatar != nil {
                let storage = FIRStorage.storage().reference().child("\(roomId).png")
                if let uploadData = UIImageJPEGRepresentation(self.avatar!, 0.1){
                    storage.put(uploadData, metadata: nil, completion: { (meta, error) in
                        self.updateProfile(mediaUrl: meta?.downloadURL()?.absoluteString)
                    })
                }
            } else {
                updateProfile(mediaUrl: nil)
            }
        } else {  // Enable updation
            txtRoom.isEnabled = true
            avatarImageView.isUserInteractionEnabled = true
            btnEdit.setTitle("Update", for: .normal)
            avatar = nil
            nameTitle = txtRoom.text
        }
    }
    
    @IBAction func openImagePicker(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }
    
}
extension ChatSettingsViewController {
    
    func fetchRoomInfo() {
        roomRef = FIRDatabase.database().reference().child("rooms").child(roomId)
        roomRef?.observe(.value, with: { snapshot in
            if let dictionary = snapshot.value as? [String: Any] {
                self.room = Mapper<Room>().map(JSON: dictionary)
                DispatchQueue.main.async {
                    self.updateUI()
                }
            }
        })
    }
    
    func fetchUsers() {
        
        HUD.show(.progress)
        FIRDatabase.database().reference().child("users").observe(.childAdded, with: { (snapshot) in
            
            HUD.hide()
            if snapshot.key == FIRAuth.auth()?.currentUser?.uid {
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
    
    func updateUI() {
        txtRoom.text = room?.name
        avatarImageView.image = nil
        if let avatarURL = room?.avatarUrl {
            self.avatarImageView.kf.setImage(with: URL(string: avatarURL))
        }
        self.itemsTableView.reloadData()
    }
    
    func updateProfile(mediaUrl: String?) {
        
        let ref = FIRDatabase.database().reference().child("rooms").child(roomId).child("info")
        if mediaUrl != nil {
            ref.updateChildValues(["avatar": mediaUrl!, "name": txtRoom.text!])
        } else {
            ref.updateChildValues(["name": txtRoom.text!])
        }
        
        HUD.hide()
        
        btnEdit.setTitle("Edit Room Info", for: .normal)
        avatarImageView.isUserInteractionEnabled = false
        txtRoom.isEnabled = false
    }
}

extension ChatSettingsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CELL") as! InviteUserCell
        let user = users[indexPath.row]
        
        cell.setupCell(with: user, invited: room?.isMyRoom(uid: user.uid) ?? false, indexPath: indexPath)
        cell.delegate = self
        return cell
    }
}

extension ChatSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 81
    }
}

extension ChatSettingsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            avatar  = image
            avatarImageView.image = image
        }
        dismiss(animated: true, completion: nil)
    }
}

extension ChatSettingsViewController: InviteUserCellDelegate {
    func inviteUser(index: IndexPath?) {
        if index == nil {
            return
        }
        
        if var users = room?.users {
            let invitedUser = self.users[index!.row]
            let ref = FIRDatabase.database().reference().child("rooms").child(roomId)
            users.append(invitedUser.uid!)
            ref.updateChildValues(["users": users])
            
            chatVC?.sendTextMessage(text: "Invited \(invitedUser.name!)")
        }
    }
}
