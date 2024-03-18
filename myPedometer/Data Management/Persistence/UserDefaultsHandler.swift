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
    private let dailyCalGoalKey = "dailyCalGoal"
    
    private init() {}
    
    func storeLastOpenedDate(_ date: Date) {
        UserDefaults.standard.set(date, forKey: lastOpenedDateKey)
    }
    
    func retrieveLastOpenedDate() -> Date? {
        return UserDefaults.standard.object(forKey: lastOpenedDateKey) as? Date
    }
    
    func storeDailyStepGoal(_ goal: Int) {
        UserDefaults.standard.set(goal, forKey: dailyStepGoalKey)
    }
    
    func retrieveDailyStepGoal() -> Int? {
        return UserDefaults.standard.integer(forKey: dailyStepGoalKey)
    }
    func storeDailyCalGoal(_ goal: Int) {
        UserDefaults.standard.set(goal, forKey: dailyCalGoalKey)
    }
    
    func retrieveDailyCalGoal() -> Int? {
        return UserDefaults.standard.integer(forKey: dailyCalGoalKey)
    }
}
