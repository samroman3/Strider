//
//  DetailViewModel.swift
//  myPedometer
//
//  Created by Sam Roman on 1/25/24.
//
import Foundation
import Combine

enum GoalAchievementStatus {
    case achieved
    case notAchieved
}

class DetailViewModel: ObservableObject {
    @Published var hourlySteps: [HourlySteps] = []
    @Published var averageHourlySteps: [HourlySteps] = []
    @Published var flightsAscended: Int = 0
    @Published var flightsDescended: Int = 0
    @Published var goalAchievementStatus: GoalAchievementStatus = .notAchieved
    @Published var dailySteps: Int = 0
    @Published var weeklyAvg: Int = 0
    @Published var dailyGoal: Int
    @Published var mostActiveHour: Int = 0
    @Published var leastActiveHour: Int = 0
    @Published var mostActivePeriod: String = ""
    @Published var todayVsWeeklyAverage: String = ""
    
    
    var insights: [String] {
        var insightsArray = [String]()
        insightsArray.append("You walked an average of \(weeklyAvg) steps a day over the last 7 days.")
        insightsArray.append("Most active hour: \(DateFormatterService.shared.formatHour(mostActiveHour))")
        insightsArray.append("Least active hour: \(DateFormatterService.shared.formatHour(leastActiveHour))")
        insightsArray.append("Most active period of the day: \(mostActivePeriod)")
        insightsArray.append("Today's activity is \(todayVsWeeklyAverage) than the weekly average.")
        return insightsArray
    }
    
    var pedometerDataProvider: PedometerDataProvider & PedometerDataObservable
    
    var date: Date
    
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var isGoalAchieved: Bool {
        dailySteps >= dailyGoal
    }
    
    var dateTitle: String {
        isToday ? "Today" : DateFormatterService.shared.format(date: date, style: .long)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init(pedometerDataProvider: PedometerDataProvider & PedometerDataObservable, date: Date, weeklyAvg: Int) {
        self.pedometerDataProvider = pedometerDataProvider
        self.date = date
        self.dailyGoal = pedometerDataProvider.retrieveDailyGoal()
        self.weeklyAvg = weeklyAvg
        self.averageHourlySteps = pedometerDataProvider.calculateWeeklyAverageHourlySteps(includeToday: false)
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
                self.calculateAdditionalInsights()
            }
        }
    }
    

    
    func calculateAdditionalInsights() {
        calculateMostAndLeastActiveHours()
        calculateMostActivePeriodOfDay()
        compareTodayWithWeeklyAverage()
    }
    
    private func calculateMostAndLeastActiveHours() {
        guard !hourlySteps.isEmpty else { 
            
            return }
        
        let sortedBySteps = hourlySteps.sorted { $0.steps > $1.steps }
        mostActiveHour = sortedBySteps.first?.hour ?? 0
        leastActiveHour = sortedBySteps.last?.hour ?? 0
    }
    
    private func calculateMostActivePeriodOfDay() {
        // morning: 5 AM - 12 PM, afternoon: 12 PM - 5 PM, evening: 5 PM - 9 PM
        let morningSteps = hourlySteps.filter { 5...11 ~= $0.hour }.reduce(0) { $0 + $1.steps }
        let afternoonSteps = hourlySteps.filter { 12...16 ~= $0.hour }.reduce(0) { $0 + $1.steps }
        let eveningSteps = hourlySteps.filter { 17...20 ~= $0.hour }.reduce(0) { $0 + $1.steps }
        
        let maxSteps = max(morningSteps, afternoonSteps, eveningSteps)
        switch maxSteps {
        case morningSteps:
            mostActivePeriod = "Morning"
        case afternoonSteps:
            mostActivePeriod = "Afternoon"
        default:
            mostActivePeriod = "Evening"
        }
    }
    
    private func compareTodayWithWeeklyAverage() {
        let todayTotalSteps = hourlySteps.reduce(0, { $0 + $1.steps })
        todayVsWeeklyAverage = todayTotalSteps > weeklyAvg ? "more active" : "less active"
    }
}
