//
//  SceneDelegate.swift
//  myPedometer
//
//  Created by Sam Roman on 3/28/24.
//

import Foundation
import UIKit
import CloudKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    let cloudKitContainer = CKContainer.default()
    
    func windowScene(_ windowScene: UIWindowScene, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        let acceptSharesOperation = CKAcceptSharesOperation(shareMetadatas: [cloudKitShareMetadata])

        // Set the per-share result block to handle the result of accepting a share.
        acceptSharesOperation.perShareResultBlock = { metadata, result in
            switch result {
            case .success(let share):
                if let url = share.url {
                    AppState.shared.handleIncomingURL(url)
                }
            case .failure(let error):
                // Handle the error here.
                print("Failed to accept share: \(error)")
            }
        }

        // Add the operation to the queue to start it.
        CKContainer.default().add(acceptSharesOperation)
        }
}
