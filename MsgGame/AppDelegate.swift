//
//  AppDelegate.swift
//  MsgGame
//
//  Created by Oleg Koshkin on 15/03/2017.
//  Copyright © 2017 Oleg Koshkin. All rights reserved.
//

import UIKit
import Firebase
import IQKeyboardManagerSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let loginVC = LoginViewController(nibName: "LoginViewController", bundle: nil)
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = loginVC
        window?.makeKeyAndVisible()
        
        FIRApp.configure()
        IQKeyboardManager.sharedManager().enable = true
        return true
    }

}

