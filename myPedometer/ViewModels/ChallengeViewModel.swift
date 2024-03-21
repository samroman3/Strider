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
    private var cloudKitManager = CloudKitManager.shared
    private var userSettingsManager = UserSettingsManager.shared
    @Published var challenges: [Challenge] = []
    @Published var pendingChallenges: [Challenge] = [] // For challenges created and awaiting acceptance
    @Published var noActiveChallengesText = "No active challenges. Invite Striders to begin!"
    
    enum State {
        case idle
        case loading
        case loaded
        case error(Error)
    }
    
    @Published private(set) var state: State = .idle
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Actions
    
    func createAndShareChallenge(goal: Int32, endTime: Date) {
            // Logic to create the challenge and retrieve CKRecord and CKShare for sharing
            Task {
                do {
                    let details = ChallengeDetails(startTime: Date(), endTime: endTime, goalSteps: goal, active: true, participants: [], recordId: UUID().uuidString)
                    let creator = Participant(user: userSettingsManager.user!, recordID: userSettingsManager.cloudKitRecordName ?? "")
                    let (record, share) = try await cloudKitManager.createChallenge(with: details, creator: creator)
                    presentCloudShareView(record: record, share: share)
                } catch {
                    print("Error creating or sharing challenge: \(error)")
                }
            }
        }
    
    private func presentCloudShareView(record: CKRecord, share: CKShare) {
           // Logic to present CloudShareView with provided record and share
           // This could involve setting some @Published properties to trigger the presentation in the view layer
       }
    
     func acceptChallenge(_ challengeDetails: ChallengeDetails) {
        Task {
            do {
                let currentUserParticipant = Participant(user: userSettingsManager.user!, recordID: userSettingsManager.cloudKitRecordName ?? "")
                try await cloudKitManager.addUserToChallenge(participant: currentUserParticipant, to: challengeDetails.recordId)
                // Notify AppState or directly update UI as necessary
//                AppState.shared.challengeAccepted()
            } catch {
                print("Error accepting challenge: \(error)")
            }
        }
    }
  
    
    func declineChallenge(_ challenge: ChallengeDetails) {
        // Decline an invitation to a challenge
    }
}
