[![License](http://img.shields.io/badge/License-MIT-green.svg?style=flat)](https://github.com/olegkoshkin06/ChatGame/blob/master/LICENSE)
[![Swift 3](https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat)](https://swift.org)

# ChatGame
Real time chat app written in Swift 3 using Firebase 3

ChatGame allows you to send and receive text messages and photos. ChatGame also provides Single-Chat and Multi-Chat.

<h3 align="center">
<img src="screenshots/ChatGame.gif" alt="Screenshot of ChatGame for iOS" />
</h3>

## Getting Started

To get started and run the app, you need to follow these simple steps:

### Install cocoapods

  ```
  sudo gem install cocoapods
  pod install
  ```

### Create your own app at Firebase (optional) 
1. Change the Bundle Identifier with yours.
2. Go to [Firebase](https://firebase.google.com) and create new project.
3. Select "Add Firebase to your iOS app" option, type the bundle Identifier & click continue.
4. Remove "GoogleService-Info.plist" from Xcode project. 
5. Download your [GoogleService-Info.plist](https://support.google.com/firebase/answer/7015592) file and add to the project.
6. Go to [Firebase Console](https://console.firebase.google.com), select your project, choose "Authentication" from left menu, select "SIGN-IN METHOD" and enable "Email/Password" option.
7. You're all set! Run ChatGame.

## License
Source code is distributed under MIT license.
