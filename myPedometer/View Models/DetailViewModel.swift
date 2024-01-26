//
//  DetailViewModel.swift
//  myPedometer
//
//  Created by Sam Roman on 1/25/24.
//
import Foundation

enum GoalAchievementStatus {
    case achieved
    case notAchieved
}

class DetailViewModel: ObservableObject {
    @Published var hourlySteps: [HourlySteps] = []
    @Published var flightsAscended: Int = 0
    @Published var flightsDescended: Int = 0
    @Published var goalAchievementStatus: GoalAchievementStatus = .notAchieved
    @Published var dailySteps: Int = 0
    @Published var weeklyAvg: Int = 0
    @Published var dailyGoal: Int = 0
    
    private var dataStore: PedometerDataStore
    private var pedometerDataProvider: PedometerDataProvider
    private var liveDataManager: LiveDataManager?
    var date: Date
    
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var isGoalAchieved: Bool {
        dailySteps >= dailyGoal
    }
    
    var dateTitle: String {
        isToday ? "Today" : formatDate(date)
    }
    
    var insightText: String {
        if isToday {
            return "You’re walking less than you usually do by this point."
        } else {
            return "Your activity summary for the selected day."
        }
    }
    
    var highlightText: String {
        "You walked an average of \(weeklyAvg) steps a day over the last 7 days."
    }
    
    init(dataStore: PedometerDataStore, pedometerDataProvider: PedometerDataProvider, date: Date, weeklyAvg: Int, liveDataManager: LiveDataManager?) {
        self.dataStore = dataStore
        self.pedometerDataProvider = pedometerDataProvider
        self.date = date
        self.dailyGoal = dataStore.retrieveDailyGoal()
        self.weeklyAvg = weeklyAvg
        self.liveDataManager = liveDataManager
        
        loadData(for: date)
    }
    
    func loadData(for date: Date) {
        if isToday {
            // Fetch live data
            if let liveData = liveDataManager {
                self.hourlySteps = liveData.liveHourlySteps
                self.flightsAscended = liveData.liveFlightsAscended
                self.flightsDescended = liveData.liveFlightsDescended
                self.dailySteps = liveData.liveStepCount
            }
            // Set goal achievement status based on live step count
            self.goalAchievementStatus = isGoalAchieved ? .achieved : .notAchieved
        } else {
            // Fetch historical data
            dataStore.getDetailData(for: date) { detailData in
                self.hourlySteps = detailData.hourlySteps.map {
                    HourlySteps(hour: $0.hour, steps: $0.steps)
                }
                print(detailData.goalAchievementStatus)
                print(detailData.dailySteps)
                print(detailData.flightsAscended)
                print(detailData.flightsDescended)
                print(detailData.dailyGoal)
                
                self.flightsAscended = detailData.flightsAscended
                self.flightsDescended = detailData.flightsDescended
                self.dailySteps = detailData.dailySteps
                self.dailyGoal = detailData.dailyGoal
                self.goalAchievementStatus = detailData.goalAchievementStatus
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    // Additional methods for calculating insights and highlights

}
