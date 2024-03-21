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
        guard let notification = CKNotification(fromRemoteNotificationDictionary: userInfo as! [String: NSObject]) else {
            completionHandler(.failed)
            return
        }
        
        switch notification.notificationType {
        case .query:
            // Ensure it's the right query notification for "Challenge" updates.
            // This assumes you have some way to verify this, like a custom key in the notification's userInfo
            // or by fetching the record by ID and checking its type.
            // The below is a simplified example:
            if let queryNotification = notification as? CKQueryNotification,
               let recordID = queryNotification.recordID {
                
                // Call a method on CloudKitManager to handle fetching and processing of the record.
                Task {
                    await CloudKitManager.shared.handleNotification(queryNotification)
                    DispatchQueue.main.async {
                        // Notify AppState or relevant ViewModel to update UI if needed.
                        // This could involve setting a published property that the UI observes.
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
        
        return true
    }
}

