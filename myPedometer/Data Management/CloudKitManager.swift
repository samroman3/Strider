//
//  CloudKitManager.swift
//  myPedometer
//
//  Created by Sam Roman on 3/16/24.
//

import Foundation
import CloudKit
import CoreData

class CloudKitManager: ObservableObject {
    
    static let shared = CloudKitManager()

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
    }
    
    @Published private(set) var state: State = .idle
    
    private var cloudKitContainer: CKContainer
    private var context: NSManagedObjectContext
    let recordZone = CKRecordZone(zoneName: "Challenges")
    
    @Published var challengeUpdates: [ChallengeDetails] = []
    
    init() {
        self.cloudKitContainer = CKContainer(identifier: "iCloud.com.samuelroman.strider")
        self.context = PersistenceController.shared.container.viewContext
        setupChallengeSubscription()
    }
    
    
    // MARK: Challenge Management
    
    func createChallenge(with details: ChallengeDetails, creator: Participant) async throws -> (CKRecord, CKShare) {
           state = .loading
           let challengeRecord = CKRecord(recordType: "Challenge", recordID: CKRecord.ID(recordName: details.recordId))
           // Set challenge record properties
           challengeRecord["startTime"] = details.startTime
           challengeRecord["endTime"] = details.endTime
           challengeRecord["goalSteps"] = details.goalSteps
           challengeRecord["status"] = details.status
           // Add creator to participants
           let creatorReference = CKRecord.Reference(recordID: CKRecord.ID(recordName: creator.id), action: .none)
           let participantReferences = details.participants.map { participant -> CKRecord.Reference in
               CKRecord.Reference(recordID: CKRecord.ID(recordName: participant.id), action: .none)
           } + [creatorReference]
           challengeRecord["participants"] = participantReferences
           // Prepare and save the CKShare
           let share = CKShare(rootRecord: challengeRecord)
           share[CKShare.SystemFieldKey.title] = "Join My Challenge"
           share.publicPermission = .readWrite
        let operation = CKModifyRecordsOperation(recordsToSave: [challengeRecord, share], recordIDsToDelete: nil)
           
           // Using async-await with continuation
        return try await withCheckedThrowingContinuation { continuation in
               operation.modifyRecordsResultBlock = { result in
                   DispatchQueue.main.async {
                       switch result {
                       case .success(_):
                           self.state = .loaded
                           continuation.resume(returning: (challengeRecord, share))
                       case .failure(let error):
                           self.state = .error(error)
                           continuation.resume(throwing: error)
                       }
                   }
               }
               
               self.cloudKitContainer.privateCloudDatabase.add(operation)
           }
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
    
    private func setupChallengeSubscription() {
          let subscriptionID = "challenge-updates"
          // Check if already subscribed
          cloudKitContainer.privateCloudDatabase.fetch(withSubscriptionID: subscriptionID) { subscription, error in
              if let error = error as? CKError, error.code == .unknownItem {
                  self.createChallengeUpdatesSubscription(subscriptionID: subscriptionID)
              } // If subscription exists or another error occurs, do nothing.
          }
      }

      private func createChallengeUpdatesSubscription(subscriptionID: String) {
          let predicate = NSPredicate(value: true) // Adjust according to your needs
          let subscription = CKQuerySubscription(recordType: "Challenge", predicate: predicate, options: [.firesOnRecordCreation, .firesOnRecordUpdate])
          let notificationInfo = CKSubscription.NotificationInfo()
          notificationInfo.alertBody = "A challenge has been updated."
          notificationInfo.shouldBadge = true
          subscription.notificationInfo = notificationInfo
          cloudKitContainer.privateCloudDatabase.save(subscription) { _, error in
              if let error = error {
                  print("Subscription failed: \(error.localizedDescription)")
                  // Handle error
              } else {
                  print("Subscription setup successfully.")
                  // Perform any setup needed after successful subscription creation
              }
          }
      }
      
      // MARK: Shared Record Handling
      
      func acceptShareAndFetchChallenge(metadata: CKShare.Metadata) async throws -> ChallengeDetails? {
          do {
              let _ = try await cloudKitContainer.accept(metadata)
              let sharedRecordID = metadata.rootRecordID
              let record = try await cloudKitContainer.privateCloudDatabase.record(for: sharedRecordID)
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
            let challengeRecord = try await cloudKitContainer.privateCloudDatabase.record(for: recordID)
            
            // Update the status to "Denied"
            challengeRecord["status"] = "Denied"
            
            // Save the updated record
            _ = try await cloudKitContainer.privateCloudDatabase.save(challengeRecord)
            
            // Optionally, delete the record if necessary
            
            // Notify the ChallengeViewModel of the declined challenge
            
             await self.challengeUpdates.append(self.convertToChallengeDetails(record: challengeRecord)!)
            
        } catch {
            print("Error declining challenge: \(error)")
        }
    }
    
    
    func addUserToChallenge(participant: Participant, to challengeID: String) async throws {
        guard let challengeRecord = try? await cloudKitContainer.privateCloudDatabase.record(for: CKRecord.ID(recordName: challengeID)) else {
            throw ManagerError.invalidRecord
        }
        
        var participantReferences = challengeRecord["participants"] as? [CKRecord.Reference] ?? []
        let newParticipantReference = CKRecord.Reference(recordID: CKRecord.ID(recordName: participant.id), action: .none)
        participantReferences.append(newParticipantReference)
        
        challengeRecord["participants"] = participantReferences
        
        // Update the challenge record with the new participant
        try await cloudKitContainer.privateCloudDatabase.save(challengeRecord)
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
            startTime: startTime,
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
                let record = try await cloudKitContainer.privateCloudDatabase.record(for: reference.recordID)
                if let participant = Participant.fromCKRecord(record) {
                    participants.append(participant)
                }
            } catch {
                print("Failed to fetch participant record: \(error)")
            }
        }
        
        return participants
    }
    
    func createZoneIfNeeded() async throws {
        guard !UserDefaults.standard.bool(forKey: "isChallengeZoneCreated") else { return }
        
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
        return try await cloudKitContainer.privateCloudDatabase.record(for: recordID)
    }
    
    
    
    // MARK: Handling Updates and Notifications
    
    func subscribeToChallengeUpdates() {
        let subscription = CKQuerySubscription(recordType: "Challenge", predicate: NSPredicate(value: true), options: [.firesOnRecordCreation, .firesOnRecordUpdate])
        
        let info = CKSubscription.NotificationInfo()
        info.alertBody = "A challenge has been updated."
        info.shouldBadge = true
        subscription.notificationInfo = info
        
        cloudKitContainer.privateCloudDatabase.save(subscription) { subscription, error in
            if let error = error {
                print("Subscription failed: \(error.localizedDescription)")
            }
        }
    }
    
    func handleNotification(_ notification: CKQueryNotification) async {
        guard let recordID = notification.recordID else {
            print("Notification does not contain a recordID.")
            return
        }
        
        do {
            let record = try await cloudKitContainer.privateCloudDatabase.record(for: recordID)
            // Process the notification
            if let updatedChallengeDetails = await convertToChallengeDetails(record: record) {
                DispatchQueue.main.async {
                    //TODO: Switch for notification - eg. participant step updates / challenge acceptance(participant added) / challenge complete(stepgoal reached or endtime reached) / challenge invite denied
                    AppState.shared.challengeAccepted(challengeDetails: updatedChallengeDetails)
                    // Update sharedChallengeDetails if necessary
                    AppState.shared.sharedChallengeDetails = updatedChallengeDetails
                }
            }
        } catch {
            print("Failed to fetch record: \(error)")
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
            
            _ = try await cloudKitContainer.privateCloudDatabase.save(challengeRecord)
            
            // Notify AppState and ChallengeViewModel

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
            // Notify AppState and ChallengeViewModel
                
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
        // Fetch the challenge record from CloudKit
        let recordID = CKRecord.ID(recordName: challengeID)
        guard let challengeRecord = try? await cloudKitContainer.privateCloudDatabase.record(for: recordID) else {
            throw ManagerError.invalidRecord
        }
        
        guard let participantReferences = challengeRecord["participants"] as? [CKRecord.Reference] else {
            throw ManagerError.invalidRecord
        }
        
        // Find the participant reference matching `participantID`
        if let participantRef = participantReferences.first(where: { $0.recordID.recordName == participantID }) {
            // Fetch the participant record
            let participantRecord = try await cloudKitContainer.privateCloudDatabase.record(for: participantRef.recordID)
            
            // Update steps in the participant record
            participantRecord["steps"] = newSteps
            
            // Save the updated participant record back to CloudKit
            _ = try await cloudKitContainer.privateCloudDatabase.save(participantRecord)
        } else {
            throw ManagerError.invalidRecord
        }
    }
    
    
}
