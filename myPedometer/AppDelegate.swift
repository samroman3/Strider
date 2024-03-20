//
//  AppDelegate.swift
//  myPedometer
//
//  Created by Sam Roman on 3/20/24.
//

import UIKit
import CloudKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    let cloudKitContainer = CKContainer.default()
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        // Handle incoming universal links for CloudKit shares
        guard let incomingURL = userActivity.webpageURL else { return false }
        AppState.shared.handleIncomingURL(incomingURL)
        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Handle CloudKit notifications, including share notifications
        guard let notification = CKNotification(fromRemoteNotificationDictionary: userInfo as! [String: NSObject]),
              notification.notificationType == .query else {
            completionHandler(.noData)
            return
        }
        AppState.shared.handleCloudKitNotification(notification)
        completionHandler(.newData)
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        return true
    }
}

