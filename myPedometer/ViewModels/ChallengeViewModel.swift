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
    private let cloudKitManager = CloudKitManager.shared
    private let userSettingsManager = UserSettingsManager.shared
    
    @Published var challenges: [ChallengeDetails] = []
    @Published var pendingChallenges: [ChallengeDetails] = [] // For challenges awaiting acceptance
    @Published var noActiveChallengesText = "No active challenges. Create and share a challenge to begin!"
    
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        cloudKitManager.$challengeUpdates
            .sink { [weak self] updates in
                self?.processUpdates(updates)
            }
            .store(in: &cancellables)
    }
    
    private func processUpdates(_ updates: [ChallengeDetails]) {
        for update in updates {
            if let index = challenges.firstIndex(where: { $0.recordId == update.recordId }) {
                challenges[index] = update
            } else {
                challenges.append(update)
            }
        }
        // Sort or filter challenges based on their status.
        pendingChallenges = challenges.filter { $0.status == "Sent" || $0.status == "Received" }
    }
    
    func createAndShareChallenge(goal: Int32, endTime: Date) {
        Task {
            do {
                let details = ChallengeDetails(startTime: Date(), endTime: endTime, goalSteps: goal, status: "Sent", participants: [], recordId: UUID().uuidString)
                if let user = userSettingsManager.user {
                    let creator = Participant(user: user, recordID: userSettingsManager.cloudKitRecordName!)
                        let (record, share) = try await cloudKitManager.createChallenge(with: details, creator: creator)
                        DispatchQueue.main.async {
                            self.presentCloudShareView(record: record, share: share)
                        }
                    }
            } catch {
                print("Error creating or sharing challenge: \(error)")
            }
        }
    }
    
    private func presentCloudShareView(record: CKRecord, share: CKShare) {
        // Implement presentation logic here.
    }
    
    func acceptChallenge(_ challengeDetails: ChallengeDetails) {
        Task {
                let currentUserParticipant = Participant(user:userSettingsManager.user! , recordID: userSettingsManager.cloudKitRecordName!)
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
