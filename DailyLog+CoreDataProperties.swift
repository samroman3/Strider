//
//  DailyLog+CoreDataProperties.swift
//  myPedometer
//
//  Created by Sam Roman on 1/24/24.
//
//

import Foundation
import CoreData


extension DailyLog {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DailyLog> {
        return NSFetchRequest<DailyLog>(entityName: "DailyLog")
    }

    @NSManaged public var date: Date?
    @NSManaged public var totalSteps: Int32
    @NSManaged public var flightsAscended: Int32
    @NSManaged public var flightsDescended: Int32

}

extension DailyLog : Identifiable {

}
