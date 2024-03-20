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
    
    init() {
        self.cloudKitContainer = CKContainer(identifier: "iCloud.com.example.myPedometer")
        self.context = PersistenceController.shared.container.viewContext
    }
    
    
    // MARK: Challenge Management
    
    func createChallenge(with details: ChallengeDetails, creator: Participant) async throws -> (CKRecord, CKShare) {
        state = .loading
        
        // Create the challenge CKRecord
        let challengeRecord = CKRecord(recordType: "Challenge", recordID: CKRecord.ID(recordName: details.recordId))
        challengeRecord["startTime"] = details.startTime
        challengeRecord["endTime"] = details.endTime
        challengeRecord["goalSteps"] = details.goalSteps
        challengeRecord["active"] = details.active
                
        let creatorReference = CKRecord.Reference(recordID: CKRecord.ID(recordName: creator.id), action: .none)
        var participantReferences = details.participants.map { participant -> CKRecord.Reference in
            return CKRecord.Reference(recordID: CKRecord.ID(recordName: participant.id), action: .none)
        }
        participantReferences.append(creatorReference) // Add the creator as a participant
        challengeRecord["participants"] = participantReferences
        
        // Prepare the CKShare
        let share = CKShare(rootRecord: challengeRecord)
        share[CKShare.SystemFieldKey.title] = "Join My Challenge"
        share.publicPermission = .readWrite
        
        // Save the challenge and share
        let operation = CKModifyRecordsOperation(recordsToSave: [challengeRecord, share], recordIDsToDelete: nil)
        
        return try await withCheckedThrowingContinuation { continuation in
            operation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
                DispatchQueue.main.async {
                    self.state = error == nil ? .loaded : .error(error ?? ManagerError.challengeCreationFailed)
                }
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let savedRecord = savedRecords?.first as? CKRecord, let savedShare = savedRecords?.last as? CKShare {
                    continuation.resume(returning: (savedRecord, savedShare))
                } else {
                    continuation.resume(throwing: ManagerError.challengeCreationFailed)
                }
            }
            self.cloudKitContainer.privateCloudDatabase.add(operation)
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


    func acceptShareAndFetchChallenge(metadata: CKShare.Metadata) async throws -> ChallengeDetails? {
        do {
            // Accept the share
            let _ = try await cloudKitContainer.accept(metadata)
            let sharedRecordID = metadata.rootRecordID
            let record = try await cloudKitContainer.privateCloudDatabase.record(for: sharedRecordID)

            // Convert the record to ChallengeDetails
            return await convertToChallengeDetails(record: record)
        } catch {
            print("Error handling incoming share: \(error)")
            throw error
        }
    }
    
    func handleNotification(_ notification: CKQueryNotification) async {
        guard let recordID = notification.recordID else {
            print("Notification does not contain a recordID.")
            return
        }

        do {
            // Fetch the updated record based on recordID
            let record = try await cloudKitContainer.privateCloudDatabase.record(for: recordID)
            // Optionally, determine the type of update and act accordingly
            // For example, if the challenge's status has changed, fetch updated details
            if let updatedChallengeDetails = await convertToChallengeDetails(record: record) {
                // TODO: Must callback to inform AppState and relevant view models to update their state.
//                print("Updated challenge details fetched: \(updatedChallengeDetails)")
            }
        } catch {
            print("Failed to fetch updated record: \(error)")
        }
    }
    
    func convertToChallengeDetails(record: CKRecord) async -> ChallengeDetails? {
        guard let startTime = record["startTime"] as? Date,
              let endTime = record["endTime"] as? Date,
              let goalSteps = record["goalSteps"] as? Int32,
              let active = record["active"] as? Bool,
              let participantReferences = record["participants"] as? [CKRecord.Reference] else {
            return nil
        }

        let participants = await fetchAndConvertParticipants(references: participantReferences)
        let recordId = record.recordID.recordName
        
        return ChallengeDetails(
            startTime: startTime,
            endTime: endTime,
            goalSteps: goalSteps,
            active: active,
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
