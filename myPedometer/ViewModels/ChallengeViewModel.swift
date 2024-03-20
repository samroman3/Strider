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
    private var cloudKitManager: CloudKitManager
    private var userSettingsManager: UserSettingsManager
    @Published var challenges: [Challenge] = []
    @Published var pendingChallenges: [Challenge] = [] // For challenges awaiting acceptance
    @Published var currentChallenge: Challenge?
    @Published var noActiveChallengesText = "No active challenges. Invite Striders to begin!"
    
    enum State {
        case idle
        case loading
        case loaded
        case error(Error)
    }
    
    @Published private(set) var state: State = .idle
    
    private var cancellables = Set<AnyCancellable>()
    
    init(userSettingsManager: UserSettingsManager, cloudKitManager: CloudKitManager) {
        self.userSettingsManager = userSettingsManager
        self.cloudKitManager = cloudKitManager
//        setupSubscriptions()
    }
    
    // MARK: - Setup
    private func setupSubscriptions() {
        // Setup any Combine publishers that listen for updates to the challenges array, etc.
        // This might include observing changes in Core Data and updating the published challenges array accordingly.
    }
    
    // MARK: - Actions
    
    func loadActiveChallenges() {
        state = .loading
        // Load active challenges from the ChallengeManager or directly from Core Data
        // Example:
//        challengeManager.fetchActiveChallenges { [weak self] result in
//            DispatchQueue.main.async {
//                switch result {
//                case .success(let challenges):
//                    self?.challenges = challenges
//                    self?.state = .loaded
//                case .failure(let error):
//                    self?.state = .error(error)
//                }
//            }
//        }
    }
    
    func loadPendingChallenges() {
        state = .loading
        // Similar to loadActiveChallenges, but fetches challenges that the user has been invited to and has not yet responded
    }
    
    func createAndShareChallenge(goal: Int32, endTime: Date) {
            // Logic to create the challenge and retrieve CKRecord and CKShare for sharing
            Task {
                do {
                    let details = ChallengeDetails(startTime: Date(), endTime: endTime, goalSteps: goal, active: true, participants: [], recordId: UUID().uuidString)
                    var creator = Participant(user: userSettingsManager.user!, recordID: userSettingsManager.cloudKitRecordName ?? "")
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
    
//    func createChallenge(details: ChallengeDetails) {
//        state = .loading
//            Task {
//                do {
//                    try await challengeManager.createChallenge(with: details)
//                    // Reload challenges upon successful creation
//                    loadActiveChallenges()
//                } catch {
//                    print("Error creating challenge: \(error)")
//                }
//            }
//        }
    
    func acceptChallenge(_ challengeDetails: ChallengeDetails) {
        Task {
            do {
                // Assuming challengeDetails contains enough information to identify the challenge
                // Add current user as a participant to the challenge
                let currentUserParticipant = Participant(user: userSettingsManager.user!, recordID: userSettingsManager.cloudKitRecordName ?? "")
                try await cloudKitManager.addUserToChallenge(participant: currentUserParticipant, to: challengeDetails.recordId)
                
                // Optionally, set the challenge to active if not already and add it to the active challenges list
                // This could involve fetching the challenge again and updating its status
                loadActiveChallenges() // Reload challenges to reflect the new state
            } catch {
                print("Error accepting challenge: \(error)")
            }
        }
    }
    
    func declineChallenge(_ challenge: ChallengeDetails) {
        // Decline an invitation to a challenge
    }
}
