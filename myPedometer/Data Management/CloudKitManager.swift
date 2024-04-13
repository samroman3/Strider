//
//  CloudKitManager.swift
//  myPedometer
//
//  Created by Sam Roman on 3/16/24.
//

import SwiftUI
import CloudKit
import CoreData
import Combine

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
    
    var challengeUpdatesPublisher = PassthroughSubject<ChallengeDetails, Never>()

    
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
    
   private func saveOwnedChallengeToCoreData(with details: ChallengeDetails, creator: User) async throws -> Challenge? {
        let challenge = Challenge(context: context!)
        challenge.startTime = details.startTime
        challenge.endTime = details.endTime
        challenge.goalSteps = details.goalSteps
        challenge.status = details.status
        challenge.recordId = details.recordId
        challenge.creatorUserName = userSettingsManager?.userName
        challenge.creatorPhotoData = userSettingsManager?.photoData
        challenge.creatorRecordID = userSettingsManager?.user?.recordId
       challenge.creatorSteps = 0
        creator.addToChallenges(challenge)
        self.saveContext()
        return challenge
    }
    
    private func saveSharedChallengeToCoreData(with details: ChallengeDetails) async throws -> Challenge? {
         print("Challenge accepted and saved: \(details)")
         let challenge = Challenge(context: context!)
         challenge.startTime = details.startTime
         challenge.endTime = details.endTime
         challenge.goalSteps = details.goalSteps
         challenge.status = "Active"
         challenge.recordId = details.recordId
         challenge.creatorUserName = details.creatorUserName
         challenge.creatorPhotoData = details.creatorPhotoData
         challenge.creatorRecordID = details.creatorRecordID
         challenge.creatorSteps = 0
         challenge.participantSteps = 0
         challenge.participantRecordID = userSettingsManager?.user?.recordId
         challenge.participantUserName = userSettingsManager?.userName
         challenge.participantPhotoData = userSettingsManager?.photoData
         challenge.winner = ""
         self.userSettingsManager?.user?.addToChallenges(challenge)
         self.saveContext()
         return challenge
     }
     

    
    func shareChallenge(_ challenge: Challenge) async throws -> (CKShare?, URL?) {
        
        try await createZoneIfNeeded()
        let challengeRecord = challenge.toCKRecord(zone: self.recordZone)
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
                if let compressedImageData = compressImage(image, targetKB: 50 ) {
                    challengeRecord["creatorPhotoData"] = compressedImageData
                }
            }
        }
        
        _ = try await self.cloudKitContainer.privateCloudDatabase.save(challengeRecord)
                
        let share = CKShare(rootRecord: challengeRecord)
        share[CKShare.SystemFieldKey.title] = "Join My Challenge on Strider!"
        share.publicPermission = .readWrite
        challengeRecord["recordId"] = share.recordID.recordName
        challengeRecord["zoneID"] = share.recordID.zoneID.zoneName
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
                    recordId: recordId,
                    creatorUserName: challenge.creatorUserName,
                    creatorPhotoData: challenge.creatorPhotoData,
                    creatorSteps: 0,
                    participantUserName: "",
                    participantPhotoData: nil,
                    participantSteps: 0
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

    func fetchActiveChallenges() async throws -> [ChallengeDetails] {
        //Check for expired records
        let _ = await deleteExpiredChallengeRecords()
        let _ = try await createZoneIfNeeded()
        let predicate = NSPredicate(format: "status == %@", "Active")
        let query = CKQuery(recordType: "Challenge", predicate: predicate)
        let results = try await cloudKitContainer.privateCloudDatabase.records(matching: query, inZoneWith: self.recordZone.zoneID)
        var challenges = [ChallengeDetails]()
        for record in results {
                if let challengeDetail = convertToChallengeDetails(record: record) {
                    challenges.append(challengeDetail)
                }
        }
        let shared = try await fetchSharedChallenges()
        challenges.append(contentsOf: shared)
        return challenges
    }
    
    private func fetchSharedChallengeRecordsFromCoreData() -> [Challenge] {
        let fetchRequest: NSFetchRequest<Challenge> = Challenge.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "status == %@", "Active")
           do {
               if let context = context {
                   return try context.fetch(fetchRequest)
               }
           } catch {
               print("Error fetching from CoreData: \(error)")
               return []
           }
        return []
       }
    
    func fetchSharedChallenges() async throws -> [ChallengeDetails] {
        // First fetch all available zones in the shared database to know where to look for records
        let zones = try await fetchAllRecordZonesFromSharedDatabase()
        var challenges = [ChallengeDetails]()
        
        // Iterate over each zone and fetch challenges
        for zone in zones {
            let records = try await fetchRecordsFrom(zone: zone.zoneID)
            let details = records.compactMap { convertToChallengeDetails(record: $0) }
            challenges.append(contentsOf: details)
        }
        
        return challenges
    }

    private func fetchAllRecordZonesFromSharedDatabase() async throws -> [CKRecordZone] {
        return try await withCheckedThrowingContinuation { continuation in
            CKContainer.default().sharedCloudDatabase.fetchAllRecordZones { (zones, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let zones = zones {
                    continuation.resume(returning: zones)
                } else {
                    continuation.resume(throwing: NSError(domain: "CustomError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown error fetching record zones"]))
                }
            }
        }
    }

    private func fetchRecordsFrom(zone zoneID: CKRecordZone.ID) async throws -> [CKRecord] {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Challenge", predicate: predicate)
        return try await withCheckedThrowingContinuation { continuation in
            CKContainer.default().sharedCloudDatabase.perform(query, inZoneWith: zoneID) { (records, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let records = records {
                    continuation.resume(returning: records)
                } else {
                    continuation.resume(throwing: NSError(domain: "CustomError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown error fetching records"]))
                }
            }
        }
    }
    
    func fetchActiveChallengeRecords() async throws -> [CKRecord] {
        let predicate = NSPredicate(format: "status == %@", "Active")
        let query = CKQuery(recordType: "Challenge", predicate: predicate)
        
        let results = try await cloudKitContainer.privateCloudDatabase.records(matching: query, inZoneWith: self.recordZone.zoneID)
        
        return results
    }
    

    func updateAllActiveChallenges(newSteps: Int) async {
//        do {
//            let activeChallenges = try await fetchActiveChallengeRecords()
//            for challenge in activeChallenges {
//                let participantID = userSettingsManager?.user?.recordId ?? ""
//                let isCreator = (challenge["creatorRecordID"] == participantID)
//                
//                try await updateSteps(forChallenge: challenge.recordID.recordName, newSteps: newSteps, isCreator: isCreator)
//            }
//        } catch {
//            print("Error updating active challenges: \(error)")
//        }
    }
    
    func updateSteps(forChallenge challengeID: String, newSteps: Int, isCreator: Bool) async throws {
        let recordID = CKRecord.ID(recordName: challengeID, zoneID: self.recordZone.zoneID)
        let database = isCreator ? cloudKitContainer.privateCloudDatabase : cloudKitContainer.sharedCloudDatabase
        let challengeRecord = try await database.record(for: recordID)

        if isCreator {
            challengeRecord["creatorSteps"] = newSteps
        } else {
            challengeRecord["participantSteps"] = newSteps
        }

        // Check goal achievement
        let stepGoal = challengeRecord["goalSteps"] as? Int ?? 0
        if let creatorSteps = challengeRecord["creatorSteps"] as? Int, let participantSteps = challengeRecord["participantSteps"] as? Int,
           creatorSteps >= stepGoal || participantSteps >= stepGoal {
            challengeRecord["winner"] = (creatorSteps >= participantSteps) ? challengeRecord["creatorRecordID"] : challengeRecord["participantRecordID"]
            challengeRecord["status"] = "Completed"
        }

        _ = try await database.save(challengeRecord)
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
        guard let challenge = try await saveOwnedChallengeToCoreData(with: details, creator: creator) else {
            throw ManagerError.challengeCreationFailed
        }
        let (share, shareURL) = try await shareChallenge(challenge)
        guard share == share, shareURL == shareURL else { throw ManagerError.sharingFailed }
        try await self.updateChallengeWithShareRecordID(challenge.recordId!, shareRecordID: (share!.recordID.recordName))
        return (share, shareURL)
    }
    
    func deleteExpiredChallengeRecords() async {

        let predicate = NSPredicate(format: "endTime <= %@", NSDate())
        let query = CKQuery(recordType: "Challenge", predicate: predicate)
        //TODO: check if saved to coredata and set to "completed" before deletion
        //alert user challenge has ended and set winner
        do {
            //delete shared records
            let shared = try await fetchSharedChallenges()
            for record in shared {
                if record.endTime < Date(){
                    deleteChallengeFromCoreData(challengeID: record.recordId)
                }
            }
            //delete expired owned records
            let owned = try await cloudKitContainer.privateCloudDatabase.perform(query, inZoneWith: self.recordZone.zoneID)
            for record in owned {
                deleteChallengeFromCoreData(challengeID: record.recordID.recordName)
                
                _ = try await cloudKitContainer.privateCloudDatabase.deleteRecord(withID: record.recordID)
            }
            print("Expired challenge records deleted successfully.")
        } catch {
            print("Error deleting expired challenge records: \(error)")
        }
    }
    
    func addCurrentUserToChallenge(challengeDetails: ChallengeDetails, record: CKRecord) async -> Bool {
        do {
            if challengeDetails.participantUserName == nil || challengeDetails.participantRecordID == nil {
                record["participantRecordID"] = userSettingsManager?.user?.recordId
                record["participantUserName"] = userSettingsManager?.userName
                
                if let imageData = userSettingsManager?.user?.photoData {
                    // Compress the image to fit within the size constraints
                    if let image = UIImage(data: imageData) {
                        if let compressedImageData = compressImage(image, targetKB: 50 ) {
                            record["participantPhotoData"] = compressedImageData
                        }
                    }
                }
                // Set the challenge status to active
                record["status"] = "Active"
                
                // Save the updated challenge record
                _ = try await cloudKitContainer.sharedCloudDatabase.save(record)
                //Save shared record to CoreData
                _ = try await self.saveSharedChallengeToCoreData(with: challengeDetails)
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
              return (convertToChallengeDetails(record: record), record)
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

        } catch {
            print("Error declining challenge: \(error)")
        }
    }
    
    func cancelChallenge(challenge: PendingChallenge) async {
        do {
            // Delete the corresponding entity from CoreData.
            deleteChallengeFromCoreData(challengeID: challenge.challengeDetails.recordId)
            
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
    func convertToChallengeDetails(record: CKRecord)  -> ChallengeDetails? {
        guard let startTime = record["startTime"] as? Date,
              let endTime = record["endTime"] as? Date,
              let goalSteps = record["goalSteps"] as? Int32,
              let status = record["status"] as? String,
              let creatorUserName = record["creatorUserName"] as? String,
              let creatorRecordID = record["creatorRecordID"] as? String
        else {
            return nil
        }

        var participant: ParticipantDetails?

        // Creator
        let creatorPhotoData = record["creatorPhotoData"] as? Data
        let creatorSteps = record["creatorSteps"] as? Int32 ?? 0

        // Participant
        if let participantUserName = record["participantUserName"] as? String,
           let participantRecordID = record["participantRecordID"] as? String,
           let participantPhotoData = record["participantPhotoData"] as? Data,
           let participantSteps = record["participantSteps"] as? Int32 {
            participant = ParticipantDetails(id: participantRecordID, userName: participantUserName, photoData: participantPhotoData, steps: Int(participantSteps))
        }

        let recordId = record.recordID.recordName

        return ChallengeDetails(
            id: recordId, startTime: startTime,
            endTime: endTime,
            goalSteps: goalSteps,
            status: status,
            recordId: recordId,
            creatorUserName: creatorUserName,
            creatorPhotoData: creatorPhotoData,
            creatorSteps: Int(creatorSteps),
            creatorRecordID: creatorRecordID,
            participantUserName: participant != nil ? participant?.userName : nil,
            participantPhotoData: participant != nil ? participant?.photoData : nil,
            participantSteps:participant != nil ? participant?.steps : nil,
            participantRecordID: participant != nil ? participant?.id : nil)
    }

    private func createZoneIfNeeded() async throws {
        let zone = CKRecordZone(zoneID: recordZone.zoneID)
        let defaultsKey = "isChallengeZoneCreated_\(zone.zoneID.zoneName)"
        
        guard !UserDefaults.standard.bool(forKey: defaultsKey) else {
            print("Zone already created and cached.")
            return  // Zone already created according to UserDefaults
        }

        do {
            _ = try await cloudKitContainer.privateCloudDatabase.save(zone)
            UserDefaults.standard.set(true, forKey: defaultsKey)  // Mark as created in UserDefaults
            print("Zone created successfully.")
        } catch {
            print("Error when trying to create a zone: \(error.localizedDescription)")
            throw error
        }
    }



    
    // MARK: Updates and Notifications
    
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
//            TODO: send to publisher
            }
        } catch {
            print("Failed to fetch record: \(error)")
        }
    }


    // Handle the asynchronous logic separately
    private func handleUpdatesForChallenge(newDetails: ChallengeDetails, currentDetails: ChallengeDetails) async {
//        if currentDetails.status != newDetails.status {
//            // Significant status change
//            handleStatusChange(from: currentDetails, to: newDetails)
//        } else if currentDetails.participants != newDetails.participants {
//            // Steps might have been updated; check for goal achievement.
////            await checkForStepGoalAchievement(challengeID: newDetails.id)
//        }
    }

    private func handleStatusChange(from currentDetails: ChallengeDetails, to newDetails: ChallengeDetails) {
        switch newDetails.status {
        case "Active" where currentDetails.status == "Pending":
            AppState.shared.challengeAccepted(challengeDetails: newDetails)
        case "Completed":
            AppState.shared.challengeCompleted(challengeDetails: newDetails)
        default:
            break // No significant change detected.
        }
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
