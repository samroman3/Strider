//
//  AppState.swift
//  myPedometer
//
//  Created by Sam Roman on 3/14/24.
//

import Foundation
import CloudKit

class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var isHandlingShare = false
    @Published var sharedChallengeDetails: ChallengeDetails?
    
    private let cloudKitManager = CloudKitManager.shared
    
    let cloudKitContainer = CKContainer.default()
      
    func handleIncomingURL(_ url: URL) {
        CKContainer.default().fetchShareMetadata(with: url) { [weak self] metadata, error in
            guard let self = self, let metadata = metadata, error == nil else {
                print("Error fetching share metadata: \(String(describing: error))")
                return
            }

            Task {
                do {
                    if let challengeDetails = try await self.cloudKitManager.acceptShareAndFetchChallenge(metadata: metadata) {
                        DispatchQueue.main.async {
                            // Update AppState with the challenge details
                            self.sharedChallengeDetails = challengeDetails
                            self.isHandlingShare = true
                        }
                    }
                } catch {
                    print("Error accepting share and fetching challenge: \(error)")
                }
            }
        }
    }
    
    func handleCloudKitNotification(_ notification: CKNotification) {
            guard let queryNotification = notification as? CKQueryNotification else {
                print("Received notification is not a query notification.")
                return
            }
            //TODO: Process the notification, update local data/ UI
            Task {
                await cloudKitManager.handleNotification(queryNotification)
            }
        }
    
}
