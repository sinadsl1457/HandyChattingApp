//
//  PushNotificationManager.swift
//  HandyChattingApp
//
//  Created by 황신택 on 2022/02/20.
//

import UIKit
import FirebaseMessaging
import Firebase
import UserNotifications
import FirebaseFirestore
import KakaoSDKAuth

extension AppDelegate: UNUserNotificationCenterDelegate, MessagingDelegate {
    func registerForPushNotifications(application: UIApplication) {
        let center = UNUserNotificationCenter.current()
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            center.requestAuthorization(
            options: authOptions,
            completionHandler: { granted, _ in
                guard granted else { return }
                
                center.delegate = self
    
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            })
        Messaging.messaging().delegate = self
        updateFirestorePushTokenIfNeeded()
    }
    
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("did fail to register remoteNoti!! \(error.localizedDescription)")
    }
    
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        defer{ completionHandler() }
        let userInfo = response.notification.request.content.userInfo
        print(userInfo)
        
        let keyWindow = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?.windows
                .filter({ $0.isKeyWindow }).first
        
        if let tabController = keyWindow?.rootViewController as? UITabBarController {
            tabController.selectedIndex = 1
            keyWindow?.rootViewController = tabController
            keyWindow?.makeKeyAndVisible()
        }
    }
    
    
    func updateFirestorePushTokenIfNeeded() {
        if let token = Messaging.messaging().fcmToken, let userid = self.userId {
            let usersRef = Firestore.firestore().collection("users").document(userid)
            usersRef.setData(["fcmToken": token], merge: true)
        }
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        updateFirestorePushTokenIfNeeded()
    }
    
}

