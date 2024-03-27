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
    @Published var pendingChallenges: [ChallengeDetails] = [] // For challenges awaiting acceptance
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
    
    private func processUpdates(_ updates: [ChallengeDetails]) {
        DispatchQueue.main.async{
            for update in updates {
                if let index = self.challenges.firstIndex(where: { $0.recordId == update.recordId }) {
                    self.challenges[index] = update
                } else {
                    self.challenges.append(update)
                }
            }
            // filter challenges based on their status.
            self.pendingChallenges = self.challenges.filter { $0.status == "Pending" }
            self.activeChallenges = self.challenges.filter { $0.status == "Active" }
        }
    }
    
    func createAndShareChallenge(goal: Int32, endTime: Date) {
        Task {
            do {
                let uuid = UUID().uuidString
                let details = ChallengeDetails(id: uuid, startTime: Date(), endTime: endTime, goalSteps: goal, status: "Sent", participants: [], recordId: uuid)
                
                guard let user = userSettingsManager.user, let recordId = user.recordId else {
                    print("User information missing")
                    return
                }
                let (share, shareURL) = try await cloudKitManager.createChallenge(with: details, creator: user)
                
                if let share = share, let shareURL = shareURL {
                    setupShare(share: share, url: shareURL, details: details)
                } else {
                    print("Failed to create or share the challenge.")
                }
            } catch {
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
    
    func acceptChallenge(_ challengeDetails: ChallengeDetails) {
        Task {
            let currentUserParticipant = Participant(user:userSettingsManager.user! , recordId: userSettingsManager.cloudKitRecordName)
                await cloudKitManager.addParticipantToChallenge(challengeID: challengeDetails.recordId, participantID: currentUserParticipant.id)
            }
    }
    
    func declineChallenge(_ challengeDetails: ChallengeDetails) {
        Task {
            do {
                await cloudKitManager.declineChallenge(challengeID: challengeDetails.recordId)
            }
        }
    }
}
