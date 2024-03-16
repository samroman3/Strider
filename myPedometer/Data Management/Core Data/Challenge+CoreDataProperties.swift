//
//  Challenge+CoreDataProperties.swift
//  myPedometer
//
//  Created by Sam Roman on 3/14/24.
//
//

import Foundation
import CoreData


extension Challenge {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Challenge> {
        return NSFetchRequest<Challenge>(entityName: "Challenge")
    }

    @NSManaged public var startTime: Date?
    @NSManaged public var endTime: Date?
    @NSManaged public var goalSteps: Int32
    @NSManaged public var active: Bool
    @NSManaged public var users: NSSet?

}

// MARK: Generated accessors for users
extension Challenge {

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
