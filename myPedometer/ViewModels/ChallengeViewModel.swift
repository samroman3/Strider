//
//  ChallengeViewModel.swift
//  myPedometer
//
//  Created by Sam Roman on 3/16/24.
//

import SwiftUI
import CloudKit
import CoreData
import Combine

class ChallengeViewModel: ObservableObject {
    var cloudKitManager: CloudKitManager
    var userSettingsManager: UserSettingsManager
    
    @Published var challenges: [ChallengeDetails] = []
    @Published var pendingChallenges: [PendingChallenge] = [] // For challenges awaiting acceptance
    @Published var activeChallenges: [ChallengeDetails] = []
    @Published var noActiveChallengesText = "No active challenges. Invite Striders to begin!"
    
    private var cancellables: Set<AnyCancellable> = []
    
    @Published var presentShareController = false
    @Published var showCreateController = false
    @Published var share: CKShare?
    @Published var shareURL: URL?
    @Published var details: ChallengeDetails?
    
    var container: CKContainer?
    
    init(userSettingsManager: UserSettingsManager, cloudKitManager: CloudKitManager){
        self.userSettingsManager = userSettingsManager
        self.cloudKitManager = cloudKitManager
        self.container = cloudKitManager.cloudKitContainer
        
        cloudKitManager.$challengeUpdates
            .sink { [weak self] updates in
                self?.processUpdates(updates)
            }
            .store(in: &cancellables)
    }
    
    func loadPendingChallenges() async {
        let loadedChallenges = await cloudKitManager.loadPendingChallenges()
        DispatchQueue.main.async {
            self.pendingChallenges = loadedChallenges
        }
    }
    
    private func processUpdates(_ updates: [ChallengeDetails]) {
        DispatchQueue.main.async{
            for update in updates {
                if let index = self.challenges.firstIndex(where: { $0.recordId == update.recordId }) {
                    self.challenges[index] = update
                } else {
                    self.challenges.append(update)
                }
                // Transition challenges from pending to active if their status has changed
                if let pendingIndex = self.pendingChallenges.firstIndex(where: { $0.challengeDetails.recordId == update.recordId && update.status == "Active" }) {
                    // Move the challenge to active challenges
                    let pendingChallenge = self.pendingChallenges.remove(at: pendingIndex)
                    self.activeChallenges.append(pendingChallenge.challengeDetails)
                }
            }

            }
            
            // filter challenges based on their status.
            self.activeChallenges = self.challenges.filter { $0.status == "Active" }
        }
    
    func createAndShareChallenge(goal: Int32, endTime: Date) {
        Task {
            do {
                let uuid = UUID().uuidString
                let details = ChallengeDetails(id: uuid, startTime: Date(), endTime: endTime, goalSteps: goal, status: "Pending", participants: [], recordId: uuid)
                
                guard let user = userSettingsManager.user, let _ = user.recordId else {
                    print("User information missing")
                    AppState.shared.triggerAlert(title: "Error", message: "Invalid User. Please sign out and sign back in.")
                    return
                }
                let (share, shareURL) = try await cloudKitManager.createChallenge(with: details, creator: user)
                
                if let share = share, let shareURL = shareURL {
                    
                    setupShare(share: share, url: shareURL, details: details)
                    let pendingChallenge = PendingChallenge(id: share.recordID.recordName, challengeDetails: details, shareRecordID: share.recordID.recordName)
                        DispatchQueue.main.async {
                            self.pendingChallenges.append(pendingChallenge)
                        }
                } else {
                    print("Failed to create or share the challenge.")
                }
            } catch {
                AppState.shared.triggerAlert(title: "Error", message: "Error creating or sharing challenge. Please try again later.")
                print("Error creating or sharing challenge: \(error)")
            }
        }
    }
    
    private func setupShare(share: CKShare, url: URL, details: ChallengeDetails) {
        // Prerequisites are met, configure the share.
        share[CKShare.SystemFieldKey.title] = "Strider Challenge: \(details.goalSteps) steps by end of \(details.endTime.formatted()) from \(userSettingsManager.userName)"
        DispatchQueue.main.async{
            // Present the share controller.
            self.presentCloudShareView(share: share, url: url, details: details)
        }
    }
    
    private func presentCloudShareView(share: CKShare, url: URL, details: ChallengeDetails) {
        self.share = share
        self.shareURL = url
        self.details = details
        self.presentShareController = true
    }
    
    func resendChallenge(_ challenge: PendingChallenge) async {
        let now = Date()
        if challenge.challengeDetails.endTime < now {
            // Challenge has expired
            AppState.shared.triggerAlert(title: "Challenge Expired", message: "This challenge has expired and cannot be resent. Please create a new challenge.")
            cancelChallenge(challenge)
            print("Challenge has expired, deleting challenge")
        }
        do {
            if let share = try await cloudKitManager.fetchShareFromRecordID(challenge.shareRecordID) {
                self.presentCloudShareView(share: share, url: share.url!, details: challenge.challengeDetails)
            }
        } catch {
            AppState.shared.triggerAlert(title: "Invalid Challenge", message: "Challenge has either expired or is no longer valid, please create a new challenge.")
            cancelChallenge(challenge)
            print("invalid share url, cancel challenge and create new one")
        }

    }
    
    func cancelChallenge(_ challenge: PendingChallenge) {
        // Find the index of the challenge to be cancelled
        if let index = pendingChallenges.firstIndex(where: { $0.id == challenge.id }) {
            // Remove the challenge from pendingChallenges with animation
            DispatchQueue.main.async{
                let _ = withAnimation {
                    self.pendingChallenges.remove(at: index)
                }
            }
        }
               Task {
            do {
                await cloudKitManager.cancelChallenge(challenge: challenge)
            }
        }
    }
}
