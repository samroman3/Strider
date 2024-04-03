//
//  Challenge+CoreDataProperties.swift
//  myPedometer
//
//  Created by Sam Roman on 4/2/24.
//
//

import Foundation
import CoreData
import CloudKit


extension Challenge {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Challenge> {
        return NSFetchRequest<Challenge>(entityName: "Challenge")
    }

    @NSManaged public var endTime: Date?
    @NSManaged public var goalSteps: Int32
    @NSManaged public var id: String?
    @NSManaged public var recordId: String?
    @NSManaged public var shareRecordID: String?
    @NSManaged public var startTime: Date?
    @NSManaged public var status: String?
    @NSManaged public var winner: String?
    @NSManaged public var creatorUserName: String?
    @NSManaged public var participantUserName: String?
    @NSManaged public var creatorRecordID: String?
    @NSManaged public var participantRecordID: String?
    @NSManaged public var creatorPhotoData: Data?
    @NSManaged public var creatorSteps: Int32
    @NSManaged public var participantSteps: Int32
    @NSManaged public var participantPhotoData: Data?
    @NSManaged public var user: NSSet?

}

// MARK: Generated accessors for user
extension Challenge {

    @objc(addUserObject:)
    @NSManaged public func addToUser(_ value: User)

    @objc(removeUserObject:)
    @NSManaged public func removeFromUser(_ value: User)

    @objc(addUser:)
    @NSManaged public func addToUser(_ values: NSSet)

    @objc(removeUser:)
    @NSManaged public func removeFromUser(_ values: NSSet)

}

extension Challenge : Identifiable {
    
    var isOngoing: Bool {
           guard let startTime = startTime, let endTime = endTime else { return false }
           let now = Date()
           return now >= startTime && now <= endTime
       }
    
    func toCKRecord() -> CKRecord {
            let recordId = self.recordId ?? UUID().uuidString
            self.recordId = recordId
            let recordZone = CKRecordZone(zoneName: "Challenges")
            let record = CKRecord(recordType: "Challenge", recordID: CKRecord.ID(recordName: recordId, zoneID: recordZone.zoneID))
            
            record["startTime"] = startTime as CKRecordValue?
            record["endTime"] = endTime as CKRecordValue?
            record["goalSteps"] = goalSteps as CKRecordValue
            record["status"] = status as CKRecordValue?
            record["recordId"] = recordId as CKRecordValue
            record["winner"] = winner as CKRecordValue?
            record["shareRecordID"] = shareRecordID as CKRecordValue?

            // Creator and participant
            record["creatorUserName"] = creatorUserName as CKRecordValue?
            record["participantUserName"] = participantUserName as CKRecordValue?
            record["creatorRecordID"] = creatorRecordID as CKRecordValue?
            record["participantRecordID"] = participantRecordID as CKRecordValue?
            record["creatorPhotoData"] = creatorPhotoData as CKRecordValue?
            record["participantPhotoData"] = participantPhotoData as CKRecordValue?
            record["creatorSteps"] = creatorSteps as CKRecordValue
            record["participantSteps"] = participantSteps as CKRecordValue

            return record
        }
}
