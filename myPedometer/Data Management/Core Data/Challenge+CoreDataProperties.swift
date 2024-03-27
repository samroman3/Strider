//
//  Challenge+CoreDataProperties.swift
//  myPedometer
//
//  Created by Sam Roman on 3/27/24.
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
    @NSManaged public var startTime: Date?
    @NSManaged public var status: String?
    @NSManaged public var winner: String?
    @NSManaged public var participants: NSSet?

}

// MARK: Generated accessors for participants
extension Challenge {
    
    var isOngoing: Bool {
           guard let startTime = startTime, let endTime = endTime else { return false }
           let now = Date()
           return now >= startTime && now <= endTime
       }

    @objc(addParticipantsObject:)
    @NSManaged public func addToParticipants(_ value: User)

    @objc(removeParticipantsObject:)
    @NSManaged public func removeFromParticipants(_ value: User)

    @objc(addParticipants:)
    @NSManaged public func addToParticipants(_ values: NSSet)

    @objc(removeParticipants:)
    @NSManaged public func removeFromParticipants(_ values: NSSet)

}

extension Challenge : Identifiable {

}


extension Challenge {
    func toCKRecord() -> CKRecord {
        let recordId = self.recordId ?? UUID().uuidString
        self.recordId = recordId // Ensure the Challenge has a recordID
        let record = CKRecord(recordType: "Challenge", recordID: CKRecord.ID(recordName: recordId))
        record["startTime"] = startTime as CKRecordValue?
        record["endTime"] = endTime as CKRecordValue?
        record["goalSteps"] = goalSteps as CKRecordValue
        record["status"] = status as CKRecordValue?
        record["recordId"] = recordId as CKRecordValue
        record["winner"] = winner as CKRecordValue?
        
        return record
    }
}
