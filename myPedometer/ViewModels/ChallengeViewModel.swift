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
    private var challengeManager: ChallengeManager
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
    
    init(userSettingsManager: UserSettingsManager, challengeManager: ChallengeManager) {
        self.userSettingsManager = userSettingsManager
        self.challengeManager = challengeManager
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
    
    func createChallenge(details: ChallengeDetails) {
        state = .loading
        // Use ChallengeManager to create a new challenge
        // You may also need to create a new `Challenge` Core Data entity here, or have the manager handle it
    }
    
    func acceptChallenge(_ challenge: Challenge) {
        // Accept an invitation to a challenge
    }
    
    func declineChallenge(_ challenge: Challenge) {
        // Decline an invitation to a challenge
    }
}
