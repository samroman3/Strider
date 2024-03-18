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

    func createChallenge(with details: ChallengeDetails) async throws {
        DispatchQueue.main.async { [weak self] in
               self?.state = .loading
           }

        let challengeRecord = CKRecord(recordType: "Challenge", recordID: CKRecord.ID(recordName: details.recordId))
        challengeRecord["startTime"] = details.startTime as NSDate
        challengeRecord["endTime"] = details.endTime as NSDate
        challengeRecord["goalSteps"] = details.goalSteps as NSNumber
        challengeRecord["active"] = details.active as NSNumber

        // Assuming that `users` are participant iCloud user record names, not directly included in CKRecord here
        
        let operation = CKModifyRecordsOperation(recordsToSave: [challengeRecord], recordIDsToDelete: nil)
        operation.modifyRecordsCompletionBlock = { [weak self] savedRecords, deletedRecordIDs, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let error = error {
                    self.state = .error(ManagerError.challengeCreationFailed)
                    print("Error creating challenge: \(error.localizedDescription)")
                } else {
                    self.state = .loaded
                    print("Challenge created successfully")
                    // Optionally update local storage or perform additional actions here
                }
            }
        }

        cloudKitContainer.privateCloudDatabase.add(operation)
    }
    
//    func shareChallenge(_ challenge: Challenge, with participants: [User]) async throws {
//        // Convert the Challenge object to a CKRecord using the extension method
//        let record = challenge.toCKRecord()
//        
//        // Now that you have the CKRecord, you can proceed with creating a CKShare for it
//        let share = CKShare(rootRecord: record)
//        share[CKShare.SystemFieldKey.title] = "Join My Challenge!" // Customize as needed
//
//        // If you need to customize the share further, such as setting permissions for participants
//        // or adding participants to the CKShare, you would do that here.
//        
//        // For example, setting public permissions (adjust according to your app's privacy requirements)
//        share.publicPermission = .readWrite
//        
//        // Create an operation to save both the record and the share
//        let operation = CKModifyRecordsOperation(recordsToSave: [record, share], recordIDsToDelete: nil)
//        operation.modifyRecordsCompletionBlock = { [weak self] savedRecords, deletedRecordIDs, error in
//            DispatchQueue.main.async {
//                guard let self = self else { return }
//                if let error = error {
//                    self.state = .error(ManagerError.sharingFailed)
//                    print("Error sharing challenge: \(error.localizedDescription)")
//                } else {
//                    self.state = .loaded
//                    print("Challenge shared successfully")
//                }
//            }
//        }
//        
//        // Add the operation to the database
//        cloudKitContainer.privateCloudDatabase.add(operation)
//    }
    


    
    func addUserToChallenge(_ user: User, to challengeID: String) {
        let fetchRequest: NSFetchRequest<Challenge> = Challenge.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "recordID == %@", challengeID)
        
        do {
            let challenges = try context.fetch(fetchRequest)
            if let challenge = challenges.first {
                challenge.addToUsers(user)
                
                try context.save()
            }
        } catch {
            // Handle the error appropriately
            print("Failed to add user to challenge: \(error)")
        }
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

}

extension Challenge {
    func configure(with details: ChallengeDetails, participants: [User]) {
        // Assign details to the properties
        self.startTime = details.startTime
        self.endTime = details.endTime
        self.goalSteps = details.goalSteps
        // Add participants, etc.
    }
}


//class ChallengeManager: ObservableObject {
////    static let shared = ChallengeManager()
//    
//    enum ViewModelError: Error {
//        case invalidRemoteShare
//        case failedToFetchChallenges(Error)
//    }
//    
//    enum State {
//        case loading
//        case loaded(private: [Challenge], shared: [Challenge])
//        case error(Error)
//    }
//    
//    @Published private(set) var state: State = .loading
//    
//    private var userSettingsManager: UserSettingsManager
//    private let context: NSManagedObjectContext
//    
//    lazy var container = CKContainer(identifier: "iCloud.com.example.myPedometer") // Replace with your container identifier
//    private lazy var database = container.privateCloudDatabase
//    let recordZone = CKRecordZone(zoneName: "Challenges")
//    
//    
//    init(userSettingsManager: UserSettingsManager) {
//        self.userSettingsManager = userSettingsManager
//        self.context = userSettingsManager.context!
//        self.state = state
//        
//    }
//}
//
//        nonisolated init() {}
//       
//        
//        func initialize() async throws {
//            do {
//                try await createZoneIfNeeded()
//            } catch {
//                state = .error(error)
//            }
//        }
//        
//        func refresh() async throws {
//            state = .loading
//            do {
//                let (privateChallenges, sharedChallenges) = try await fetchPrivateAndSharedChallenges()
//                state = .loaded(private: privateChallenges, shared: sharedChallenges)
//            } catch {
//                state = .error(error)
//            }
//        }
//        
//        func fetchPrivateAndSharedChallenges() async throws -> (private: [Challenge], shared: [Challenge]) {
//            async let privateChallenges = fetchChallenges(scope: .private, in: [recordZone])
//            async let sharedChallenges = fetchSharedChallenges()
//            
//            return (private: try await privateChallenges, shared: try await sharedChallenges)
//        }
//        
//    func createFriendship(with user: User) async throws {
//            do {
//                // Create and save a friendship record
//                let friendshipRecord = CKRecord(recordType: "Friendship")
//                friendshipRecord["participant"] = CKRecord.Reference(recordID: user.recordID!, action: .none)
//                friendshipRecord["user"] = CKRecord.Reference(recordID: userSettingsManager.currentUser.recordID!, action: .none)
//                _ = try await database.save(friendshipRecord)
//            } catch {
//                throw error
//            }
//        }
//

//        
//        func fetchOrCreateShare(for challenge: Challenge) async throws -> (CKShare, CKContainer) {
//            guard let existingShare = challenge.recordID else {
//                let share = CKShare(rootRecord: challenge)
//                share[CKShare.SystemFieldKey.title] = "Challenge: \(challenge.id ?? "")"
//                _ = try await database.modifyRecords(saving: [challenge.associatedRecord, share], deleting: [])
//                return (share, container)
//            }
//            
//            guard let share = try await database.record(for: CKRecord.ID(recordName: existingShare)) as? CKShare else {
//                throw ViewModelError.invalidRemoteShare
//            }
//            
//            return (share, container)
//        }
//        
//        private func fetchChallenges(scope: CKDatabase.Scope, in zones: [CKRecordZone]) async throws -> [Challenge] {
//            let database = container.database(with: scope)
//            var allChallenges: [Challenge] = []
//            
//            @Sendable func challengesInZone(_ zone: CKRecordZone) async throws -> [Challenge] {
//                var allChallenges: [Challenge] = []
//                
//                var awaitingChanges = true
//                var nextChangeToken: CKServerChangeToken? = nil
//                
//                while awaitingChanges {
//                    let zoneChanges = try await database.recordZoneChanges(inZoneWith: zone.zoneID, since: nextChangeToken)
//                    let challenges = zoneChanges.modificationResultsByID.values
//                        .compactMap { try? $0.get().record }
//                        .compactMap { Challenge(record: $0, context: context) }
//                    allChallenges.append(contentsOf: challenges)
//                    
//                    awaitingChanges = zoneChanges.moreComing
//                    nextChangeToken = zoneChanges.changeToken
//                }
//                
//                return allChallenges
//            }
//            
//            do {
//                try await withThrowingTaskGroup(of: [Challenge].self) { group in
//                    for zone in zones {
//                        group.addTask {
//                            try await challengesInZone(zone)
//                        }
//                    }
//                    
//                    for try await challengesResult in group {
//                        allChallenges.append(contentsOf: challengesResult)
//                    }
//                }
//            } catch {
//                throw ViewModelError.failedToFetchChallenges(error)
//            }
//            
//            return allChallenges
//        }
//        
//        private func fetchSharedChallenges() async throws -> [Challenge] {
//            let sharedZones = try await container.sharedCloudDatabase.allRecordZones()
//            guard !sharedZones.isEmpty else {
//                return []
//            }
//            
//            return try await fetchChallenges(scope: .shared, in: sharedZones)
//        }
//        
//        private func createZoneIfNeeded() async throws {
//            guard !UserDefaults.standard.bool(forKey: "isChallengeZoneCreated") else {
//                return
//            }
//            
//            do {
//                _ = try await database.modifyRecordZones(saving: [recordZone], deleting: [])
//            } catch {
//                print("ERROR: Failed to create custom zone: \(error.localizedDescription)")
//                throw error
//            }
//            
//            UserDefaults.standard.setValue(true, forKey: "isChallengeZoneCreated")
//        }
//    }
