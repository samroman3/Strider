//
//  Challenge+CoreDataProperties.swift
//  myPedometer
//
//  Created by Sam Roman on 3/14/24.
//
//

import Foundation
import CoreData
import CloudKit


extension Challenge {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Challenge> {
        return NSFetchRequest<Challenge>(entityName: "Challenge")
    }

    @NSManaged public var startTime: Date?
    @NSManaged public var endTime: Date?
    @NSManaged public var goalSteps: Int32
    @NSManaged public var status: String?
    @NSManaged public var users: NSSet?
    @NSManaged public var id: String?
    @NSManaged public var recordID: String?

}

// MARK: Generated accessors for users
extension Challenge {
    
    var isOngoing: Bool {
           guard let startTime = startTime, let endTime = endTime else { return false }
           let now = Date()
           return now >= startTime && now <= endTime
       }

    @objc(addUsersObject:)
    @NSManaged public func addToUsers(_ value: User)

    @objc(removeUsersObject:)
    @NSManaged public func removeFromUsers(_ value: User)

    @objc(addUsers:)
    @NSManaged public func addToUsers(_ values: NSSet)

    @objc(removeUsers:)
    @NSManaged public func removeFromUsers(_ values: NSSet)

}

extension Challenge : Identifiable {

}
    
    extension Challenge {
        func toCKRecord() -> CKRecord {
            let recordId = self.recordID ?? UUID().uuidString
            self.recordID = recordId // Ensure the Challenge has a recordID
            let record = CKRecord(recordType: "Challenge", recordID: CKRecord.ID(recordName: recordId))
            record["startTime"] = startTime as CKRecordValue?
            record["endTime"] = endTime as CKRecordValue?
            record["goalSteps"] = goalSteps as CKRecordValue
            record["status"] = status as CKRecordValue?
            
            return record
        }
    }


