//
//  SceneDelegate.swift
//  HandyChattingApp
//
//  Created by 황신택 on 2021/12/16.
//

import UIKit
import KakaoSDKAuth
import GoogleSignIn
import FBSDKCoreKit
import Firebase

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    let appdelegate = AppDelegate()
    
    /// Connect the FIRAuth object and the listener to get information about the user logged in to the app in each app view. This listener is called whenever the user's login status changes.
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        Auth.auth().addStateDidChangeListener { auth, user in
            if user != nil {
                let HomeVC = storyboard.instantiateViewController(withIdentifier: "HomeVC")
                self.window?.rootViewController = HomeVC
            } else {
                let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC")
                self.window?.rootViewController = loginVC
            }
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
    
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        
    }
    
    
}


extension SceneDelegate {
    /// give permisstion external url
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            if (AuthApi.isKakaoTalkLoginUrl(url)) {
                _ = AuthController.handleOpenUrl(url: url)
            }
            else if url.absoluteString.hasPrefix("fb") {
                ApplicationDelegate.shared.application(
                    UIApplication.shared,
                    open: url,
                    sourceApplication: nil,
                    annotation: [UIApplication.OpenURLOptionsKey.annotation]
                )
            }
        }
    }
}

