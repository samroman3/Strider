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
    
    private var pedometerDataProvider: PedometerDataProvider
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
    
    init(pedometerDataProvider: PedometerDataProvider, date: Date, weeklyAvg: Int) {
        self.pedometerDataProvider = pedometerDataProvider
        self.date = date
        self.dailyGoal = pedometerDataProvider.retrieveDailyGoal()
        self.weeklyAvg = weeklyAvg
        loadData(for: date)
    }
    
    func loadData(for date: Date) {
        pedometerDataProvider.getDetailData(for: date) { detailData in
            DispatchQueue.main.async {
                self.hourlySteps = detailData.hourlySteps
                self.flightsAscended = detailData.flightsAscended
                self.flightsDescended = detailData.flightsDescended
                self.dailySteps = detailData.dailySteps
                self.goalAchievementStatus = self.isGoalAchieved ? .achieved : .notAchieved
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}
