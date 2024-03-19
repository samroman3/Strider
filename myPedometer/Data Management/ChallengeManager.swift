//
//  ChallengeManager.swift
//  myPedometer
//
//  Created by Sam Roman on 3/16/24.
//

import Foundation
import CloudKit
import CoreData

class ChallengeManager: ObservableObject {
    
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
    
    func createChallenge(with details: ChallengeDetails) async throws -> (CKRecord, CKShare) {
        state = .loading
        
        // Create the challenge CKRecord
        let challengeRecord = CKRecord(recordType: "Challenge", recordID: CKRecord.ID(recordName: details.recordId))
        challengeRecord["startTime"] = details.startTime
        challengeRecord["endTime"] = details.endTime
        challengeRecord["goalSteps"] = details.goalSteps
        challengeRecord["active"] = details.active
        
        // Create participants references
        let participantReferences = details.participants.map { participant -> CKRecord.Reference in
            return CKRecord.Reference(recordID: CKRecord.ID(recordName: participant.id), action: .none)
        }
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
    
    func handleIncomingShare(metadata: CKShare.Metadata) async {
        // Handle accepting an incoming share
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
        
        // Assuming 'participants' is stored as an array of references in the challenge record,
        // and you have a way to fetch participant records by their IDs to update them.
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
            throw ManagerError.invalidRecord // Or a more specific error if needed
        }
    }
}
