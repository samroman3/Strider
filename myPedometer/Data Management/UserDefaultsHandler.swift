//
//  UserDefaultsHandler.swift
//  myPedometer
//
//  Created by Sam Roman on 1/29/24.
//

import Foundation
class UserDefaultsHandler {
    static let shared = UserDefaultsHandler()
    
    private let lastOpenedDateKey = "lastOpenedDate"
    private let dailyStepGoalKey = "dailyStepGoal"
    
    private init() {}
    
    func storeLastOpenedDate(_ date: Date) {
        UserDefaults.standard.set(date, forKey: lastOpenedDateKey)
    }
    
    func retrieveLastOpenedDate() -> Date? {
        return UserDefaults.standard.object(forKey: lastOpenedDateKey) as? Date
    }
    
    func storeDailyGoal(_ goal: Int) {
        UserDefaults.standard.set(goal, forKey: dailyStepGoalKey)
    }
    
    func retrieveDailyGoal() -> Int? {
        return UserDefaults.standard.integer(forKey: dailyStepGoalKey)
    }
}
