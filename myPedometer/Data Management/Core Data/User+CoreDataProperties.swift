//
//  User+CoreDataProperties.swift
//  myPedometer
//
//  Created by Sam Roman on 3/14/24.
//
//

import Foundation
import CoreData


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

extension User : Identifiable {

}
