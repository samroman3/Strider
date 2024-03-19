//
//  User+CoreDataProperties.swift
//  myPedometer
//
//  Created by Sam Roman on 3/14/24.
//
//

import Foundation
import CoreData
import CloudKit


extension User {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }

    @NSManaged public var calorieRecord: Int32
    @NSManaged public var lifetimeSteps: Int32
    @NSManaged public var photoData: Data?
    @NSManaged public var stepsRecord: Int32
    @NSManaged public var userName: String?
    @NSManaged public var appleId: String?
    @NSManaged public var challenges: NSSet?
    @NSManaged public var dailyLogs: NSSet?
    @NSManaged public var recordID: String?

}

// MARK: Generated accessors for challenges
extension User {

    @objc(addChallengesObject:)
    @NSManaged public func addToChallenges(_ value: Challenge)

    @objc(removeChallengesObject:)
    @NSManaged public func removeFromChallenges(_ value: Challenge)

    @objc(addChallenges:)
    @NSManaged public func addToChallenges(_ values: NSSet)

    @objc(removeChallenges:)
    @NSManaged public func removeFromChallenges(_ values: NSSet)

}

extension User {

    @objc(addDailyLogsObject:)
    @NSManaged public func addToDailyLogs(_ value: DailyLog)

    @objc(removeDailyLogsObject:)
    @NSManaged public func removeFromDailyLogs(_ value: DailyLog)

    @objc(addDailyLogs:)
    @NSManaged public func addToDailyLogs(_ values: NSSet)

    @objc(removeDailyLogs:)
    @NSManaged public func removeFromDailyLogs(_ values: NSSet)

}

extension User : Identifiable {

}

extension User {
    
    // Check if a log exists for a specific date or create a new one
    func dailyLog(for date: Date) -> DailyLog? {
        let calendar = Calendar.current
        
        // Try to find an existing log for the specified date
        if let dailyLogs = self.dailyLogs as? Set<DailyLog> {
            for log in dailyLogs {
                if let logDate = log.date, calendar.isDate(logDate, inSameDayAs: date) {
                    return log
                }
            }
        }
        
        // No existing log found
        return nil
    }
}

extension User {
    func toCKRecord(recordID: String) -> CKRecord {
        let record = CKRecord(recordType: "User", recordID: CKRecord.ID(recordName: recordID))
        
        // Set user-specific properties
        record["userName"] = self.userName
        record["photoData"] = self.photoData
        record["recordID"] = self.recordID
        
        return record
    }
}
