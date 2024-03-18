//
//  DailyLog+CoreDataProperties.swift
//  myPedometer
//
//  Created by Sam Roman on 1/25/24.
//
//

import Foundation
import CoreData


extension DailyLog {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DailyLog> {
        return NSFetchRequest<DailyLog>(entityName: "DailyLog")
    }
    
    @NSManaged public var date: Date?
    @NSManaged public var flightsAscended: Int32
    @NSManaged public var flightsDescended: Int32
    @NSManaged public var totalSteps: Int32
    @NSManaged public var hourlyStepData: NSSet?
    @NSManaged public var caloriesBurned: Int32
    @NSManaged public var calGoal: Int32
    @NSManaged public var stepsGoal: Int32
    @NSManaged public var user: User?
    @NSManaged public var recordID: String?

}

// MARK: Generated accessors for hourlyStepData
extension DailyLog {
    
    @objc(addHourlyStepDataObject:)
    @NSManaged public func addToHourlyStepData(_ value: HourlyStepData)
    
    @objc(removeHourlyStepDataObject:)
    @NSManaged public func removeFromHourlyStepData(_ value: HourlyStepData)
    
    @objc(addHourlyStepData:)
    @NSManaged public func addToHourlyStepData(_ values: NSSet)
    
    @objc(removeHourlyStepData:)
    @NSManaged public func removeFromHourlyStepData(_ values: NSSet)
    
}

extension DailyLog : Identifiable {
    
}
