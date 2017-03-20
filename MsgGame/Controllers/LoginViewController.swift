//
//  LoginViewController.swift
//  MsgGame
//
//  Created by Oleg Koshkin on 15/03/2017.
//  Copyright © 2017 Oleg Koshkin. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import PKHUD

class LoginViewController: UIViewController {

    @IBOutlet weak var segmentedController: UISegmentedControl!
    @IBOutlet weak var txtName: UITextField!
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var avatarImageView: UIImageView!
    
    var avatar: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if FIRAuth.auth()?.currentUser != nil {
            DispatchQueue.main.async {
                self.presentMessagesController()
            }
        }
    }
    
    @IBAction func changeUI(_ sender: Any) {
        txtName.isHidden = segmentedController.selectedSegmentIndex == 0
        avatarImageView.isUserInteractionEnabled = segmentedController.selectedSegmentIndex == 1
        avatarImageView.image = segmentedController.selectedSegmentIndex == 0 ? #imageLiteral(resourceName: "avatar.png") : (avatar ?? #imageLiteral(resourceName: "camera.png"))
    }

    @IBAction func signIn(_ sender: Any) {
        if segmentedController.selectedSegmentIndex == 0 {
            handleLogin()
        } else {
            handleRegister()
        }
    }
    
    @IBAction func changeAvatar(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }
}

extension LoginViewController {
    
    func presentMessagesController() {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.window?.rootViewController = UINavigationController(rootViewController: MessagesViewController(nibName: "MessagesViewController", bundle: nil))
    }
    
    func handleLogin() {
        guard let email = txtEmail.text, let password = txtPassword.text else {
            return
        }
        
        HUD.show(.progress)
        FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user, error) in
            if error != nil {
                HUD.flash(.error)
                print("Firebase Error: \(error)")
                return
            }
            
            DispatchQueue.main.async {
                HUD.hide()
                self.presentMessagesController()
            }
        })
    }
    
    func handleRegister() {
        guard let name = txtName.text, let email = txtEmail.text, let password = txtPassword.text else {
            return
        }
        
        HUD.show(.progress)
        FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user, error) in
            if error != nil || user == nil {
                HUD.flash(.error)
                print("Firebase Error: \(error)")
                return
            }
            
            if self.avatar != nil {
                let storage = FIRStorage.storage().reference().child("\(user!.uid).png")
                if let uploadData = UIImageJPEGRepresentation(self.avatar!, 0.1){
                    storage.put(uploadData, metadata: nil, completion: { (meta, error) in
                        self.updateProfile(user: user!, email: email, name: name, avatar: meta?.downloadURL())
                    })
                }
            } else {
                self.updateProfile(user: user!, email: email, name: name, avatar: nil)
            }
            
            
        })
    }
    
    func updateProfile(user: FIRUser, email: String, name: String, avatar: URL?) {
        let ref = FIRDatabase.database().reference()
        let userRef = ref.child("users").child(user.uid)
        
        if avatar == nil {
            userRef.updateChildValues(["email": email, "name": name])
        } else {
            userRef.updateChildValues(["email": email, "name": name, "avatar": avatar!.absoluteString])
        }
        
        let updateRequest = user.profileChangeRequest()
        updateRequest.displayName = name
        updateRequest.photoURL = avatar
        
        updateRequest.commitChanges(completion: { _ in
            DispatchQueue.main.async {
                HUD.hide()
                self.presentMessagesController()
            }
        })
    }
}

extension LoginViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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
