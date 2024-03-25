//
//  DetailViewModel.swift
//  myPedometer
//
//  Created by Sam Roman on 1/25/24.
//
import Foundation
import Combine

class DetailViewModel: ObservableObject {
    @Published var hourlySteps: [HourlySteps] = []
    @Published var averageHourlySteps: [HourlySteps] = []
    @Published var goalAchievementStatus: GoalAchievementStatus = .notAchieved
    @Published var dailySteps: Int = 0
    @Published var weeklyAvg: Int = 0
    @Published var dailyGoal: Int
    @Published var todayLog: DailyLog?
    @Published var flightsAscended: Int = 0
    @Published var flightsDescended: Int = 0
    @Published var mostActiveHour: Int = 0
    @Published var leastActiveHour: Int = 0
    @Published var mostActivePeriod: String = ""
    @Published var todayVsWeeklyAverage: String = ""
    @Published var error: UserFriendlyError?
    
    
    // Computed property for generating insights based on pedometer data.
    var insights: [String] {
        var insightsArray = [String]()
        insightsArray.append("You walked an average of \(weeklyAvg) steps a day over the last 7 days.")
        insightsArray.append("Most active hour: \(DateFormatterService.shared.formatHour(mostActiveHour))")
        insightsArray.append("Least active hour: \(DateFormatterService.shared.formatHour(leastActiveHour))")
        insightsArray.append("Most active period of the day: \(mostActivePeriod)")
        insightsArray.append("Today's activity is \(todayVsWeeklyAverage) than the weekly average.")
        return insightsArray
    }
    
    var date: Date
    
    // Dependency for fetching pedometer data.
    var pedometerDataProvider: PedometerDataProvider & PedometerDataObservable
    
    
    
    // Computed property to check if the date is today.
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    // Computed property to check if the daily goal is achieved.
    var isGoalAchieved: Bool {
        dailySteps >= dailyGoal
    }
    
    // Computed property for formatting the date title.
    var dateTitle: String {
        isToday ? "Today" : DateFormatterService.shared.format(date: date, style: .long)
    }
    // Set for storing cancellable instances
    private var cancellables = Set<AnyCancellable>()
    
    // Initializer
    init(pedometerDataProvider: PedometerDataProvider & PedometerDataObservable, date: Date, weeklyAvg: Int, averageHourlySteps: [HourlySteps]) {
        self.pedometerDataProvider = pedometerDataProvider
        self.date = date
        self.dailyGoal = UserDefaultsHandler.shared.retrieveDailyStepGoal() ?? 0
        self.weeklyAvg = weeklyAvg
        self.averageHourlySteps = averageHourlySteps
        
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        pedometerDataProvider.todayLogPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] value in
                if self?.isToday == true {
                    self?.dailySteps = Int(value?.totalSteps ?? 0)
                }
            })
            .store(in: &cancellables)
        
        pedometerDataProvider.detailDataPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] detailData in
                self?.updateProperties(with: detailData)
            }
            .store(in: &cancellables)
        
        self.pedometerDataProvider.errorPublisher
            .compactMap { $0 } // Filter out nil errors
            .sink { [weak self] error in
                self?.handleError(error)
            }
            .store(in: &cancellables)
    }
    
    private func handleError(_ error: Error) {
        self.error = UserFriendlyError(error: error) // Pass the error to the view model
    }
    
    //Fetch on detailview appear
    func fetchData() {
        pedometerDataProvider.fetchDetailData(for: date)
    }
    
    //Update properties according to subscribed detailData
    private func updateProperties(with detailData: DetailData?) {
        guard let detailData = detailData else { return }
        self.hourlySteps = detailData.hourlySteps
        self.flightsAscended = detailData.flightsAscended
        self.dailySteps = detailData.dailySteps
        self.goalAchievementStatus = self.isGoalAchieved ? .achieved : .notAchieved
        self.goalAchievementStatus = isGoalAchieved ? .achieved : .notAchieved
        self.calculateAdditionalInsights()
    }
    
    
    
    // Methods for calculating insights based on the pedometer data.
    func calculateAdditionalInsights() {
        let activeHours = PedometerDataProcessor.calculateMostAndLeastActiveHours(hourlySteps: hourlySteps)
        mostActiveHour = activeHours.mostActive
        leastActiveHour = activeHours.leastActive
        
        mostActivePeriod = PedometerDataProcessor.calculateMostActivePeriodOfDay(hourlySteps: hourlySteps)
        todayVsWeeklyAverage = PedometerDataProcessor.compareTodayWithWeeklyAverage(todayTotalSteps: dailySteps, weeklyAvg: weeklyAvg)
    }
}
