//
//  StepDataViewModel.swift
//  myPedometer
//
//  Created by Sam Roman on 1/24/24.
//

import Foundation
import CoreMotion

class StepDataViewModel: ObservableObject {
    @Published var liveStepCount: Int = 0
    @Published var stepDataList: [DailyLog] = []
    @Published var goalAchievementStatus: GoalAchievementStatus = .notAchieved(goal: 10000) // Example goal
    @Published var hourlySteps: [Int] = Array(repeating: 0, count: 24)

    var pedometerManager: PedometerDataProvider
    var dataStore: PedometerDataStore
    let calendar = Calendar.current
    
    enum GoalAchievementStatus {
            case achieved
            case notAchieved(goal: Int)
        }

    init(pedometerDataProvider: PedometerDataProvider, dataStore: PedometerDataStore) {
        self.pedometerManager = pedometerDataProvider
        self.dataStore = dataStore
        startLiveStepUpdates()
        fetchStepData()
    }
    
    func fetchHourlyStepData(for date: Date) {
            pedometerManager.fetchHourlySteps(for: date) { [weak self] hourlyData in
                DispatchQueue.main.async {
                    self?.hourlySteps = hourlyData
                }
            }
        }
    
    func weeklyAverageSteps() -> Int {
            let totalSteps = stepDataList.reduce(0) { $0 + Int($1.totalSteps) }
            return totalSteps / stepDataList.count
        }
    
    func checkGoalAchievement(for date: Date) {
            let dailyGoal = dataStore.retrieveDailyGoal()
            let totalStepsForDay = stepDataList.first(where: { $0.date == date })?.totalSteps ?? 0
            if totalStepsForDay >= dailyGoal {
                goalAchievementStatus = .achieved
            } else {
                goalAchievementStatus = .notAchieved(goal: dailyGoal)
            }
        }

    private func startLiveStepUpdates() {
        pedometerManager.startPedometerUpdates { [weak self] stepCount in
            DispatchQueue.main.async {
                // Only update if it's today
                if self?.isToday() ?? false {
                    self?.liveStepCount = stepCount
                }
            }
        }
    }
    func fetchStepData() {
           // Call PedometerDataStore's method to fetch data for the last seven days
           dataStore.fetchLastSevenDaysData { [weak self] dailyLogs in
               DispatchQueue.main.async {
                   self?.stepDataList = dailyLogs.filter { $0.date ?? Date() <= Date() }
                   self?.stepDataList.sort(by: { $0.date ?? Date() > $1.date ?? Date() })
               }
           }
       }

     func isToday() -> Bool {
        return calendar.isDateInToday(Date())
    }
}
