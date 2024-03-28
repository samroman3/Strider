//
//  AppDelegate.swift
//  myPedometer
//
//  Created by Sam Roman on 3/20/24.
//

import UIKit
import CloudKit
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    let cloudKitContainer = CKContainer.default()
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        // Handle incoming universal links for CloudKit shares
        guard let incomingURL = userActivity.webpageURL else { return false }
        AppState.shared.handleIncomingURL(incomingURL)
        return true
    }
    
    func registerForPushNotifications() {
        UNUserNotificationCenter.current().delegate = self
         UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
             guard granted else { return }
             UNUserNotificationCenter.current().getNotificationSettings { settings in
                 guard settings.authorizationStatus == .authorized else { return }
                 DispatchQueue.main.async {
                     UIApplication.shared.registerForRemoteNotifications()
                 }
             }
         }
     }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        guard let notification = CKNotification(fromRemoteNotificationDictionary: userInfo as! [String: NSObject]) else {
            completionHandler(.failed)
            return
        }
        
        switch notification.notificationType {
        case .query:
            // Ensure it's the right query notification by fetching the record by ID and checking its type.
            if let queryNotification = notification as? CKQueryNotification,
               let recordID = queryNotification.recordID {
            //MARK: TODO
                // Call a method on CloudKitManager to handle fetching and processing of the record.
                Task {
                    await CloudKitManager.shared.handleNotification(queryNotification)
                    DispatchQueue.main.async {
                   //TODO: set background notifs for challenge updates
                        // Notify AppState/ ChallengeViewModel to update UI based on notificaton.
                    }
                    completionHandler(.newData)
                }
            } else {
                completionHandler(.noData)
            }
        default:
            completionHandler(.noData)
        }
    }

    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        registerForPushNotifications()
        return true
    }

}

