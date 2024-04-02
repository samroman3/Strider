//
//  AppState.swift
//  myPedometer
//
//  Created by Sam Roman on 3/14/24.
//

import SwiftUI
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
struct AlertItem: Identifiable {
    let id = UUID()
    let title: Text
    let message: Text
    let dismissButton: Alert.Button
}


class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var isHandlingShare = false
    @Published var challengeCompleted = false
    @Published var participantAddedToChallenge = false
    @Published var challengeInvitation: ChallengeDetails?
    var challengeMetadata: CKShare.Metadata?
    @Published var currentChallengeState: ChallengeState? = nil
    
    
    private let cloudKitManager = CloudKitManager.shared
    
    @Published var alertItem: AlertItem?
    
    func triggerAlert(title: String, message: String) {
        let alert = AlertItem(title: Text(title), message: Text(message), dismissButton: .default(Text("OK")))
        DispatchQueue.main.async {
            self.alertItem = alert
        }
    }
    
    let cloudKitContainer = CKContainer.default()
    
    func handleIncomingURL(_ url: URL) {
        cloudKitContainer.fetchShareMetadata(with: url) { [weak self] metadata, error in
            guard let self = self, let metadata = metadata, error == nil else {
                print("Error fetching share metadata: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            Task {
                // Accept the share and fetch challenge details for "preview"
                do {
                    if let challengeDetails = try await self.cloudKitManager.acceptShareAndFetchChallenge(metadata: metadata) {
                        DispatchQueue.main.async {
                            self.challengeInvitation = challengeDetails
                            self.challengeMetadata = metadata
                            self.currentChallengeState = .invitation(challengeDetails)
                        }
                    }
                } catch {
                    print("Error handling incoming share: \(error)")
                    self.triggerAlert(title: "Error", message: "Error handling incoming share.")
                }
            }
        }
    }
    
    func declineChallenge() {
        DispatchQueue.main.async {
            self.challengeInvitation = nil
            self.challengeMetadata = nil
            self.triggerAlert(title: "Challenge", message: "Challenge Declined")
        }
    }
    
    func acceptChallenge() async {
        guard let metadata = challengeMetadata,
              let _ = challengeInvitation else { return }
        
        do {
            // Use the stored metadata to accept the challenge
            guard let acceptedChallengeDetails = try await cloudKitManager.acceptShareAndFetchChallenge(metadata: metadata) else { return  }
            let acceptSuccess = await cloudKitManager.addCurrentUserToChallengeIfPossible(challengeDetails: acceptedChallengeDetails)
            if acceptSuccess {
                self.currentChallengeState = .challengeActive(acceptedChallengeDetails)
                // Clear temporary storage after use
                self.challengeMetadata = nil
                self.challengeInvitation = nil
            }
            else {
                //Challenge participants full, alert user and remove metadata
                self.challengeMetadata = nil
                self.challengeInvitation = nil
                self.triggerAlert(title: "Error Adding Participant", message: "This challenge may already have the maximum number of participants.")
            }
        } catch {
            print("Error accepting challenge: \(error)")
            self.triggerAlert(title: "Error", message: "Error Accepting Challenge")
        }
    }
    
    func receiveChallengeInvitation(_ challengeDetails: ChallengeDetails, metadata: CKShare.Metadata){
        DispatchQueue.main.async {
            self.challengeInvitation = challengeDetails
            self.challengeMetadata = metadata
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
           AppState.shared.triggerAlert(title: "Challenge Active", message: "Challenge is now active! Goal: \(challengeDetails.goalSteps), End Time: \(challengeDetails.endTime.formatted())")
        }
    }
    
    func challengeCompleted(challengeDetails: ChallengeDetails) {
        DispatchQueue.main.async {
            self.currentChallengeState = .challengeCompleted(challengeDetails)
        }
    }
    
    func challengeDenied(challengeDetails: ChallengeDetails) {
        // Update UI and alert user about the denied challenge.
    }
    
    func participantAdded(challengeDetails: ChallengeDetails) {
        DispatchQueue.main.async {
            self.currentChallengeState = .challengeActive(challengeDetails)
        }
    }
}
