//
//  HourlyStepData+CoreDataProperties.swift
//  myPedometer
//
//  Created by Sam Roman on 1/25/24.
//
//

import Foundation
import CoreData


extension HourlyStepData {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<HourlyStepData> {
        return NSFetchRequest<HourlyStepData>(entityName: "HourlyStepData")
    }
    
    @NSManaged public var hour: Int16
    @NSManaged public var stepCount: Int32
    @NSManaged public var date: Date?
    @NSManaged public var dailyLog: DailyLog?
    @NSManaged public var recordID: String?

    
}

extension HourlyStepData : Identifiable {
    
}
