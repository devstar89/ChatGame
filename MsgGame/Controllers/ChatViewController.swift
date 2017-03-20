//
//  ChatViewController.swift
//  MsgGame
//
//  Created by Oleg Koshkin on 16/03/2017.
//  Copyright © 2017 Oleg Koshkin. All rights reserved.
//

import UIKit
import RSKPlaceholderTextView
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import ObjectMapper
import IQKeyboardManagerSwift
import Kingfisher

class ChatViewController: UIViewController {

    @IBOutlet weak var itemsTableView: UITableView!
    @IBOutlet weak var txtMessage: RSKPlaceholderTextView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    var messages: [Message] = []
    var roomId: String!
    var senderId: String!
    
    var roomRef: FIRDatabaseQuery?
    var queryRef: FIRDatabaseQuery?
    
    var startingFrame: CGRect?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Chat Room"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(handleClose))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(handleSettings))
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
        
        itemsTableView.register(UINib(nibName: "ChatTextCell", bundle: nil), forCellReuseIdentifier: "TextCell")
        itemsTableView.register(UINib(nibName: "ChatImageCell", bundle: nil), forCellReuseIdentifier: "ImageCell")
        itemsTableView.estimatedRowHeight = 52
        itemsTableView.rowHeight = UITableViewAutomaticDimension
        itemsTableView.keyboardDismissMode = UIScrollViewKeyboardDismissMode.interactive
        
        senderId = FIRAuth.auth()?.currentUser?.uid
        
        fetchRoomInfo()
        fetchMessages()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        IQKeyboardManager.sharedManager().enable = false
        IQKeyboardManager.sharedManager().enableAutoToolbar = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        IQKeyboardManager.sharedManager().enable = true
        IQKeyboardManager.sharedManager().enableAutoToolbar = true
    }
    
    func keyboardWillShow(notification: Notification) {
        if let rect = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            let duration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue ?? 0.25
            bottomConstraint.constant = rect.size.height
            UIView.animate(withDuration: duration, animations: {
                self.view.layoutIfNeeded()
            }) { _ in
                self.scrollToBottom()
            }
        }
    }
    
    func keyboardWillHide(notification: Notification) {
        let duration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue ?? 0.25
        bottomConstraint.constant = 0
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    func handleClose() {
        roomRef?.removeAllObservers()
        queryRef?.removeAllObservers()
        self.view.endEditing(true)
        navigationController!.popViewController(animated: true)
    }
    
    func handleSettings() {
        let settingsVC = ChatSettingsViewController(nibName: "ChatSettingsViewController", bundle: nil)
        settingsVC.roomId = roomId
        settingsVC.chatVC = self
        self.view.endEditing(true)
        self.navigationController?.pushViewController(settingsVC, animated: true)
    }

    @IBAction func sendMessage(_ sender: Any) {
        if txtMessage.text != "" {
            sendTextMessage(text: txtMessage.text)
        }
    }
    @IBAction func openImagePicker(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }
}

// Chat Handlers
extension ChatViewController {
    
    func fetchRoomInfo(){
        roomRef = FIRDatabase.database().reference().child("rooms").child(roomId).child("info")
        roomRef?.observe(.value, with: { snapshot in
            if let dictionary = snapshot.value as? [String: Any] {
                self.title = dictionary["name"] as? String
            }
        })
    }
    
    func fetchMessages() {
        let ref = FIRDatabase.database().reference().child("messages")
        queryRef = ref.queryOrdered(byChild: "roomId").queryEqual(toValue: roomId)
        
        queryRef?.observe(.childAdded, with: { (snapshot) in
            if let  dictionary = snapshot.value as? [String: Any] {
                self.updateMessage(messageId: snapshot.key, dictionary: dictionary)
            }
        })
        
        queryRef?.observe(.childChanged, with: { (snapshot) in
            if let  dictionary = snapshot.value as? [String: Any] {
                self.updateMessage(messageId: snapshot.key, dictionary: dictionary)
            }
        })
    }
    
    func updateMessage(messageId: String, dictionary: [String: Any]) {
        if let message = Mapper<Message>().map(JSON: dictionary) {
            
            if message.mediaType != nil && message.mediaUrl == nil {
                // uploading media failed
                return
            }
            
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.scrollToBottom), object: nil)
            
            let index = self.messages.index(where: { (msg) -> Bool in
                return msg.messageId == messageId
            })
            
            message.messageId = messageId
            if index != nil {
                self.messages[index!] = message
                self.itemsTableView.reloadRows(at: [IndexPath(row: index!, section: 0)], with: .automatic)
            } else {
                self.addMessageToController(message: message)
            }
        }
    }
    
    func addMessageToController(message: Message) {
        self.messages.append(message)
        
        let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
        self.itemsTableView.beginUpdates()
        self.itemsTableView.insertRows(at: [indexPath], with: .automatic)
        self.itemsTableView.endUpdates()
        
        self.perform(#selector(self.scrollToBottom), with: nil, afterDelay: 0.05)
    }
    
    func send(message: Message) -> FIRDatabaseReference{
        let ref = FIRDatabase.database().reference().child("messages")
        let msgRef = ref.childByAutoId()
        msgRef.updateChildValues(message.toJSON())
        
        let roomRef = FIRDatabase.database().reference().child("rooms").child(roomId)
        roomRef.updateChildValues(["recent": message.toJSON()])
        
        message.messageId = msgRef.key
        addMessageToController(message: message)
        return msgRef
    }
    
    func sendTextMessage(text: String) {
        let message = Message(roomId: roomId, text: text)
        _ = send(message: message)
        txtMessage.text = ""
    }
    
    func sendImageMessage(image: UIImage) {
        let message = Message(roomId: self.roomId, mediaType: .photo, width: image.size.width as NSNumber, height: image.size.height as NSNumber)
        let msgRef = send(message: message)
        ImageCache.default.store(image, forKey: msgRef.key)
        
        let storage = FIRStorage.storage().reference().child("\(roomId).png")
        if let uploadData = UIImageJPEGRepresentation(image, 0.1){
            storage.put(uploadData, metadata: nil, completion: { (meta, error) in
                if let url = meta?.downloadURL()?.absoluteString {
                    msgRef.updateChildValues(["mediaUrl": url])
                }
            })
        }
    }
    
    func scrollToBottom() {
        if messages.count == 0 {
            return
        }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        self.itemsTableView.scrollToRow(at: indexPath, at: .top, animated: true)
    }
}

// Image Handlers

extension ChatViewController {
    func handleZoomInImage(imageView: UIImageView) {
        
        startingFrame = imageView.superview?.convert(imageView.frame, to: nil)
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleZoomOutImage(gesture:)))
        let zoomingImageView = UIImageView(frame: startingFrame!)
        zoomingImageView.clipsToBounds = true
        zoomingImageView.contentMode = .scaleAspectFit
        zoomingImageView.image = imageView.image
        zoomingImageView.isUserInteractionEnabled = true
        zoomingImageView.addGestureRecognizer(gesture)
        zoomingImageView.backgroundColor = UIColor.clear
        
        if let keywindow = UIApplication.shared.keyWindow {
            keywindow.addSubview(zoomingImageView)
            UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseOut, animations: {
                zoomingImageView.frame = keywindow.bounds
            })
            
            UIView.animate(withDuration: 0.2, delay: 0.3, options: .curveEaseOut, animations: {
                zoomingImageView.backgroundColor = UIColor.black
            })
        }
    }
    
    func handleZoomOutImage(gesture: UITapGestureRecognizer) {
        if let imageView = gesture.view {
            UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseOut, animations: {
                imageView.backgroundColor = UIColor.black
            })
            
            UIView.animate(withDuration: 0.3, delay: 0.1, options: .curveEaseIn, animations: {
                imageView.frame = self.startingFrame!
                imageView.backgroundColor = UIColor.clear
            }) { _ in
                imageView.removeFromSuperview()
            }
        }
    }
}

extension ChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        var cell: ChatCell!
        if message.mediaType != nil {
            
            // will extend video, file in the future ....
            cell = tableView.dequeueReusableCell(withIdentifier: "ImageCell") as! ChatImageCell
            cell.delegate = self
            cell.indexPath = indexPath
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "TextCell") as! ChatTextCell
        }
        
        cell.setupCell(with: message)
        return cell
    }
}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            sendImageMessage(image: image)
        }
        dismiss(animated: true, completion: nil)
    }
}

extension ChatViewController: ChatCellDelegate {
    func openMedia(indexPath: IndexPath, with: Any? = nil) {
        let message = messages[indexPath.row]
        
        if message.mediaType == .photo {
            if let imageView = with as? UIImageView {
                handleZoomInImage(imageView: imageView)
            }
        }
    }
}
