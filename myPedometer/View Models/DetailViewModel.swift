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
    @Published var flightsAscended: Int = 0
    @Published var flightsDescended: Int = 0
    @Published var goalAchievementStatus: GoalAchievementStatus = .notAchieved
    @Published var dailySteps: Int = 0
    @Published var weeklyAvg: Int = 0
    @Published var dailyGoal: Int = 0
    
    var pedometerDataProvider: PedometerDataProvider & PedometerDataObservable
    
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
    
    private var cancellables = Set<AnyCancellable>()
    
    init(pedometerDataProvider: PedometerDataProvider & PedometerDataObservable, date: Date, weeklyAvg: Int) {
        self.pedometerDataProvider = pedometerDataProvider
        self.date = date
        self.dailyGoal = pedometerDataProvider.retrieveDailyGoal()
        self.weeklyAvg = weeklyAvg
        loadData(for: date)
    }
    
        func subscribeToUpdates() {
            pedometerDataProvider.todayLogPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] (log: DailyLog?) in
                    if let log = log, Calendar.current.isDateInToday(log.date ?? Date()) {
                        self?.updateView(with: log)
                    }
                }
                .store(in: &cancellables)
        }
    

    private func updateView(with log: DailyLog) {
        if let hourlyData = log.hourlyStepData as? Set<HourlyStepData> {
            let sortedHourlyData = hourlyData.sorted { $0.hour < $1.hour }
            self.hourlySteps = sortedHourlyData.map { HourlySteps(hour: Int($0.hour), steps: Int($0.stepCount)) }
        } else {
            self.hourlySteps = []
        }
        print("log updated: \(log.totalSteps)")
        self.flightsAscended = Int(log.flightsAscended)
        self.flightsDescended = Int(log.flightsDescended)
        self.dailySteps = Int(log.totalSteps)
        self.goalAchievementStatus = isGoalAchieved ? .achieved : .notAchieved
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
