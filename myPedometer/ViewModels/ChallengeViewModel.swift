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

final class ChallengeViewModel: ObservableObject {
    var cloudKitManager: CloudKitManager
    var userSettingsManager: UserSettingsManager
    
    @Published var challenges: [ChallengeDetails] = []
    @Published var pendingChallenges: [PendingChallenge] = []
    @Published var activeChallenges: [ChallengeDetails] = []
    
    private var cancellables: Set<AnyCancellable> = []
    
    @Published var presentShareController = false
    @Published var showCreateController = false
    @Published var share: CKShare?
    @Published var shareURL: URL?
    @Published var details: ChallengeDetails?
    
    // Properties to hold the steps for the current user and their competitor
    
    @Published var myInfo: ParticipantDetails?
    @Published var competitorInfo: ParticipantDetails?

    @Published var mySteps: Int = 0
    @Published var theirSteps: Int = 0

    var container: CKContainer?
    
    init(userSettingsManager: UserSettingsManager, cloudKitManager: CloudKitManager){
        self.userSettingsManager = userSettingsManager
        self.cloudKitManager = cloudKitManager
        self.container = cloudKitManager.cloudKitContainer
        // Subscribe to challenge updates
            cloudKitManager.challengeUpdatesPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] challengeDetails in
                    self?.processChallengeUpdate(challengeDetails)
                }
                .store(in: &cancellables)
    }
    
    private func processChallengeUpdate(_ newDetails: ChallengeDetails) {
        DispatchQueue.main.async {
            // Directly add or update challenges in their respective arrays
            switch newDetails.status {
            case "Active":
                // Move challenge from pending to active, if present
                if let index = self.pendingChallenges.firstIndex(where: { $0.challengeDetails.recordId == newDetails.recordId }) {
                    self.pendingChallenges.remove(at: index)
                }
                if !self.activeChallenges.contains(where: { $0.recordId == newDetails.recordId }) {
                    self.activeChallenges.append(newDetails)
                }
            case "Completed":
                // Remove from active, move to past if needed
                if let index = self.activeChallenges.firstIndex(where: { $0.recordId == newDetails.recordId }) {
                    self.activeChallenges.remove(at: index)
                }
            default:
                break
            }
        }
    }
    
    func fetchChallenges() {
        self.pendingChallenges = cloudKitManager.loadPendingChallenges()
        Task {
             cloudKitManager.fetchActiveChallenges() { [weak self] activeChallenges in
                self?.activeChallenges = activeChallenges
            }
        }
    }

      func updateStepsAndInfo(for challengeDetails: ChallengeDetails) {
          guard let userID = userSettingsManager.user?.recordId else { return }
          
          for participant in challengeDetails.participants {
              if participant.id == userID {
                  // Update current user's info and steps
                  myInfo = participant
                  mySteps = participant.steps // Assuming steps is part of ParticipantDetails
              } else {
                  // Update competitor's info and steps
                  competitorInfo = participant
                  theirSteps = participant.steps // Assuming steps is part of ParticipantDetails
              }
          }
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
                AppState.shared.triggerAlert(title: "Error", message: "Error creating or sharing challenge. Please try again later.\(error))")
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
        DispatchQueue.main.async {
                self.share = share
                self.shareURL = url
                self.details = details
                self.presentShareController = true
            }
    }
    
    func resendChallenge(_ challenge: PendingChallenge) async {
        let now = Date()
        if challenge.challengeDetails.endTime < now {
            await cancelChallenge(challenge)
            // Challenge has expired
            AppState.shared.triggerAlert(title: "Challenge Expired", message: "This challenge has expired and cannot be resent. Please create a new challenge.")
            print("Challenge has expired, deleting challenge")
        }
        do {
            if let share = try await cloudKitManager.fetchShareFromRecordID(challenge.shareRecordID) {
                self.presentCloudShareView(share: share, url: share.url!, details: challenge.challengeDetails)
            }
        } catch {
            await cancelChallenge(challenge)
            AppState.shared.triggerAlert(title: "Invalid Challenge", message: "Challenge has either expired or is no longer valid, please create a new challenge.")
            print("invalid share url, cancel challenge and create new one")
        }

    }
    
    func cancelChallenge(_ challenge: PendingChallenge) async {
        await cloudKitManager.cancelChallenge(challenge: challenge)
        // Find the index of the challenge to be cancelled
        if let index = pendingChallenges.firstIndex(where: { $0.id == challenge.id }) {
            // Remove the challenge from pendingChallenges with animation
            DispatchQueue.main.async{
                let _ = withAnimation {
                    self.pendingChallenges.remove(at: index)
                }
            }
        }
    }
    
}
