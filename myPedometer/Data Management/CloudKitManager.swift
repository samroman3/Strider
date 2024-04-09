//
//  CloudKitManager.swift
//  myPedometer
//
//  Created by Sam Roman on 3/16/24.
//

import SwiftUI
import CloudKit
import CoreData

final class CloudKitManager: ObservableObject {
    
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
    
   private func saveContext() {
        guard let context = self.context, context.hasChanges else { return }
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    // MARK: Challenge Management
    
   private func saveChallengeToCoreData(with details: ChallengeDetails, creator: User) async throws -> Challenge? {
        let challenge = Challenge(context: context!)
        challenge.startTime = details.startTime
        challenge.endTime = details.endTime
        challenge.goalSteps = details.goalSteps
        challenge.status = details.status
        challenge.recordId = details.recordId
        challenge.creatorUserName = userSettingsManager?.userName
        challenge.creatorPhotoData = userSettingsManager?.photoData
        challenge.creatorRecordID = userSettingsManager?.user?.recordId
        creator.addToChallenges(challenge)
        self.saveContext()
        return challenge
    }
    
    func shareChallenge(_ challenge: Challenge) async throws -> (CKShare?, URL?) {
        
        try await createZoneIfNeeded()
        let challengeRecord = challenge.toCKRecord()
        // Set challenge record properties
        challengeRecord["startTime"] = challenge.startTime
        challengeRecord["endTime"] = challenge.endTime
        challengeRecord["goalSteps"] = challenge.goalSteps
        challengeRecord["status"] = "Pending"
        challengeRecord["recordId"] = challenge.recordId
        challengeRecord["creatorUserName"] = challenge.creatorUserName
        challengeRecord["creatorRecordID"] = challenge.creatorRecordID
    
        if let imageData = challenge.creatorPhotoData {
            // Compress the image to fit within the size constraints
            if let image = UIImage(data: imageData) {
                if let compressedImageData = compressImage(image, targetKB: 200 ) {
                    challengeRecord["creatorPhotoData"] = compressedImageData
                }
            }
        }
        
        _ = try await self.cloudKitContainer.privateCloudDatabase.save(challengeRecord)
                
        let share = CKShare(rootRecord: challengeRecord)
        share[CKShare.SystemFieldKey.title] = "Join My Challenge on Strider!"
        share.publicPermission = .readWrite
            
        let operation = CKModifyRecordsOperation(recordsToSave: [challengeRecord, share], recordIDsToDelete: nil)
        self.cloudKitContainer.privateCloudDatabase.add(operation)
        return try await waitForShareOperation(operation, withShare: share)

    }
    
    // Method to compress the image data to fit within a specific byte size limit
   private func compressImage(_ image: UIImage, targetKB: Int) -> Data? {
        var compression: CGFloat = 1.0
        var imageData = image.jpegData(compressionQuality: compression)
        while let data = imageData, data.count > targetKB * 1024 && compression > 0 {
            compression -= 0.05 // Decrease compression in small steps
            imageData = image.jpegData(compressionQuality: compression)
        }
        return imageData
    }
    
    private func updateChallengeWithShareRecordID(_ challengeID: String, shareRecordID: String) async throws  {
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
            throw error
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
    
    private func waitForShareOperation(_ operation: CKModifyRecordsOperation, withShare share: CKShare) async throws -> (CKShare?, URL?) {
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
        let (share, shareURL) = try await shareChallenge(challenge)
        guard share == share, shareURL == shareURL else { throw ManagerError.sharingFailed }
        try await self.updateChallengeWithShareRecordID(challenge.recordId!, shareRecordID: (share!.recordID.recordName))
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
    
    func addCurrentUserToChallenge(challengeDetails: ChallengeDetails, record: CKRecord) async -> Bool {
        do {
            if challengeDetails.participants.count < 2 {
                record["participantRecordID"] = userSettingsManager?.user?.recordId
                record["participantUserName"] = userSettingsManager?.userName
                
                if let imageData = userSettingsManager?.user?.photoData {
                    // Compress the image to fit within the size constraints
                    if let image = UIImage(data: imageData) {
                        if let compressedImageData = compressImage(image, targetKB: 200 ) {
                            record["participantPhotoData"] = compressedImageData
                        }
                    }
                }
                // Set the challenge status to active
                record["status"] = "Active"

                // Save the updated challenge record
                _ = try await cloudKitContainer.sharedCloudDatabase.save(record)
                return true
            } else {
                return false // Maximum number of participants reached.
            }
        } catch {
            print("Error adding current user to challenge: \(error)")
            return false
        }
    }


      
      // MARK: Share Handling
      
      func acceptShareAndFetchChallenge(metadata: CKShare.Metadata) async throws -> (ChallengeDetails?, CKRecord?)? {
          do {
              let _ = try await cloudKitContainer.accept(metadata)
              let sharedRecordID = metadata.rootRecordID
              let record = try await cloudKitContainer.sharedCloudDatabase.record(for: sharedRecordID)
              return await (convertToChallengeDetails(record: record), record)
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
              let creatorUserName = record["creatorUserName"] as? String,
              let creatorRecordID = record["creatorRecordID"] as? String
        else {
            return nil
        }
        let creatorPhotoData = record["creatorPhotoData"] as? Data
        
        let creatorSteps = record["creatorSteps"] as? Int32
        
        let participants = [ParticipantDetails(id: creatorRecordID, userName: creatorUserName, photoData: creatorPhotoData, steps: Int(creatorSteps ?? 0))]
        let recordId = record.recordID.recordName
        
        return ChallengeDetails(
            id: recordId, startTime: startTime,
            endTime: endTime,
            goalSteps: goalSteps,
            status: status,
            participants: participants ,
            recordId: recordId
        )
    }

    
  private func createZoneIfNeeded() async throws {
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
    
   private func processChallengeUpdate(with newDetails: ChallengeDetails) async {
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
//            await checkForStepGoalAchievement(challengeID: newDetails.id)
        }
    }

    private func handleStatusChange(from currentDetails: ChallengeDetails, to newDetails: ChallengeDetails) {
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

    func updateSteps(forChallenge challengeID: String, newSteps: Int, isCreator: Bool) async throws {
        let recordID = CKRecord.ID(recordName: challengeID)
        let challengeRecord = try await cloudKitContainer.sharedCloudDatabase.record(for: recordID)
           if isCreator {
               challengeRecord["creatorSteps"] = newSteps
           } else {
               challengeRecord["participantSteps"] = newSteps
           }
           // Check if the step goal is achieved
           let stepGoal = challengeRecord["goalSteps"] as? Int ?? 0
           let creatorSteps = challengeRecord["creatorSteps"] as? Int ?? 0
           let participantSteps = challengeRecord["participantSteps"] as? Int ?? 0
           
           if creatorSteps >= stepGoal || participantSteps >= stepGoal {
               // Declare a winner based on who achieved the goal
               let winnerIsCreator = creatorSteps >= participantSteps
               challengeRecord["winner"] = winnerIsCreator ? challengeRecord["creatorRecordID"] : challengeRecord["participantRecordID"]
               challengeRecord["status"] = "Completed"
               try await notifyChallengeCompletion(challengeID: challengeID, winnerIsCreator: winnerIsCreator)
           }
           
           // Save the updated challenge record
           _ = try await cloudKitContainer.privateCloudDatabase.save(challengeRecord)
       }
    
    private func notifyChallengeCompletion(challengeID: String, winnerIsCreator: Bool) async throws {
        let recordID = CKRecord.ID(recordName: challengeID)
        let challengeRecord = try await cloudKitContainer.sharedCloudDatabase.record(for: recordID)
           if winnerIsCreator {
               print("Creator wins")
           } else {
               print("Participant wins")
           }
        if let challengeDetails = await convertToChallengeDetails(record: challengeRecord) {
            AppState.shared.challengeCompleted(challengeDetails: challengeDetails)
        }
       }

}
