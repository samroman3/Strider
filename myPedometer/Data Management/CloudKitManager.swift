//
//  CloudKitManager.swift
//  myPedometer
//
//  Created by Sam Roman on 3/16/24.
//

import SwiftUI
import CloudKit
import CoreData

class CloudKitManager: ObservableObject {
    
    static let shared = CloudKitManager()
    
    var userSettingsManager: UserSettingsManager?
    
    enum State {
        case idle
        case loading
        case loaded
        case error(Error)
    }
    
    enum ManagerError: Error {
        case invalidRecord
        case challengeCreationFailed
        case sharingFailed
        case invalidUser
    }
    
    @Published private(set) var state: State = .idle
    
    var cloudKitContainer: CKContainer
    var context: NSManagedObjectContext?
    let recordZone = CKRecordZone(zoneName: "Challenges")
    
    @Published var challengeUpdates: [ChallengeDetails] = []
    
    @Published var pendingChallenges: [PendingChallenge] = []

    
    init() {
        self.cloudKitContainer =  CKContainer.default()
        setupChallengeSubscription()
    }
    
    func saveContext() {
        guard let context = self.context, context.hasChanges else { return }
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    // MARK: Challenge Management
    
    func saveChallengeToCoreData(with details: ChallengeDetails, creator: User) async throws -> Challenge? {
        let challenge = Challenge(context: context!)
        challenge.startTime = details.startTime
        challenge.endTime = details.endTime
        challenge.goalSteps = details.goalSteps
        challenge.status = details.status
        challenge.recordId = details.recordId
        challenge.addToParticipants(creator)
        creator.addToChallenges(challenge)
        self.saveContext()
        return challenge
    }
    
    func shareChallenge(_ challenge: Challenge, withParticipants participants: [Participant], creator: User) async throws -> (CKShare?, URL?) {
        
        try await createZoneIfNeeded()

        let challengeRecordID = CKRecord.ID(recordName: challenge.recordId!, zoneID: recordZone.zoneID)
        let challengeRecord = CKRecord(recordType: "Challenge", recordID: challengeRecordID)
        // Set challenge record properties
        challengeRecord["startTime"] = challenge.startTime
        challengeRecord["endTime"] = challenge.endTime
        challengeRecord["goalSteps"] = challenge.goalSteps
        challengeRecord["status"] = "Pending"
        challengeRecord["recordId"] = challenge.recordId
        // Add creator to participants
        if let userRecordName = userSettingsManager?.userRecord?.recordID.recordName {
            let creatorReference = CKRecord.Reference(recordID: CKRecord.ID(recordName: userRecordName), action: .none)
            let participantReferences = participants.map { participant -> CKRecord.Reference in
                CKRecord.Reference(recordID: CKRecord.ID(recordName: participant.id), action: .none)
            } + [creatorReference]
            challengeRecord["participants"] = participantReferences
            let share = CKShare(rootRecord: challengeRecord)
            share[CKShare.SystemFieldKey.title] = "Join My Challenge on Strider!"
            share.publicPermission = .readWrite
            
            let operation = CKModifyRecordsOperation(recordsToSave: [challengeRecord, share], recordIDsToDelete: nil)
            self.cloudKitContainer.privateCloudDatabase.add(operation)
            return try await waitForShareOperation(operation, withShare: share)
        } else {
            throw ManagerError.invalidUser
        }
    }
    
    func updateChallengeWithShareRecordID(_ challengeID: String, shareRecordID: String) {
        guard let context = self.context else { return }
        let fetchRequest: NSFetchRequest<Challenge> = Challenge.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "recordId == %@", challengeID)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let challengeToUpdate = results.first {
                challengeToUpdate.shareRecordID = shareRecordID
                saveContext()
            }
        } catch {
            print("Updating Challenge with shareRecordID failed: \(error)")
        }
    }
    
    func loadPendingChallenges() -> [PendingChallenge] {
        guard let context = self.context else { return [] }
        let fetchRequest: NSFetchRequest<Challenge> = Challenge.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "status == %@ AND shareRecordID != NIL", "Pending")

        var loadedPendingChallenges = [PendingChallenge]()

        do {
            let results = try context.fetch(fetchRequest)
            for challenge in results {
                guard let shareRecordID = challenge.shareRecordID, let recordId = challenge.recordId else { continue }
                let details = ChallengeDetails(
                    id: recordId,
                    startTime: challenge.startTime ?? Date(),
                    endTime: challenge.endTime ?? Date(),
                    goalSteps: challenge.goalSteps,
                    status: challenge.status ?? "Pending",
                    participants: [],
                    recordId: recordId
                )
                let pendingChallenge = PendingChallenge(
                    id: recordId,
                    challengeDetails: details,
                    shareRecordID: shareRecordID
                )
                loadedPendingChallenges.append(pendingChallenge)
            }
        } catch {
            print("Failed to load pending challenges: \(error)")
        }

        return loadedPendingChallenges
    }


    
    func fetchShareFromRecordID(_ recordIDString: String) async throws -> CKShare? {
        let recordID = CKRecord.ID(recordName: recordIDString, zoneID: recordZone.zoneID)
 
        let database = cloudKitContainer.privateCloudDatabase

        do {
            let record = try await database.record(for: recordID)
            
            // Directly attempt to cast the fetched record as CKShare
            guard let shareRecord = record as? CKShare else {
                print("Record fetched is not a CKShare")
                return nil
            }

            return shareRecord
        } catch {
            print("Error fetching share from CloudKit: \(error)")
            throw error
        }
    }
    
    func waitForShareOperation(_ operation: CKModifyRecordsOperation, withShare share: CKShare) async throws -> (CKShare?, URL?) {
        return try await withCheckedThrowingContinuation { continuation in
            operation.modifyRecordsResultBlock = { result in
                    switch result {
                    case .success():
                        //TODO: set loading view during create
                        //self.state = .loaded
                        self.cloudKitContainer.privateCloudDatabase.fetch(withRecordID: share.recordID) { (record, error) in
                                          if let error = error {
                                              continuation.resume(throwing: error)
                                              return
                                          }

                                          guard let updatedShare = record as? CKShare, let shareURL = updatedShare.url else {
                                              continuation.resume(throwing: ManagerError.sharingFailed)
                                              return
                                          }
                                          
                                          continuation.resume(returning: (updatedShare, shareURL))
                                      }
                    case .failure(let error):
                        self.state = .error(error)
                        continuation.resume(throwing: error)
                    }
                }
        }
    }
    
    func createChallenge(with details: ChallengeDetails, creator: User) async throws -> (CKShare?, URL?) {
        guard let challenge = try await saveChallengeToCoreData(with: details, creator: creator) else {
            throw ManagerError.challengeCreationFailed
        }
        let (share, shareURL) = try await shareChallenge(challenge, withParticipants: details.participants, creator: creator)
        self.updateChallengeWithShareRecordID(challenge.recordId!, shareRecordID: (share?.recordID.recordName)!)
        return (share, shareURL)
    }
    
    func deleteExpiredChallengeRecords() async {

        let predicate = NSPredicate(format: "expirationDate <= %@", NSDate())
        let query = CKQuery(recordType: "Challenge", predicate: predicate)
        
        do {
            
            let results = try await cloudKitContainer.privateCloudDatabase.perform(query, inZoneWith: nil)
            for record in results {
                _ = try await cloudKitContainer.privateCloudDatabase.deleteRecord(withID: record.recordID)
            }
            print("Expired challenge records deleted successfully.")
        } catch {
            print("Error deleting expired challenge records: \(error)")
        }
    }
    
        func addCurrentUserToChallengeIfPossible(challengeDetails: ChallengeDetails) async -> Bool {
            do {
                let challengeRecord = try await fetchChallengeRecord(challengeID: challengeDetails.id)
                
                // Extract participant references from the challenge record
                var participantReferences = challengeRecord["participants"] as? [CKRecord.Reference] ?? []
                
                // Check if adding another participant exceeds the maximum limit
                if participantReferences.count >= 2 {
                    // Maximum participants reached, cannot add more
                    return false
                }
                
                // Add the current user as a participant
                let currentUserReference = CKRecord.Reference(recordID: CKRecord.ID(recordName: (userSettingsManager!.userRecord?.recordID.recordName)!), action: .none)
                    participantReferences.append(currentUserReference)
                    challengeRecord["participants"] = participantReferences
                    
                    // Set the challenge status to active
                    challengeRecord["status"] = "Active"
                    
                    // Save the updated challenge record
                    _ = try await cloudKitContainer.sharedCloudDatabase.save(challengeRecord)
                    
                    // Update local challenge details with the new state
                    // Crucial to ensure local app state reflects changes
                    var updatedChallengeDetails = challengeDetails
                    updatedChallengeDetails.participants = await fetchAndConvertParticipants(references: participantReferences)
                    updatedChallengeDetails.status = "Active"
                    return true
            } catch {
                print("Error adding current user to challenge: \(error)")
                return false
            }
        }

      
      // MARK: Share Handling
      
      func acceptShareAndFetchChallenge(metadata: CKShare.Metadata) async throws -> ChallengeDetails? {
          do {
              let _ = try await cloudKitContainer.accept(metadata)
              let sharedRecordID = metadata.rootRecordID
              let record = try await cloudKitContainer.sharedCloudDatabase.record(for: sharedRecordID)
              return await convertToChallengeDetails(record: record)
          } catch {
              print("Error handling incoming share: \(error)")
              throw error
          }
      }
    
    func declineChallenge(challengeID: String) async {
        do {
            // Fetch the challenge record
            let recordID = CKRecord.ID(recordName: challengeID)
            let challengeRecord = try await cloudKitContainer.sharedCloudDatabase.record(for: recordID)
            
            // Update the status to "Denied"
            //Deciding if creator should see a denied alert. may not be necessary
//            challengeRecord["status"] = "Denied"
            // Save the updated record
            _ = try await cloudKitContainer.sharedCloudDatabase.save(challengeRecord)
            
            // Optionally, delete the record if necessary
            self.deleteChallengeFromCoreData(challengeID: challengeID)
            await self.challengeUpdates.append(self.convertToChallengeDetails(record: challengeRecord)!)
            
        } catch {
            print("Error declining challenge: \(error)")
        }
    }
    
    func cancelChallenge(challenge: PendingChallenge) async {
        do {
            // Delete the corresponding entity from CoreData.
            deleteChallengeFromCoreData(challengeID: challenge.id)
            
            // Delete the share associated with the challenge.
            let shareRecordID = challenge.shareRecordID
            try await deleteShareRecordAsync(shareRecordID: shareRecordID)
            
        } catch {
            print("Error cancelling challenge: \(error)")
        }
    }

    func deleteChallengeFromCoreData(challengeID: String) {
        let fetchRequest: NSFetchRequest<Challenge> = Challenge.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "recordId == %@", challengeID)
        
        do {
            let results = try context?.fetch(fetchRequest)
            if let challengeToDelete = results?.first {
                context?.delete(challengeToDelete)
                saveContext()
            }
        } catch {
            print("Error deleting challenge from CoreData: \(error)")
        }
    }
    
    func deleteShareRecordAsync(shareRecordID: String) async throws {
        let database = cloudKitContainer.privateCloudDatabase
        if let record = try await fetchShareFromRecordID(shareRecordID) {
            return try await withCheckedThrowingContinuation { continuation in
                database.delete(withRecordID: record.recordID) { recordID, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            }
        }
    }

    func convertToChallengeDetails(record: CKRecord) async -> ChallengeDetails? {
        guard let startTime = record["startTime"] as? Date,
              let endTime = record["endTime"] as? Date,
              let goalSteps = record["goalSteps"] as? Int32,
              let status = record["status"] as? String,
              let participantReferences = record["participants"] as? [CKRecord.Reference] else {
            return nil
        }

        let participants = await fetchAndConvertParticipants(references: participantReferences)
        let recordId = record.recordID.recordName
        
        return ChallengeDetails(
            id: recordId, startTime: startTime,
            endTime: endTime,
            goalSteps: goalSteps,
            status: status,
            participants: participants,
            recordId: recordId
        )
    }

    func fetchAndConvertParticipants(references: [CKRecord.Reference]) async -> [Participant] {
        var participants = [Participant]()
        for reference in references {
            do {
                let record = try await fetchParticipantRecord(reference.recordID)
                if let participant = Participant.fromCKRecord(record) {
                    participants.append(participant)
                }
            } catch {
                print("Failed to fetch participant record: \(error)")
            }
        }
        return participants
    }

    private func fetchParticipantRecord(_ recordID: CKRecord.ID) async throws -> CKRecord {
        do {
            let record = try await cloudKitContainer.privateCloudDatabase.record(for: recordID)
            return record
        } catch {
            let record = try await cloudKitContainer.sharedCloudDatabase.record(for: recordID)
            return record
        }
    }

    
    func createZoneIfNeeded() async throws {
        guard !UserDefaults.standard.bool(forKey: "isChallengeZoneCreated") else { 
            
            return }
        
        do {
            let zone = CKRecordZone(zoneID: recordZone.zoneID)
            _ = try await cloudKitContainer.privateCloudDatabase.save(zone)
            UserDefaults.standard.setValue(true, forKey: "isChallengeZoneCreated")
        } catch {
            print("ERROR: Failed to create custom zone: \(error.localizedDescription)")
            throw error
        }
    }
    
    func fetchChallengeRecord(challengeID: String) async throws -> CKRecord {
        let recordID = CKRecord.ID(recordName: challengeID)
        // Attempt to fetch from the private database first
        do {
            let record = try await cloudKitContainer.privateCloudDatabase.record(for: recordID)
            return record
        } catch {
            // If not found in private, attempt to fetch from shared
            let record = try await cloudKitContainer.sharedCloudDatabase.record(for: recordID)
            return record
        }
    }

    
    
    // MARK: Updates and Notifications
    
    private func setupChallengeSubscription() {
          let subscriptionID = "challenge-updates"
          // Check if already subscribed
          cloudKitContainer.sharedCloudDatabase.fetch(withSubscriptionID: subscriptionID) { subscription, error in
              if let error = error as? CKError, error.code == .unknownItem {
                  self.createChallengeUpdatesSubscription(subscriptionID: subscriptionID)
              } // If subscription exists or another error occurs, do nothing.
          }
      }

      private func createChallengeUpdatesSubscription(subscriptionID: String) {
          let predicate = NSPredicate(value: true)
          let subscription = CKQuerySubscription(recordType: "Challenge", predicate: predicate, options: [.firesOnRecordCreation, .firesOnRecordUpdate])
          let notificationInfo = CKSubscription.NotificationInfo()
          notificationInfo.alertBody = "A challenge has been updated."
          notificationInfo.shouldBadge = true
          subscription.notificationInfo = notificationInfo
          cloudKitContainer.sharedCloudDatabase.save(subscription) { _, error in
              if let error = error {
                  print("Subscription failed: \(error.localizedDescription)")
                  // Handle error
              } else {
                  print("Subscription setup successfully.")
                  // Perform any setup needed after successful subscription creation
              }
          }
      }
    
    func handleNotification(_ notification: CKQueryNotification) async {
        guard let recordID = notification.recordID else {
            print("Notification does not contain a recordID.")
            return
        }
        
        do {
            let record = try await cloudKitContainer.sharedCloudDatabase.record(for: recordID)
            if let updatedChallengeDetails = await convertToChallengeDetails(record: record) {
                await processChallengeUpdate(with: updatedChallengeDetails)
            }
        } catch {
            print("Failed to fetch record: \(error)")
        }
    }
    
    func processChallengeUpdate(with newDetails: ChallengeDetails) async {
        await MainActor.run {
            // Attempt to find an existing challenge to update
            if let index = self.challengeUpdates.firstIndex(where: { $0.recordId == newDetails.recordId }) {
                let currentDetails = self.challengeUpdates[index]

                // If there's a significant status change or participant update...
                if currentDetails.status != newDetails.status || currentDetails.participants != newDetails.participants {
                    // Perform the check and possible update on a new task
                    Task {
                        await self.handleUpdatesForChallenge(newDetails: newDetails, currentDetails: currentDetails)
                    }
                }

                // Always update the local array with the new details
                self.challengeUpdates[index] = newDetails
            } else {
                // New challenge received
                self.challengeUpdates.append(newDetails)
                AppState.shared.currentChallengeState = .invitation(newDetails)
            }
        }
    }

    // Handle the asynchronous logic separately
    private func handleUpdatesForChallenge(newDetails: ChallengeDetails, currentDetails: ChallengeDetails) async {
        if currentDetails.status != newDetails.status {
            // Significant status change
            handleStatusChange(from: currentDetails, to: newDetails)
        } else if currentDetails.participants != newDetails.participants {
            // Steps might have been updated; check for goal achievement.
            await checkForStepGoalAchievement(challengeID: newDetails.id)
        }
    }

    func handleStatusChange(from currentDetails: ChallengeDetails, to newDetails: ChallengeDetails) {
        switch newDetails.status {
        case "Active" where currentDetails.status == "Pending":
            AppState.shared.challengeAccepted(challengeDetails: newDetails)
        case "Completed":
            AppState.shared.challengeCompleted(challengeDetails: newDetails)
        case "Denied":
            AppState.shared.challengeDenied(challengeDetails: newDetails)
        default:
            break // No significant change detected.
        }
    }



    
    // MARK: Game Logic
    
    func addParticipantToChallenge(challengeID: String, participantID: String) async {
        do {
            let challengeRecord = try await fetchChallengeRecord(challengeID: challengeID)
            var participantReferences = challengeRecord["participants"] as? [CKRecord.Reference] ?? []
            let newParticipantRef = CKRecord.Reference(recordID: CKRecord.ID(recordName: participantID), action: .none)
            participantReferences.append(newParticipantRef)
            challengeRecord["participants"] = participantReferences
            challengeRecord["status"] = "Active" // Mark as active
            
            _ = try await cloudKitContainer.sharedCloudDatabase.save(challengeRecord)
        

            await AppState.shared.participantAdded(challengeDetails: convertToChallengeDetails(record: challengeRecord)!)
            
        } catch {
            print("Error adding participant to challenge: \(error)")
        }
    }
    
    func checkForStepGoalAchievement(challengeID: String) async {
        do {
            let challengeRecord = try await fetchChallengeRecord(challengeID: challengeID)
            guard let stepGoal = challengeRecord["goalSteps"] as? Int else { return }

            // Fetch participants and their steps
            let participants = await fetchAndConvertParticipants(references: (challengeRecord["participants"] as? [CKRecord.Reference])!)
            let winner = participants.max(by: { $0.steps < $1.steps })
            
            // Check if the step goal is achieved
            if let winner = winner, winner.steps >= stepGoal {
            // Update challenge record with the winner and mark as done
            await updateChallengeRecordWithWinner(challengeRecord: challengeRecord, winner: winner)
            await AppState.shared.challengeCompleted(challengeDetails: convertToChallengeDetails(record: challengeRecord)!)
                
            }
        } catch {
            print("Error checking for step goal achievement: \(error)")
        }
    }
    
    func updateChallengeRecordWithWinner(challengeRecord: CKRecord, winner: Participant) async {
        challengeRecord["winner"] = CKRecord.Reference(recordID: CKRecord.ID(recordName: winner.id), action: .none)
        challengeRecord["status"] = "Completed"
        do {
            _ = try await cloudKitContainer.privateCloudDatabase.save(challengeRecord)
        } catch {
            print("Error updating challenge with winner: \(error)")
        }
    }


    
    func updateParticipantSteps(participantID: String, newSteps: Int, inChallenge challengeID: String) async throws {
        // Fetch the challenge record to determine the correct database
        let record = try await fetchChallengeRecord(challengeID: challengeID)
        
        guard let participantReferences = record["participants"] as? [CKRecord.Reference] else {
            throw ManagerError.invalidRecord
        }
        
        // Find the participant reference matching `participantID`
        if let participantRef = participantReferences.first(where: { $0.recordID.recordName == participantID }) {
            // Fetch the participant record
            let participantRecord = try await cloudKitContainer.sharedCloudDatabase.record(for: participantRef.recordID)
            
            // Update steps in the participant record
            participantRecord["steps"] = newSteps
            
            // Save the updated participant record back to CloudKit
            _ = try await cloudKitContainer.sharedCloudDatabase.save(participantRecord)
        } else {
            throw ManagerError.invalidRecord
        }
    }

    
    
}
