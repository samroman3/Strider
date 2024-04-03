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
    let title: String
    let message: String
    let dismissButton: Alert.Button
}

struct CustomModalView: View {
    var alertItem: AlertItem
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Text(alertItem.title)
                .bold()
                .foregroundStyle(.black)
            Text(alertItem.message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.black)
            Button("OK", action: onDismiss)
                .buttonStyle(AppButtonStyle(backgroundColor: AppTheme.greenGradient))
        }
        .padding()
        .background(.primary)
        .cornerRadius(15)
        .shadow(radius: 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.4).edgesIgnoringSafeArea(.all))
    }
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
        let alert = AlertItem(title: title, message: message, dismissButton: .default(Text("OK")))
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
                            self.challengeInvitation = challengeDetails.0
                            self.challengeMetadata = metadata
                            self.currentChallengeState = .invitation(challengeDetails.0!)
                        }
                    } else {
                        self.triggerAlert(title: "Error", message: "Invalid Challenge Details")
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
            self.currentChallengeState = nil
            self.triggerAlert(title: "Challenge", message: "Challenge Declined")
        }
    }
    
    func acceptChallenge() async {
        guard let metadata = challengeMetadata,
              let _ = challengeInvitation else { return }
        
        do {
            // Use the stored metadata to accept the challenge
            guard let (acceptedChallengeDetails,record) = try await cloudKitManager.acceptShareAndFetchChallenge(metadata: metadata) else { return  }
            let acceptSuccess = await cloudKitManager.addCurrentUserToChallenge(challengeDetails: acceptedChallengeDetails!, record: record!)
            if acceptSuccess {
                DispatchQueue.main.async{
//                    self.currentChallengeState = .challengeActive(acceptedChallengeDetails!)
                    // Clear temporary storage after use
                    self.challengeMetadata = nil
                    self.challengeInvitation = nil
                    self.currentChallengeState = nil
                    self.triggerAlert(title: "Challenge", message: "Challenge Now Active!")
                }
            }
            else {
                DispatchQueue.main.async{
                    //Challenge participants full, alert user and remove metadata
                    self.challengeMetadata = nil
                    self.challengeInvitation = nil
                    self.currentChallengeState = nil
                    self.triggerAlert(title: "Error", message: "This challenge may already have the maximum number of participants or is no longer available.")
                }
            }
        } catch {
            print("Error accepting challenge: \(error)")
            self.challengeMetadata = nil
            self.challengeInvitation = nil
            self.currentChallengeState = nil
            self.triggerAlert(title: "Error", message: "Cannot Accept Challenge")
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
    }
    
    func participantAdded(challengeDetails: ChallengeDetails) {
        DispatchQueue.main.async {
            self.currentChallengeState = .challengeActive(challengeDetails)
        }
    }
}
