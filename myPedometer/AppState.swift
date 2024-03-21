//
//  AppState.swift
//  myPedometer
//
//  Created by Sam Roman on 3/14/24.
//

import Foundation
import CloudKit

enum ChallengeState: Identifiable {
    case invitation(ChallengeDetails)
    case challengeActive(ChallengeDetails)
    case challengeCompleted(ChallengeDetails)
    
    // Identifiable conformance
    var id: String {
        switch self {
        case .invitation(let challengeDetails),
             .challengeActive(let challengeDetails),
             .challengeCompleted(let challengeDetails):
            return challengeDetails.recordId
        }
    }
}


class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var isHandlingShare = false
    @Published var sharedChallengeDetails: ChallengeDetails?
    @Published var showAlertForAcceptedChallenge = false
    @Published var challengeCompleted = false
    @Published var participantAddedToChallenge = false
    
    @Published var currentChallengeState: ChallengeState? = nil

    
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
                                self.currentChallengeState = .invitation(challengeDetails)
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
            
            Task {
                await cloudKitManager.handleNotification(queryNotification)
            }
        }
    
    func challengeAccepted(challengeDetails: ChallengeDetails) {
           DispatchQueue.main.async {
               self.currentChallengeState = .challengeActive(challengeDetails)
           }
       }
       
       func challengeCompleted(challengeDetails: ChallengeDetails) {
           DispatchQueue.main.async {
               self.currentChallengeState = .challengeCompleted(challengeDetails)
           }
       }
       
       func participantAdded(challengeDetails: ChallengeDetails) {
           DispatchQueue.main.async {
               self.currentChallengeState = .challengeActive(challengeDetails)
           }
       }
}
